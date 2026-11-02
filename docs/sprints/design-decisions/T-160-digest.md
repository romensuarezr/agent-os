# Executive Design Digest — T-160

## 🎯 Objetivo
Crear el workflow especializado `.agents/workflows/deep-research.md` e integrarlo en el flujo de `sprint-planning.md` implementando una bifurcación determinista: si Bane está configurado y alcanzable ("activo"), despacha la consulta automáticamente y deposita la investigación estructurada sin intervención humana; si Bane está inactivo, ausente o no responde, preserva íntegramente el flujo manual actual emitiendo el bloque de prompt listo para copiar en Perplexity Pro sin provocar bloqueos ni roturas.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico de T-160 satisface rigurosamente las decisiones e interfaces selladas en el diseño macro aprobado para el Sprint 28. La bifurcación determinista evaluada mediante `bane-client.sh --check` garantiza un comportamiento fail-soft que preserva al 100% el flujo manual clásico de Perplexity Pro ante la ausencia o fallo del servicio Bane, previniendo regresiones en entornos satélite.

La delimitación de la caja de archivos autorizada es precisa y estricta, la estructura de volcado autónomo respeta las cabeceras canónicas de investigación de Agent OS, y se compromete el mantenimiento del denominador de la suite de control plane en 37/37 (0 errores).
- **Prospección Scout**: `CONFORME (sprint-28-research.md)`
  - Alternativa detectada:** `@mastra/core` (v1.81.0, NPM), `@anthropic-ai/claude-agent-sdk` (v0.3.316, NPM).
  - Recomendación del agente:** Desarrollo a medida justificado (evolución determinista de `.agents/workflows/`).
  - Decisión del usuario:** Desarrollo a medida justificado — crear el workflow especializado `.agents/workflows/deep-research.md` e integrarlo en `sprint-planning.md` con bifurcación automática:
  - Rama A (Bane Activo / Autónomo)*: Si `bane-client.sh --check` confirma que el servicio está configurado y alcanzable en timeout, el workflow despacha la consulta automáticamente, captura la investigación estructurada en stdout y la deposita directamente en el research del sprint o tarea sin requerir intervención humana.
- **Mensaje de Cierre**: `Merge branch 'feat/T-160-deep-research-workflow' into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-160.md`
- `.agents/workflows/deep-research.md`
- `.agents/workflows/sprint-planning.md`
- `docs/sprints/design-decisions/T-159-digest.md`
- `docs/sprints/design-decisions/T-159-raw.json`
- `docs/sprints/sprint-28-core.md`
- `scripts/agent/design-digest.sh`
- `tests/validate-control-plane.sh`

## 🧠 Skills Declaradas y Aplicadas
- `agent-os-scripts`
- `workflow-designer`
