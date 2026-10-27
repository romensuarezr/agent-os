# Task-115: Versión del core en la flota (vista agregada de desfase)

## Objetivo
Cerrar la última pieza del versionado: una vista **read-only y determinista** del desfase entre la
versión del core y la que cada satélite registró en su `.agents/context/last-sync.md`. Alcance mínimo:
una tabla en una pantalla + digest `--json`. Sin dashboards, sin red, sin escrituras.

## Contexto técnico
El dato ya existe: `install.sh:792-805` y `sync.sh:519-534` escriben
`.agents/context/last-sync.md` (`fecha`, `version:`, `tag:`, `commit:`), y `audit-child.sh:224-236`
compara por hijo y avisa. Falta la vista agregada. Descubrimiento de satélites:
`.agents/config/satellites.yaml` (esquema distribuido, ejemplos comentados) o `fleet.yaml`
(estado local, gitignored). El `last-sync.md` del propio core **no** es el ledger (es un documento a
mano): debe clasificarse como `SELF`/`LEGACY` y no romper la herramienta. Caso real: `ops-hub`
arrancó con el core del 5-6 oct; el core ya es `v1.14.0`.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/fleet-version.sh` (nuevo, ejecutable)
- `tests/validate-control-plane.sh` (check 31)
- `docs/runbooks/` (runbook de flota si existe; si no, nota en `docs/runbooks/sprint-close.md` o el
  runbook de instalación; decidir en el plan y no crear un fichero nuevo si hay uno adecuado)

## Criterios de done
- [x] `fleet-version.sh [--satellites <yaml>] [--json] [rutas...]`: lee cada `last-sync.md`, compara
      con `VERSION` del core por componentes semver (no por string) y reporta `ALINEADO`,
      `DESFASE`, `LEGACY`, `AUSENTE` o `SELF`
- [x] Sin satélites configurados: lo dice explícitamente y sale 0 (no inventa flota ni falla)
- [x] Read-only verificable: snapshot del árbol antes/después idéntico + grep estático de
      escrituras (`>>`, `cp`, `mv`, `rm`, `tee`, `git add`) y de red (`curl`, `wget`, `ssh`,
      `git fetch/pull`)
- [x] Digest `--json` estable (mismas claves que la vista humana) y exit 0 salvo error de uso
- [x] Check 31 con fixture: un satélite alineado, uno desfasado, uno legacy, uno sin ledger y el
      core (`last-sync.md` no-ledger) — sin tocar el sistema real
- [x] Suite completa en verde (31/31)

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — 2026-10-27
- [x] Rama creada: `feat/T-115-fleet-version`
- [x] Lock activo: `.agent-session.lock`
- [x] Sesión cerrada correctamente

## Notas de implementación

- **Descubrimiento**: `fleet.yaml` no declara rutas de repo (su esquema es `nodes/services`), así que
  solo se usa si contiene un bloque `satellites:`; si no, `.agents/config/satellites.yaml`. Las
  rutas posicionales (`rutas...`) se añaden a lo que venga de la declaración, nunca la sustituyen.
- **SELF**: se detecta por ruta real igual al core, o por el encabezado
  `# last-sync.md — Estado operativo del core`. Nunca se interpreta como ledger.
- **Semver**: `^[0-9]+\.[0-9]+(\.[0-9]+)?$` (patch opcional = 0), comparación por componentes en
  bash puro con normalización `10#` (evita el octal `08`). Sin `sort -V`.
- **`delta`**: magnitud en el nivel más alto donde difieren (major/minor/patch), no un vector
  acumulado; `direction` indica `atras`/`adelante`.
- **Dedupe** por ruta real; se conserva el primer alias. `~/` se expande contra `$HOME`.
- **Exit**: 0 siempre que la lectura se complete (también con `DESFASE`), 1 si el core no tiene
  `VERSION` legible, 2 en error de uso.
- `sync.sh:348` distribuye `scripts/agent/*.sh`, así que el script nuevo llega a los hijos sin tocar
  el manifest.
