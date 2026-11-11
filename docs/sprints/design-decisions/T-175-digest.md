# Executive Design Digest — T-175

## 🎯 Objetivo
Desmantelar y purgar de forma integral todos los residuos del motor fantasma Bane en el repositorio (wrapper obsoleto, plantillas Docker y runbook), migrar workflows y sondas de flota hacia el cliente soberano existente `searxng-client.sh` y adaptar las validaciones de los Checks 34 y 38 en `tests/validate-control-plane.sh` preservando rígidamente el denominador en **38/38** (0 errores), sin duplicar código de búsqueda ya implementado.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan de trabajo para T-175 satisface con rigor los requisitos del diseño macro aprobado para el Sprint 31. Establece una delimitación estricta de la caja de archivos autorizados (purga de 'bane-client.sh', 'templates/bane/' y su runbook, junto con la actualización de los workflows 'sprint-planning.md', 'deep-research.md' y 'fleet-doctor.sh') y garantiza la reutilización soberana del cliente determinista preexistente 'scripts/agent/lib/searxng-client.sh' sin incurrir en duplicaciones de código.

Asimismo, la estrategia de adaptación de la suite de validación de control plane ('tests/validate-control-plane.sh') preserva la invariante estricta del denominador 38/38 mediante la reconfiguración determinista de los Checks 34 y 38. El protocolo de integración y cierre se ajusta de forma limpia al estándar de Opción D (avance desatendido en camino limpio, merge no-ff y ejecución de 'close-task.sh'). Proceder con la ejecución sin objeciones técnicas.
- **Prospección Scout**: `CONFORME (sprint-31-research.md)`
  - Alternativa detectada:** Cliente soberano SearXNG existente `scripts/agent/lib/searxng-client.sh` (283 líneas, validado en T-169), wrapper de compatibilidad `scripts/agent/lib/bane-client.sh`, plantillas `templates/bane/`, runbook `docs/runbooks/bane-deep-research-service.md`.
  - Recomendación del agente:** Saneamiento total del core erradicando el motor fantasma Bane. Cero duplicación de `searxng-client.sh` (cliente primario activo). Purga de plantillas, cliente y runbook obsoletos, y adaptación de workflows y de los Checks 34 y 38 en `validate-control-plane.sh` manteniendo el denominador inmutable en 38/38.
  - Dictamen del Relé:** **APROBADA formalmente con el alcance verificado**.
  - Notas de integración:**
- **Mensaje de Cierre**: `merge: feat(T-175) purga de residuos Bane, unificacion en SearXNG y adaptacion del control plane`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-175.md`
- `.agents/workflows/deep-research.md`
- `.agents/workflows/sprint-planning.md`
- `docs/runbooks/bane-deep-research-service.md`
- `docs/sprints/sprint-31-core.md`
- `scripts/agent/fleet-doctor.sh`
- `scripts/agent/lib/bane-client.sh`
- `templates/bane/.env.example`
- `templates/bane/docker-compose.yml`
- `tests/validate-control-plane.sh`

## 🧠 Skills Declaradas y Aplicadas
- `agent-os-scripts`
- `tool-inventory`
