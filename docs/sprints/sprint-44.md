# Sprint 44 — 2026-11-23 → 2026-11-27

## Estado
🟡 En curso

## Tareas
| ID | Descripción | Tamaño | Estado | Dependencias | Task file |
|---|---|:---:|:---:|:---:|:---:|
| T-233 | Homologación y Actualización Integral del Stack de Flota (OpenCode, Hermes, Infisical, Orca) | S | ✅ Hecho | — | [.agents/tasks/task-233.md](file:///.agents/tasks/task-233.md) |
| T-234 | Actualización de la Skill `orca-cli` a v1.4.268 (Bots Hermes/OpenCode, Multimodalidad y Browser Remoto) | S | ⬜ Pendiente | T-233 | [.agents/tasks/task-234.md](file:///.agents/tasks/task-234.md) |
| T-235 | Puente Declarativo: `.agents/profiles/` a Orca Bot Identities y Standing Instructions | M | ⬜ Pendiente | T-234 | [.agents/tasks/task-235.md](file:///.agents/tasks/task-235.md) |
| T-236 | Optimización Reactiva de Coordinación en `orca-reactive-wait.sh` (Despertar Nativo sin Polling) | S | ⬜ Pendiente | T-234 | [.agents/tasks/task-236.md](file:///.agents/tasks/task-236.md) |
| T-237 | Validación Integral del Control Plane, Sincronización de Flota y Cierre de Sprint 44 | S | ⬜ Pendiente | T-233, T-234, T-235, T-236 | [.agents/tasks/task-237.md](file:///.agents/tasks/task-237.md) |

## Régimen Operativo del Sprint
> Sellado en arranque tras confirmación explícita del operador: A, aprobado (Régimen Desatendido).
- **Régimen**: Desatendida
- **Orden de Carriles (DAG de dependencias)**:
  - Carril 1 (Stack de Flota, Skill & Gobernanza de Bots): [T-233 → T-234 → T-235]
  - Carril 2 (Reactividad de Orquestación): [T-236]
  - Carril 3 (Validación Integral y Cierre de Flota): [T-237]
- **Sellado en**: 2026-11-21 (Arranque de Sprint 44)

## Notas de planning
- Sprint enfocado en la absorción y gobernanza nativa de **Orca v1.4.268** y la actualización integral de las herramientas de la flota detectadas por la sonda determinista (`check-tooling-updates.sh`).
- T-233 homologa y documenta las versiones upstream de OpenCode v2.3.2, Hermes v0.23.3, Infisical v0.45.14 y Orca v1.4.268 antes de las tareas de gobernanza profunda.
- T-234 evoluciona la skill `.agents/skills/orca-cli/SKILL.md` dotando a los agentes del core y satélites de instrucciones claras para interactuar con bots, adjuntar imágenes a comentarios de worktrees y realizar anotaciones sobre webs remotas de Coolify.
- T-235 crea el puente declarativo entre los perfiles `.agents/profiles/` y las *standing instructions* / tarjetas de identidad consumidas orgánicamente por OpenCode y Hermes en Orca ADE.
- T-236 adapta `scripts/agent/lib/orca-reactive-wait.sh` para capitalizar el despertar automático nativo que Orca 1.4.268 emite cuando un worker finaliza su reporte, acelerando la deliberación sin consumo de tokens ni ciclos muertos.
- T-237 valida que la suite `tests/validate-control-plane.sh` se mantenga en 16/16 verde y prepara los manifiestos de sincronización con proyectos satélite (`sync.sh`).
