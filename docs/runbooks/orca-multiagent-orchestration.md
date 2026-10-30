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
Útil cuando deseas delegar dos o tres tareas que no tienen dependencia mutua directa.

#### A1. Modo Interactivo en GUI / App
Para aprovisionar un worktree y vincular un agente interactivo en la aplicación Orca:

```bash
# Aprovisionar worktree y lanzar agente interactivo (OpenCode en rama feat-auth)
orca worktree create --repo name:<repo> --name feat-auth --no-parent --agent opencode

# Aprovisionar segundo worktree en paralelo (OpenCode en rama feat-docs)
orca worktree create --repo name:<repo> --name feat-docs --no-parent --agent opencode

# Resumen de orquestación compacto a través de worktrees (o 'orca worktree list' para listado por repositorio)
orca worktree ps
```

> [!NOTE]
> **Evidencia de `orca worktree create --help` y Desacoplamiento del Core**:
> Aunque la CLI de Orca expone `--prompt <text>` (*"Prompt text for agent-backed commands"*) para inyectar instrucciones iniciales en lanzamientos interactivos de GUI, el core de Agent OS descarta su uso para la orquestación programática autónoma. En su lugar, el core reemplaza el paso de prompts informales por la secuencia canónica desacoplada (`worktree-dispatch.sh` + `orca orchestration worker-start` con especificación declarativa estructurada).

#### A2. Modo Desacoplado Programático / Ralph Loop (Core de Agent OS)
Para flujos automatizados de arbitraje, deliberación y verificación de metas (`deliberate-plan.sh`, `verify-goal.sh`), se utiliza el ciclo de vida canónico del worker:

1. **Sonda determinista de presencia (<1s)**:
   ```bash
   orca status --json # verifica que .result.runtime.state == "ready"
   ```
2. **Aislamiento estricto de entorno (`env -i`)**:
   Todo worker se ejecuta aislando el entorno con la whitelist canónica exacta de 10 variables de `orca-client.sh` (`HOME`, `PATH`, `USER`, `SHELL`, `LANG`, `LC_ALL`, `TMPDIR`, `ORCA_USER_DATA_PATH`, `ORCA_TERMINAL_HANDLE`, `ORCA_CALLS_LOG`), impidiendo que credenciales, variables de inferencia o tokens de la sesión coordinadora se filtren al worker.
3. **Inicio de Worker**:
   ```bash
   orca orchestration worker-start \
     --run "<run_id>" \
     --task-title "deliberate-plan <task-id>" \
     --spec "<directiva_ejecucion>" \
     --agent opencode \
     --worktree current \
     --json
   ```
4. **Monitoreo y Lectura**:
   - Vía sondeo periódico: `orca orchestration worker-read --dispatch "<dispatch_id>" --json`
   - Vía escucha reactiva: `orca orchestration check --run "<run_id>" --wait --types worker_done --json`
5. **Detención y Liberación Canónica (Máquina de Estados)**:
   - Si el worker continúa en ejecución (`running`), detenerlo primero con:
     ```bash
     orca orchestration worker-stop --dispatch "<dispatch_id>" --json
     ```
   - Liberar inmediatamente terminales y recursos asociados:
     ```bash
     orca orchestration worker-release --dispatch "<dispatch_id>" --json
     ```
   - *Invariante del Core*: La invocación de `worker-release` está garantizada en todos los caminos (éxito, error o timeout) mediante manejadores `trap EXIT INT TERM` en los scripts de control.

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
| Sonda primaria de presencia | `orca status --json` | Verifica `.result.runtime.state == "ready"` fail-fast (<1s) |
| Flujo completo supervisado | `run-flow --objective … --spec-file …` | Para en el gate; cae al fallback sin runtime |
| Diagnóstico del runtime | `orca-orchestrate.sh status` | Se degrada con gracia sin runtime |
| Informe de un lote | `… report <run-id> [--json]` | Read-only: tareas, workers, gates y veredicto en una pantalla |
| Despachar una tarea suelta | `… dispatch-worker --run …` + `create-gate` manual | Componer a mano = asumir tú la parada en el gate |
| Resumen de worktrees | `orca worktree ps` / `orca worktree list` | `ps` muestra resumen de orquestación; `list` lista por repo |
| Detener y liberar worker | `worker-stop` + `worker-release` | Secuencia obligatoria en workers activos (garantizado con trap) |
| Lote rápido sin gates | `… batch …` | **Legado**: no para en gates ni cae al fallback; usa `run-flow` |
| Sin Orca en absoluto | `dispatch-satellite.sh --satellite …` (T-104) | Ruta Git-nativa directa |
| Limpiar restos | `worktree-gc.sh --apply` | Nunca toca principal, bloqueados ni sucios |

---

## 7. Informe consolidado read-only: `report`

Agrega un run completo en una sola pantalla: ejecución, tareas, workers/worktrees,
gates y veredicto. No muta estado: solo invoca primitivas de lectura
(`run-list`, `task-list`, `gate-list`, `worker-list`, `worktree ps`).

```bash
# Vista humana (una pantalla)
bash scripts/agent/orca-orchestrate.sh report run_6f65ff2df394

# Digest para agentes (mismas claves, JSON estable)
bash scripts/agent/orca-orchestrate.sh report run_6f65ff2df394 --json
```

Salida:
- Cabecera del run (id, objetivo, fecha de creación).
- Tabla de tareas con estado (`✅` hecho, `⏳` en curso/listo, `❌` fallo), gate asociado,
  estado del worker, worktree y diffstat por worker.
- Gates pendientes y resueltos.
- Veredicto: `COMPLETADO`, `GATE_PENDIENTE`, `CON_FALLOS`, `EN_CURSO`, `SIN_TAREAS`,
  `DATOS_INCOMPLETOS` o `SIN_RUNTIME`.

Garantías:
- **Read-only verificable**: el bloque está delimitado por los marcadores
  `# >>> T-112 report` / `# <<< T-112 report`, y la suite (check 29) falla si contiene
  primitivas de mutación (`create-*`, `dispatch-*`, `resolve-*`, `worker-start|stop|release|retain`,
  `gh pr`, `git push|merge`).
- **Degradación**: sin runtime informa `SIN_RUNTIME` y sale 0, sin traceback.
- **Diffstat**: usa la ref base que registre el run; si no la registra, muestra `n/d`.
  No inventa comparaciones.
- **Sin ejecución desatendida**: el informe nunca continúa un flujo ni resuelve gates;
  la decisión sigue siendo humana.

---

## 8. Recetas y Comandos Rápidos CLI

| Acción | Comando |
| :--- | :--- |
| **Sonda Primaria de Presencia** | `orca status --json` (evaluar `.result.runtime.state == "ready"`) |
| **Secuencia supervisada** | `bash scripts/agent/orca-orchestrate.sh run-flow --objective "<obj>" --spec-file <plan.json>` |
| **Diagnóstico del Runtime** | `bash scripts/agent/orca-orchestrate.sh status` |
| **Listar Runs Activos** | `bash scripts/agent/orca-orchestrate.sh list-runs` |
| **Informe de Lote** | `bash scripts/agent/orca-orchestrate.sh report <run-id> [--json]` |
| **Comprobar Eventos** | `bash scripts/agent/orca-orchestrate.sh check-events --run <id>` |
| **Listar Decision Gates** | `bash scripts/agent/orca-orchestrate.sh list-gates --run <id>` |
| **Detener Worker Activo** | `orca orchestration worker-stop --dispatch <dispatch_id> --json` |
| **Liberar Terminal de Worker** | `orca orchestration worker-release --dispatch <dispatch_id> --json` |
