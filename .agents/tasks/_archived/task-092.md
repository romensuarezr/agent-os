# Task-092: Fix consistencia de secciones en roadmap.md y audit-repo.sh (HIGH)

## Objetivo
Armonizar la validación de secciones de `roadmap.md` en `scripts/agent/audit-repo.sh` (tanto en la comprobación diagnóstica de la sección 5 como en el bloque de auto-fix de la sección 6) y alinear la plantilla distribuida `templates/root/roadmap.md` incorporando `## Completado`, garantizando que ambos compartan la misma lógica de sinónimos canónicos (`En curso`/`En progreso`, `Completado`/`Completado recientemente`, `Próximo`/`Backlog`) y el vocabulario de la plantilla para eliminar advertencias espurias y evitar duplicación de secciones en proyectos satélite.

## Contexto técnico
- **Sprint**: Sprint 14 ("Automejora y Confianza").
- **Origen**: Hallazgo empírico durante el pilotaje ciego T-090 (`docs/idea-inbox/_archived/2026-09-30-consistencia-secciones-roadmap.md`).
- **Problema en `audit-repo.sh`**:
  - Sección 5 (diagnóstico, ~línea 548): itera rígidamente sobre `## En progreso`, `## Completado`, `## Backlog`. Si se usan los encabezados canónicos estándar de la plantilla (`## En curso`, `## Próximo`), emite advertencias espurias de secciones faltantes.
  - Sección 6 (auto-fix `--apply`, ~líneas 302-310): utiliza un bucle con `grep` literal sobre `## En progreso`, `## Completado`, `## Backlog` y añade bloques con vocabulario legacy, pudiendo duplicar secciones funcionales existentes.
- **Problema en `templates/root/roadmap.md`**:
  - Carece de bloque `## Completado` (solo contiene `## En curso`, `## Próximo`, `## Descartado`). `## Descartado` no es sinónimo de completado.
- **Requisitos de la solución**:
  1. Ambos bloques (diagnóstico y auto-fix) deben compartir la misma lógica regex de sinónimos canónicos:
     - Bloque activo: `^##[[:space:]]+(En curso|En progreso)`
     - Bloque completado: `^##[[:space:]]+(Completado|Completado recientemente)`
     - Bloque futuro: `^##[[:space:]]+(Próximo|Backlog)`
  2. Las secciones añadidas por auto-fix deben emplear el vocabulario estándar de la plantilla: `## En curso`, `## Completado`, `## Próximo`.
  3. `templates/root/roadmap.md` debe incluir explícitamente `## Completado`.
  4. La verificación debe demostrar:
     - Caso A: Un repo satélite con la plantilla pasa con 0 warnings.
     - Caso B: Un roadmap que carece de un bloque lógico real sigue fallando (sin laxitud).
     - Caso C: Ejecutar `--apply` sobre un roadmap que usa la plantilla no duplica secciones.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/audit-repo.sh`
- `templates/root/roadmap.md`
- `.agents/tasks/task-092.md` (nuevo)
- `docs/sprints/sprint-14-core.md`

## Criterios de done
- [x] `scripts/agent/audit-repo.sh` (sección 5) modificado para verificar la presencia de cada área funcional mediante sinónimos canónicos (`^##[[:space:]]+(En curso|En progreso)`, `^##[[:space:]]+(Completado|Completado recientemente)`, `^##[[:space:]]+(Próximo|Backlog)`).
- [x] `scripts/agent/audit-repo.sh` (sección 6 auto-fix) modificado para compartir la misma lógica regex y añadir secciones faltantes con vocabulario estándar de la plantilla sin duplicar bloques existentes.
- [x] `templates/root/roadmap.md` actualizado con sección `## Completado`.
- [x] Verificación empírica completa (3 casos en entorno efímero):
  - [x] Caso A: Roadmap con plantilla pasa con 0 advertencias de secciones.
  - [x] Caso B: Roadmap incompleto (falta un bloque real) emite advertencia precisa (no laxo).
  - [x] Caso C: Auto-fix `--apply` sobre roadmap de plantilla no duplica secciones.
- [x] Validación de control plane: `tests/validate-control-plane.sh` pasa sin errores.
- [x] Working tree limpio tras la ejecución.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO CON CAMBIOS recibido — fecha/hora: 2026-09-30 11:30:00+01:00
- [x] Rama creada: feat/T-092-fix-roadmap-sections-consistency
- [x] Lock activo: 2026-09-30T11:30:35+01:00
- [x] Sesión cerrada correctamente
