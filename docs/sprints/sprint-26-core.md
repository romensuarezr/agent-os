# Sprint 26 — Cierre Determinista de Sprint y Hardening de Gobernanza

## Estado
🟡 En curso

## Tareas
| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :--- | :--: | :--- | :--- |
| T-146 | Cierre de sprint en invocación única concatenada y determinista (`close-sprint.sh` + `update-changelog.sh`) | Core / Gobernanza | S | ✅ Completada | — | [.agents/tasks/task-146.md](.agents/tasks/_archived/task-146.md) |

## Notas de planning

- **Objetivo**: Garantizar que el cierre de cualquier sprint en el ecosistema de Agent OS se complete en una única invocación determinista (`bash scripts/agent/close-sprint.sh <sprint>`), orquestando la actualización del changelog de forma automática sin pasos manuales previos, con bump semver determinista, manteniendo estricta retrocompatibilidad para satélites y fail-closed ante errores.
- **Resultado exigido (T-146)**:
  - `close-sprint.sh` se encarga de que la entrada del changelog exista (llamando a `update-changelog.sh` por dentro o fallando de forma explícita si falta), sin depender de un paso manual previo.
  - El bump de versión resultante debe ser determinista, sin elección interactiva.
  - El comportamiento para los satélites que ya usan `close-sprint.sh` debe seguir siendo compatible (si el changelog ya viene modificado, no duplicar la entrada).
  - Prueba del flujo completo de cierre sobre un sprint de prueba o en seco, demostrando que ya no hace falta el paso manual previo.
- **Guardarraíles operativos**:
  - Trabajo en rama aislada `feat/T-146-*`.
  - Aprobación previa de plan legible en `.agents/context/plan-draft.md` y deliberación mediante `deliberate-plan.sh` (timeout default 60s).
  - Caja estricta de la tarea: `scripts/agent/close-sprint.sh`, `scripts/agent/update-changelog.sh`, `tests/validate-control-plane.sh`, `.agents/tasks/task-146.md`.
  - Suite de control plane limpia (`tests/validate-control-plane.sh` 37/37).
  - Cero modificaciones a `main`, cero tags creados.
- **Relación con el Documento de Research**:
  - Ver `docs/sprints/sprint-26-research.md` (Gate Scout-First, T-129).
