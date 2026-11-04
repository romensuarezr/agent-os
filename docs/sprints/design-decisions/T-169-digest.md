# Executive Design Digest — T-169

## 🎯 Objetivo
Evaluar y poner en producción viva una solución soberana de búsqueda profunda para la flota de Agent OS. En primera instancia, realizar un ensayo en vivo de Vane comprobando de forma determinista la disponibilidad de una imagen pública descargable (`docker pull`) y la generación de un informe útil; en caso de que la imagen no exista o el ensayo no resulte satisfactorio, abortar inmediatamente a humano (fail-closed, quedando prohibido cerrar con meras plantillas). Tras el ensayo o como solución soberana prioritaria, reactivar la instancia preexistente de SearXNG en la flota sin uso actual, validando una consulta real y cableándola como backend del motor de búsqueda sin duplicar contenedores. Finalmente, sustituir los artefactos fantasma de Bane (cliente CLI, workflow de deep-research, checks de la suite y runbook) por componentes adaptados al motor validado, cerrando la tarea con una investigación real ejecutada por la ruta autónoma del workflow.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico de la T-169 cumple con total fidelidad la directriz sellada en la Enmienda 5 del Sprint 30. Aplica el principio fail-closed ante la inexistencia de artefactos públicos para Vane, prioriza la reutilización de infraestructura preexistente (SearXNG + Redis en Coolify) sin duplicidad de recursos, y aísla la configuración viva en el overlay privado sin comprometer la frontera portable de `fleet.example.yaml`.

La sustitución del cliente fantasma de Bane por una utilidad CLI determinista ($0) y la actualización del Check 38 preservando estrictamente el denominador en 38/38 garantizan la integridad del plano de control y la trazabilidad operativa sin riesgo de regresiones arquitectónicas.
- **Prospección Scout**: `CONFORME (sprint-30-research.md)`
  - Alternativa detectada:** Vane (`pythops/vane`), SearXNG (`searxng/searxng`), DuckDuckGo HTML scraping, APIs comerciales (Tavily, Perplexity).
  - Recomendación del agente:** Ensayo de Vane con compuerta fail-closed: pull previo obligatorio de imagen Docker pública; si no existe o el ensayo no da informe útil, aborto inmediato a humano. Reactivación del contenedor SearXNG preexistente en la flota (sin duplicar instancias), probando consulta real y conectándolo como backend del motor de búsqueda profunda. Sustituir componentes de Bane por los del motor probado.
  - Dictamen del Relé (Enmienda vinculante):** Ratificado. T-169 sucede a T-165 con nuevo ID. El cierre exige investigación real autónoma ejecutada por el workflow canónico `deep-research.md`. Denominador inmutable en 38/38.
  - Alternativas rechazadas y motivos:**
- **Mensaje de Cierre**: `Merge branch 'feat/T-169-search-engine-vane-searxng' into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-169.md`
- `.agents/workflows/deep-research.md`
- `.gitignore`
- `docs/runbooks/searxng-deep-research-service.md`
- `docs/sprints/sprint-30-core.md`
- `scripts/agent/lib/bane-client.sh`
- `scripts/agent/lib/searxng-client.sh`
- `templates/searxng/.env.example`
- `templates/searxng/docker-compose.yml`
- `templates/searxng/limiter.toml`
- `templates/searxng/settings.yml`
- `tests/validate-control-plane.sh`

## 🧠 Skills Declaradas y Aplicadas
- `remote-admin`
- `tech-scout`
- `coolify-admin`
- `agent-os-scripts`
