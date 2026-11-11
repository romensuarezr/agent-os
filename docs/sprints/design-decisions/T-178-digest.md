# Executive Design Digest — T-178

## 🎯 Objetivo
Erradicar por completo los residuos de configuración y código del motor fantasma Bane que permanecen en el repositorio, concretamente el bloque de servicio `bane:` en `.agents/config/fleet.example.yaml` y las referencias de fallback `BANE_API_URL` y `svcs['bane']` en `scripts/agent/lib/searxng-client.sh`, blindando su ausencia definitiva en el Check 34 (§18) de `tests/validate-control-plane.sh`.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico propuesto para T-178 satisface plenamente los principios de diseño atómico y no regresión de Agent OS. La caja de archivos se encuentra estrictamente acotada a los 4 archivos pertinentes (.agents/config/fleet.example.yaml, scripts/agent/lib/searxng-client.sh, tests/validate-control-plane.sh y .agents/tasks/task-178.md). La erradicación de fallbacks heredados de Bane se realiza preservando de forma limpia la jerarquía de resolución soberana de SearXNG (SEARXNG_API_URL -> fleet.yaml/fleet.example.yaml -> localhost:8080).

Asimismo, la extensión de la sección §18 dentro del Check 34 existente garantiza el blindaje estático determinista contra regresiones de residuos Bane sin alterar el denominador canónico inmutable de la suite (38/38 checks en verde). Cumple con el estándar de Opción D y está listo para ejecución desatendida en camino limpio.
- **Prospección Scout**: `CONFORME (sprint-32-research.md)`
  - Alternativa detectada:** Residuos de configuración y fallback detectados en `fleet.example.yaml:89` (`bane:`), fallback `BANE_API_URL` y bloque `svcs['bane']` en `scripts/agent/lib/searxng-client.sh`, y verificación existente en `tests/validate-control-plane.sh` Check 34 (§18).
  - Recomendación del agente:** Erradicación determinista y completa de las referencias residuales a Bane en la configuración de ejemplo y en el cliente de SearXNG. Blindar en el Check 34 (§18) de `validate-control-plane.sh` que ni `fleet.example.yaml` ni `searxng-client.sh` contengan menciones al motor obsoleto Bane, preservando el denominador 38/38.
  - Dictamen del Operador:** Aprobada. Se aclara explícitamente que las comprobaciones de Bane viven en Check 34 (§18) y no en Check 18.
  - Notas de integración:**
- **Mensaje de Cierre**: `merge: feat(T-178) purga definitiva de residuos Bane en fleet y searxng-client`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/config/fleet.example.yaml`
- `.agents/tasks/_archived/task-178.md`
- `docs/sprints/sprint-32-core.md`
- `scripts/agent/lib/searxng-client.sh`
- `tests/validate-control-plane.sh`

## 🧠 Skills Declaradas y Aplicadas
- Ninguna skill adicional registrada.
