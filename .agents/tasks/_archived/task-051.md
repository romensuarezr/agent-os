# Task-051: Despliegue de Homepage en Coolify (oracle) y generador dinámico desde config/fleet.yaml

## Objetivo
Desplegar el dashboard de observabilidad e infraestructura Homepage (`ghcr.io/gethomepage/homepage:latest`) en el VPS `oracle` mediante Coolify, e implementar un generador determinista CLI que traduzca el inventario de `config/fleet.yaml` a la configuración declarativa de Homepage (`services.yaml`, `bookmarks.yaml`, `widgets.yaml`, `settings.yaml`), ofreciendo un panel unificado de estado de la flota.

## Contexto técnico
- VPS `oracle` con Coolify v4 y Traefik operativos tras T-035/T-042/T-050 (`https://coolify.romensuarez.com`).
- Coolify MCP (`@masonator/coolify-mcp`) activo para aprovisionamiento automatizado.
- Homepage: Imagen oficial `ghcr.io/gethomepage/homepage:latest`, puerto interno 3000. Configuración puramente declarativa en archivos YAML montados en `/app/config`. No requiere base de datos (0 MB de sobrecoste en motores DB).
- Generador determinista `scripts/agent/generate-homepage-config.sh`: Script en Bash/Python que parsea `config/fleet.yaml` (o digest de `discover-fleet.sh`) y estructura los grupos de servicios (Pasarelas de Inferencia IA, Gestor de Secretos, PaaS, Herramientas de Dev) con iconos, URLs y verificaciones de estado (pings).
- Registro del servicio en `config/fleet.yaml` y plantilla universal en `config/fleet.example.yaml`.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `docs/sprints/sprint-08-core.md`
- `.agents/tasks/task-051.md`
- `scripts/agent/generate-homepage-config.sh`
- `templates/homepage/docker-compose.yml`
- `templates/homepage/config/settings.yaml`
- `templates/homepage/config/widgets.yaml`
- `config/fleet.yaml`
- `config/fleet.example.yaml`

## Criterios de done
- [x] Script CLI determinista `scripts/agent/generate-homepage-config.sh` creado para mapear `config/fleet.yaml` a los servicios de Homepage.
- [x] Plantilla declarativa `templates/homepage/docker-compose.yml` y configs base creadas.
- [x] Aplicación Homepage creada y desplegada en Coolify (`oracle`) en el proyecto `Agencia IA` (entorno `production`).
- [x] Verificación de liveness HTTP y renderizado del dashboard de flota en el navegador.
- [x] Registro del servicio en `config/fleet.yaml` y plantilla universal en `config/fleet.example.yaml`.
- [x] Suite de pruebas `tests/validate-control-plane.sh` pasando con 0 errores (respetando 100% agnosticism).

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-26T21:17:25+01:00
- [x] Rama creada: feat/T-051-deploy-homepage-fleet-dashboard
- [x] Lock activo: .agent-session.lock
- [ ] Sesión cerrada correctamente
