# Task-027: Desplegar FreeLLMAPI en el VPS datamanager vía Docker Compose

## Objetivo
Desplegar la plataforma FreeLLMAPI en el VPS `datamanager` mediante Docker Compose con persistencia de datos (SQLite), clave de cifrado generada y exposición restringida a la red privada de Tailscale en el puerto 3001, dejando preparado el enlace de red hacia Ollama.

## Contexto técnico
- Servidor destino: VPS `datamanager` (alias SSH `datamanager`, IP Tailscale `100.77.82.13`).
- Imagen: `ghcr.io/tashfeenahmed/freellmapi:latest`.
- Clave de cifrado obligatoria: `ENCRYPTION_KEY="$(openssl rand -hex 32)"`.
- Persistencia: volumen Docker `freellmapi-data` montado en `/app/server/data`.
- Restricción de red: bind exclusivo en `100.77.82.13:3001:3001` para evitar exposición en la IP pública.
- Conectividad con host: `extra_hosts: ["host.docker.internal:host-gateway"]` para acceso futuro a Ollama (`11434`).
- Ruta en el servidor: `/home/ubuntu/freellmapi/`.

## Caja de archivos
Archivos autorizados para modificación:
- `templates/freellmapi/docker-compose.yml`
- `templates/freellmapi/.env.example`
- `docs/sprints/sprint-04-core.md`

## Criterios de done
- [x] Plantillas versionadas `templates/freellmapi/docker-compose.yml` y `templates/freellmapi/.env.example` creadas en el repositorio core.
- [x] Directorio `/home/ubuntu/freellmapi/` creado en el VPS `datamanager`.
- [x] Configuración `.env` y `docker-compose.yml` desplegada en el VPS con `ENCRYPTION_KEY` segura y bind en Tailscale.
- [x] Contenedor FreeLLMAPI en ejecución (`docker compose up -d`) y verificado mediante `remote-admin`.
- [x] Validación de respuesta HTTP en `http://100.77.82.13:3001`.
- [x] Tarea T-027 marcada en `docs/sprints/sprint-04-core.md`.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-19T14:58:34+01:00
- [x] Rama creada: feat/T-027-deploy-freellmapi-datamanager
- [x] Lock activo: 2026-09-19T14:58:40+01:00
- [x] Sesión cerrada correctamente
