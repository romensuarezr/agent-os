# Research Sprint 09 — Core
> Fuente: Perplexity & Hallazgos Técnicos — 2026-09-27  
> Tarea principal: Multi-Agent Parallel Orchestration & Deterministic Goals Engine (T-054 a T-058)

---

## Hallazgos Clave

### 1. Ciclo de Vida de Git Worktrees (`.worktrees/<task-id>/`)
- **Exclusión obligatoria**: Excluir `.worktrees/` en `.gitignore` del repositorio core y en la plantilla `.gitignore-agent-os`.
- **Aprovisionamiento aislado**: Creación determinista mediante:
  ```bash
  git worktree add -b feat/<task-id>-<profile> .worktrees/<task-id> HEAD
  ```
- **Inyección de contexto**: Exportar `AGENT_OS_ROOT="$(git rev-parse --show-toplevel)"` para que los scripts y perfiles mantengan acceso determinista a `.agents/`.
- **Desmantelamiento atómico sin fugas (ADR 004)**: Limpieza mediante:
  ```bash
  git worktree remove --force .worktrees/<task-id>
  git worktree prune
  ```
  Esto purga metadatos administrativos en `.git/worktrees/`, liberando espacio y evitando colisiones de locks en disco o saturación de inodos.

### 2. Quality Gates y End State Contracts (`scripts/agent/verify-goal.sh` a 0 tokens)
- **Working Tree Limpio**: Verificar que no existan modificaciones no guardadas ni archivos untracked residuales con:
  ```bash
  test -z "$(git status --porcelain)"
  ```
- **Caja de Archivos Autorizados (Strict Allowlist)**: Comparar la salida de `git diff --name-only <base>...HEAD` contra la lista de archivos explícitamente autorizados en el contrato `/goal` o task file. Si se detecta cualquier archivo fuera de la lista, el gate falla de inmediato (`exit 1`) para evitar contaminación y efectos secundarios.
- **Ejecución Determinista de Suites**: Correr la suite de pruebas del proyecto (`tests/validate-control-plane.sh` o test runner detectado por `detect-stack.sh`) exigiendo código de retorno 0.

### 3. Patrón Judge Independiente (Ralph Loop / Bucle de Verificación)
- **Interfaz Desacoplada**: El agente Worker vuelca su estado, artefactos y diff en disco; el agente Judge (o `qa-judge`) evalúa exclusivamente el resultado emitido por `verify-goal.sh` y el diff generado, sin re-ejecutar heurísticas subjetivas ni alucinaciones de auto-evaluación.
- **Condición de Parada (Circuit Breaker)**: Máximo 3 intentos de corrección. Si el Worker no supera las compuertas al tercer intento consecutivo, se emite un estado `escalated_to_human` y se activa un Decision Gate (`pending_approval`).

---

## Decisiones Tomadas

- **Decisión 1**: Desacoplar completamente la verificación determinista (Bash puro a 0 tokens) de la síntesis del Judge (modelo LLM en perfil `qa-judge`).
  - **Por qué**: Garantiza reproducibilidad, velocidad y coste 0 de tokens en las compuertas técnicas duras.
  - **Constraint clave**: Toda compuerta técnica debe poder ejecutarse y evaluarse en modo CLI sin dependencias pesadas.
- **Decisión 2**: Aislar cada agente obrero en su propio `.worktrees/<task-id>/`.
  - **Por qué**: Evita interferencias de ramas, colisiones en disco y carreras de commits entre agentes concurrentes.
  - **Constraint clave**: Siempre invocar `git worktree remove --force` y `git worktree prune` para cumplir la regla de preservación de disco (ADR 004).
- **Decisión 3**: Contratos de meta formales y binarios en formato Markdown (`goal.schema.md`).
  - **Por qué**: Alinea la semántica de `/goal` y `/subgoal` de Hermes Agent con el estándar declarativo de agent-os.

---

## Descartado

- **Orquestadores TUI / Runtimes propietarios (ej. `agentic-tui`, `claude-orchestrate`)**: Descartados por requerir librerías externas o atarse exclusivamente a un único vendor. agent-os opera con Bash agnóstico.
- **Librerías npm de gatekeeping (`jules-orchestrator-kit`)**: Descartadas a favor de Bash/POSIX determinista nativo con 0 dependencias y 0 overhead.
