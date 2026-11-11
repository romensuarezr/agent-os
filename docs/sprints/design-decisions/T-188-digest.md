# Executive Design Digest — T-188

## 🎯 Objetivo
Resolver de forma integral tres fricciones operativas detectadas en la ejecución desatendida del core: 1. Eliminar la fuga de procesos huérfanos de `agy` garantizando que el timeout de 30s de `deliberate-plan.sh` y `portable-timeout.sh` mate todo el grupo de procesos (`PGID`). 2. Hacer condicional el Paso 6 de `sprint-planning.md`: si la investigación fue autónoma (SearXNG activo), suprimir el prompt de Perplexity y la pausa; si SearXNG estaba inactivo, emitir anuncio explícito del motivo/código antes de solicitar la asistencia manual. 3. Estandarizar la compuerta proactiva de `session-start.md` para que ante un sprint con `[PENDIENTE_ARRANQUE]` emita de forma invariable y determinista la consulta estructurada de Régimen (A: Opción D / B: Clásico) y el camino de carriles.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan de trabajo para T-188 aborda con precisión quirúrgica los 3 mandatos técnicos de la enmienda del Sprint 33. La estrategia para la gestión de timeouts mediante el aislamiento de grupos de procesos (PGID vía `setsid` y `start_new_session=<redacted:start_new_session> junto con la propagación estricta de señales (`SIGTERM`/`SIGKILL`) mitiga eficazmente la fuga de procesos huérfanos sin poner en riesgo la sesión principal del agente.

Asimismo, el desacoplamiento condicional de SearXNG/Perplexity en `sprint-planning.md` garantiza resiliencia con feedback determinista no silencioso en fallbacks, mientras que la estandarización de la compuerta proactiva en `session-start.md` elimina la ambigüedad en el arranque del sprint. La caja de archivos autorizados está estrictamente acotada y los criterios de verificación aseguran la integridad del control plane sin regresiones.
- **Prospección Scout**: `CONFORME (sprint-33-research.md)`
  - Alternativa detectada:**
  - 1. Fuga de procesos huérfanos de `agy --conversation` detectada en producción durante timeouts de `deliberate-plan.sh` (ej. PID 814302, 38+ min activos) debido a que `portable-timeout.sh` señalizaba únicamente al proceso directo y no a todo el process group.
  - 2. Paso 6 de `sprint-planning.md` rígido, que forzaba pausa y prompt de Perplexity incluso cuando SearXNG ejecutó la investigación técnica de forma 100% autónoma.
  - 3. Compuerta de arranque de sprint en `session-start.md`: diagnóstico de activación ante estado `[PENDIENTE_ARRANQUE]` y estandarización del bloque interactivo proactivo de opciones (A/B + carriles).
- **Mensaje de Cierre**: `Merge branch 'feat/T-188-endurecimiento-flujo-desatendido' into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-188.md`
- `.agents/workflows/session-start.md`
- `.agents/workflows/sprint-planning.md`
- `docs/sprints/sprint-33-core.md`
- `scripts/agent/lib/portable-timeout.sh`
- `tests/validate-control-plane.sh`

## 🧠 Skills Declaradas y Aplicadas
- Ninguna skill adicional registrada.
