# Task-035: Auditoría no destructiva de capacidad de disco y exposición de puertos en oracle

## Objetivo
Realizar una auditoría técnica en modo solo lectura de la capacidad de disco y la exposición de puertos de red en el VPS `oracle`, generando un informe detallado con desglose de Docker, logs, backups y análisis de superficie de ataque sin ejecutar ninguna acción destructiva.

## Contexto técnico
- Host: `oracle` (Ubuntu 24.04 ARM64, Tailscale `100.96.20.7`).
- Estado actual detectado: `/dev/sda1` al 72% de uso (55GB libres de ~200GB).
- Motor de aplicaciones: Coolify 4.0.0-beta.460 gestionando ~25 contenedores activos con Traefik como reverse proxy.
- Red: UFW inactivo, múltiples puertos (8000, 3000, 8888, 5800, etc.) escuchando en `0.0.0.0`.
- Restricción crítica: Operación 100% de solo lectura (`remote-admin` / SSH de lectura). No ejecutar `rm`, `prune`, `restart`, `ufw enable` ni alterar contenedores.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `.agents/skills/remote-admin/scripts/audit-host.sh` (nuevo script reusable de diagnóstico SSH de una sola llamada)
- `.agents/skills/remote-admin/SKILL.md` (documentar nuevo script en la skill remote-admin)
- `docs/runbooks/oracle-disk-and-ports-audit.md` (nuevo informe de auditoría específico de oracle)
- `.agents/tasks/task-035.md` (task file activo)
- `docs/sprints/sprint-06-core.md` (registro de estado y enlace a task file)

## Criterios de done
- [x] Creación del script reusable `.agents/skills/remote-admin/scripts/audit-host.sh` que recolecte métricas de host, almacenamiento, Docker (desglose/espacio recuperable), puertos en escucha (públicos vs Tailscale/local) y firewall en un único comando vía SSH.
- [x] Actualización de `.agents/skills/remote-admin/SKILL.md` para documentar la invocación del script de auditoría optimizado en tokens.
- [x] Ejecución remota de diagnóstico no destructivo en `oracle` usando el script reusable.
- [x] Documentación detallada en `docs/runbooks/oracle-disk-and-ports-audit.md` con desglose de consumo de disco en `oracle` y recomendaciones priorizadas de poda segura / endurecimiento de puertos.
- [x] Cero alteraciones en el filesystem, servicios o contenedores de `oracle` durante la auditoría.
- [x] Suite de validación local `bash tests/validate-control-plane.sh` pasando sin errores.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-24T16:14:47+01:00
- [x] Rama creada: feat/T-035-oracle-disk-ports-audit
- [x] Lock activo: 2026-09-24T16:15:20+01:00
- [x] Sesión cerrada correctamente
