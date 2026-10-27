# Task-109: Unificar el literal CHANGELOG.md → changelog.md

## Objetivo
Invertir la preferencia a minúsculas en `update-changelog.sh` y `close-sprint.sh` (la convención que
`audit-repo.sh` ya impone migrando) y corregir los ~40 literales de texto que apuntan a un fichero
inexistente. Incluye condensar los pasos 4b (MVP tracker) y 5 (Perplexity) de `sprint-planning.md`
con cláusulas condicionales para el core.

## Contexto técnico
Ambos scripts tienen fallback (`[ -f ] || changelog.md`, líneas 37/43) así que no rompen hoy;
el defecto es de dirección: prefieren `CHANGELOG.md` y sus mensajes mienten
(`📋 CHANGELOG.md añadido al stage`). Único literal a CONSERVAR en mayúsculas:
`audit-repo.sh:196` (detecta el nombre viejo para migrarlo — ese fichero NO se toca).
SECUENCIAL tras T-108: el fix de versión toca las líneas que esta tarea renombra.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/update-changelog.sh` (preferencia + textos)
- `scripts/agent/close-sprint.sh` (preferencia + textos)
- `.agents/workflows/changelog-workflow.md`
- `.agents/workflows/session-close.md`
- `.agents/workflows/sprint-inicial.md`
- `.agents/workflows/sprint-planning.md` (literales + cláusulas 4b/5 para el core)

## Criterios de done
- [x] `audit-repo.sh` intacto (sus líneas 195-198 siguen detectando y migrando el nombre viejo, byte-idénticas)
- [x] 0 literales engañosos `CHANGELOG.md` fuera de las líneas 195-198 de `audit-repo.sh` y de los 2 fallbacks legacy (verificar con `grep -rn`)
- [x] `sprint-planning.md` pasos 4b y 5 condicionales: se omiten si el proyecto no tiene
      `docs/MVP-TRACKER.md` / producto con stakeholders (el core) — 4 cláusulas (lista, 4b, 5, paso 7)
- [x] Suite en verde (26/26 tras T-108); sin ADR (no toca estructura); entrada en changelog
      como universalización

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-10-16 (APROBADO CON CAMBIOS: 664 a idea-inbox, 4 cláusulas, done enmendado a 195-198)
- [x] Rama creada: feat/T-109-convencion-changelog
- [x] Lock activo: N/A (sesión en modo plan; sin Fase 4, sin lock)
- [x] Sesión cerrada correctamente
