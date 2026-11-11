# Executive Design Digest — T-161

## 🎯 Objetivo
Consolidar el ciclo completo de integración de Bane incorporando la sonda de diagnóstico en `scripts/agent/fleet-doctor.sh` (modo warn-only), documentando la guía operativa paso a paso en `docs/runbooks/bane-deep-research-service.md`, implementando el nuevo **Check 38** en la suite de validación `tests/validate-control-plane.sh` y actualizando de forma explícita el denominador formal de la suite de **37/37 a 38/38**, cerrando el mini-sprint de Bane y consolidando las métricas de intervención del piloto Opción D.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico para T-161 cumple de forma exhaustiva con el diseño macro y los principios de arquitectura del core. La integración de la sonda de Bane en `fleet-doctor.sh` bajo la política `warn-only` (exit code 0 garantizado) preserva la estabilidad de diagnósticos de flota sin dependencias duras ni regresiones de salida. Asimismo, la ampliación ordenada de la suite de control plane a 38/38 con migración atómica de denominadores y comprobación estricta de remanentes asegura la integridad del harness de validación.

La delimitación estricta de la caja de archivos autorizados, junto con la frontera portable para el runbook operativo y la consolidación formal del informe de telemetría del Piloto de Autonomía Opción D, satisface los criterios de seguridad, higiene y trazabilidad del sistema. No se identifican riesgos de ruptura, acoplamiento indebido ni credenciales expuestas.
- **Prospección Scout**: `CONFORME (sprint-28-research.md)`
  - Alternativa detectada:** `@hasna/uptime` (v0.1.71, NPM), `@deepseek-ai/dsh-sandbox-local` (v0.0.1-rc.1, NPM).
  - Recomendación del agente:** Desarrollo a medida justificado (sonda determinista en `fleet-doctor.sh` y Check 38 en la suite).
  - Decisión del usuario:** Desarrollo a medida justificado — cerrar el ciclo de integración de Bane con herramientas de diagnóstico y certificación integral del control plane:
  - Sonda en `fleet-doctor.sh`*: Añadir verificación de servicio `bane` en modo `warn-only` (exit code 0, status OK si responde, WARN si está ausente/caído).
- **Mensaje de Cierre**: `Merge branch 'feat/T-161-fleet-doctor-runbook-and-suite-38' into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-161.md`
- `docs/runbooks/bane-deep-research-service.md`
- `docs/sprints/sprint-28-autonomy-pilot-report.md`
- `docs/sprints/sprint-28-core.md`
- `scripts/agent/fleet-doctor.sh`
- `tests/validate-control-plane.sh`

## 🧠 Skills Declaradas y Aplicadas
- `agent-os-scripts`
- `testing-flows`
- `doc-maintainer`
