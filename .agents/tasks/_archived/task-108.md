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

📚 Research integrado (sprint-18-core-research.md, `### T-108`): `scout.sh` detectó
`semantic-release` (24.1k⭐ MIT), `release-it` (9.1k⭐ MIT) y `standard-version` (npm) →
**desarrollo a medida justificado**: las tres son del ecosistema Node/npm y el core es bash
agnóstico de stack (principio 1 de AGENTS.md). El fix son ~3 líneas sobre el script existente,
sin integración externa.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/update-changelog.sh`
- `tests/validate-control-plane.sh`

## Criterios de done
- [x] Caso de regresión: `## [Unreleased]` delante de una cabecera semver → el bump parte de la
      semver, nunca de `0.0.0` (el `0.1.0` no puede volver a generarse) — check 26 caso 1 + prueba aislada
- [x] Segunda fuente: si el changelog no tiene semver válida, se usa el último `git tag v*` — caso 2
- [x] Check 26 añadido a la suite con el caso anterior (suite 26/26 en verde)
- [x] `close-sprint.sh` no necesita cambios; T-109 se ejecuta DESPUÉS (comparten ficheros)

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-10-16 (APROBADO CON CAMBIOS, bug PREV_TAG → idea-inbox)
- [x] Rama creada: feat/T-108-semver-changelog
- [x] Lock activo: N/A (sesión en modo plan; sin Fase 4, sin lock)
- [x] Sesión cerrada correctamente
