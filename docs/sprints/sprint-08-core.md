# Sprint 08 — Core

**Período**: 2026-09-25 → 2026-10-02  
**Objetivo**: Fase 2B del Control Plane: Pasarelas de Inferencia $0, Gestión Centralizada de Secretos e Ingesta Remota HITL hacia Orca. Desplegar OmniRoute en `datamanager` con compresión RTK para OpenCode; desplegar Infisical CE en Coolify (`oracle`) para inyección de secretos en memoria; integrar Hermes Agent hacia las compuertas de Orca ADE (`pending_approval`); y programar la prospección periódica OSS.

---

## Estado
🟡 En curso

---

## Tareas del Sprint (Fase 2B)

| ID | Descripción | Tamaño | Estado | Dependencias / Bloqueos | Task file |
| :--- | :--- | :---: | :---: | :--- | :---: |
| T-048 | Despliegue de OmniRoute en `datamanager` ($0 inferencia) y plugin `opencode-omniroute-auth` | M | ⬜ Pendiente | FreeLLMAPI en `datamanager`, T-039 | [.agents/tasks/task-048.md](file:///home/romen/Proyectos/agent-os/.agents/tasks/task-048.md) |
| T-042 | Despliegue de Infisical Community Edition en Coolify (`oracle`) y skill de inyección de secretos | M | ⬜ Pendiente | Coolify y Docker en `oracle` (T-035 auditado) | [.agents/tasks/task-042.md](file:///home/romen/Proyectos/agent-os/.agents/tasks/task-042.md) |
| T-047 | Integración Hermes Agent → Compuertas de decisión Orca en estado `pending_approval` | M | ⬜ Pendiente | T-041 (`orca-orchestrate.sh`), T-037 | [.agents/tasks/task-047.md](file:///home/romen/Proyectos/agent-os/.agents/tasks/task-047.md) |
| T-043 | Prospección periódica automatizada de herramientas Freemium / OSS para `tool-inventory` | S | ⬜ Pendiente | T-038 (`scout.sh`), T-040 | [.agents/tasks/task-043.md](file:///home/romen/Proyectos/agent-os/.agents/tasks/task-043.md) |

---

## Lotes Sugeridos de Ejecución (Opcional / DAG)

- **Lote 1 (Concurrente sugerido — Nodos de cómputo independientes)**:
  - `T-048` (Inferencia en VPS `datamanager` vía Tailscale)
  - `T-042` (Gestor de secretos en VPS `oracle` tras Traefik/Coolify)  
  *No comparten archivos de código ni servidores. Aptas para ejecución paralela en Orca ADE.*
- **Lote 2 (Secuencial / Concurrente posterior)**:
  - `T-047` (Ingesta remota Hermes hacia compuertas de Orca Desktop)
  - `T-043` (Automatización de prospección determinista OSS)

---

## Criterio de Éxito del Sprint 08

1. OmniRoute desplegado en contenedor Docker en `datamanager` (puerto 3002) detrás de Tailscale, respondiendo con $0 de coste a peticiones OpenAI y conectado al cliente local de OpenCode mediante el plugin `opencode-omniroute-auth` con compresión RTK.
2. Infisical Community Edition levantado en `oracle` en modo lite (<500MB RAM), permitiendo inyección de variables en memoria (`infisical run`) sin filtrar secretos en repositorios.
3. Conector de Hermes Agent despachando eventos a Orca ADE registrando compuertas de decisión humanas en estado `pending_approval`.
4. Script programable o workflow ejecutando prospecciones periódicas de librerías OSS y registrando automáticamente candidatos en `config/fleet.yaml` e inboxes.
