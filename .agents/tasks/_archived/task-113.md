# Task-113: El cierre de sprint escribe `VERSION`

## Objetivo
Que `close-sprint.sh` escriba el fichero `VERSION` de la raíz con la versión que ya detecta en el
changelog, dentro del mismo commit de archivado, y que un check de la suite verifique que tras el
cierre `VERSION` coincide con la entrada superior de `changelog.md`.

## Contexto técnico
`close-sprint.sh:112-122` ya calcula `VERSION_TAG` desde la primera entrada `## [` del changelog y
lo usa en el mensaje del commit (`:170-171`), pero nunca escribe `VERSION`. La release `v1.14.0` se
publicó con `VERSION = 1.12.0` (dos releases de retraso). `VERSION` ya es canónico para
`install.sh:196-217`/`:796-805`, `sync.sh:522-523` y `audit-child.sh:80-99`/`:224-236`, así que el
desfase se propaga al ledger de los satélites.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/close-sprint.sh` (escritura de `VERSION` + staging acotado)
- `tests/validate-control-plane.sh` (check 30)
- `.agents/workflows/session-close.md` (si menciona el cierre y hay que dejar constancia)

## Criterios de done
- [x] `close-sprint.sh` escribe `VERSION` con `VERSION_TAG` cuando lo detecta; si no lo detecta,
      avisa y **no** toca el fichero (nunca escribe `unknown`)
- [x] `VERSION` entra en el staging acotado y viaja en el commit de archivado, no en uno posterior
- [x] Idempotente: si `VERSION` ya tiene el valor, no produce cambios en el árbol
- [x] Check 30: falla si `VERSION` ≠ primera versión semver del changelog; prueba negativa
      con fixture temporal (no depende del estado real del repo)
- [x] Suite completa en verde (30/30), sin regresión de los checks 26/28/29

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO — 2026-10-27 (cambio: lectura por primera cabecera CON semver, regla T-108)
- [x] Rama creada: `feat/T-113-version-auto` (desde `multi-agent`)
- [x] Lock activo: `.agent-session.lock`
- [x] Sesión cerrada correctamente

## Notas de implementación
- La extracción del mensaje de commit (`close-sprint.sh:120`) tenía el mismo bug de T-108
  (`grep -m1 '^## \['`, que casa con `Unreleased`). Se sustituyó por la lib: un solo guard y una
  sola regla. Verificado en fixture: el commit pasa a `chore: archive sprint-99-core [v1.15.0]`.
- `agent_sync_version` solo escribe cuando `CHANGELOG_MODIFIED` es cierto: si no, la primera versión
  del changelog es la anterior y escribirla sería un retroceso. En ese caso avisa y no toca nada.
