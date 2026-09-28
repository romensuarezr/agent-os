# Task-063: Productividad DX, Búsqueda SearXNG y Widget GitHub en Homepage

## Objetivo
Integrar las herramientas de productividad para el desarrollador y el agente en Homepage. Configurar la barra de búsqueda en la cabecera (`templates/homepage/config/widgets.yaml`) con proveedor DuckDuckGo (`target: _blank`), e incorporar en `templates/homepage/config/services.yaml` el widget oficial de GitHub para el repositorio `romensuarezr/agent-os` junto a la tarjeta de acceso rápido de ByteBox. Registrar la auditoría de estado de SearXNG.

## Contexto técnico
- **Buscador en Cabecera (`widgets.yaml`)**: Se configura el widget de búsqueda integrado de Homepage con proveedor `duckduckgo` y apertura en nueva pestaña (`target: _blank`).
- **Estado de SearXNG (`192.0.2.10:8080`)**:
  - *Comprobación*: `curl -s --connect-timeout 3 -m 4 http://192.0.2.10:8080` → `SEARXNG_OFFLINE`.
  - *Diagnóstico*: La instancia autoalojada en `datamanager` permanece deliberadamente en reposo para ahorrar recursos, dado que la prospección técnica avanzada se resuelve prioritariamente vía motores de investigación profunda (Perplexity AI y Google AI Studio / Gemini). No se enlaza como servicio activo para evitar alertas de conexión en el dashboard.
- **Widget Oficial de GitHub (`services.yaml`)**: Vinculado al repositorio central `romensuarezr/agent-os` mediante `widget: { type: "github", repo: "romensuarezr/agent-os" }`, reportando commits, ramas y estrellas.
- **Acceso Rápido a ByteBox**: Acceso directo para el gestor de comandos CLI y snippets con endpoint de salud `/api/cards`.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `templates/homepage/config/widgets.yaml`
- `templates/homepage/config/settings.yaml`
- `templates/homepage/config/services.yaml`
- `.agents/tasks/task-063.md`
- `docs/sprints/sprint-10-core.md`

## Criterios de done
- [x] Configurado el bloque `search` en `templates/homepage/config/widgets.yaml` con proveedor `duckduckgo` y `target: _blank`.
- [x] Incorporado en `templates/homepage/config/services.yaml` el widget oficial `type: github` para el repositorio `romensuarezr/agent-os`.
- [x] Configurada la tarjeta de ByteBox con icono `si-gnubash` y verificación `/api/cards` (SearXNG en reposo documentado).
- [x] Estado de conectividad de SearXNG verificado deterministamente (`SEARXNG_OFFLINE`).
- [x] Validación sintáctica estricta de YAML aprobada.
- [x] `tests/validate-control-plane.sh` pasa 10/10 checks.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-27T15:24:12+01:00
- [x] Rama creada: feat/T-063-dx-searxng-github-widgets
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
