# Sprint 42 — 2026-11-17 → 2026-11-21

## Estado
🟡 En curso

## Tareas
| ID | Descripción | Tamaño | Estado | Dependencias | Task file |
|---|---|:---:|:---:|:---:|:---:|
| T-224 | Script Determinista de Sincronización del Core y Regeneración Atómica de Symlinks de Skills en VPS | S | ⬜ Pendiente | — | [.agents/tasks/task-224.md](file:///.agents/tasks/task-224.md) |
| T-225 | Integración del Cronjob `no_agent: true` de Auto-Sincronización en Hermes y Telemetría Matutina | S | ⬜ Pendiente | T-224 | [.agents/tasks/task-225.md](file:///.agents/tasks/task-225.md) |
| T-226 | Despliegue del Contrato Operativo `AGENTS.md` de Conserje en el Home de Hermes (`/home/ubuntu/AGENTS.md`) | S | ⬜ Pendiente | — | [.agents/tasks/task-226.md](file:///.agents/tasks/task-226.md) |
| T-227 | Actualización del Runbook Operativo de Hermes VPS (`/reload-skills`, auto-sync y manual de conserjería) | S | ⬜ Pendiente | T-224, T-225, T-226 | [.agents/tasks/task-227.md](file:///.agents/tasks/task-227.md) |

## Régimen Operativo del Sprint
> Se sella en la primera sesión de /session-start tras consulta proactiva única al operador.
- **Régimen**: [PENDIENTE_ARRANQUE — Desatendida | Tarea a tarea (Clásico)]
- **Orden de Carriles (DAG de dependencias)**:
  - Carril 1 (Automatización y Sincronización del Core): [T-224 → T-225]
  - Carril 2 (Gobernanza y Contratos de Hermes Conserje): [T-226]
  - Carril 3 (Documentación y Cierre de Runbook): [T-227]
- **Sellado en**: [PENDIENTE]

## Notas de planning
- Sprint 41 cerrado con éxito, release `v1.37.0` publicada y validada con 38/38 checks verdes.
- T-224 resuelve la actualización determinista del repositorio `/home/ubuntu/projects/agent-os` en `<nodo-inferencia>` y la regeneración atómica de symlinks para skills nuevas (ej. `orca-cli`).
- T-225 aprovecha la capacidad nativa de cronjobs `no_agent: true` de Hermes descubierta en la investigación técnica, ejecutando la sincronización periódicamente y reportando nuevas versiones en el briefing matutino de WhatsApp a $0 tokens.
- T-226 implementa la mejor práctica de Nous Research separando la identidad (`SOUL.md`) de las instrucciones operativas de conserje (`AGENTS.md` en `/home/ubuntu`).
- T-227 formaliza el uso del comando `/reload-skills` en el runbook operativo y documenta el ciclo de vida proactivo.
