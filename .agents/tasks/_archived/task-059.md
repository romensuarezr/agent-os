# Task-059: Automatización Determinista de Promoción a Main y Cierre de Ciclo

## Objetivo
Eliminar la necesidad de ejecutar comandos manuales de Git (`git checkout main`, `git merge --ff-only`, `git push`) al finalizar un sprint o consolidar una rama de trabajo. El proceso debe ser autónomo, determinista (0 tokens), no destructivo y gobernado por un Decision Gate humano estricto.

## Contexto técnico
- Entregables requeridos:
  1. `scripts/agent/promote-to-main.sh`:
     - Soporta flags: `--source <rama>` (por defecto la rama actual), `--target <rama>` (por defecto `main`), `--push` y `--json`.
     - Valida que el working tree esté limpio (`git status --porcelain`).
     - Detecta si `<target>` está asignada en otro worktree mediante `git worktree list --porcelain` para ejecutar el merge en el worktree correspondiente o hacer checkout local de forma segura.
     - Ejecuta la suite de verificación determinista `tests/validate-control-plane.sh` antes de proceder.
     - Realiza `git merge --ff-only` y, si se indica `--push`, sube los cambios a `origin <target>`.
     - Asignar permisos ejecutables (`chmod +x`).
  2. `.agents/skills/orchestrator/SKILL.md`:
     - Documentar el comando declarativo: `/promote [source] [--target main] [--push]`.
     - Documentar el Decision Gate previo: el agente debe presentar el estado de los checks y el commit a promover, solicitando confirmación explícita (`APROBADO`) antes de ejecutar el script.
  3. `scripts/agent/sync.sh` e `install.sh`:
     - Incluir `promote-to-main.sh` en la propagación hacia proyectos hijos con `chmod +x`.
  4. `tests/validate-control-plane.sh`:
     - Check 9: Comprobar sintaxis (`bash -n`) y permisos de ejecución (`test -x`) para `promote-to-main.sh`.
  5. `docs/sprints/_archived/sprint-09-core.md` y `changelog.md`:
     - Registrar la tarea T-059 como extensión final del Sprint 09 Core y en el changelog v1.8.0.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `scripts/agent/promote-to-main.sh`
- `.agents/skills/orchestrator/SKILL.md`
- `scripts/agent/sync.sh`
- `scripts/agent/install.sh`
- `tests/validate-control-plane.sh`
- `docs/sprints/_archived/sprint-09-core.md`
- `changelog.md`
- `.agents/tasks/task-059.md`

## Criterios de done
- [x] `scripts/agent/promote-to-main.sh` implementado con soporte de worktrees, flags `--source`, `--target`, `--push`, `--json`, validación de working tree y suite de tests.
- [x] Permisos de ejecución (`chmod +x`) asignados a `promote-to-main.sh`.
- [x] `.agents/skills/orchestrator/SKILL.md` actualizado documentando la gramática de `/promote` y el Decision Gate mandatorio.
- [x] `scripts/agent/sync.sh` e `install.sh` actualizados para propagar `promote-to-main.sh` con `chmod +x`.
- [x] `tests/validate-control-plane.sh` actualizado (Check 9 incluye `promote-to-main.sh`) y 10/10 checks pasando al 100%.
- [x] `docs/sprints/_archived/sprint-09-core.md` y `changelog.md` actualizados reflejando T-059 en la versión v1.8.0.
- [x] Plan presentado y validado en Decision Gate.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-27T13:03:32+01:00
- [x] Rama creada: feat/T-059-promote-to-main
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
