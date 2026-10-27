# Task-118: Redacción obligatoria y normas de secretos coherentes

## Objetivo
Cerrar la vía por la que un diagnóstico puede incrustar valores: `lib/redact.sh` como filtro
obligatorio para salidas que pueden contener secretos; reescritura quirúrgica de la skill
`infisical-secrets`; y enmiendas a `agent-permissions.md` y `AGENT_ONBOARDING.md §7` para que la
norma diga lo mismo que la herramienta. Enforcement en la suite.

## Contexto técnico
La matriz de permisos prohíbe leer/imprimir secretos (L3), pero la skill enseña lo contrario:
`eval $(infisical export ...)` (`SKILL.md:120` y `:194`), `secrets set CLAVE="valor"`
(`:175`, `:321`) y `echo $<CLAVE>` (`secret-locate.sh`, receta final). `import-secrets.sh` y
`materialize-secrets.sh` ya garantizan "nunca imprimir valores", pero no existe filtro para
`docker compose config`, `docker inspect` o `env`/`printenv`, que sí pueden volcar valores.
`AGENT_ONBOARDING.md:72` remite a `import-secrets.sh` "o el cliente oficial": lista abierta, sin
consecuencia si el agente improvisa.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/lib/redact.sh` (nuevo)
- `.agents/skills/infisical-secrets/SKILL.md`
- `.agents/rules/global/agent-permissions.md`
- `.agents/AGENT_ONBOARDING.md`
- `tests/validate-control-plane.sh` (check 33)

## Criterios de done
- [x] `lib/redact.sh` lee stdin y sustituye el valor de cada clave conocida por `<redacted:CLAVE>`:
      `--keys A,B`, `--catalog FICHERO` o el default `$REPO/.agents/config/secrets-catalog.yaml`
      (ruta canónica del generador, sobre-escribible con `AGENT_OS_SECRETS_CATALOG`); estructura
      preservada (mismo nº de líneas, JSON válido — los escalares pasan a string entrecomillado)
- [x] `redact.sh` es determinista, sin red, sin escrituras y sin depender de `jq`
- [x] `SKILL.md`: **0** `eval $(infisical export`, **0** recetas con valor en `argv`, **0**
      `echo $<CLAVE>` dentro de bloques de código; las recetas usan `infisical run -- ...`,
      `secrets.sh` o el pipe de `redact.sh`
- [x] `agent-permissions.md`: solo los scripts del core tocan secretos; se declara explícitamente
      que **`argv` = transcript** (nunca un valor en línea de comandos)
- [x] `AGENT_ONBOARDING.md §7`: lista **cerrada** de scripts autorizados; si no hay script para lo
      que se necesita, el agente **se para y lo propone** (no improvisa)
- [x] Check 33: estático fence-aware (patrones prohibidos solo en bloques de código de la skill,
      marcadores de lista cerrada y argv/transcript) + funcional (`--keys`, JSON con `json.loads`,
      YAML, comillas, fixture de catálogo en formato exacto, passthrough sin claves, determinismo)
- [x] Suite completa en verde (33/33)

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — 2026-10-27 (CON CAMBIOS: ruta/formato reales del catálogo y fixture)
- [x] Rama creada: `feat/T-118-redaction-rules`
- [x] Lock activo: `.agent-session.lock`
- [x] Sesión cerrada correctamente

## Notas de implementación

- El catálogo **no está versionado**: `.agents/config/secrets-catalog.yaml` lo genera
  `generate-secrets-catalog.sh` y está en `.gitignore`. `redact.sh` lo usa solo como default
  opcional; si falta o está vacío, avisa por stderr y hace passthrough (un satélite recién
  instalado no falla). `--keys` y `--catalog` son las vías deterministas.
- Formas cubiertas: `KEY=valor`, `KEY="valor"`, `"KEY": "valor"`, `"KEY": 123` (→ string
  entrecomillado, JSON válido) y `KEY: valor` (YAML/compose, consume hasta fin de línea).
- Frontera de palabra: `MY_API_TOKEN` no se confunde con `API_TOKEN`.
- Límites asumidos: sobre-redacta en prosa (`KEY: texto`) por fail-safe; los valores anidados en
  objetos/arrays JSON no se redactan.
- Check 33 escanea **solo bloques de código** de la skill, así las menciones de lo prohibido en
  prosa no se auto-disparan; controles negativos ejercitados (fence con `eval $(infisical export)`
  → `skill-patron-prohibido`; sin patrón de comillas → `quoted`).
