# Sprint 16 — Frontera Portable y Saneado de Exposición

## Estado
🟡 En curso

## Tareas
| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :--- | :--: | :--- | :--- |
| T-103 | Sanear la exposición de infraestructura del core y hacer cumplir la frontera portable con un check automático | Bug del sistema / DX | M | ⬜ Pendiente | T-100 | — |

## Notas de planning

- **Origen**: auditoría de preparación para compartir el repo. El repo es **público en GitHub
  desde 2026-06-12** y arrastra exposición de infraestructura tanto en el árbol actual como en
  la historia.
- **La frontera portable ya se decidió el 2026-09-28**: cero `***REMOVED-PATH***`, cero IPs Tailscale,
  cero hostnames en el core; lo personal vive en un overlay local ignorado por git. **Esta tarea
  no re-decide nada: la hace cumplir.** El repo la tenía escrita en `docs/critical-flows.md` y
  su propia historia la incumplía 451 veces.
- **Fuera de alcance y por decisión del usuario**: la reescritura de historia (Fase 2) queda
  bloqueada hasta confirmación de que la credencial filtrada está rotada. La rotación es del
  usuario, no del agente.
- **Auditoría de los otros 4 repos públicos**: tarea aparte, fuera de este sprint.