# Sprint 36 — 2026-11-16 → 2026-11-20

## Estado
🟡 En curso

## Tareas
| ID | Descripción | Tamaño | Estado | Dependencias | Task file |
|---|---|---|---|---|---|
| T-196 | Jerarquía de conocimiento y comunicación natural: crear `.agents/rules/global/knowledge-hierarchy.md` (separación canónica directrices humanas inmutables vs digests sintéticos de máquina) y regla anti-AI-slop (lenguaje denso, conciso, técnico) | S | ✅ Hecho | — | [.agents/tasks/task-196.md](.agents/tasks/_archived/task-196.md) |
| T-197 | Auditoría determinista de tokenomics en skills: extender `scripts/agent/inspect-skills.sh` con `--context` (líneas y peso estimado de tokens por `SKILL.md`) y detección de skills huérfanas no referenciadas en workflows ni perfiles | M | ✅ Hecho | — | [.agents/tasks/task-197.md](.agents/tasks/_archived/task-197.md) |
| T-198 | Política de enrutamiento `/advisor` y catálogo FreeLLMAPI: formalizar el rol Asesor en `.agents/config/routing-policy.yaml` (workers rápidos para codificación, top-model para diseño/arbitraje) y declarar proveedores DeepSeek MoE y Nvidia NIM en `templates/freellmapi/config/freellmapi.config.json` | M | ✅ Hecho | — | [.agents/tasks/task-198.md](.agents/tasks/_archived/task-198.md) |
| T-199 | Sandboxing no-root y auditoría defensiva de satélites: crear `.agents/rules/global/agent-sandbox.md` (daemons/agentes/contenedores sin privilegios root) y la skill `.agents/skills/security-audit/SKILL.md` (escáner estático de autorización de rutas, firma JWT e IDOR) | M | ✅ Hecho | — | [.agents/tasks/task-199.md](.agents/tasks/_archived/task-199.md) |
| T-200 | Skill `idea-validator`: filtro de viabilidad objetiva para `docs/idea-inbox/` con veredicto numérico 1–10 basado en prospección determinista SearXNG (`searxng-search.py`) y `scout.sh` para neutralizar el sesgo de complacencia | M | ✅ Hecho | — | [.agents/tasks/task-200.md](.agents/tasks/_archived/task-200.md) |

## Régimen Operativo del Sprint
> Se sella en la primera sesión de /session-start tras consulta proactiva única al operador.
- **Régimen**: Desatendida (alias histórico «Opción D»)
- **Orden de Carriles (DAG de dependencias)**:
  - Carril 1 (secuencial, dictamen NO-GO paralelismo Sprint 25): T-196 → T-197 → T-198 → T-199 → T-200
- **Sellado en**: 2026-11-11 — veredicto del operador: `A, aprobado` (autorización macro para régimen Desatendido)

## Notas de planning
- Fuente: paquete `docs/idea-inbox/2026-11-11-paquete-gobernanza-seguridad-contexto.md` (Bloques A–E seleccionados; Bloque F — compuerta storyboard y marcado GEO/JSON-LD — diferido a `## Backlog` del roadmap por límite de 5 tareas).
- Firewall anti-duplicación: los 4 drafts de tooling regenerados por la sonda (opencode v2.2.7, hermes v0.23.1, orca v1.4.256, infisical) se **descartan** — idénticos a los ya procesados y homologados en T-192 (Sprint 35, ✅ en changelog `1.31.0`). Residuo observado: los binarios del host siguen en versiones antiguas; su aplicación es acción operativa a demanda del operador (bump cosmético prohibido como tarea de sprint).
- Spillover: ninguno (sistema limpio, sprint-35 archivado). `TAREA_SIGUIENTE_ID` = T-196 → numeración correlativa T-196…T-200.
- Diseño macro de cada tarea se sella en el materializado de task files tras veredicto del operador en el Paso 7 (sección `## Diseño macro aprobado en planning` con `[APROBADO_EN_PLANNING]`).
- Research Scout-First (Gate T-129) en `docs/sprints/sprint-36-research.md`; SearXNG activo (exit 0) → investigación autónoma, sin fallback Perplexity.
