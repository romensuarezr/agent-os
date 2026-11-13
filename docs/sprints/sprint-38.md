# Sprint 38 — 2026-11-13 → 2026-11-17

## Estado
🟡 En curso

## Tareas
| ID | Descripción | Tamaño | Estado | Dependencias | Task file |
|---|---|---|---|---|---|
| T-205 | Protocolo dinámico de modelos/cuotas, matriz de esfuerzo y reporte de rendición de cuentas | M | ✅ Completada | — | `.agents/tasks/_archived/task-205.md` |
| T-206 | Telemetría de arnés/modelo en orchestration-report.sh y sincronización a la flota | S | ✅ Completada | T-205 | `.agents/tasks/_archived/task-206.md` |
| T-207 | Regla global de Priorización por Retorno Económico (ROI-First) y sesgo Anti-Activity Theater | M | ✅ Completada | T-205, T-206 | `.agents/tasks/task-207.md` |
| T-208 | Promoción a main (Decision Gate), versión v1.34.0 y sincronización universal a satélites | S | ⬜ Pendiente | T-207 | `.agents/tasks/task-208.md` |

## Régimen Operativo del Sprint
> Se sella en el sprint planning bajo la gobernanza de Autonomía Acotada (Régimen Desatendido).
- **Régimen**: Desatendido (camino limpio avanza de forma 100% desatendida; aborta fail-closed ante anomalías técnicas o falta de consenso).
- **Orden de Carriles (DAG de dependencias)**:
  - **Carril 1 (Gobernanza Dinámica & Telemetría)**: `T-205` (protocolo dinámico en Coordinador) → `T-206` (telemetría CLI). [Completado ✅]
  - **Carril 2 (Orientación a Negocio & Priorización ROI-First)**: `T-207` (regla global de priorización económica y recomendación proactiva en arranque del Coordinador).
  - **Carril 3 (Consolidación a Main & Sincronización Universal)**: `T-208` (promoción a `main` con Decision Gate, tag `v1.34.0`, propagación universal a `<satelites>` y auditoría de integridad).
- **Sellado en**: 2026-11-13

## Notas de planning
- **T-205**: Protocolo dinámico de modelos/cuotas y matriz de esfuerzo en Coordinador (`.agents/profiles/coordinator.md`, `.agents/rules/global/coordinator-boot.md`, `.agents/skills/orchestrator/SKILL.md`).
- **T-206**: Soporte de arnés, modelo y esfuerzo en `scripts/agent/orchestration-report.sh`.
- **T-207**: Regla `.agents/rules/global/roi-first-prioritization.md` e integración en `coordinator-boot.md` y `coordinator.md`, incorporando el sesgo anti-actividad (*anti-activity bias*) y la matriz de retorno (Tier 1: Revenue & Conversion, Tier 2: Distribution & Trust, Tier 3: Supporting).
- **T-208**: Ejecución del Decision Gate `/promote` hacia `main`, actualización de `changelog.md` (`v1.34.0`), propagación a los satélites (`annascheer-web`, etc.) mediante `sync.sh --force --cleanup --commit` y validación con `audit-satellites.sh`.

## Estado de Research y Prospección
- **Scout OSS & Industry Research**: Exhaustivo en `docs/sprints/sprint-38-research.md` (Gate Scout-First verificado).
- **Inspección de entorno en vivo**: Verificada la existencia de modelos reales con niveles de esfuerzo (`gemini-3.8-flash-low/medium/high`, `claude-sonnet-4-6`) y cuotas vivas.
- **Investigación de ROI en agentes**: Analizados modelos de *Profit Infrastructure*, *Value-First Matrix* y *Anti-Activity Bias*.

## ✅ Completado (Sprints previos)
- Sprint 37: Orquestación Declarativa, Boot de Coordinador en Satélites, Regla de Umbral y Telemetría Eficiente (T-201 a T-204, v1.33.0).
