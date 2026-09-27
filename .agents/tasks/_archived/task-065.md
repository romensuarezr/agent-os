# Task-065: Runbook de Despliegue en Coolify con Docker Compose y MCP Tooling

## Objetivo
Elaborar el procedimiento operativo estándar (SOP) y runbook técnico para desplegar y migrar la instancia activa de Homepage en Coolify (`oracle`) desde un contenedor Docker simple a un stack desacoplado Docker Compose junto a `tecnativa/docker-socket-proxy` con perfil RO y límite de 32MB de RAM (ADR 004), mapeo persistente de configuraciones generadas, automatización vía Coolify MCP Server y verificaciones post-despliegue deterministas con `curl`.

## Contexto técnico
- **Gobernanza de Recursos en `oracle` (ADR 004)**: El VPS `oracle` tiene restricciones de disco y recursos. El stack Compose debe usar `tecnativa/docker-socket-proxy` limitado a `mem_limit: 32m` con variables RO estrictas (`CONTAINERS=1`, `INFO=1`, `POST=0`) para eliminar el montaje peligroso de `/var/run/docker.sock` en el contenedor web.
- **Estructura Compose Desacoplada**: El servicio `homepage` y `docker-socket-proxy` coexisten en una red interna (`homepage-network`), permitiendo a Homepage consultar el proxy en `tcp://docker-socket-proxy:2375`.
- **Mapeo de Volúmenes**: Montaje de archivos locales generados en el host/Coolify (`services.yaml`, `widgets.yaml`, `settings.yaml`, `bookmarks.yaml`, `custom.css`) en `/app/config`.
- **Orquestación con Coolify MCP Server**: Documentación de la integración mediante las tools del servidor MCP de Coolify para actualizar la configuración de Compose y disparar redeploys automáticos sin requerir interacción manual con la GUI.
- **Verificación Determinista**: Comprobaciones con `curl -fsSL -I https://homepage.romensuarez.com` para verificar HTTP 200, cabeceras de proxy y salud de la aplicación.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `docs/runbooks/coolify-homepage-deployment.md`
- `.agents/tasks/task-065.md`
- `docs/sprints/sprint-10-core.md`
- `roadmap.md`

## Criterios de done
- [x] `docs/runbooks/coolify-homepage-deployment.md` creado con procedimiento paso a paso de migración en Coolify (`oracle`) a Docker Compose.
- [x] Definición del compose stack documentada con `tecnativa/docker-socket-proxy` (RO, `mem_limit: 32m`) y `ghcr.io/gethomepage/homepage:latest`.
- [x] Mapeo de volúmenes persistentes para configuraciones (`services.yaml`, `widgets.yaml`, etc.) detallado.
- [x] Guía de automatización con Coolify MCP Server documentada con ejemplos de payload y comandos de despliegue.
- [x] Comprobaciones deterministas con `curl` hacia `https://homepage.romensuarez.com` y verificación de headers HTTP documentadas.
- [x] `tests/validate-control-plane.sh` ejecutado con 100% de checks aprobados.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-27T15:57:27+01:00
- [x] Rama creada: feat/T-065-coolify-compose-deployment
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
