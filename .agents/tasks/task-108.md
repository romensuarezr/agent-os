# Task-108: Semver real en el cierre de sprint

## Objetivo
Que `update-changelog.sh` ignore `## [Unreleased]` al leer la versión actual y calcule el bump
desde la última cabecera con semver válido (con `git tag v*` como segunda fuente). Cerrar el bug
que generó `## [0.1.0]` en sprint-17.

## Contexto técnico
Causa raíz: `update-changelog.sh:110` hace `grep -m1 '^## \['`, que cae en `## [Unreleased]`
(línea 119 del changelog, sin semver) → fallback `0.0.0` → bump a `0.1.0`. Reproducido y parcheado
a mano en el cierre de sprint-17. La suite no valida el changelog (0 matches): el fix debe añadir
el check 26 con caso de regresión. Sin cambio de comportamiento por defecto.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/update-changelog.sh`
- `tests/validate-control-plane.sh`

## Criterios de done
- [ ] Caso de regresión: `## [Unreleased]` delante de una cabecera semver → el bump parte de la
      semver, nunca de `0.0.0` (el `0.1.0` no puede volver a generarse)
- [ ] Segunda fuente: si el changelog no tiene semver válida, se usa el último `git tag v*`
- [ ] Check 26 añadido a la suite con el caso anterior (suite 26/26 en verde)
- [ ] `close-sprint.sh` no necesita cambios; T-109 se ejecuta DESPUÉS (comparten ficheros)

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
