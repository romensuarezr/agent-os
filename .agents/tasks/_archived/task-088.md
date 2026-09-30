# Task-088: Ledger de versiones del core y auditoría de salud en satélites (audit-child.sh con suite dedicada)

## Objetivo
Implementar el ledger de versiones del core y la herramienta de diagnóstico y auditoría de salud en proyectos satélite (`audit-child.sh`), permitiendo inspeccionar la conformidad arquitectónica de cualquier repositorio hijo, detectar drift de configuraciones (ej. presencia de rutas deprecadas `config/` vs `.agents/config/`), validar la vigencia de sincronización y registrar trazabilidad estricta de upgrades, respaldado por una suite de pruebas dedicada (`tests/test-audit-child.sh`) desacoplada del control plane para preservar el invariante 12/12.

## Contexto técnico y Dependencias
- **Anti-telemetría absoluta**: `audit-child.sh` es 100% local y offline. Cero llamadas de red (cero `curl`, `wget`, `git fetch`), cero reporte de métricas o telemetría al core. El hijo se autodiagnostica de forma autónoma; el core solo distribuye la herramienta.
- **Trazabilidad de versión en satélites**: Tanto `install.sh` como `sync.sh` registran atómicamente el estado de versión del core en `.agents/context/last-sync.md` con formato enriquecido (aditivo, retrocompatible con formato legacy):
  - Línea 1: Fecha UTC (`YYYY-MM-DD`).
  - Línea 2: `version: <VERSION>` (versión canónica del core).
  - Línea 3: `tag: v<VERSION>`.
  - Línea 4: `commit: <sha>`.
- **Auditoría de Salud de Satélites (`audit-child.sh`)**:
  Script universal que se ejecuta dentro de un repositorio hijo (o apuntando a uno con `--path /ruta`) y ejecuta 6 diagnósticos deterministas con umbrales configurables (`DRIFT_WARN_DAYS=7`, `DRIFT_CRITICAL_DAYS=14` como constantes nombradas):
  1. **Estructura base de Agent OS**: Existencia de `.agents/rules`, `.agents/workflows`, `.agents/skills`, `.agents/profiles`, `.agents/config` y `scripts/agent`.
  2. **Detección de Drift de Configuración**: Alerta si persisten rutas obsoletas (`config/fleet.yaml`, `config/skills-manifest.yaml`) que debieron migrar a `.agents/config/`.
  3. **Vigencia y Ledger de Versión**: Lee `.agents/context/last-sync.md`, extrae versión y fecha, y calcula los días transcurridos desde el último sync (aviso de actualización si >7 días, crítico si >14 días; soporta parsing de ledger enriquecido y fallback legacy). En modo standalone juzga integridad + edad; en modo `--path` (o con `AGENT_OS_PATH` disponible) contrasta además con la `VERSION` canónica del core.
  4. **Integridad de Onboarding**: Verifica que `.agents/AGENT_ONBOARDING.md` existe y no es la plantilla genérica sin completar.
  5. **Ejecutabilidad de Ferramental**: Verifica permisos `+x` en los scripts de `scripts/agent/*.sh`.
  6. **Detección Defensiva de Stack**: Ejecuta `scripts/agent/lib/detect-stack.sh` y reporta `AGENT_OS_STACK`, `AGENT_OS_PACKAGE_MANAGER` y advertencias de divergencia si existen.
- **Cableado del disparador en satélites**: Actualización de `.agents/templates/AGENT_ONBOARDING.project.md` para incluir el pre-flight de arranque de sesión ejecutando `bash scripts/agent/audit-child.sh`.
- **Aislamiento de Testing del Control Plane**:
  `audit-child.sh` se valida de forma no destructiva y determinista mediante `tests/test-audit-child.sh` (con mocks de repositorios satélite en estados sano, con drift, desactualizado y roto), sin modificar `tests/validate-control-plane.sh` que conserva rígidamente su invariante 12/12.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `docs/sprints/sprint-13-core.md`
- `.agents/tasks/task-088.md`
- `scripts/agent/audit-child.sh`
- `scripts/agent/install.sh`
- `scripts/agent/sync.sh`
- `scripts/agent/assets-manifest.txt`
- `.agents/templates/AGENT_ONBOARDING.project.md`
- `tests/test-audit-child.sh`

## Criterios de done
- [x] `scripts/agent/install.sh` y `scripts/agent/sync.sh` registran atómicamente fecha, versión, tag y commit SHA en `.agents/context/last-sync.md`.
- [x] `scripts/agent/audit-child.sh` implementado con soporte para ejecución local en repo activo o vía `--path /ruta/al/hijo`.
- [x] `audit-child.sh` es 100% local, offline, sin telemetría ni llamadas de red.
- [x] `audit-child.sh` define constantes `DRIFT_WARN_DAYS=7` y `DRIFT_CRITICAL_DAYS=14`, diagnosticando los 6 aspectos con soporte standalone y `--path`.
- [x] Salida formateada con semáforo estándar: `✅ CONFORME`, `⚠️ DRIFT DETECTADO`, `❌ NO CONFORME`, con código de salida determinista (0 en conforme/advertencia, 1 en error crítico).
- [x] `.agents/templates/AGENT_ONBOARDING.project.md` incorpora el pre-flight de arranque con interpretación conforme a `deterministic-execution.md`.
- [x] `scripts/agent/assets-manifest.txt` actualizado incluyendo `scripts/agent/audit-child.sh`.
- [x] Nueva suite unitaria `tests/test-audit-child.sh` valida todos los escenarios de diagnóstico en repositorios efímeros.
- [x] `tests/validate-control-plane.sh` permanece en 12/12 PASS sin modificaciones ni regresiones.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-30T00:57:50+01:00
- [x] Rama creada: feat/T-088-audit-child-version-ledger
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
