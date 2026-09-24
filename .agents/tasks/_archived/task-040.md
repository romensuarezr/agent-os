# Task-040: Inventario Activo de Herramientas de la Flota (tool-inventory) y registro de capacidades

## Objetivo
Crear el Inventario Activo de Herramientas de la Flota (`docs/architecture/tool-inventory.md`) estructurado en 4 capas operativas (Local/Consola, VPS/Agentes Persistentes con MCPs, Infraestructura Coolify/Traefik, y Web AI/Cloud Tiers) y formalizar la nueva skill `.agents/skills/tool-inventory/SKILL.md` para que cualquier agente consulte y aproveche las herramientas existentes antes de proponer soluciones redundantes o de pago.

## Contexto técnico
- Basado en la idea capturada en `docs/idea-inbox/2026-09-24-tool-inventory-and-prospector.md`.
- El ecosistema cuenta con múltiples herramientas y agentes distribuidos que no estaban unificados en un catálogo consultable:
  - **Local (`inteligencia-colectiva`)**: Antigravity CLI, Orca Desktop (`audit-orca.sh`), OpenCode CLI (v1.3.9 con FreeLLMAPI y modelo promo `space-bunny-free` de 1M contexto), scripts deterministas (`scout.sh`, `audit-host.sh`, `check-git-remote.sh`).
  - **VPS `datamanager`**: Hermes Agent 24/7 (con MCP Coolify preinstalado), FreeLLMAPI (:3001 en Tailscale con clave unificada y modelos locales Qwen 2.5 7B, Llama 3.1 8B, Qwen 2.5 3B), Ollama local, Qdrant vector DB.
  - **VPS `oracle`**: Coolify (~25 contenedores gestionados), Traefik reverse proxy, PostgreSQL, Redis.
  - **Web AI y Cloud Tiers**: Google AI Studio (Gemini 2.5 Pro / Flash con contexto de 2M tokens y claves en free tier), Gemini Web, Perplexity Pro (búsqueda técnica y scraping en profundidad), Claude/ChatGPT web, OpenRouter.
- La skill `tool-inventory` permitirá a cualquier agente consultar este catálogo estructurado y seleccionar la herramienta óptima según coste, privacidad y latencia.

## Caja de archivos
Archivos autorizados para modificación:
- `docs/sprints/sprint-07-core.md`
- `.agents/tasks/task-040.md`
- `docs/architecture/tool-inventory.md`
- `.agents/skills/tool-inventory/SKILL.md`
- `.agents/skills/tool-inventory/references/local-environment.md`
- `.agents/skills/tool-inventory/references/persistent-agents-vps.md`
- `.agents/skills/tool-inventory/references/saas-infrastructure-vps.md`
- `.agents/skills/tool-inventory/references/cloud-and-web-ai.md`
- `docs/idea-inbox/_archived/2026-09-24-tool-inventory-and-prospector.md`

## Criterios de done
- [x] Creación de `docs/architecture/tool-inventory.md` como Hub/Router central y documentos satélites especializados en `docs/architecture/tools/` para cada una de las 4 capas.
- [x] Creación de la skill `.agents/skills/tool-inventory/SKILL.md` con su frontmatter estándar, mapa de capacidades, protocolo de consulta previa y reglas de delegación.
- [x] Archivado de `2026-09-24-tool-inventory-and-prospector.md` en `docs/idea-inbox/_archived/` reflejando el Componente A completado y enlazando el Hub.
- [x] Verificación y actualización de estado en `docs/sprints/sprint-07-core.md`.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-24 23:25:42
- [x] Rama creada: feat/T-040-fleet-tool-inventory
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
