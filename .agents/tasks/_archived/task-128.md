# Task-128: Puente de Deliberación Worktree → Principal en Desmontaje

## Objetivo
Implementar en `scripts/agent/worktree-merge.sh` el mecanismo de rescate determinista que copie el artefacto de deliberación `.agents/context/deliberation-${TASK_ID}.json` desde el worktree efímero hacia el checkout principal antes de ejecutar el desmontaje (`git worktree remove --force`), garantizando que la deliberación real del worker sobreviva para el cierre de tarea y generación del Executive Design Digest en `close-task.sh`.

## Contexto técnico
En Sprint 20 y 21 se introdujo el bucle de deliberación Coder-Reviewer y su persistencia en `.agents/context/deliberation-${TASK_ID}.json`. Dicho fichero vive gitignored en el entorno de desarrollo.
Cuando el worker opera dentro de un Git Worktree efímero (`<padre>/<repo>-<task-id>/`), genera y persiste la deliberación dentro del worktree.
Sin embargo, `worktree-merge.sh`:
1. Verifica el árbol de trabajo.
2. Integra la rama efímera hacia la rama base (`--ff-only` o squash).
3. Desmonta y purga el directorio del worktree con `git worktree remove --force`.
Al estar gitignored, `deliberation-${TASK_ID}.json` no forma parte del commit de git y se destruía junto con el worktree. Como consecuencia, cuando el Coordinator ejecuta posteriormente `close-task.sh <TASK_ID>` en el checkout principal, no encuentra el fichero nombrado y cae al fallback degradado `N/A`.
Esta tarea resuelve esta desconexión:
- `worktree-merge.sh` comprueba si existe `$WT_DIR/.agents/context/deliberation-${TASK_ID}.json`.
- Si existe, lo copia a `$TARGET_ROOT/.agents/context/deliberation-${TASK_ID}.json` antes de desmontar el worktree.
- Informa en stdout/JSON del artefacto rescatado.

## Skills relevantes
- `orchestrator`: Gestión del ciclo de vida e integración de Git Worktrees efímeros.
- `agent-os-scripts`: Robustez en bash, manejo seguro de rutas y preservación de contratos CLI.

## Caja de archivos
- `scripts/agent/worktree-merge.sh`
- `.agents/tasks/task-128.md`

## Criterios de done
- [x] `worktree-merge.sh` detecta y copia `.agents/context/deliberation-${TASK_ID}.json` desde el worktree al checkout principal previo a `git worktree remove`.
- [x] Preservación del contrato JSON emitido por `worktree-merge.sh` con campo informativo del rescate de deliberación.
- [x] Idempotencia y tolerancia a fallos: no falla si el worktree no contenía deliberación (modo tolerante).
- [x] Verificación determinista en test aislado sin alterar el checkout principal ni violar la allowlist.
