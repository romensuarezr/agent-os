# Research Sprint 04 — Core

> Fuente: Investigación interna y validación directa sobre entorno y repositorios  
> Fecha: 2026-09-19  
> Tarea principal: T-026 (Universalización de remote-admin) y T-027 (Despliegue FreeLLMAPI en datamanager)

## Hallazgos clave

### 1. Skill `remote-admin`
- En los repositorios `polymarket` y `Agencia_IA`, `remote-admin` estaba fuertemente acoplada a Oracle (`ssh oracle`, IP `158.179.213.240`).
- En `agent-os` core, debe ser agnóstica: invocar `ssh <alias> <comando>` donde `<alias>` se resuelve directamente en `~/.ssh/config`.
- Debe añadirse a `scripts/agent/assets-manifest.txt` bajo `[active]` para que `sync.sh` la replique a los proyectos hijos.
- Debe incluir buenas prácticas de seguridad: sólo lectura por defecto, confirmación previa para escrituras o reinicios de contenedores (`docker restart`), y timeouts.

### 2. Despliegue de FreeLLMAPI en `datamanager`
- **Imagen**: `ghcr.io/tashfeenahmed/freellmapi:latest`.
- **Persistencia**: SQLite en `/app/server/data`. Volumen Docker `freellmapi-data`.
- **Seguridad y Red**:
  - `datamanager` tiene IP pública (`141.253.197.108`) e IP privada Tailscale (`100.77.82.13`).
  - Para evitar exponer el dashboard y la API a internet público sin autenticación, el puerto debe enlazarse explícitamente a la IP de Tailscale: `100.77.82.13:3001:3001` (o a localhost si se accede por túnel).
- **Conectividad con Ollama local**:
  - Ollama está corriendo en el VPS escuchando en `127.0.0.1:11434`.
  - Mediante `extra_hosts: ["host.docker.internal:host-gateway"]` en el `docker-compose.yml`, FreeLLMAPI puede acceder a Ollama en `http://host.docker.internal:11434/v1`.
- **Configuración declarativa**:
  - `ENCRYPTION_KEY`: 64 caracteres hex (`openssl rand -hex 32`).
  - `FREEAPI_CONFIG_PATH`: `/app/config/freellmapi.config.json` para precargar proveedores o enlazar Ollama sin requerir configuración manual exclusiva en UI.

## Decisiones tomadas

- **Decisión 1**: Crear la skill universal en `.agents/skills/remote-admin/SKILL.md` e integrarla en `scripts/agent/assets-manifest.txt` y `.agents/context/skills-inventory.md`.
  - **Por qué**: Sigue el principio "global pequeño, local fino" y DRY. Todos los proyectos hijos dispondrán de la misma herramienta.
- **Decisión 2**: El despliegue de FreeLLMAPI en el VPS se organizará en `/home/ubuntu/freellmapi/` con `docker-compose.yml`, `.env` y persistencia de datos.
  - **Por qué**: Mantiene orden con el resto de servicios (`/home/ubuntu/polybot`, etc.).
- **Decisión 3**: Mapear puerto 3001 restringido a Tailscale (`100.77.82.13:3001:3001`).
  - **Por qué**: Previene accesos no autorizados desde la interfaz pública.

## Descartado

- Crear una skill independiente `vps-datamanager`: descartado para no fragmentar el core con skills por cada máquina o VPS.
