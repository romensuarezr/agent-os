# Runbook: Orquestación Multi-Agente en Orca ADE

> **Guía Operativa y Arquitectura de Ejecución Concurrente**  
> **Área**: Orquestación / Multi-Agente / Workspaces / HITL  
> **Fecha**: 2026-09-25  
> **Estado**: Activo (Versión 1.0)  
> **Herramienta CLI**: `scripts/agent/orca-orchestrate.sh`

---

## 1. Introducción y Conceptos Fundamentales

Orca ADE (*Agent Development Environment*) es el entorno de desarrollo y orquestación diseñado para ejecutar, supervisar y sincronizar múltiples agentes de software de forma concurrente sobre repositorios locales y servidores remotos.

Para operar eficazmente con Orca ADE, es esencial comprender la jerarquía de sus tres conceptos estructurales:

```
PROYECTO (Durable Project)
  │  Ej: github:romensuarezr/agent-os (identidad del repositorio y metadata)
  │
  ├── HOST LOCAL (/home/romen/Proyectos/agent-os)
  └── HOSTS REMOTOS (datamanager o oracle vía SSH)
        │
        ├── WORKSPACE / WORKTREE 1 (feat/auth) ──▶ Worker A (Developer en OpenCode - $0)
        ├── WORKSPACE / WORKTREE 2 (test/auth) ──▶ Worker B (Reviewer en OpenCode - $0)
        └── WORKSPACE / WORKTREE 3 (docs/api)  ──▶ Worker C (Writer en OpenCode - $0)
```

### Diferencias Clave:
1. **Proyecto (`Project`)**: Entidad permanente en Orca que asocia tu repositorio git con tus cuentas (GitHub, etc.), variables y entornos de computación (local y servidores SSH).
2. **Espacio de Trabajo / Worktree (`Workspace / Worktree`)**: Un checkout independiente de git (`git worktree`) generado en un subdirectorio aislado (ej. `/home/romen/orca/workspaces/agent-os/tarea-1`).
   - Cada agente trabaja en su propio directorio con su propia rama.
   - **Aislamiento total**: Múltiples agentes pueden editar archivos al mismo tiempo sin colisiones de git ni sobrescritura accidental.
   - Cada worktree posee sus propios terminales PTY y navegador embebido para pruebas visuales o webviews.
3. **Terminales y Agentes (`Terminals & Agents`)**: Procesos PTY embebidos donde se ejecutan los agentes soportados (`antigravity`, `opencode`, `codex`, `claude`, `hermes`).

---

## 2. El Mandato de Inferencia $0 en la Orquestación

Para garantizar que el trabajo en paralelo no dispare costes ni agote las cuotas de tokens comerciales:

- **Coordinador**: Se ejecuta en **Antigravity CLI (`agy` / `agy2`)** utilizando modelos de alto razonamiento (Claude 3.5 Sonnet / Gemini Pro). Su labor es puramente estratégica: trocear la épica, redactar contratos de subtareas y auditar el diff final.
- **Workers (Trabajadores de Ejecución)**: Tienen **prohibido consumir saldo o cuotas de pago**. Se despachan con **OpenCode CLI** conectándose a nuestras pasarelas de coste $0:
  - `freellmapi` en `datamanager:3001` ($0.00 / token).
  - `omniroute` (pasarela con 150+ modelos gratuitos).
  - `ollama` en `datamanager:11434` (offline / privado).

---

## 3. Patrones de Trabajo Multi-Agente

### Patrón A: Paralelismo Autónomo por Handoff (Features Independientes)
Útil cuando deseas delegar dos o tres tareas que no tienen dependencia mutua directa:

```bash
# Despachar Agente 1 (OpenCode en rama feat-auth)
orca worktree create --repo name:agent-os --name feat-auth --no-parent --agent opencode --prompt "Implementar validador de tokens JWT en auth.ts"

# Despachar Agente 2 en paralelo (OpenCode en rama feat-docs)
orca worktree create --repo name:agent-os --name feat-docs --no-parent --agent opencode --prompt "Documentar endpoints en docs/api.md"

# Consultar el estado de todos los worktrees activos
orca worktree ps
```

---

### Patrón B: Orquestación Supervisada con Coordinador (DAG y Decision Gates)
El flujo completo donde un Coordinador divide una tarea en subtareas, despacha trabajadores en paralelo y espera su resolución.

