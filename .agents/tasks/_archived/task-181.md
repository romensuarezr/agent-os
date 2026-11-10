# Task-181: Sincronización y automatización de last-sync.md en el cierre de sprint (close-sprint.sh)

## Objetivo
Actualizar la marca de contexto operativo del core `.agents/context/last-sync.md` a la versión actual (`v1.27.0`) e incorporar en `scripts/agent/close-sprint.sh` la sincronización atómica y determinista de este fichero, garantizando que el estado operativo de agent-os sobre sí mismo no se desincronice en futuros cierres.

## Contexto técnico
El archivo `.agents/context/last-sync.md` actúa como registro del estado del core en modo self-hosted. Se detectó que permanecía congelado en Sprint 19 (`v1.14.0`), requiriendo actualización manual. Dado que `close-sprint.sh` ya sincroniza atómicamente el archivo `VERSION` y `changelog.md`, la actualización de `last-sync.md` debe formar parte del mismo ritual determinista.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 32 / 2026-11-10
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Actualizar de inmediato `.agents/context/last-sync.md` con la versión semver `1.27.0`, último sprint cerrado `sprint-31-core` y fecha actual.
  - Modificar `scripts/agent/close-sprint.sh` para que, tras derivar la nueva versión o archivar el sprint, actualice los campos `Versión del core` y `Último sprint cerrado` en `.agents/context/last-sync.md` (si existe en el repositorio) y lo incluya en el commit atómico de cierre.
  - Asegurar que `tests/validate-control-plane.sh` Check 19 certifique la sincronización de `last-sync.md` sin regresiones ni llamadas destructivas.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/context/last-sync.md`
- `scripts/agent/close-sprint.sh`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-181.md`

## Criterios de done
- [x] `.agents/context/last-sync.md` actualizado con metadatos de versión `v1.27.0` y estado de sprint actual.
- [x] `scripts/agent/close-sprint.sh` actualiza e incluye `last-sync.md` en el commit atómico de cierre de sprint de forma idempotente y determinista.
- [x] Check 19 de `tests/validate-control-plane.sh` valida la sincronización limpia de `last-sync.md`.
- [x] Suite de pruebas `tests/validate-control-plane.sh` 38/38 en verde.
- [x] `locator-hygiene.sh` 100% limpio.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `CONSENSO`
  - **Rol del revisor**: Compuerta técnica determinista (caja de archivos, tests, realidad repo, fidelidad a diseño macro).
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-11-10T19:15:25Z (Opción D - Desatendida, Aprobado en Planning Sprint 32)
- [x] Rama creada: feat/T-181-sincronizacion-last-sync-close-sprint
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
