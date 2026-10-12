# Task-095: Sección de secretos (Infisical) en la plantilla de onboarding del satélite

## Objetivo
Que cualquier agente que arranque sesión en un proyecto satélite encuentre, en su propio documento de onboarding, cómo obtener e inyectar secretos de forma efímera y sin dejar credenciales en disco ni en el repositorio.

## Contexto técnico
`.agents/templates/AGENT_ONBOARDING.project.md` es la plantilla que `install.sh` despliega en el hijo. Hoy tiene cinco secciones (pre-flight de salud, stack, estructura de carpetas, comandos frecuentes, convenciones) y **ninguna de secretos**. El efecto es reproducible: el agente del satélite busca la API key de un gateway, no encuentra la instrucción y termina pidiéndola por chat o escribiéndola en un archivo.

El flujo canónico ya existe y está documentado en la skill global `infisical-secrets`: dos pasos obligatorios (`infisical login` con Machine Identity → token efímero), resolución por proyecto con `--path="/<proyecto>"` y borrado compartido con `--type=shared`. `audit-repo.sh` ya detecta credenciales en archivos rastreados, de modo que un volcado a disco produce un hallazgo inmediato.

La sección nueva debe cubrir: patrón de 2 pasos, `--path` por proyecto, `--type=shared` para borrado, y la prohibición explícita de `infisical export > .env` dentro del repositorio.

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/templates/AGENT_ONBOARDING.project.md`
- `changelog.md`
- `.agents/tasks/task-095.md`

## Criterios de done
- [ ] La plantilla incluye una sección de secretos con el patrón de 2 pasos y las rutas por proyecto.
- [ ] La sección prohíbe explícitamente volcar secretos a archivo rastreado y remite a la skill `infisical-secrets`.
- [ ] `install.sh` la propaga sin cambios al satélite (verificado sobre un repo de prueba).
- [ ] `bash scripts/agent/audit-repo.sh` sobre el satélite de prueba no reporta falsos positivos de secretos.
- [ ] `bash tests/validate-control-plane.sh` sin regresiones.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente