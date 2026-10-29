# Sprint 22 — Resiliencia de Orquestación Multi-Agente, Puentes de Estado y Flujos Autónomos

## Estado
⚪ Planificado (en proceso de aprobación de planning)

## Tareas
| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :--- | :--: | :--- | :--- |
| T-128 | Puente de Deliberación Worktree → Principal (rescate de `.agents/context/deliberation-${TASK_ID}.json` antes de purga en `worktree-merge.sh`) | Workflow / Orquestación | S | ✅ Completada | — | [.agents/tasks/task-128.md](.agents/tasks/_archived/task-128.md) |
| T-129 | Enforcement Scout y Auditoría de Completitud en Workflow de Planning (`sprint-planning.md` y validación en `design-digest.sh`) | DX / Workflow | S | ✅ Completada | — | [.agents/tasks/task-129.md](.agents/tasks/_archived/task-129.md) |
| T-130 | Cascada de Inferencia y Fallback Resiliente en Routing Policy (`routing-policy.yaml` y `deliberate-plan.sh`) | Nueva herramienta / Core | S | ⬜ Pendiente | — | [.agents/tasks/task-130.md](.agents/tasks/task-130.md) |
| T-131 | Ensayo End-to-End del Bucle Multi-Agente con Check 36 y Denominador 35→36 en `validate-control-plane.sh` | DX / Tests | M | ⬜ Pendiente | T-128, T-129, T-130 | [.agents/tasks/task-131.md](.agents/tasks/task-131.md) |

## Notas de planning

- **Origen**: Solicitud de plataforma del operador para resolver la desconexión de artefactos gitignored entre worktrees efímeros y el checkout principal, robustecer el proceso scout de planning y dotar de tolerancia a fallos escalonada al motor de inferencia.
- **Triaje y Evaluación de Ideas de Vídeos (`docs/external-inbox/`)**:
  - **Aprobada para adopción en Core**: *Cascada de inferencia en routing policy* (T-130) para permitir degradación escalonada entre tiers de modelos antes del fallback offline.
  - **Diferidas / Fuera de alcance**:
    - `idea-validator` y `sprint-planning v2` condicionadas a Bane: quedan en el inbox hasta que Bane sea validado y desplegado formalmente en la infraestructura VPS.
    - `clean-room-contracts`: derivada a la línea arquitectónica independiente de REA (análisis de binarios y servidores MCP).
    - `plantilla Nango opcional`: concierne a integraciones de satélites externos, no al core universal.
    - `frontend-critic`, `web-privacy-noindex`, `natural-communication`, `fact-check`, `self-healing pre-flight`: específicas de frontends satélite, operadas por rules/workflows vigentes o diferidas al backlog.
- **Evaluación de Candidatos de Plataforma**:
  - **T-128 (Puente Worktree → Principal)**: Soluciona la brecha descubierta en Sprint 21 donde la deliberación del worker, al vivir gitignored en `<repo>-<task-id>/`, se pierde al desmontar el worktree con `worktree-merge.sh`, provocando que `close-task.sh` no pueda redactar el digest histórico sin degradar.
  - **T-129 (Enforcement Scout)**: Institucionaliza la lección operativa de Sprint 21 ("sin research no hay plan"), convirtiendo la prospección scout determinista a $0 tokens y la presencia de `docs/sprints/sprint-XX-research.md` en una compuerta obligatoria del workflow y del digest de planning.
  - **T-131 (Ensayo E2E & Check 36)**: Unifica y certifica el ciclo de vida completo (despacho → deliberación aislada → implementación → rescate de deliberación en merge → digest histórico no degradado en cierre → purga de huérfanos con gc).
- **Dogfooding Deliberativo**: El presente plan ha sido sometido a deliberación determinista mediante `deliberate-plan.sh`.