```text
               ┌────────────────────────┐
               │   COORDINADOR (Orca)   │
               └───────────┬────────────┘
                           │
       ┌───────────────────┴───────────────────┐
       ▼                                       ▼
┌──────────────┐                       ┌──────────────┐
│   WORKER 1   │                       │   WORKER 2   │
│  Developer   │                       │   Reviewer   │
│  (Worktree)  │                       │  (Worktree)  │
└──────┬───────┘                       └──────┬───────┘
       │                                       │
       ▼                                       ▼
   ¿Duda? ──▶ orca ask (pregunta bloqueante al coordinador)
   ¿Fin?  ──▶ worker_done con resumen de cambios
```

#### Paso 1: Inicializar el Run de Orquestación
```bash
bash scripts/agent/orca-orchestrate.sh create-run --objective "Refactorizar arquitectura de autenticación y suite de tests"
```
*Salida:* Genera un identificador de Run, ej: `run_6f65ff2df394`.

#### Paso 2: Crear Tareas Asociadas al Run
```bash
# Subtarea A (Developer)
bash scripts/agent/orca-orchestrate.sh create-task \
  --run "run_6f65ff2df394" \
  --title "Implementar nuevo middleware de permisos" \
  --spec "Target: src/middleware/auth.ts. Change: añadir comprobación L1/L2/L3. Invariants: no romper retrocompatibilidad."

# Subtarea B (Reviewer / Tests)
bash scripts/agent/orca-orchestrate.sh create-task \
  --run "run_6f65ff2df394" \
  --title "Escribir arnés de pruebas unitarias" \
  --spec "Target: tests/auth/. Change: crear tests para permisos L1/L2/L3. Acceptance: todos los tests pasando."
```

#### Paso 3: Despachar Workers Concurrentes en Worktrees Aislados
```bash
# Despachar Developer ($0 inferencia)
bash scripts/agent/orca-orchestrate.sh dispatch-worker \
  --run "run_6f65ff2df394" \
  --title "Middleware Auth" \
  --spec "Implementar nuevo middleware de permisos en src/middleware/auth.ts" \
  --agent opencode \
  --role developer \
  --name wt-auth-middleware

# Despachar Reviewer en paralelo ($0 inferencia)
bash scripts/agent/orca-orchestrate.sh dispatch-worker \
  --run "run_6f65ff2df394" \
  --title "Tests Auth" \
  --spec "Escribir tests unitarios en tests/auth/ para el nuevo middleware" \
  --agent opencode \
  --role reviewer \
  --name wt-auth-tests
```

#### Paso 4: Monitoreo y Supervisión de Eventos
El Coordinador no realiza esperas ciegas ni bucles activos que quemen recursos. Consulta el estado de los workers o espera eventos de finalización:
```bash
# Supervisión periódica de eventos
bash scripts/agent/orca-orchestrate.sh check-events --run "run_6f65ff2df394"

# O espera bloqueante con timeout
bash scripts/agent/orca-orchestrate.sh check-events --run "run_6f65ff2df394" --wait --timeout-ms 300000
```

---

## 4. Compuertas de Decisión (Decision Gates — Nivel L3)

Cuando un agente worker detecta que una acción mutaría infraestructura remota, eliminaría tablas en bases de datos o afectaría a secretos de producción, la política de permisos L3 exige la creación de una **Decision Gate**:

```bash
# Crear compuerta bloqueante
bash scripts/agent/orca-orchestrate.sh create-gate \
  --task "<task_id>" \
  --question "¿Autorizas la ejecución de migraciones en la base de datos de producción?"

# Listar compuertas pendientes
bash scripts/agent/orca-orchestrate.sh list-gates --run "<run_id>"

# Resolver compuerta tras confirmación humana
bash scripts/agent/orca-orchestrate.sh resolve-gate \
  --id "<gate_id>" \
  --resolution "Aprobado por el operador"
```

El worker en Orca permanece en pausa hasta que la compuerta cambia a `status: resolved`, garantizando seguridad absoluta frente a mutaciones autónomas imprevistas.

---

## 5. Recetas y Comandos Rápidos CLI

| Acción | Comando |
| :--- | :--- |
| **Diagnóstico del Runtime** | `bash scripts/agent/orca-orchestrate.sh status` |
| **Listar Runs Activos** | `bash scripts/agent/orca-orchestrate.sh list-runs` |
| **Despacho Rápido en Lote** | `bash scripts/agent/orca-orchestrate.sh batch --objective "<obj>" --spec-file <plan.json>` |
| **Comprobar Eventos** | `bash scripts/agent/orca-orchestrate.sh check-events --run <id>` |
| **Listar Decision Gates** | `bash scripts/agent/orca-orchestrate.sh list-gates --run <id>` |
