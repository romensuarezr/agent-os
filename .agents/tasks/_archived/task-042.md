# Task-042: Despliegue de Infisical Community Edition en Coolify (oracle) y skill de inyección de secretos

## Objetivo
Desplegar Infisical Community Edition en modo Standalone Lite (<500MB RAM) en el VPS `oracle` mediante Coolify/Docker, e integrar la skill/runbook y CLI para inyección en memoria (`infisical run`) con Universal Auth para la flota de Agent OS.

## Contexto técnico
- VPS `oracle` (Ubuntu 24.04, Coolify, Traefik, Docker auditado en T-035).
- Configuración Standalone Lite documentada en `docs/sprints/sprint-08-core-research.md`: Postgres 15 Alpine con buffers ajustados (64MB) + Infisical core con límite a 320MB RAM, telemetry desactivada y sin Redis distribuido.
- Advertencia técnica del research: Picos transitorios de migración DB de ~350MB, por lo que el límite en Coolify debe calibrarse a 450-500MB.
- La inyección de secretos se ejecuta en memoria vía `@infisical/cli` (`infisical run -- <comando>`), protegiendo el entorno frente a filtraciones de claves en archivos `.env` o commits.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `docs/sprints/sprint-08-core.md`
- `.agents/tasks/task-042.md`
- `templates/infisical/docker-compose.yml`
- `.agents/skills/infisical-secrets/SKILL.md`
- `config/fleet.yaml`
- `config/fleet.example.yaml`
- `tests/validate-control-plane.sh`

## Criterios de done
- [x] Stack de Infisical CE verificado en `oracle` (desplegado en Coolify, endpoint registrado en `config/fleet.yaml`).
- [x] Machine Identity (Universal Auth) y workspace de Agent OS configurados en Infisical.
- [x] Skill `.agents/skills/infisical-secrets/SKILL.md` creada con runbook para inyección en memoria (`infisical run`).
- [x] Registro del servicio Infisical en `config/fleet.yaml` y plantilla universal en `config/fleet.example.yaml`.
- [x] Suite `tests/validate-control-plane.sh` pasando con 0 errores.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-26T14:04:15+01:00 (Aprobado con cambios: omitir despliegue manual, usar instancia Coolify activa)
- [x] Rama creada: feat/T-042-deploy-infisical-oracle
- [x] Lock activo: .agent-session.lock
- [ ] Sesión cerrada correctamente
