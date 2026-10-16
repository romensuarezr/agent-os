# Runbook: Orquestación Multi-Agente en Orca ADE

> **Guía Operativa y Arquitectura de Ejecución Concurrente**
> **Área**: Orquestación / Multi-Agente / Workspaces / HITL
> **Fecha**: 2026-10-16 (v2.0, reescrito contra el runtime: T-105)
> **Estado**: Activo
> **Herramienta CLI**: `scripts/agent/orca-orchestrate.sh`
> **Capas**: ver `docs/architecture/orchestration-layers.md` (qué capa decide qué)

---

## 1. Introducción y Conceptos Fundamentales

Orca ADE (*Agent Development Environment*) es el entorno de desarrollo y orquestación diseñado para ejecutar, supervisar y sincronizar múltiples agentes de software de forma concurrente sobre repositorios locales y servidores remotos.

Jerarquía estructural:

```
PROYECTO (Durable Project)
  │  Ej: github:<owner>/<repo> (identidad del repositorio y metadata)
  │
  ├── HOST LOCAL (/ruta/local/al/repositorio)
  └── HOSTS REMOTOS (servidores definidos en .agents/config/fleet.yaml vía SSH)
        │
        ├── WORKSPACE / WORKTREE 1 (feat/auth) ──▶ Worker A (Developer en OpenCode - $0)
        ├── WORKSPACE / WORKTREE 2 (test/auth) ──▶ Worker B (Reviewer en OpenCode - $0)
        └── WORKSPACE / WORKTREE 3 (docs/api)  ──▶ Worker C (Writer en OpenCode - $0)
```

### Diferencias Clave:
1. **Proyecto (`Project`)**: Entidad permanente en Orca que asocia tu repositorio git con tus cuentas (GitHub, etc.), variables y entornos de computación (local y servidores SSH).
2. **Espacio de Trabajo / Worktree (`Workspace / Worktree`)**: Un checkout independiente de git en su propio directorio, con su propia rama. Ubicación canónica del core (T-107): **hermano al checkout** (`<padre>/<repo>-<task-id>/`), fuera del árbol. Orca decide sus propias ubicaciones (`new-top-level`/`new-child`); el core documenta el mapeo y no lucha contra el runtime.
   - Cada agente trabaja en su propio directorio con su propia rama.
   - **Aislamiento total**: Múltiples agentes pueden editar archivos al mismo tiempo sin colisiones de git ni sobrescritura accidental.
   - Cada worktree posee sus propios terminales PTY y navegador embebido para pruebas visuales o webviews.
3. **Terminales y Agentes (`Terminals & Agents`)**: Procesos PTY embebidos donde se ejecutan los agentes soportados (`antigravity`, `opencode`, `codex`, `claude`, `hermes`).

---

## 2. El Mandato de Inferencia $0 en la Orquestación

Para garantizar que el trabajo en paralelo no dispare costes ni agote las cuotas de tokens comerciales:

- **Coordinador**: Se ejecuta en **Antigravity CLI (`agy` / `agy2`)** utilizando modelos de alto razonamiento (Claude 3.5 Sonnet / Gemini Pro). Su labor es puramente estratégica: trocear la épica, redactar contratos de subtareas y auditar el diff final.
- **Workers (Trabajadores de Ejecución)**: Tienen **prohibido consumir saldo o cuotas de pago**. Se despachan con **OpenCode CLI** conectándose a nuestras pasarelas de coste $0:
  - `freellmapi` ($0.00 / token).
  - `omniroute` (pasarela con 150+ modelos gratuitos).
  - `ollama` (offline / privado).

---

## 3. El flujo supervisado: `run-flow` (recomendado)

Un solo comando recorre los 5 pasos y **se detiene en el gate**. Sin runtime usable cae al fallback Git-nativo (T-104) con ruta explícita; nunca finge éxito.

```bash
bash scripts/agent/orca-orchestrate.sh run-flow \
  --objective "Refactorizar autenticación y su suite de tests" \
  --spec-file plan.json \
  --satellite mi-repo          # solo se usa si no hay runtime
```

`plan.json` (mismo formato que `batch`; `deps` opcional, solo hacia atrás):
```json
{"tasks": [
  {"title": "Middleware Auth", "spec": "Target: src/middleware/auth.ts...",
   "agent": "opencode", "role": "developer"},
  {"title": "Tests Auth", "spec": "Target: tests/auth/...",
   "agent": "opencode", "role": "reviewer", "deps": ["Middleware Auth"]}
]}
```

Lo que `run-flow` ejecuta por debajo (verificado contra el runtime 1.4.216):

```bash
# 1. Run y vinculación del coordinador
orca orchestration run-create --objective "<objetivo>" --json

# 2. Tareas con dependencias reales (--deps existe en el runtime)
orca orchestration task-create --run <id> --task-title "<t>" --spec "<s>" \
  --deps '["<task_id>"]' --json

# 3. Un worker por tarea, en el repo destino
orca orchestration worker-start --task <task_id> --repo path:<repo> \
  --worktree new-top-level --agent <id> --json

# 4. Seguimiento (una consulta, o espera con --wait en run-flow)
orca orchestration check --types worker_done,escalation,question --run <id> --json

# 5. Gate por tarea. AQUÍ SE PARA.
orca orchestration gate-create --task <task_id> --question "<qué se decide>" --json
# resolve-gate SOLO lo invoca el humano, nunca el flujo:
orca orchestration gate-resolve --id <gate_id> --resolution "<tu decisión>" --json
```

