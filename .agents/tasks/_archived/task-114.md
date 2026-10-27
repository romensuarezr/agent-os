# Task-114: `PREV_TAG` por versión, no por fecha de creación

## Objetivo
Corregir la selección del tag base en `update-changelog.sh` para que el rango de commits se calcule
sobre la última versión publicada y no sobre el tag creado más recientemente, y extender el check 26
para cubrir el caso.

## Contexto técnico
`update-changelog.sh:49` usaba `git tag --sort=-creatordate | head -1`. Acertaba solo mientras los
tags se crearan en orden cronológico. El fallback sin tags es `HEAD~50..HEAD` (`:52`). Idea de
origen: `docs/idea-inbox/2026-10-16-prev-tag-orden-version.md`.

Mecanismo aprobado: `git tag --list 'v*' --sort=-v:refname | head -1`. Se descartó
`git describe --tags --abbrev=0` (propuesto inicialmente) porque en `multi-agent` devuelve
`v1.12.0`: los tags `v1.13.0`/`v1.14.0` viven solo en `main` (la promoción va de `multi-agent` a
`main`, nunca al revés) y `describe` solo ve etiquetas alcanzables desde HEAD. Eso reabriría el
rango de los sprints 17 y 18 y los duplicaría en la entrada del 19.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/update-changelog.sh`
- `tests/validate-control-plane.sh` (extensión del check 26)

## Criterios de done
- [x] El tag base se elige por **versión** (`git tag --list 'v*' --sort=-v:refname`), no por fecha
- [x] Con tags creados en orden no monotónico, el rango elegido es el de la versión mayor
- [x] Sin tags válidos, degrada al fallback actual sin abortar
- [x] Check 26 ampliado con fixture de tags fuera de orden (creados con `GIT_COMMITTER_DATE`
      invertido) que verifica el rango elegido + caso real (base == `v$(cat VERSION)`)
- [x] Suite completa en verde (30/30)

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — 2026-10-27, con cambio de mecanismo: `-v:refname` en lugar de `describe`
- [x] Rama creada: `feat/T-114-prev-tag-version`
- [x] Lock activo: `.agent-session.lock`
- [x] Sesión cerrada correctamente

## Notas de implementación

- `PREV_TAG` = `git tag --list 'v*' --sort=-v:refname | head -1`. El filtro `v*` evita que un tag
  arbitrario (p. ej. `backup-2024`) se cuele como base.
- Check 26, caso 4: `c1` base → `c2 feat: ya lanzado` → `c3 chore: release 1.13.0` con tag
  `v1.13.0` (2026-10-01) → `c4 feat: solo nuevo` (HEAD) + tag `v1.12.0` sobre `c1` con fecha
  2026-10-25. Con `-creatordate` el rango arranca en `v1.12.0` y duplica `ya lanzado`; con
  `-v:refname` arranca en `v1.13.0` y solo entra `solo nuevo`. Verificado en ambos sentidos.
- Caso real: si existe el tag `v$(cat VERSION)`, la base debe ser ese tag (hoy `v1.14.0` en
  `multi-agent` y en `main`); si aún no existe (ventana cierre→tag) se omite con aviso.
