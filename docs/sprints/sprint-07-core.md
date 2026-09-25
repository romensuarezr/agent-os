# Sprint 07 — Core

**Período**: 2026-09-24 → 2026-09-30  
**Objetivo**: Fase 2 del Control Plane: Conexión y Validación de Agentes. Configurar y validar localmente OpenCode contra FreeLLMAPI garantizando coste $0; crear el Inventario Activo de Herramientas de la flota; y diseñar la integración Human-in-the-Loop (HITL) de Hermes Agent hacia la cola de Orca en estado `pending_approval`.

---

## Estado
🟡 En curso

---

## Tareas del Sprint (Fase 2)

| ID | Descripción | Tamaño | Estado | Dependencias / Bloqueos | Task file |
| :--- | :--- | :---: | :---: | :--- | :---: |
| T-039 | Validación y configuración local de OpenCode con FreeLLMAPI ($0 inferencia) | M | ✅ Completada | FreeLLMAPI en `datamanager` activo vía Tailscale | [.agents/tasks/task-039.md](file:///home/romen/Proyectos/agent-os/.agents/tasks/task-039.md) |
| T-040 | Inventario Activo de Herramientas de la Flota (`tool-inventory`) y registro de capacidades | S | ✅ Completada | T-035, T-037 | [.agents/tasks/task-040.md](file:///home/romen/Proyectos/agent-os/.agents/tasks/task-040.md) |
| T-044 | Universalización agnóstica de `tool-inventory` y desacople de flota en `config/fleet.yaml` | S | ✅ Completada | T-040 | [.agents/tasks/task-044.md](file:///home/romen/Proyectos/agent-os/.agents/tasks/task-044.md) |
| T-045 | Salvaguarda de prospección determinista en `sprint-planning.md` y `tool-decision-flow.md` | S | ✅ Completada | T-038 | [.agents/tasks/task-045.md](file:///home/romen/Proyectos/agent-os/.agents/tasks/task-045.md) |
| T-046 | Script CLI determinista `discover-fleet.sh` para auto-descubrimiento y generación de `fleet.yaml` | M | ✅ Completada | T-044 | [.agents/tasks/task-046.md](file:///home/romen/Proyectos/agent-os/.agents/tasks/task-046.md) |
| T-041 | Orquestación Multi-Agente en Orca ADE: Coordinador, despacho paralelo y enrutamiento de LLMs | M | ✅ Completada | T-037, T-040, T-046 | [.agents/tasks/_archived/task-041.md](file:///home/romen/Proyectos/agent-os/.agents/tasks/_archived/task-041.md) |

---

## Backlog Priorizado (Bloqueado — Fase 2B / Sprint 08)

### T-042: Despliegue de Infisical Community Edition y Skill de Inyección de Secretos
- **Estado**: ⏸ Bloqueada en Backlog
- **Dependencias**: Docker y Coolify en `oracle` (T-035 auditado).
- **Riesgos**: Consumo de RAM en VPS; exposición accidental de variables en repositorios o logs.
- **Criterio de aceptación**: Docker-compose ligero (<500MB RAM) desplegado tras Traefik en `oracle`; skill o runbook para inyección en memoria (`infisical run`) con Universal Auth.
- **Rollback**: `docker compose down -v` en el stack de Infisical en Coolify.

### T-043: Prospección Periódica de Herramientas Freemium / OSS
- **Estado**: ⏸ Bloqueada en Backlog
- **Dependencias**: T-038 (`scout.sh`), T-040 (`tool-inventory`).
- **Riesgos**: Ruido de resultados irrelevantes; desgaste de cuotas gratuitas de APIs.
- **Criterio de aceptación**: Script programable o workflow que ejecute búsquedas específicas en repositorios y registre herramientas candidatas en el inventario.

### T-047: Integración Hermes Agent → Cola de tareas Orca en estado `pending_approval`
- **Estado**: ⏸ Bloqueada en Backlog (Reubicada desde T-041 para priorizar orquestación nativa en Orca ADE)
- **Dependencias**: T-041 (Orquestación en Orca), T-037.
- **Riesgos**: Exposición a prompt injection desde canales externos (WhatsApp).
- **Criterio de aceptación**: Script de encolado seguro para mensajes externos de Hermes Agent registrando compuertas de decisión en Orca Desktop.

---

## Criterio de Éxito del Sprint 07

1. OpenCode CLI validado operando localmente contra FreeLLMAPI en nodo de inferencia privado (`routing.default_local_llm_endpoint`), generando cambios y ejecutando tool-calling de forma aislada en carpeta de pruebas sin consumir saldo cloud ($0).
2. Registro centralizado y estructurado (`docs/architecture/tool-inventory.md`) de herramientas de la flota (locales, servidores, web LLMs, agentes).
3. Orquestación multi-agente en Orca ADE demostrada con éxito: Coordinador troceando una tarea y despachando múltiples agentes concurrentes en worktrees aislados con selección de LLM apropiada.
