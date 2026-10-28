# Sprint 21 — Arquitectura Multi-Agente, Orquestación y Workflows

## Estado
⚪ Planificado (en proceso de aprobación de planning)

## Tareas
| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :--- | :--: | :--- | :--- |
| T-124 | Persistencia y Handover de Deliberación Multi-Sesión (`deliberation-${TASK_ID}.json`) para evitar fallbacks N/A en cierres | Nueva herramienta / DX | S | ✅ Completada | — | [.agents/tasks/task-124.md](.agents/tasks/_archived/task-124.md) |
| T-125 | Protocolo de Handover y Contratos Inter-Agente en Perfiles Declarativos (Coordinator, Coder, Reviewer, QA-Judge) | Arquitectura / Contratos | S | ⬜ Pendiente | T-124 | [.agents/tasks/task-125.md](.agents/tasks/task-125.md) |
| T-126 | Integración del Bucle de Deliberación en Workflows de Despacho y Orquestación Paralela con Worktrees | Workflow / Orquestación | M | ⬜ Pendiente | T-124, T-125 | [.agents/tasks/task-126.md](.agents/tasks/task-126.md) |
| T-127 | Extensión de la Suite de Validación con Check 35 y Denominador 34→35 para Gobernanza Multi-Agente | DX / Tests | S | ⬜ Pendiente | T-124, T-125, T-126 | [.agents/tasks/task-127.md](.agents/tasks/task-127.md) |

## Notas de planning

- **Origen**: Solicitud de plataforma del operador tras la consolidación del motor de deliberación y digests en el Sprint 20.
- **Dogfooding del bucle de deliberación**: La planificación del Sprint 21 utiliza por primera vez de forma real el bucle deliberativo de Fase 3.4/3.5 desarrollado en el Sprint 20.
- **Modo Piloto Supervisado**: El relay externo (Muse) continúa activo como control de auditoría; el bucle autónomo opera bajo supervisión estricta y con Decision Gates humanos obligatorios.
- **Insumos y Focos Técnicos**:
  1. *Persistencia de la deliberación entre sesiones*: Resolver la pérdida de contexto cuando el cierre de tarea ocurre en una sesión separada (como sucedió en T-123).
  2. *Contratos inter-agente*: Formalizar compuertas y transiciones (Coordinator → Coder → Reviewer → QA-Judge → Merge) en los perfiles declarativos.
  3. *Worktrees efímeros*: Integrar la deliberación en el flujo de trabajo paralelo hermano-fuera-del-árbol (`parallel-orchestration.md`).
- **Exclusiones Explícitas (Fuera de Alcance)**:
  - Ideas del agente de vídeos (diferidas para después del Sprint 21).
  - REA / inspección clean-room de MCPs (evaluación arquitectónica independiente).
  - Rotación de credenciales revocadas de Cloudflare (bloqueadas hasta definición de política de tokens).
  - Promoción a `main` y creación de tags (decisión aparte del operador).
