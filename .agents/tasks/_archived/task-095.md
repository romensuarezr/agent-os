# Task-095: Sección de secretos (Infisical) en la plantilla de onboarding del satélite

## Objetivo
Cerrar el ciclo de vida de los secretos en la flota: que un agente sepa **dónde vive** una clave sin adivinar ni preguntar, que la bóveda sea auditable (revocados, duplicados y shadowing), que exista una taxonomía de alcance respaldada por medición, y que el onboarding del satélite transmita todo eso.

**Alcance ampliado de S a L durante la ejecución** tras el incidente reportado: un agente buscó una clave en la carpeta de su proyecto, no la encontró y tuvo que preguntar al usuario; después encontró tokens ya revocados. La causa no era la falta de un secreto, sino la ausencia total de inventario, convención y auditoría.

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
- [x] `bash scripts/agent/secret-locate.sh --name <CLAVE>` responde dónde vive una clave sin mostrar valores.
- [x] `--list` devuelve el inventario de carpetas con conteo de claves.
- [x] `--audit` detecta claves duplicadas y carpetas casi clonadas por similitud.
- [x] `verify-secrets.py --source=infisical` audita la bóveda reutilizando el verificador de vigencia existente.
- [x] Detecta shadowing: mismo nombre de clave con valores distintos en varias carpetas.
- [x] La skill define taxonomía (`scope`/`env`/`owner`/`consumers`/`rot`) y reglas de ubicación.
- [x] La skill y la plantilla desaconsejan explícitamente el comando que imprime valores en claro.
- [x] La plantilla de onboarding incluye la sección de secretos con el protocolo de "no adivinar".
- [x] `bash tests/validate-control-plane.sh` sin regresiones (14/14).

## Resultado del saneamiento (Fase B)

Ejecutado tras la puerta de aprobación, con verificación previa clave por clave:

- **Carpeta `shared` creada** y poblada con las 5 claves transversales migradas desde
  `/configuraciones`, con integridad verificada por hash. `/configuraciones` se conserva
  intacta para no romper consumidores; su retirada es una pasada posterior.
- **`/kanairos_backup` eliminada**: 0 claves exclusivas en toda la bóveda.
- **`/codigo_descargado` eliminada**: 21 claves exclusivas, de las cuales 4 son
  credenciales reales (`EVOLUTION_API_SECRET_KEY`, `NGROK_AUTHTOKEN`,
  `N8N_BASIC_AUTH_PASSWORD`, `SENTRY_API_KEY`) que **no** se migraron: preservar
  credenciales de código borrado perpetuaría superficie de ataque sin dueño. Su revocación
  corresponde al operador en la consola de cada proveedor.
- **Balance**: 13 → 12 carpetas, 236 → 207 claves únicas. Desaparecen 29 claves en total
  (21 exclusivas + 8 que solo existían en esas dos carpetas simultáneamente), todas
  presentes en los repositorios locales.
- **Copia de seguridad**: ambas carpetas exportadas antes de borrar en
  `~/.local/share/agent-os/secret-backups/2026-10-12-pre-sanitation/` (permisos 600).

**Pendiente para el operador**: revocar `OPENROUTER_API_KEY` (detectada revocada en
`/Agencia_IA`) y rotar las 3 credenciales de `/kanarii` que quedaron expuestas al ejecutar
por error un comando de la CLI que imprime valores en claro.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-10-12T15:37:20+01:00
- [x] Rama creada: feat/T-095-secret-lifecycle
- [x] Lock activo: `.agent-session.lock`
- [ ] Sesión cerrada correctamente