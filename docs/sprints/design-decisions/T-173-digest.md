# Executive Design Digest — T-173

## 🎯 Objetivo
Implementar una utilidad CLI determinista en `scripts/agent/check-tooling-updates.sh` con coste $0 de tokens para inspeccionar versiones disponibles de las herramientas y CLIs de la flota a través de registros oficiales (npm, GitHub releases, PyPI), con normalización semver, mapeo de fuente verídica por herramienta y soporte de ejecución resiliente ante cuotas y desconexión.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico de T-173 satisface los principios de arquitectura determinista y coste $0 de tokens de Agent OS. Respeta estrictamente la caja de archivos autorizados (`scripts/agent/check-tooling-updates.sh`, `tests/validate-control-plane.sh` y `.agents/tasks/task-173.md`), garantiza resiliencia operativa frente a caídas de red o límites de cuota (HTTP 429/403) con timeout estricto de 5s y degradación limpia, y salvaguarda la inmutabilidad del denominador 38/38 en la suite de validación sin alterar la gobernanza de Opción D.
- **Prospección Scout**: `CONFORME (sprint-31-research.md)`
  - Alternativa detectada:** `new-releases.io` (servicio SaaS de monitorización), Renovate con Custom Regex Managers (`datasource=<redacted:datasource> API pública de GitHub (`releases/latest`), registro npm (`registry.npmjs.org`), API de PyPI (`pypi.org/pypi/<pkg>/json`).
  - Recomendación del agente:** Implementación de un script CLI determinista en `scripts/agent/check-tooling-updates.sh` con coste $0 de tokens, que verifique versiones sin autenticación obligatoria y con fallback fail-soft ante cuotas o desconexión.
  - Dictamen del Relé:** Recomendación ratificada. Mapeo explícito de la fuente verídica de versión por herramienta (ejemplo: npm para `@opencode/cli` debido a que GitHub releases devuelve v1.x; GitHub para repositorios como `stablyai/orca` o `hermes-agent`). Normalización semver (eliminando prefijo `v`), soporte de flags `--json`, `--check` y timeout estricto.
  - Notas de integración:**
- **Mensaje de Cierre**: `Merge branch 'feat/T-173-tooling-updates-probe' into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-173.md`
- `docs/sprints/sprint-31-core.md`
- `scripts/agent/check-tooling-updates.sh`
- `tests/validate-control-plane.sh`

## 🧠 Skills Declaradas y Aplicadas
- `agent-os-scripts`
- `tool-inventory`