Sin runtime, los mismos 5 pasos se resuelven por la ruta Git-nativa
(`dispatch-satellite.sh --satellite <alias>` por tarea, worktree hermano al
satélite, registro en `dispatched.jsonl`). El JSON final lo dice explícitamente:
`"route": "git-fallback"`.

---

## 4. Patrones de Trabajo Multi-Agente

### Patrón A: Paralelismo Autónomo por Handoff (Features Independientes)
Útil cuando deseas delegar dos o tres tareas que no tienen dependencia mutua directa:

```bash
# Despachar Agente 1 (OpenCode en rama feat-auth)
orca worktree create --repo name:<repo> --name feat-auth --no-parent --agent opencode --prompt "Implementar validador de tokens JWT en auth.ts"

# Despachar Agente 2 en paralelo (OpenCode en rama feat-docs)
orca worktree create --repo name:<repo> --name feat-docs --no-parent --agent opencode --prompt "Documentar endpoints en docs/api.md"

# Consultar el estado de todos los worktrees activos
orca worktree ps
```

### Patrón B: Orquestación Supervisada con Coordinador (DAG y Decision Gates)
Es `run-flow` (§3). El diagrama del flujo:

```text
               ┌────────────────────────┐
               │   COORDINADOR (Orca)   │
               └───────────┬────────────┘
                           │
         ┌─────────────────┴───────────────────┐
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
         │                                       │
         └───────────────────┬───────────────────┘
                             ▼
              🛑 GATE: el humano aprueba o rechaza.
              El flujo NO continúa solo.
```

Si prefieres los pasos manuales (mismos comandos que ejecuta `run-flow`):

```bash
bash scripts/agent/orca-orchestrate.sh create-run --objective "Refactorizar arquitectura de autenticación y suite de tests"
# → run_6f65ff2df394

bash scripts/agent/orca-orchestrate.sh create-task \
  --run "run_6f65ff2df394" \
  --title "Implementar nuevo middleware de permisos" \
  --spec "Target: src/middleware/auth.ts. Change: añadir comprobación L1/L2/3."

bash scripts/agent/orca-orchestrate.sh dispatch-worker \
  --run "run_6f65ff2df394" \
  --title "Middleware Auth" \
  --spec "Implementar nuevo middleware de permisos en src/middleware/auth.ts" \
  --agent opencode \
  --role developer \
  --name wt-auth-middleware

bash scripts/agent/orca-orchestrate.sh check-events --run "run_6f65ff2df394" --wait --timeout-ms 300000

bash scripts/agent/orca-orchestrate.sh create-gate \
  --task "<task_id>" \
  --question "¿Autorizas la integración del middleware?"
# Y AQUÍ SE PARA. Resolver es humano:
bash scripts/agent/orca-orchestrate.sh resolve-gate --id "<gate_id>" --resolution "Aprobado por el operador"
```

---

## 5. Compuertas de Decisión (Decision Gates — Nivel L3)

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

El worker en Orca permanece en pausa hasta que la compuerta cambia a `status: resolved`, garantizando seguridad absoluta frente a mutaciones autónomas imprevistas. **Ningún script, subcomando ni flag resuelve un gate solo** (el check 25 lo verifica por log de invocaciones).

---

## 6. Qué comando cuándo

| Necesidad | Comando | Notas |
|---|---|---|
| Flujo completo supervisado | `run-flow --objective … --spec-file …` | Para en el gate; cae al fallback sin runtime |
| Diagnóstico del runtime | `… status` | Se degrada con gracia sin runtime |
| Despachar una tarea suelta | `… dispatch-worker --run …` + `create-gate` manual | Componer a mano = asumir tú la parada en el gate |
| Lote rápido sin gates | `… batch …` | **Legado**: no para en gates ni cae al fallback; usa `run-flow` |
| Sin Orca en absoluto | `dispatch-satellite.sh --satellite …` (T-104) | Ruta Git-nativa directa |
| Limpiar restos | `worktree-gc.sh --apply` | Nunca toca principal, bloqueados ni sucios |

---

## 7. Recetas y Comandos Rápidos CLI

| Acción | Comando |
| :--- | :--- |
| **Secuencia supervisada** | `bash scripts/agent/orca-orchestrate.sh run-flow --objective "<obj>" --spec-file <plan.json>` |
| **Diagnóstico del Runtime** | `bash scripts/agent/orca-orchestrate.sh status` |
| **Listar Runs Activos** | `bash scripts/agent/orca-orchestrate.sh list-runs` |
| **Comprobar Eventos** | `bash scripts/agent/orca-orchestrate.sh check-events --run <id>` |
| **Listar Decision Gates** | `bash scripts/agent/orca-orchestrate.sh list-gates --run <id>` |
