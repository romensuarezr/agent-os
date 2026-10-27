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
- [ ] `secrets.sh set <CLAVE>` acepta el valor **solo** por stdin (`--stdin`) o generado
      (`--generate[=N]`); un valor en `argv` se rechaza con exit 2 y mensaje explícito
- [ ] Sin eco: sin `set -x`, lectura con `read -rs` cuando hay TTY, y el valor no aparece en
      `ps`, en el historial ni en la salida
- [ ] Confirmación por metadatos + huella: imprime clave, carpeta, entorno y `sha256` truncado;
      **nunca** un fragmento del valor ni su longitud exacta
- [ ] `rotate` = generar + set + verificar por el motor existente (que el secreto existe y cambió
      `updatedAt`), sin imprimir el valor
- [ ] `secret-locate.sh --search <texto>`: recorre todas las carpetas desde el script, informa
      carpeta y clave coincidentes, **nunca** imprime valores; exit 0 con coincidencias, 6 sin
      coincidencias, 64 uso incorrecto
- [ ] `--hygiene` hace **un** barrido: el número de `infisical export` es igual al número de
      carpetas (verificable con un stub que cuente invocaciones)
- [ ] La receta final de `secret-locate.sh` deja de recomendar `echo $<CLAVE>`: pasa a
      `infisical run -- <comando>` (consumo, sin imprimir) y a `| redact.sh` para diagnósticos
- [ ] Check 32: estático (sin rutas de valor por `argv`, sin `eval`) + funcional con stub
      (`--search` no filtra valores; `--hygiene` no duplica exportaciones)
- [ ] Suite completa en verde

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
