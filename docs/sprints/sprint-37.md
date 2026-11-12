# Sprint 37 — 2026-11-16 → 2026-11-20

## Estado
🟡 En curso

## Tareas
| ID | Descripción | Tamaño | Estado | Dependencias | Task file |
|---|---|---|---|---|---|
| T-201 | Plantilla AGENTS.md para satélites y regla de boot del Coordinador | M | ✅ Completada | — | `.agents/tasks/task-201.md` |
| T-202 | Declaración de Playbooks de orquestación y regla de umbral (<= 3 archivos) | M | ✅ Completada | T-201 | `.agents/tasks/task-202.md` |
| T-203 | Contrato de retorno compacto anti-context rot y script de telemetría | M | ✅ Completada | T-202 | `.agents/tasks/task-203.md` |
| T-204 | Ensayo y validación E2E en satélite real (annascheer-web) | S | ✅ Completada | T-201, T-202, T-203 | `.agents/tasks/task-204.md` |

## Régimen Operativo del Sprint
> Se sella en el sprint planning bajo la gobernanza de Autonomía Acotada (Régimen Desatendido).
- **Régimen**: Desatendido (camino limpio avanza de forma 100% desatendida; aborta fail-closed ante anomalías técnicas o falta de consenso).
- **Orden de Carriles (DAG de dependencias)**:
  - **Carril 1 (Onboarding & Gobernanza)**: `T-201` (fundación de descubrimiento proactivo para satélites).
  - **Carril 2 (Motor de Playbooks)**: `T-202` (requiere T-201 para formalizar la regla de umbral y playbooks).
  - **Carril 3 (Telemetría & Aislamiento de Contexto)**: `T-203` (requiere T-202 para medir el uso de playbooks).
  - **Carril 4 (Validación E2E en Satélite Real)**: `T-204` (requiere T-201, T-202 y T-203 para ensayar en `annascheer-web`).
- **Sellado en**: 2026-11-12

## Notas de planning
- **T-201** requiere: creación de `templates/root/AGENTS.md` para satélites, inclusión en `install.sh` y `sync.sh`, y regla global `.agents/rules/global/coordinator-boot.md` que ejecuta pre-flight determinista silencioso (`check-session.sh` + `check-sprint.sh`) y saluda proactivamente como Coordinador con el menú interactivo.
- **T-202** requiere: especificación declarativa en `.agents/config/orchestration-playbooks.yaml` de las estrategias (`direct`, `scout-then-build`, `plan-big-execute-small`, `parallel-worktrees`, `review-gate`), y la regla dura de umbral (si la allowlist tiene $\le 3$ archivos, forzar `direct` sin overhead de delegación ni worktrees).
- **T-203** requiere: actualización de `.agents/profiles/coder.md` y `worktree-merge.sh` para exigir que los workers entreguen únicamente digests estructurados (diffstat + `verify-goal.sh --json`), y desarrollo de `scripts/agent/orchestration-report.sh` para telemetría de ejecución y reporte de coste/ahorro.
- **T-204** requiere: sincronizar los activos a `<satelites>/annascheer-web` con `sync.sh --commit`, validar la presencia de `AGENTS.md`, comprobar que el pre-flight del Coordinador detecta el estado del Sprint 02 (T-008, T-009, T-010) y dejar la guía paso a paso para la prueba manual del operador.

## Estado de Research y Prospección
- **Scout OSS**: Completado en `docs/sprints/sprint-37-research.md` (Gate Scout-First T-129 verificado).
- **Investigación técnica**: Autónoma con SearXNG (`[ACTIVO]`, evidencia de benchmarks de Anthropic y Alethe integrada).
- **Prompt Perplexity**: No requerido (SearXNG disponible y validado).

## ✅ Completado (Sprints previos)
- Sprint 36: Fortalecimiento de gobernanza, skill `idea-validator` (T-200), sandbox no-root y auditoría de seguridad (T-199).
