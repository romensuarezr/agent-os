# Sprint 04 — Core

**Período**: 2026-09-19 → 2026-09-25  
**Objetivo**: Integrar FreeLLMAPI en el VPS `datamanager` como backend centralizado de inferencia gratuita para el ecosistema, y universalizar la skill `remote-admin` en el core para que esté disponible en todos los repositorios hijos.

---

## Tareas

- [x] T-026: Universalizar y promover la skill `remote-admin` al core (soporte multi-host SSH: `datamanager`, `oracle`, etc.) — Universalización
- [x] T-027: Desplegar FreeLLMAPI en el VPS `datamanager` vía Docker Compose — Infraestructura / Integración
- [ ] T-028: Configurar proveedores gratuitos y backend local Ollama en FreeLLMAPI — Integración / DX
- [ ] T-029: Validación E2E del endpoint OpenAI `/v1` y redacción de `docs/freellmapi-vps-runbook.md` — Documentación

## Criterio de éxito

1. La skill `remote-admin` vive en el core (`.agents/skills/remote-admin`), está registrada en `skills-inventory.md` y lista para distribuirse a cualquier repositorio hijo vía `sync.sh`.
2. FreeLLMAPI está corriendo en `datamanager` vía Docker Compose, vinculado de forma segura a Tailscale (puerto 3001) y enrutando inferencias hacia proveedores gratuitos y Ollama local.
3. El runbook operativo `docs/freellmapi-vps-runbook.md` documenta la topología, verificación de servicios y ejemplos de uso con `curl`.

## Notas

- T-026 promueve la experiencia previa de `polymarket` y `Agencia_IA`, unificando la administración remota en una única skill universal en lugar de fragmentarla por servidor.
- La numeración de tareas continúa de forma correlativa tras el cierre del Sprint 03 (`T-023` a `T-025`).
