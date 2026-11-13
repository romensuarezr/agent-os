# Task-208: Promoción a main (Decision Gate), versión v1.34.0 y sincronización universal a satélites

## Objetivo
Promover los cambios consolidados en `multi-agent` hacia la rama principal `main` mediante el Decision Gate formal `/promote` (`scripts/agent/promote-to-main.sh`), cortar la release oficial `v1.34.0` con `update-changelog.sh sprint-38`, y sincronizar exhaustivamente los nuevos activos del core (protocolo dinámico de modelos, telemetría, regla de priorización ROI-first) a los repositorios satélite de la flota (`<satelites>/annascheer-web`) con `sync.sh --force --cleanup --commit`, validando la integridad con `audit-satellites.sh`.

## Contexto técnico
- El usuario solicitó explícitamente incluir en el sprint la actualización de satélites una vez mergeado a main.
- En Agent OS, la promoción a `main` es una compuerta humana vinculante (Decision Gate `/promote`) que valida working tree limpio, ejecución completa de la suite de pruebas y topología de worktrees antes de mergear y etiquetar la versión.
- Una vez en `main`, los satélites reciben la versión estable del core con el nuevo comportamiento proactivo de negocio.

### Research integrado (`docs/sprints/sprint-38-research.md` → `### T-208`)
- **Scout OSS & Core Tooling**: `promote-to-main.sh`, `update-changelog.sh`, `sync.sh`, `audit-satellites.sh`.
- **Veredicto**: `Aprovechar utilidades existentes` del control plane.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 38 / 2026-11-13
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - Presentar el Decision Gate `/promote` al operador antes de ejecutar la promoción a `main`.
  - Ejecutar `promote-to-main.sh` para integrar de forma determinista y segura en `main`.
  - Cortar la versión `v1.34.0` en `changelog.md` y formalizar el commit y tag correspondiente.
  - Ejecutar `sync.sh --force --cleanup --commit` sobre `<satelites>/annascheer-web`.
  - Confirmar que `audit-satellites.sh` reporta satélites LIMPIOS (61/61 scripts OK).
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `docs/sprints/sprint-38.md`
- `.agents/tasks/task-208.md`
- `changelog.md`
- `VERSION`
- Referencia externa: `<satelites>/annascheer-web` (solo vía `sync.sh`)

## Criterios de done
- [x] Decision Gate `/promote` presentado formalmente al usuario.
- [x] Promoción a `main` completada exitosamente sin regresiones de control plane.
- [x] Versión `v1.34.0` generada y registrada en `changelog.md`.
- [x] Tag Git `v1.34.0` creado.
- [x] Sincronización a satélite `<satelites>/annascheer-web` ejecutada limpiamente vía `sync.sh`.
- [x] `audit-satellites.sh` confirma satélite LIMPIO (61/61 scripts OK).
- [x] Suite `tests/validate-control-plane.sh` pasando limpia sin regresiones (38/38 checks verdes).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
- [x] Plan presentado al usuario (Fase 3.5)
- [x] Rama de trabajo creada
- [x] Verificación con verify-goal.sh
- [x] Cierre y merge formalizado