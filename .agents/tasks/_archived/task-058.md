# Task-058: Distribución Core (sync.sh, install.sh) y Hardening de Suite de Pruebas (validate-control-plane.sh)

## Objetivo
Actualizar los scripts de distribución universal `sync.sh` e `install.sh` para incluir los nuevos artefactos de orquestación y metas (`templates/goals/`, perfiles `.agents/profiles/`, scripts `verify-goal.sh`, `worktree-dispatch.sh`, `worktree-merge.sh`), y expandir `tests/validate-control-plane.sh` con validaciones automáticas de sintaxis, ejecución y contratos.

## Contexto técnico
- Basado en los requerimientos del sprint y las necesidades de propagación a proyectos hijos:
  - `scripts/agent/sync.sh`:
    - Incorporar la sincronización de `templates/goals/` a `$TARGET_PROJECT/templates/goals/` (o ruta correspondiente).
    - Sincronizar perfiles de `.agents/profiles/` preservando perfiles locales del proyecto.
    - Sincronizar los nuevos scripts ejecutables: `verify-goal.sh`, `worktree-dispatch.sh`, `worktree-merge.sh`.
  - `scripts/agent/install.sh`:
    - Crear los directorios operativos necesarios en proyectos hijos (`.agents/profiles`, `templates/goals`).
    - Copiar plantillas y scripts con permisos de ejecución correspondientes.
  - `tests/validate-control-plane.sh`:
    - Agregar paso de validación `[9/10]` para comprobar la existencia y funcionamiento de los scripts `verify-goal.sh`, `worktree-dispatch.sh` y `worktree-merge.sh` (ejecutando `--help` o validación mock).
    - Agregar paso de validación `[10/10]` para auditar la integridad de `templates/goals/goal.schema.md` y los nuevos perfiles de agentes especialistas.
    - Asegurar que la suite completa termine con código de retorno 0.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `scripts/agent/sync.sh`
- `scripts/agent/install.sh`
- `tests/validate-control-plane.sh`
- `docs/adrs/adr-005-multi-agent-parallel-orchestration.md`
- `docs/adrs/README.md`
- `changelog.md`
- `docs/sprints/sprint-09-core.md`
- `.agents/tasks/task-058.md`

## Criterios de done
- [x] `scripts/agent/sync.sh` actualizado para propagar templates de goals, perfiles y nuevos scripts de worktree/goal a proyectos hijos con `chmod +x`.
- [x] `scripts/agent/install.sh` actualizado para provisionar la estructura y archivos base de orquestación en nuevos proyectos con `chmod +x`.
- [x] `tests/validate-control-plane.sh` ampliado con validaciones [9/10] (sintaxis bash -n y permisos ejecutables) y [10/10] (frontmatter YAML de perfiles .md).
- [x] `docs/adrs/adr-005-multi-agent-parallel-orchestration.md` redactado formalizando el motor de orquestación, Ralph Loop y veto de ADR 004 en `oracle`.
- [x] `docs/adrs/README.md` actualizado con la referencia al ADR 005.
- [x] `changelog.md` actualizado registrando la versión v1.8.0.
- [x] Ejecución de `tests/validate-control-plane.sh` pasando al 100% (10/10 checks, 0 errores).
- [x] Estado reflejado en `docs/sprints/sprint-09-core.md` y `.agents/tasks/task-058.md`.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-27T12:40:30+01:00
- [x] Rama creada: feat/T-058-core-distribution-and-hardening
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
