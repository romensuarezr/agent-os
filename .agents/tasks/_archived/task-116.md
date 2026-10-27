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
- [x] Sobre un directorio que no es repo git: veredicto explícito **no verificable** y exit **2**;
      nunca "limpio". Aplica también a `--staged` (antes decía "nada en staging")
- [x] Los ficheros sin trackear se escanean **por defecto** (`--others --exclude-standard`), con
      `--tracked-only` como opt-out; los ignorados por `.gitignore` no se escanean
- [x] Check 22 ampliado: no-repo (exit 2 sin "limpio"), untracked con literal (exit 1), ignorado
      untracked (exit 0) y `--tracked-only` (exit 0)
- [x] `--path` y las excepciones del repo escaneado siguen funcionando (check 27 en verde)
- [x] Suite completa en verde (31/31)

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — 2026-10-27
- [x] Rama creada: `feat/T-116-locator-honesty`
- [x] Lock activo: `.agent-session.lock`
- [x] Sesión cerrada correctamente

## Notas de implementación

- Guardia `git -C "$ROOT" rev-parse --git-dir` justo después de parsear argumentos: si falla,
  stderr `❌ No verificable: '<ruta>' no es un repositorio git (nada escaneado).` y `exit 2`.
  Cubre el bug de `--staged` en un no-repo (el `|| true` de `git diff --cached` dejaba FILES vacío
  y el script decía "nada en staging" con exit 0).
- Enumeración: `--staged` → índice; `--tracked-only` → `ls-files --cached`; por defecto →
  `ls-files --cached --others --exclude-standard` (tracked + untracked no ignorados).
- El fixture de la suite construye el literal en runtime (`printf '/%s/ana/...' home`) para no
  autoincumplir el check 22 al vivir el propio test en el repo escaneado.
- `--help` recorta la cabecera hasta la línea 30 (banner de cierre); si la cabecera crece, ajustar.
