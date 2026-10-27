# Task-114: `PREV_TAG` por versión, no por fecha de creación

## Objetivo
Corregir la selección del tag base en `update-changelog.sh` para que el rango de commits se calcule
sobre la última versión publicada y no sobre el tag creado más recientemente, y extender el check 26
para cubrir el caso.

## Contexto técnico
`update-changelog.sh:49` usa `git tag --sort=-creatordate | head -1`. Hoy acierta solo porque los
tags se crearon en orden cronológico. Con un tag de parche creado después sobre una release
anterior, un reetiquetado o un tag importado con fecha antigua, `PREV_TAG..HEAD` omite o repite
commits. El fallback sin tags es `HEAD~50..HEAD` (`:52`). Idea de origen:
`docs/idea-inbox/2026-10-16-prev-tag-orden-version.md`.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/update-changelog.sh`
- `tests/validate-control-plane.sh` (extensión del check 26)

## Criterios de done
- [ ] El tag base se elige por **versión** (`git describe --tags --abbrev=0` sobre tags `vX.Y.Z`, o
      `sort -V` filtrando el patrón), no por fecha
- [ ] Con tags creados en orden no monotónico, el rango elegido es el de la versión mayor
- [ ] Sin tags válidos, degrada al fallback actual sin abortar
- [ ] Check 26 ampliado con fixture de tags fuera de orden (creados con `GIT_COMMITTER_DATE`
      invertido) que verifica el rango elegido
- [ ] Suite completa en verde

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
