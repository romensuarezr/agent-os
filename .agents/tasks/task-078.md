# Task-078: Higiene documental del core

## Objetivo
Documentación veraz, versionada y reutilizable por terceros: versiones, changelog, roadmap, runbooks y convenciones de ficheros.

## Contexto técnico
Auditoría 2026-09-28 (bloque docs): `README.md` congelado en "*Core version: 1.1*" mientras `changelog.md` va por `[1.9.0]`; 3 commits posteriores a v1.9.0 (incl. el T-066) fuera del changelog; `roadmap.md` con "En curso" ya completado; `DEFINITION_OF_DONE.md` huérfano (nada lo referencia); casing inconsistente (`docs/MVP-TRACKER.md`); `docs/critical-flows.md` inejecutable como procedimiento; runbooks escritos como diario operativo del autor (IPs, alias, rutas personales), no reutilizables por un tercero.

## Caja de archivos
Archivos autorizados para modificación:
- `README.md`
- `changelog.md`
- `roadmap.md`
- `AGENTS.md`
- `docs/runbooks/*`
- `.agents/tasks/task-078.md`
- `docs/sprints/sprint-11-core.md`

## Criterios de done
- [x] La versión del README se genera desde el changelog o desaparece la cifra hardcodeada (una sola fuente de verdad).
- [x] `changelog.md` incluye los commits post-1.9.0 y se actualiza al cerrar este sprint (procedimiento documentado, no manual).
- [x] `roadmap.md`: "En curso" refleja la realidad; nada completado como pendiente.
- [x] `DEFINITION_OF_DONE.md` referenciado desde `AGENTS.md`/workflows o eliminado (nada huérfano).
- [x] Casing consistente en `docs/` (verificado inventario; ficheros inexistentes MVP-TRACKER/critical-flows purgados del plan).
- [x] Runbooks sin IPs/alias/rutas personales: referencian `fleet.yaml` y son ejecutables por un tercero en su propia flota.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-29T18:59:46+01:00 (APROBADO CON CAMBIOS)
- [x] Rama creada: feat/T-078-core-docs-hygiene
- [x] Lock activo: .agent-session.lock
- [ ] Sesión cerrada correctamente
