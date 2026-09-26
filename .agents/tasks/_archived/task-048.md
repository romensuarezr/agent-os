# Task-048: Despliegue de OmniRoute en datamanager ($0 inferencia) y plugin opencode-omniroute-auth

## Objetivo
Desplegar la pasarela OmniRoute en contenedor Docker headless en el VPS `datamanager` (puerto 3002 vía red Tailscale), configurar el plugin `opencode-omniroute-auth` en local para compresión semántica RTK de contexto y registrar el nuevo servicio en `config/fleet.yaml` y `config/routing-policy.yaml`.

## Contexto técnico
- Docker y Tailscale activos en `datamanager` (`100.77.82.13`).
- Credencial `OMNIROUTER_API_KEY` disponible en `/home/romen/Proyectos/Agencia_IA/.env:21`.
- Configuración headless optimizada en `docs/sprints/sprint-08-core-research.md` con compresión RTK (`ENABLE_RTK_COMPRESSION=true`, `RTK_COMPRESSION_RATIO=0.4`) y límite de RAM a 256MB.
- Plugin oficial `opencode-omniroute-auth` (v1.2.2 en npm) para OpenCode CLI.
- No requiere UI web ni componentes pesados, opera como gateway OpenAI-compatible a coste $0.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `docs/sprints/sprint-08-core.md`
- `.agents/tasks/task-048.md`
- `templates/omniroute/docker-compose.yml`
- `config/fleet.yaml`
- `config/routing-policy.yaml`
- `tests/validate-control-plane.sh`

## Criterios de done
- [x] Template `templates/omniroute/docker-compose.yml` y configuración headless creada con compresión RTK y límites de memoria.
- [x] Contenedor OmniRoute levantado en `datamanager` expuesto en puerto `20128` vía Tailscale.
- [x] Verificación del endpoint OpenAI-compatible (`http://100.77.82.13:20128/v1/chat/completions`) respondiendo con $0 tokens.
- [x] Integración y validación del plugin `opencode-omniroute-auth` en la configuración local de OpenCode.
- [x] Registro de OmniRoute como servicio en `config/fleet.yaml` y tier secundario en `config/routing-policy.yaml`.
- [x] Suite `tests/validate-control-plane.sh` pasando con 0 errores.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-26T13:06:49+01:00
- [x] Rama creada: feat/T-048-deploy-omniroute-datamanager
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
