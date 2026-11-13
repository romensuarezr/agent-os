# Sprint 38 — 2026-11-13 → 2026-11-17

## Estado
🟡 En curso

## Tareas
| ID | Descripción | Tamaño | Estado | Dependencias | Task file |
|---|---|---|---|---|---|
| T-205 | Protocolo dinámico de modelos/cuotas, matriz de esfuerzo y reporte de rendición de cuentas | M | ⬜ Pendiente | — | `.agents/tasks/task-205.md` |
| T-206 | Telemetría de arnés/modelo en orchestration-report.sh y sincronización a la flota | S | ⬜ Pendiente | T-205 | `.agents/tasks/task-206.md` |

## Régimen Operativo del Sprint
> Se sella en el sprint planning bajo la gobernanza de Autonomía Acotada (Régimen Desatendido).
- **Régimen**: Desatendido (camino limpio avanza de forma 100% desatendida; aborta fail-closed ante anomalías técnicas o falta de consenso).
- **Orden de Carriles (DAG de dependencias)**:
  - **Carril 1 (Gobernanza y Criterio Dinámico)**: `T-205` (protocolo dinámico, matriz de esfuerzo y reporte en el Coordinador).
  - **Carril 2 (Telemetría y Sincronización)**: `T-206` (evolución de `orchestration-report.sh` y distribución a satélites).
- **Sellado en**: 2026-11-13

## Notas de planning
- **T-205** requiere: actualizar `.agents/profiles/coordinator.md`, `.agents/rules/global/coordinator-boot.md` y `.agents/skills/orchestrator/SKILL.md` para instruir el descubrimiento dinámico de modelos y cuotas en tiempo real, la matriz de dificultad × cuota y la exigencia de emitir el reporte de decisiones de enrutamiento al finalizar.
- **T-206** requiere: enriquecer `scripts/agent/orchestration-report.sh` para soportar la visualización del arnés, modelo y nivel de esfuerzo empleados, sincronizar los activos a los satélites (`<satelites>/annascheer-web`) con `sync.sh --force --cleanup --commit` y auditar con `audit-satellites.sh`.

## Estado de Research y Prospección
- **Scout OSS**: Completado en `docs/sprints/sprint-38-research.md` (Gate Scout-First verificado).
- **Inspección de entorno en vivo**: Verificada la existencia de modelos reales con niveles de esfuerzo (`gemini-3.8-flash-low/medium/high`, `claude-sonnet-4-6`, etc.) y cuotas vivas.

## ✅ Completado (Sprints previos)
- Sprint 37: Orquestación Declarativa, Boot de Coordinador en Satélites, Regla de Umbral y Telemetría Eficiente (T-201 a T-204, v1.33.0).
