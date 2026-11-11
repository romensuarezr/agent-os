# Task-133: Cliente Unificado `lib/orca-client.sh` y Detección Portable de Runtime (`orca-ide`)

## Objetivo
Implementar una biblioteca compartida y universal `scripts/agent/lib/orca-client.sh` que centralice la detección determinista de Orca ADE, la resolución de su ejecutable sin ambigüedad (`orca-ide` por PATH, sin colisionar con el lector de pantalla `/usr/bin/orca` y sin rutas personales hardcodeadas como `<home-usuario>`), y abstraiga las operaciones fundamentales del ciclo de vida de workers (`status`, `worker-start`, `worker-read`, `worker-release`).

## Contexto técnico
Actualmente coexisten fragmentos de resolución e invocación de Orca en `scripts/agent/orca-orchestrate.sh` y `scripts/agent/dispatch-satellite.sh`. Algunos fragmentos verifican shims locales o asumen variables de entorno dispares. Además, `/usr/bin/orca` en sistemas Linux basados en GNOME corresponde al lector de pantalla accesible, provocando cuelgues o timeouts si un script invoca `orca` sin verificar previamente la presencia del ADE.

Esta tarea:
1. Audita los puntos de invocación en `orca-orchestrate.sh` y `dispatch-satellite.sh` para extraer los patrones comunes sin duplicación (DRY).
2. Crea `scripts/agent/lib/orca-client.sh` con funciones POSIX:
   - `orca_resolve_bin()`: detecta prioritariamente `orca-ide` en PATH o mediante el shim estándar del ADE ($HOME), descartando el lector GNOME.
   - `orca_is_ready()`: sonda fail-fast determinista con timeout estricto (<1s) que valida si el runtime ADE está escuchando.
   - `orca_status()`: consulta el estado del runtime con salida JSON.
   - `orca_worker_start()`: inicia workers supervisados bajo whitelist única de aislamiento de entorno (`env -i`).
   - `orca_worker_read()`: lee la transcripción o terminal del worker.
   - `orca_worker_release()`: libera de forma limpia e idempotente el terminal asignado.
3. Refactoriza los scripts consumidores para reutilizar la biblioteca compartida manteniendo retrocompatibilidad.

## Skills relevantes
- `agent-os-scripts`: Regla aplicada: contratos CLI deterministas, scripts bash modulares y portabilidad POSIX entre plataformas.
- `orchestrator`: Regla aplicada: interfaces unificadas para el control del ciclo de vida multi-agente.

## Caja de archivos
- `scripts/agent/lib/orca-client.sh` (nuevo)
- `scripts/agent/orca-orchestrate.sh`
- `scripts/agent/dispatch-satellite.sh`
- `.agents/tasks/task-133.md`

## Criterios de done
- [ ] `lib/orca-client.sh` implementado y resolviendo deterministamente `orca-ide` vía PATH/shims ($HOME) sin contener rutas personales `<home-usuario>`.
- [ ] `orca_is_ready()` implementado con timeout <1s y sin cuelgues ante colisiones con el lector GNOME (`/usr/bin/orca`).
- [ ] Whitelist `env -i` única y documentada en `lib/orca-client.sh` aplicada en `orca_worker_start()`.
- [ ] Prueba viva con evidencia real del ciclo de vida del worker bajo whitelist (`orca_worker_start` → `orca_worker_read` → `orca_worker_release`).
- [ ] `orca-orchestrate.sh` y `dispatch-satellite.sh` refactorizados para consumir `lib/orca-client.sh` sin cambiar su comportamiento CLI ni salidas.
