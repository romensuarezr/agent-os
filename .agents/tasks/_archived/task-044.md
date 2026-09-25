# Task-044: Universalización agnóstica de tool-inventory y desacople de flota en config/fleet.yaml

## Objetivo
Desacoplar la infraestructura privada del usuario del núcleo de `agent-os`, transformando el catálogo de herramientas en un esquema modular y agnóstico. Publicar `config/fleet.example.yaml` (compatible con el estándar MCP y fallbacks declarativos), ignorar `config/fleet.yaml` en git para preservar la flota privada de forma local, anonimizar la arquitectura pedagógica y refactorizar `.agents/skills/tool-inventory/` para lectura dinámica sin hardcodear IPs o credenciales privadas en el repositorio.

## Contexto técnico
En T-040 se creó el inventario de herramientas de la flota. Sin embargo, se incluyeron hosts, dominios personales e IPs privadas de los servidores directamente en archivos versionados (`docs/architecture/tool-inventory.md` y `.agents/skills/tool-inventory/references/*.md`). Esto impide que el repositorio sea compartido con colaboradores o publicado en OSS sin filtrar topología privada o romper la portabilidad en equipos ajenos.
Siguiendo las conclusiones del scouting OSS (`modelcontextprotocol/registry` y `musistudio/claude-code-router`), se adopta la especificación declarativa estándar `mcpServers` y fallbacks en `config/fleet.example.yaml`.

## Caja de archivos
Archivos autorizados para modificación:
- `docs/sprints/sprint-07-core.md`
- `.agents/tasks/task-044.md`
- `.gitignore`
- `templates/.gitignore-agent-os`
- `CONTRIBUTING.md`
- `config/fleet.example.yaml`
- `config/fleet.yaml`
- `.agents/skills/tool-inventory/SKILL.md`
- `docs/architecture/tool-inventory.md`
- `docs/architecture/tools/cloud-and-web-ai.md`
- `docs/architecture/tools/local-environment.md`
- `docs/architecture/tools/persistent-agents-vps.md`
- `docs/architecture/tools/saas-infrastructure-vps.md`

## Criterios de done
- [x] `config/fleet.yaml` añadido a `.gitignore` para blindar cualquier infraestructura privada local.
- [x] `config/fleet.example.yaml` creado en el repositorio como plantilla declarativa limpia, documentando capas: Local, VPS Workers/Nodes, Web/Cloud AI y servidores MCP (`mcpServers`).
- [x] Archivo privado `config/fleet.yaml` preservado en el entorno local con la topología real de Romen (Tailscale IPs, servicios activos de `datamanager` y `oracle`), preparado para ser enriquecido por `discover-fleet.sh` (T-046).
- [x] Guía estándar de contribución `CONTRIBUTING.md` creada en la raíz siguiendo estándares OSS (convenciones de commits, ramas, flujo de agentes, `contribute.sh`, PRs y directrices agnósticas).
- [x] `docs/architecture/tool-inventory.md` anonimizado con nombres genéricos (`worker-node-01`, `saas-node-02`, `100.x.y.z`, `example.com`), explicando la lectura desacoplada de `config/fleet.yaml`.
- [x] Documentos de referencia movidos a `docs/architecture/tools/*.md` para servir como guías pedagógicas universales legibles por humanos sin contaminar la skill portable.
- [x] `.agents/skills/tool-inventory/SKILL.md` refactorizado para ser 100% portable (sin carpeta `references/`), priorizando la consulta dinámica de `config/fleet.yaml`.
- [x] `templates/.gitignore-agent-os` actualizado para que proyectos hijos ignoren automáticamente `config/fleet.yaml` y `docs/architecture/tools/*.local.md`.
- [x] `tests/validate-control-plane.sh` y verificación de working tree limpios sin filtraciones de datos privados en el diff de git.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-25T10:04:46+01:00
- [x] Rama creada: feat/T-044-agnostic-fleet-decoupling
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
