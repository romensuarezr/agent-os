# Task-112: Informe consolidado de lote read-only

## Objetivo
Nuevo subcomando de `orca-orchestrate.sh` (nombre a fijar en el plan: `report`) que agrega un run
en una sola pantalla para el humano: run → tareas → worktrees → gates → diffstat por worker →
veredicto. Estrictamente read-only: cierra el hueco legítimo de la idea 2026-09-25 sin tocar el
modelo de seguridad (sin ejecución desatendida).

## Contexto técnico
`run-flow` ya emite JSON con tareas y gates y se detiene (`orca-orchestrate.sh:700`); no existe
agregación de lectura. Fuentes disponibles con `--json` (23 flags): `list-runs`, `list-tasks --run`,
`list-gates --run`, `status`. El informe solo lee: prohibido llamar a `create-*`, `dispatch-*`,
`resolve-*` o cualquier primitiva con mutación desde el nuevo subcomando.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/orca-orchestrate.sh` (solo el nuevo subcomando + entrada en `usage()`)
- `docs/runbooks/orca-multiagent-orchestration.md` (documentar el subcomando)
- `tests/validate-control-plane.sh` (check: el subcomando no contiene llamadas con mutación)

## Criterios de done
- [x] Subcomando read-only verificable: `grep` demuestra 0 llamadas a primitivas con mutación
      (`create-`, `dispatch-`, `resolve-`, `gh pr`, `git push/merge`) en su cuerpo
- [x] Vista humana (una pantalla) + digest `--json` para agentes (principio 6 de AGENTS.md)
- [x] Funciona sin runtime Orca degradando con gracia (como `run-flow`: informa, no aborta con traceback)
- [x] Suite 29/29; runbook actualizado; idea 2026-09-25 se archiva al cerrar

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO — 2026-10-23 (cambio: check 29 incluye ciclo de vida del worker)
- [x] Rama creada: `feat/T-112-report-lote-readonly` (desde `multi-agent`)
- [x] Lock activo: `.agent-session.lock`
- [ ] Sesión cerrada correctamente
