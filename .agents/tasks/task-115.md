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
- [ ] `fleet-version.sh [--satellites <yaml>] [--json] [rutas...]`: lee cada `last-sync.md`, compara
      con `VERSION` del core por componentes semver (no por string) y reporta `ALINEADO`,
      `DESFASE`, `LEGACY` o `AUSENTE`
- [ ] Sin satélites configurados: lo dice explícitamente y sale 0 (no inventa flota ni falla)
- [ ] Read-only verificable: 0 escrituras (`grep` de `>`, `cp`, `mv`, `git add` en su cuerpo);
      sin llamadas de red
- [ ] Digest `--json` estable (mismas claves que la vista humana) y exit 0 salvo error de uso
- [ ] Check 31 con fixture: un satélite alineado, uno desfasado, uno sin ledger y el core
      (`last-sync.md` no-ledger) — sin tocar el sistema real
- [ ] Suite completa en verde

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
