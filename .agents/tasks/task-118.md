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
- [ ] `lib/redact.sh` lee stdin y sustituye el valor de cada clave conocida por `<redacted:CLAVE>`:
      claves declaradas por `--keys A,B` y, por defecto, las del catálogo
      `.agents/config/secrets-catalog.yaml`; preserva estructura (una línea sigue siendo una línea,
      JSON sigue siendo JSON válido cuando lo era)
- [ ] `redact.sh` es determinista, sin red, sin escrituras y sin depender de `jq`
- [ ] `SKILL.md`: **0** `eval $(infisical export`, **0** recetas con valor en `argv`, **0**
      `echo $<CLAVE>`; las recetas usan `infisical run -- ...`, `secrets.sh` o el pipe de
      `redact.sh`
- [ ] `agent-permissions.md`: solo los scripts del core tocan secretos; se declara explícitamente
      que **`argv` = transcript** (nunca un valor en línea de comandos)
- [ ] `AGENT_ONBOARDING.md §7`: lista **cerrada** de scripts autorizados; si no hay script para lo
      que se necesita, el agente **se para y lo propone** (no improvisa)
- [ ] Check 33: estático (patrones prohibidos sobre skill/reglas/onboarding) + funcional
      (`printf 'API_TOKEN=abc123\n' | redact.sh --keys API_TOKEN` → `<redacted:API_TOKEN>`;
      JSON preservado)
- [ ] Suite completa en verde

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
