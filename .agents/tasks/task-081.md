# Task-081: Portabilidad Shell, Robustez CLI y Validación de Sincronización en `sync.sh`

## Objetivo
Garantizar la portabilidad shell universal (Linux y macOS) reemplazando comandos no portables (`which`, `timeout` GNU), robustecer `sync.sh` e `install.sh` con pre-flights de escritura y validación canónica de `AGENT_OS_PATH`, y registrar la trazabilidad de commit SHA del core en `last-sync.md`.

## Contexto técnico
La auditoría del Sprint 11 identificó dependencias y comportamientos no portables:
- **SCR-B6**: `discover-fleet.sh` invoca `which` en 3 puntos dentro de su bloque Python embebido. Debe reemplazarse por `shutil.which()`.
- **SCR-M11**: `timeout` GNU en `sync.sh` y `check-session.sh` falla en macOS estándar. Debe modularizarse una única función en `scripts/agent/lib/portable-timeout.sh` y reutilizarse mediante `source`.
- **SCR-B4**: `install.sh` y `sync.sh` no validaban permisos de escritura (`[ -w ]`) en el destino antes de operar.
- **Validación de Core**: `sync.sh` solo comprobaba que `AGENT_OS_PATH` no fuese idéntico al target. Debe validar marcadores canónicos (`AGENTS.md`, `.agents/`, `scripts/agent/`).
- **Trazabilidad SHA**: `sync.sh` grababa únicamente la fecha en `last-sync.md`. Debe incluir el commit SHA (`commit: <sha>`) preservando retrocompatibilidad de lectura.
- **SCR-M5 / SCR-B5**: `check-session.sh` requiere `set -euo pipefail`, pre-flights y silenciado total de `stderr` en llamadas `git rev-parse`.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/lib/portable-timeout.sh`
- `scripts/agent/discover-fleet.sh`
- `scripts/agent/sync.sh`
- `scripts/agent/check-session.sh`
- `scripts/agent/install.sh`
- `docs/sprints/sprint-12-core.md`
- `.agents/tasks/task-081.md`

## Criterios de done
- [x] `scripts/agent/lib/portable-timeout.sh`: implementado de forma modular y portable para Linux y macOS sin requerir GNU coreutils.
- [x] `scripts/agent/discover-fleet.sh`: `shutil.which()` utilizado en reemplazo de `which` (import `shutil`).
- [x] `scripts/agent/sync.sh`: valida marcadores canónicos en `AGENT_OS_PATH` (`AGENTS.md`, `.agents/`, `scripts/agent/`).
- [x] `scripts/agent/sync.sh`: pre-flight `[ -w "$TARGET_PROJECT" ]` antes de sincronizar.
- [x] `scripts/agent/sync.sh`: sustituido `timeout 3` por `portable_timeout 3`.
- [x] `scripts/agent/sync.sh`: registra fecha en L1 y `commit: <sha>` en L2 en `.agents/context/last-sync.md`.
- [x] `scripts/agent/check-session.sh`: `set -euo pipefail` activo, pre-flights verificados y stderr de `git rev-parse` silenciado.
- [x] `scripts/agent/check-session.sh`: sustituido `timeout 3s` por `portable_timeout 3`.
- [x] `scripts/agent/check-session.sh`: lee `last-sync.md` compatiblemente con el nuevo formato multilínea.
- [x] `scripts/agent/install.sh`: pre-flight de comprobación `[ -w "$TARGET_DIR" ]`.
- [x] Pruebas operativas exitosas (`discover-fleet.sh --json`, `check-session.sh`, `sync.sh --dry-run`).
- [x] `tests/validate-control-plane.sh` pasa 12/12 sin regresiones.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-29T21:05:39+01:00 (APROBADO CON CAMBIOS)
- [x] Rama creada: feat/T-081-portabilidad-sync
- [x] Lock activo: .agent-session.lock
- [ ] Sesión cerrada correctamente
