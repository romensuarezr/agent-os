# Task-117: `secrets.sh` como único punto que toca valores

## Objetivo
Crear `scripts/agent/secrets.sh` como el único punto del core que manipula **valores** de secretos
(set/rotate: valor por stdin sin eco o generado en el script; confirmación por metadatos + huella
hash, nunca fragmentos del valor; verificación por el motor existente), añadir
`secret-locate.sh --search <texto>` (la búsqueda la itera el script, no el agente) y corregir la
doble exportación del modo `--hygiene`.

## Contexto técnico
Hoy no existe `secrets.sh`: los valores se tocan desde `import-secrets.sh` (`.env` → bóveda, masivo),
`materialize-secrets.sh` (bóveda → `.env` 600, rechaza ficheros versionados) y, sobre todo, desde
recetas de la skill que ponen el valor en `argv`. `secret-locate.sh` solo lee metadatos y descarta
valores (`keys_with_meta`), pero su receta final imprime `echo $<CLAVE>`.

**Bug de la doble exportación (`--hygiene`)**: el barrido inicial construye
`inventory = {f: keys_in(f) ...}` (`secret-locate.sh:170-175`) y el bloque de higiene vuelve a llamar
`keys_with_meta(f)` por cada carpeta (`:197-201`), es decir, un segundo `infisical export` por
carpeta. Además, la receta de higiene (`:212`) muestra
`infisical secrets set <CLAVE>='<valor>'` con el valor en `argv`.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/secrets.sh` (nuevo, ejecutable)
- `scripts/agent/secret-locate.sh` (`--search` + caché del barrido de higiene)
- `tests/validate-control-plane.sh` (check 32)
- `docs/runbooks/` (runbook de secretos: decidir en el plan si se amplía uno existente o se crea
  `secret-operations.md`; no duplicar el de `infisical-secrets`)

## Criterios de done
- [x] `secrets.sh set <CLAVE>` acepta el valor **solo** por stdin (`--stdin`) o generado
      (`--generate[=N]`); un valor en `argv` se rechaza con exit 2 y mensaje explícito
- [x] Sin eco: sin `set -x`, lectura con `read -rs` cuando hay TTY, y el valor no aparece en
      `ps`, en el historial ni en la salida
- [x] Confirmación por metadatos + huella: imprime clave, carpeta, entorno y `sha256` truncado;
      **nunca** un fragmento del valor ni su longitud exacta
- [x] `rotate` = generar + set + verificar por el motor existente (existe y cambió `updatedAt`),
      sin imprimir el valor
- [x] `secret-locate.sh --search <texto>`: solo metadatos, informa carpeta y clave, **nunca**
      valores; exit 0/6/64
- [x] `--hygiene` hace **un** barrido: 1 `infisical export` por carpeta (stub contador: 2/2)
- [x] La receta final deja de recomendar `echo $<CLAVE>`: pasa a `infisical run -- <comando>` y a
      `| redact.sh` (marcado "tras T-118"); la de higiene usa `--file /dev/stdin`
- [x] Check 32: estático (sin `set -x`, sin `eval`, valor por stdin) + funcional con stubs
      (`--search` sin fuga con valor señuelo; `--hygiene` sin duplicar exportaciones)
- [x] Suite completa en verde (32/32)

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — 2026-10-27
- [x] Rama creada: `feat/T-117-secrets-ops`
- [x] Lock activo: `.agent-session.lock`
- [ ] Sesión cerrada correctamente

## Notas de implementación

- El valor viaja al CLI por `--file /dev/stdin` (verificado con el CLI real 0.43.137: lee stdin
  antes de llamar a la API). Sin fichero temporal, sin `--value`, sin `eval`.
- Rechazos con exit 2: segundo posicional, `CLAVE=valor`, `--value`/`--value=`, y `set` sin
  `--stdin`/`--generate`. `--generate` default 32, rango 16-128.
- Carpeta: `--path` o resolución única vía `secret-locate.sh --name --json`; **crear sin `--path`
  es exit 6** (no hay carpeta que resolver).
- `secret-locate.sh --name --json` añade `hits_detail:[{folder,updated_at}]` (aditivo; `found_in`
  intacto) para que `rotate` verifique sin leer valores.
- Un único `_sweep` reutilizado por inventario, higiene y nombres: 1 export por carpeta en todos
  los modos.
- `--search` solo metadatos (clave, descripción, etiquetas, carpeta); buscar en valores queda
  rechazado por diseño (R4).
- Debt: ~15 líneas de mint de token duplicadas de `secret-locate.sh` (caja sin lib común).
