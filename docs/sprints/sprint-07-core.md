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
| T-040 | Inventario Activo de Herramientas de la Flota (`tool-inventory`) y registro de capacidades | S | ⬜ Pendiente | T-035, T-037 | [.agents/tasks/task-040.md](file:///home/romen/Proyectos/agent-os/.agents/tasks/task-040.md) |
| T-041 | Integración Hermes Agent → Cola de tareas Orca en estado `pending_approval` | M | ⬜ Pendiente | T-037, T-039 | [.agents/tasks/task-041.md](file:///home/romen/Proyectos/agent-os/.agents/tasks/task-041.md) |

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

---

## Criterio de Éxito del Sprint 07

1. OpenCode CLI validado operando localmente contra FreeLLMAPI (`http://100.77.82.13:3001/v1`), generando cambios y ejecutando tool-calling de forma aislada en carpeta de pruebas sin consumir saldo cloud ($0).
2. Registro centralizado y estructurado (`docs/architecture/tool-inventory.md`) de herramientas de la flota (locales, servidores, web LLMs, agentes).
3. Pipeline HITL documentado e integrado para que Hermes Agent reciba solicitudes por WhatsApp y las encole de forma segura con token efímero y estado `pending_approval` en Orca.
