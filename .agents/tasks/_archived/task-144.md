# Task-144: Estabilidad de terminales, censo `worker-list` y recolección de basura

## Objetivo
Implementar mecanismos deterministas de recolección de procesos (process reaper) y limpieza garantizada de terminales en el host mediante traps de señales del sistema operativo (`EXIT`, `INT`, `TERM`, `HUP`), asegurando que tras cualquier ejecución concurrente (exitosa o interrumpida) el censo emitido por `orca orchestration worker-list` reporte exactamente 0 terminales huérfanas.

## Contexto técnico
Uno de los criterios determinantes del Gate de T-140 es la ausencia absoluta de fugas de recursos en el runtime de Orca ADE. En ejecuciones paralelas, si un script falla a mitad de ciclo o el usuario envía un `SIGINT` (Ctrl+C), los terminales aprovisionados en el host pueden quedar en estado zombie o bloqueando sockets locales.
Esta tarea introduce una utilidad centralizada de saneamiento y trampas de salida (`trap`) que registra los `dispatch_id` aprovisionados, asegurando que ante cualquier condición de salida se dispare de forma determinista la secuencia `worker-stop --dispatch <id>` y `worker-release --dispatch <id>`, auditando el censo de `worker-list --terminal-state active` antes y después de cada lote.

## Skills relevantes
- `orchestrator`: Gestión del ciclo de vida de procesos de orquestación y recolección de estados residuales.
- `agent-os-scripts`: Robustez en control de señales POSIX y scripts CLI a prueba de interrupciones.

## Caja de archivos
- `scripts/agent/lib/terminal-reaper.sh` (nuevo módulo helper determinista)
- `scripts/agent/deliberate-plan.sh` (adopción de trampas y registro de dispatch activo)
- `.agents/tasks/task-144.md`

## Criterios de done
- [x] Módulo `scripts/agent/lib/terminal-reaper.sh` implementado con registro de workers activos (`REAPER_TRACKED_DISPATCHES`), traps POSIX deterministas (`EXIT`, `INT`, `TERM`, `HUP`) e integración unificada en `deliberate-plan.sh`.
- [x] Secuencia de liberación determinista (`worker-stop` + `worker-release`) garantizada ante interrupción forzada o salida anómala; fail-safe `worker-abandon` condicionado a backend alcanzable y log para inspección humana en desconexión total.
- [x] Verificación determinista post-ejecución: `orca orchestration worker-list --terminal-state active --json` reporta 0 terminales activas (`result.workers: []`, `result.page.total: 0`, `delta_active == 0`).
- [x] Prueba de estrés simulando aborto abrupto (`SIGINT` rc=130 y `SIGTERM` rc=143) confirmando que los traps ejecutan `reaper_cleanup_all` y no quedan terminales zombies.
- [x] Plan deliberado en Fase 3.5: SIN_REVISOR por timeout/indisponibilidad de pasarela (aprobación del relé, sin Revisor Ejecutor vivo).
- [x] Suite completa de control plane `tests/validate-control-plane.sh` pasando limpia (37/37) y cero violaciones de higiene.
