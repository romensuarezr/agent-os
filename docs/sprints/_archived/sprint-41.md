# Sprint 41 — 2026-11-17 → 2026-11-21

## Estado
🟡 En curso

## Tareas
| ID | Descripción | Tamaño | Estado | Dependencias | Task file |
|---|---|:---:|:---:|:---:|:---:|
| T-219 | Integración Automática de Reporte de Orquestación en `close-sprint.sh` y `session-close.md` | S | ✅ Hecho | — | [.agents/tasks/task-219.md](file:///.agents/tasks/task-219.md) |
| T-220 | Absorción de `orca-cli` (v1.4.258), actualización de `infisical-secrets` (v0.45.8) y fix de staging acotado en `contribute.sh` | S | ✅ Hecho | — | [.agents/tasks/task-220.md](file:///.agents/tasks/task-220.md) |
| T-221 | Auditoría Bidireccional de Drift Core ↔ Satélites (`audit-satellites.sh --skills`) | M | ✅ Hecho | — | [.agents/tasks/task-221.md](file:///.agents/tasks/task-221.md) |
| T-222 | Sincronización y Propagación de Herramientas Ops (`scripts/ops/coolify.sh`) en `sync.sh` | S | ✅ Hecho | — | [.agents/tasks/task-222.md](file:///.agents/tasks/task-222.md) |
| T-223 | Universalización y Recipe Determinista de Despliegue Coolify para Next.js (soporte monorepo + flat) | M | ✅ Hecho | T-222 | [.agents/tasks/task-223.md](file:///.agents/tasks/task-223.md) |

## Régimen Operativo del Sprint
> Sellado formalmente tras aprobación macro del operador (2026-11-14).
- **Régimen**: Desatendida
- **Orden de Carriles (DAG de dependencias)**:
  - Carril 1 (Gobernanza y Cierre): [T-219 → T-220]
  - Carril 2 (Sincronización Bidireccional de Flota): [T-221 → T-222]
  - Carril 3 (Universalización de Despliegues): [T-223]
- **Sellado en**: 2026-11-14 (Aprobación Macro por Humano/Operador)

## Notas de planning
- Sprint 40 cerrado cleanly y tag `v1.36.0` publicado con 38/38 checks de control plane verdes.
- T-219 resuelve la visibilidad obligatoria del informe de orquestación (playbooks, floor cost savings de tokens y workers ejecutados) en el cierre de sprint y workflows de sesión.
- T-220 homologa en el Core las mejoras desarrolladas en el satélite `romensuarez-web` (`orca-cli` v1.4.258 y `infisical-secrets` v0.45.8), y corrige la vulnerabilidad de higiene en `contribute.sh` línea 73 (`git add .` indiscriminado reemplazado por staging estrictamente acotado).
- T-221 proporciona la herramienta para evitar desincronizaciones silenciosas: `audit-satellites.sh --skills` comparará las skills del core con los satélites y avisará de desvíos o skills huérfanas.
- T-222 propaga `scripts/ops/` (incluyendo `coolify.sh`) a los proyectos satélite a través de `sync.sh`, cerrando la brecha detectada en la auditoría de `leaderboard-platform`.
- T-223 universaliza `.agents/skills/coolify-nextjs-deploy/` con una recipe determinista completa que soporte tanto despliegues de Next.js plano (ej. `annascheer-web`) como monorepos pnpm (ej. `leaderboard-platform`), con plantillas multi-stage standalone y runbook paso a paso.
