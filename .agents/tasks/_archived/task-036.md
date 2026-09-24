# Task-036: Diseño y normalización de autenticación GitHub SSH en datamanager y oracle

## Objetivo
Diagnosticar y normalizar de forma no destructiva la autenticación Git vía SSH con GitHub (`git@github.com`) en los servidores remotos `datamanager` y `oracle`, eliminando el error `Host key verification failed`, evaluando claves existentes y diseñando una estrategia segura de Deploy Keys / SSH config sin prompts interactivos ni exposición de secretos.

## Contexto técnico
- Entorno local: Autenticación funcional hacia GitHub mediante alias `github.com-romen` (`IdentityFile ~/.ssh/id_ed25519_romensuarezr`).
- `datamanager` (`100.77.82.13`): Ubuntu 22.04 ARM64. Falla con `Host key verification failed` al conectar a `git@github.com`.
- `oracle` (`100.96.20.7`): Ubuntu 24.04 ARM64. Falla con `Host key verification failed` al conectar a `git@github.com`.
- Requisito de seguridad estricto: No almacenar tokens ni claves privadas en el repositorio. Decision gate humano previo a cualquier generación o instalación de nuevas claves en los servidores.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `.agents/skills/remote-admin/scripts/check-git-remote.sh` (nuevo script reusable para diagnóstico no destructivo de Git SSH en hosts remotos)
- `.agents/skills/remote-admin/SKILL.md` (documentación de verificación Git SSH remota en la skill)
- `docs/runbooks/github-ssh-setup-remote.md` (nuevo runbook con arquitectura de autenticación y pasos de resolución)
- `.agents/tasks/task-036.md` (task file activo)
- `docs/sprints/sprint-06-core.md` (registro de estado y enlace a task file)

## Criterios de done
- [x] Creación de script reusable `.agents/skills/remote-admin/scripts/check-git-remote.sh` para diagnosticar en 1 llamada SSH: estado de `known_hosts` para github.com, presencia de claves SSH públicas en `~/.ssh/` y prueba de handshake `ssh -T git@github.com`.
- [x] Actualización de `.agents/skills/remote-admin/SKILL.md` documentando la herramienta de verificación de conectividad Git remota.
- [x] Ejecución de diagnóstico no destructivo en `datamanager` y `oracle` identificando el estado exacto de claves y `known_hosts`.
- [x] Redacción de runbook `docs/runbooks/github-ssh-setup-remote.md` con la estrategia recomendada (Deploy Keys de solo lectura vs claves de bot), aprovisionamiento seguro de `known_hosts` vía `ssh-keyscan` y comandos exactos bajo gate humano.
- [x] Cero exposición de secretos o claves privadas en el repo y validación local `bash tests/validate-control-plane.sh` pasando sin errores.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-24T16:32:24+01:00
- [x] Rama creada: feat/T-036-remote-github-ssh-auth
- [x] Lock activo: 2026-09-24T16:32:35+01:00
- [x] Sesión cerrada correctamente
