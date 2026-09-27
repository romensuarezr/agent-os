# Task-060: Seguridad Perimetral y Contención Docker Socket (ADR 004)

## Objetivo
Implementar el aislamiento del socket de Docker en Homepage mediante el servicio intermediario `tecnativa/docker-socket-proxy` con perfil estricto de solo lectura (`CONTAINERS=1`, `INFO=1`, `POST=0`) y limitación de memoria a 32MB para respetar las restricciones de recursos en el VPS `oracle` (ADR 004). Eliminar el montaje directo de `/var/run/docker.sock` en el contenedor de Homepage y documentar la protección perimetral en `docs/runbooks/homepage-security.md`.

## Contexto técnico
- **Restricción de Recursos en `oracle` (ADR 004)**: El VPS `oracle` aloja múltiples servicios de la flota. No debe permitirse consumo desmedido de RAM ni demonios secundarios no esenciales. `tecnativa/docker-socket-proxy` se limitará explícitamente a `mem_limit: 32m` y operará sobre una red interna de Docker compartida con Homepage.
- **Riesgo de Montaje Directo de Docker Socket**: El montaje de `/var/run/docker.sock` en Homepage permitía potencial escalada de privilegios o denegación de servicio. Con el proxy, solo las llamadas GET autorizadas a listar contenedores e información general del daemon son aceptadas por HAProxy; cualquier verbo POST o llamada destructiva es rechazada con HTTP 403 Forbidden.
- **Configuración de Homepage**: La conexión a Docker en `docker.yaml` pasará de socket UNIX local a endpoint TCP interno `tcp://docker-socket-proxy:2375`.
- **Protección Perimetral**: Homepage debe ser blindado frente a accesos públicos no autorizados mediante Cloudflare Zero Trust (Access) o middleware de autenticación en Traefik.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `templates/homepage/docker-compose.yml`
- `docs/runbooks/homepage-security.md`
- `.agents/tasks/task-060.md`
- `docs/sprints/sprint-10-core.md`

## Criterios de done
- [x] `templates/homepage/docker-compose.yml` incluye el servicio `docker-socket-proxy` con imagen `tecnativa/docker-socket-proxy:latest`, entorno seguro (`CONTAINERS=1`, `INFO=1`, `POST=0`) y límite `mem_limit: 32m`.
- [x] Eliminado el volumen host `/var/run/docker.sock` del contenedor `homepage`, reemplazándolo por enlace de red al proxy.
- [x] Documentado en `docs/runbooks/homepage-security.md` el esquema de aislamiento, variables del proxy y guías para Cloudflare Access / Traefik Basic Auth.
- [x] Validación sintáctica y de compose exitosa (`docker compose config` sin errores).
- [x] `tests/validate-control-plane.sh` pasa 10/10 checks.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-27T14:30:29+01:00
- [x] Rama creada: feat/T-060-docker-socket-proxy-hardening
- [x] Lock activo: no-lock
- [x] Sesión cerrada correctamente
