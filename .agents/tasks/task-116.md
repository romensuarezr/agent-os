# Task-116: Honestidad del escáner (`locator-hygiene.sh`)

## Objetivo
Que `locator-hygiene.sh` deje de afirmar "limpio" cuando no ha podido verificar, y que cubra los
ficheros sin trackear. Después: ampliar el check 22 para que ambos huecos queden cubiertos por la suite.

## Contexto técnico
`locator-hygiene.sh:118` enumera con `git ls-files` (solo trackeados) y, si `$ROOT` no es un repo,
`ls-files` falla, `FILES` queda vacío y el script termina con `exit 0` → "limpio". Reproducido en
T-106 sobre un directorio no-repo; el fix de entonces (`--path` honra excepciones) no cambió esa
salida. El check 22 (`tests/validate-control-plane.sh:947`) lo ejecuta sobre el core, siempre repo
git y todo trackeado, así que no puede ver ninguno de los dos huecos.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/lib/locator-hygiene.sh`
- `tests/validate-control-plane.sh` (check 22 ampliado)

## Criterios de done
- [ ] Sobre un directorio que no es repo git: veredicto explícito **no verificable** y exit ≠ 0;
      nunca "limpio" (se decide en el plan: `exit 2` por uso/entorno o `exit 1` por hallazgo)
- [ ] Los ficheros sin trackear se escanean (vía `--include-untracked` o por defecto; decisión y
      motivo en el plan) respetando las excepciones existentes
- [ ] Check 22 ampliado: fixture temporal no-repo → detecta el falso limpio; fixture con un fichero
      untracked que contiene un literal → lo detecta
- [ ] `--path` y las excepciones del repo escaneado siguen funcionando (sin regresión de T-106)
- [ ] Suite completa en verde

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
