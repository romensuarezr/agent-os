# Sprint 16 — Frontera Portable y Saneado de Exposición

## Estado
✅ Completado

## Tareas
| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :--- | :--: | :--- | :--- |
| T-103 | Sanear la exposición de infraestructura del core y hacer cumplir la frontera portable con un check automático | Bug del sistema / DX | M | ✅ Completada | T-100 | [.agents/tasks/_archived/task-103.md](.agents/tasks/_archived/task-103.md) |

## Notas de planning

- **Origen**: auditoría de preparación para compartir el repo. El repo es **público en GitHub
  desde 2026-06-12** y arrastra exposición de infraestructura tanto en el árbol actual como en
  la historia.
- **La frontera portable ya se decidió el 2026-09-28**: cero `$HOME`, cero IPs Tailscale,
  cero hostnames en el core; lo personal vive en un overlay local ignorado por git. **Esta tarea
  no re-decide nada: la hace cumplir.** El repo la tenía escrita en `docs/critical-flows.md` y
  su propia historia la incumplía 451 veces.
- **Fuera de alcance y por decisión del usuario**: la reescritura de historia (Fase 2) queda
  bloqueada hasta confirmación de que la credencial filtrada está rotada. La rotación es del
  usuario, no del agente.
- **Auditoría de los otros 4 repos públicos**: tarea aparte, fuera de este sprint.

## Cierre

- **T-103 completada y mergeada** en `main` (`aef5c09`). 22/22 en la suite.
- **Fase 2 del saneamiento ejecutada**: reescritura completa de la historia con
  `git-filter-repo` sobre los 3 refs publicados y los 2 tags, verificada sobre un clon nuevo
  (`git log --all -S` de la credencial filtrada → 0).
- **Pendiente para el siguiente sprint**: `romensuarez-web` sigue apareciendo en el árbol. Se
  decidió tratarlo como tarea aparte, no parte de este sprint.