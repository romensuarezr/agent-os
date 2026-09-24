# Task-037: Primer Run Orca read-only y prueba de Decision Gates (L3)

## Objetivo
Verificar el entorno de orquestación de Orca Desktop 1.4.207, auditar la base de datos `orchestration.db` y los relays remotos en `datamanager` y `oracle`, implementar una herramienta determinista (`scripts/agent/audit-orca.sh`) para salud de orquestación, y documentar el protocolo y validación de Decision Gates (L3) obligatorios ante mutaciones.

## Contexto técnico
- Orca Desktop activo localmente (PID 1668497) con base de datos SQLite en `/home/romen/.config/orca/orchestration.db`.
- Relays remotos activos en `datamanager` (PID 1078790) y `oracle` (PID 2014091).
- La política de permisos L1/L2/L3 (`.agents/rules/global/agent-permissions.md`) exige que cualquier acción que altere infraestructura o archivos en servidores remotos active una compuerta bloqueante (`decision_gates`) en Orca Desktop que impida la ejecución sin confirmación explícita del usuario.
- Restricción estricta: Operación 100% no destructiva. No matar procesos de relay, no forzar mutaciones destructivas ni modificar bases de datos operativas en caliente sin supervisión.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `scripts/agent/audit-orca.sh` (nuevo script determinista de salud de Orca local y remoto en 1 sola llamada)
- `docs/runbooks/orca-read-only-audit.md` (actualización con protocolo de verificación y Decision Gates)
- `.agents/tasks/task-037.md` (task file activo)
- `docs/sprints/sprint-06-core.md` (registro de estado y cierre del sprint)

## Criterios de done
- [x] Creación del script `scripts/agent/audit-orca.sh` que verifique: proceso Orca Desktop local, estadísticas y tablas de `orchestration.db` (runs, tasks, decision_gates), y conectividad de relays en `datamanager` y `oracle` en 1 sola ejecución.
- [x] Ejecución de diagnóstico no destructivo con `scripts/agent/audit-orca.sh` reportando el estado del ecosistema de orquestación.
- [x] Documentación en `docs/runbooks/orca-read-only-audit.md` del protocolo de ejecución de Runs y el mecanismo de verificación de Decision Gates (L3).
- [x] Verificación de integridad local con `bash tests/validate-control-plane.sh` pasando con 0 errores.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-24T17:44:40+01:00
- [x] Rama creada: feat/T-037-orca-readonly-and-gates
- [x] Lock activo: 2026-09-24T17:44:50+01:00
- [x] Sesión cerrada correctamente
