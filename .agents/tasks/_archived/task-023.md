# Task-023: Rediseñar el flujo roadmap ↔ sprint ↔ changelog

## Objetivo
Rediseñar y simplificar el acoplamiento y responsabilidades entre `roadmap.md`, `IMPLEMENTED.md` y `changelog.md`, eliminando solapamientos y definiendo un formato limpio y manipulable.

## Contexto técnico
- Actualmente, tres artefactos (`roadmap.md`, `IMPLEMENTED.md`, `changelog.md`) solapan responsabilidades.
- `roadmap.md` no tiene un formato consistente ni manipulable fiablemente mediante scripts.
- `IMPLEMENTED.md` duplica información ya presente en los sprints archivados y en el changelog.
- 📚 Research de Sprint 03 integrado (ver docs/sprints/sprint-03-core-research.md).

## Caja de archivos
Archivos autorizados para modificación:
- `roadmap.md` (o `ROADMAP.md`)
- `docs/IMPLEMENTED.md` (a deprecar/eliminar)
- `scripts/agent/close-task.sh`
- `scripts/agent/close-sprint.sh`
- `templates/docs/sprint-template.md` (u otros templates de planning)
- `.agents/workflows/sprint-planning.md`
- `.agents/workflows/sprint-inicial.md`
- `scripts/agent/audit-repo.sh`

## Criterios de done
- [x] Redefinir `roadmap.md` como documento de intención de alto nivel con secciones: `## En curso`, `## Próximo`, `## Descartado` (sin IDs ni checkboxes).
- [x] Eliminar/deprecar `docs/IMPLEMENTED.md` y remover cualquier referencia a este archivo en los scripts que escriben en él (ej. `close-task.sh`).
- [x] Modificar `close-sprint.sh` (y/o `close-task.sh`) para que no escriban en `roadmap.md`. El roadmap solo reflejará líneas de trabajo amplias, no tareas individuales.
- [x] Corregir el bug sintáctico de `close-sprint.sh` provocado por la tubería `grep -c` cuando no hay coincidencias de tareas (devolviendo `0\n0`).
- [x] Actualizar el template de sprint planning para mover la línea correspondiente de `roadmap.md` a `## En curso` durante la fase de planning, no de ejecución.
- [x] El agente puede ejecutar el flujo completo de cierre y archivado sin inconsistencias.

## Estado de aprobación
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-06-17T14:07:02+01:00
- [x] Rama creada: feat/T-023-redesign-roadmap-sprint-changelog-flow
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
