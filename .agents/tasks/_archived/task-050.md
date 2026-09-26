# Task-050: Despliegue de ByteBox en Coolify (oracle) vía Coolify MCP para gestión de snippets y comandos

## Objetivo
Desplegar ByteBox (`pinkpixel-dev/bytebox`) en el VPS `oracle` mediante Coolify, probando operativamente por primera vez el Coolify MCP (`@masonator/coolify-mcp`), para disponer de un gestor self-hosted de comandos CLI, snippets y notas técnicas que sustituya el registro informal en Notion.

## Contexto técnico
- VPS `oracle` con Coolify v4 y Traefik operativos tras T-035/T-042 (`https://coolify.romensuarez.com`).
- Diagnóstico de Coolify completado:
  - Estructura actual de proyectos: `Agencia IA` (servicios core/infraestructura compartida como Infisical y n8n), y 6 proyectos de clientes/aplicaciones independientes (`bot3-multimoneda`, `polybot`, `kanAIrOS`, `Finca Adama`, `Alisios app`, `romensuarez-web`).
  - Base de Datos y Optimización RAM: La política de "Unified-DB" prohíbe desplegar contenedores adicionales de PostgreSQL. ByteBox cumple al 100% esta directiva sin requerir Unified-DB porque opera en modo *local-first* con SQLite embebido (`file:/data/bytebox.db`), consumiendo 0 procesos de BD adicionales y usando únicamente un volumen Docker persistente (`bytebox-data:/data`).
  - Ubicación objetivo en Coolify: Proyecto `Agencia IA` (entorno `production`, id: 1) o nuevo proyecto `Dev Tools / Agent OS` junto a las herramientas de control plane.
- ByteBox: Repo público `https://github.com/pinkpixel-dev/bytebox` (build pack Dockerfile/Docker Compose con Next.js standalone), puerto 1334, volumen `/data`.
- Despliegue gestionado a través de Coolify MCP (`@masonator/coolify-mcp`) / API y exposición web bajo subdominio seguro (Traefik SSL).
- Integración en `config/fleet.yaml` y plantilla estandarizada en `templates/bytebox/docker-compose.yml`.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `docs/sprints/sprint-08-core.md`
- `.agents/tasks/task-050.md`
- `templates/bytebox/docker-compose.yml`
- `config/fleet.yaml`
- `config/fleet.example.yaml`

## Criterios de done
- [x] Plantilla Docker Compose estandarizada en `templates/bytebox/docker-compose.yml` con persistencia de SQLite.
- [x] Aplicación ByteBox creada y desplegada en Coolify (`oracle`) utilizando el Coolify MCP (`@masonator/coolify-mcp`).
- [x] Verificación de liveness HTTP y acceso a la interfaz web de ByteBox.
- [x] Registro del servicio ByteBox en `config/fleet.yaml` y plantilla en `config/fleet.example.yaml`.
- [x] Suite de pruebas `tests/validate-control-plane.sh` pasando con 0 errores (respetando agnosticism sin exponer IPs/dominios privados).

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-26T20:50:20+01:00
- [x] Rama creada: feat/T-050-deploy-bytebox-coolify
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
