#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/worktree-gc.sh — Basura de worktrees huérfanos (T-107)
# ==============================================================================
# Lista (y con --apply purga) los worktrees huérfanos del repo actual:
#   - PRUNABLE: el directorio ya no existe (metadata colgada).
#   - MERGED:   su HEAD ya está integrado en la base (nada único que perder,
#               incluya o no rama: un detached limpio en un commit integrado
#               también es desechable por definición).
#
# Nunca toca: el checkout principal, worktrees bloqueados (locked), ni worktrees
# con cambios sin commitear (DIRTY-SKIP, ni siquiera con --apply: borrar trabajo
# sucio exige decisión humana explícita).
#
# Por defecto es --dry-run (solo informa). --apply ejecuta la purga.
#
# Salida JSON (--json, una línea en stdout, logs a stderr):
#   {"scanned":N,"base":"...","orphans":[...],"removed":[...],"skipped":[...],
#    "applied":bool,"exit_code":0}
# Cada entrada: {"path","branch","reason"} con reason PRUNABLE|MERGED|DIRTY-SKIP
# (y en skipped también LOCKED y REMOVE-FAILED).
# ==============================================================================
set -uo pipefail

for cmd in git python3; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ ERROR: Dependencia requerida no encontrada: $cmd" >&2
    exit 1
  fi
done

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR" || exit 1

APPLY=false
JSON_MODE=false

show_help() {
  cat << 'EOF'
Uso: scripts/agent/worktree-gc.sh [--dry-run] [--apply] [--json]

Lista los worktrees huérfanos del repo actual. Sin flags equivale a --dry-run.

  --dry-run   Solo informa (default). No toca nada.
  --apply     Purga los huérfanos (remove --force + prune). Nunca toca
              el checkout principal, bloqueados ni sucios.
  --json      Emite únicamente JSON plano a stdout.
  -h, --help  Muestra esta ayuda.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) APPLY=false; shift ;;
    --apply) APPLY=true; shift ;;
    --json) JSON_MODE=true; shift ;;
    -h|--help) show_help; exit 0 ;;
    *) echo "❌ ERROR: argumento desconocido: $1" >&2; exit 1 ;;
  esac
done

log() {
  if [ "$JSON_MODE" = false ]; then
    echo -e "$@"
  else
    echo -e "$@" >&2
  fi
}

# Base de integración: main si existe, si no master, si no HEAD.
BASE_REF="HEAD"
for b in main master; do
  if git rev-parse --verify --quiet "refs/heads/$b" >/dev/null; then
    BASE_REF="$b"
    break
  fi
done

ORPHANS=""
REMOVED=""
SKIPPED=""
SCANNED=0

WT_PATH=""; WT_HEAD=""; WT_REF=""; WT_ATTRS=""
while IFS= read -r line; do
  case "$line" in
    "worktree "*) WT_PATH="${line#worktree }" ;;
    "HEAD "*) WT_HEAD="${line#HEAD }" ;;
    "branch "*) WT_REF="${line#branch }" ;;
    "detached"|"bare") WT_REF="$line" ;;
    "locked"|"prunable"*) WT_ATTRS="${WT_ATTRS} ${line}" ;;
    "")
      if [ -n "$WT_PATH" ] && [ "$WT_PATH" != "$ROOT_DIR" ]; then
        SCANNED=$((SCANNED + 1))
        case "$WT_REF" in
          refs/heads/*) WT_BRANCH="${WT_REF#refs/heads/}" ;;
          *) WT_BRANCH="(detached)" ;;
        esac
        if [[ "$WT_ATTRS" == *"locked"* ]]; then
          SKIPPED+="${WT_PATH}|${WT_BRANCH}|LOCKED
"
          log "  🔒 ${WT_PATH}: bloqueado, no se toca."
        elif [ "$WT_BRANCH" = "$BASE_REF" ]; then
          : # posado en la rama base: checkout de integración, nunca efímero.
        elif [ ! -d "$WT_PATH" ]; then
          ORPHANS+="${WT_PATH}|${WT_BRANCH}|PRUNABLE
"
          log "  🧹 ${WT_PATH} (${WT_BRANCH}): huérfano (PRUNABLE)."
        elif [ -n "$(git -C "$WT_PATH" status --porcelain 2>/dev/null)" ]; then
          SKIPPED+="${WT_PATH}|${WT_BRANCH}|DIRTY-SKIP
"
          log "  ⏭️  ${WT_PATH} (${WT_BRANCH}): sucio, no se toca."
        elif git merge-base --is-ancestor "$WT_HEAD" "$BASE_REF" 2>/dev/null; then
          ORPHANS+="${WT_PATH}|${WT_BRANCH}|MERGED
"
          log "  🧹 ${WT_PATH} (${WT_BRANCH}): huérfano (MERGED en ${BASE_REF})."
        fi
      fi
      WT_PATH=""; WT_HEAD=""; WT_REF=""; WT_ATTRS="" ;;
  esac
done < <(git worktree list --porcelain; echo)

if [ "$APPLY" = true ]; then
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    P="${entry%%|*}"; rest="${entry#*|}"; B="${rest%%|*}"
    git worktree remove --force "$P" 2>/dev/null || rm -rf "$P" 2>/dev/null || true
    if [ "$B" != "(detached)" ]; then
      git branch -d "$B" >/dev/null 2>&1 || true
    fi
    git worktree prune 2>/dev/null || true
    if [ ! -e "$P" ] && ! git worktree list --porcelain | grep -qxF "worktree $P"; then
      REMOVED+="${entry}
"
      log "  ✅ purgado ${P}."
    else
      SKIPPED+="${P}|${B}|REMOVE-FAILED
"
      log "  ❌ no se pudo purgar ${P}."
    fi
  done <<< "$ORPHANS"
  ORPHANS=""
else
  if [ -z "$ORPHANS" ]; then
    log "  ✅ Sin worktrees huérfanos (--dry-run, nada que purgar)."
  else
    log "  ℹ️  --dry-run: nada purgado. Usa --apply para purgar."
  fi
fi

to_json_array() {
  python3 -c "
import json,sys
out=[]
for line in sys.stdin.read().splitlines():
    if not line.strip(): continue
    p,b,r = line.split('|',2)
    out.append({'path':p,'branch':b,'reason':r})
print(json.dumps(out))
"
}

if [ "$JSON_MODE" = true ]; then
  OJ="$(printf '%s' "$ORPHANS" | to_json_array)"
  RJ="$(printf '%s' "$REMOVED" | to_json_array)"
  SJ="$(printf '%s' "$SKIPPED" | to_json_array)"
  if [ "$APPLY" = true ]; then APPLIED_PY=True; else APPLIED_PY=False; fi
  python3 -c "import json; print(json.dumps({'scanned':$SCANNED,'base':'$BASE_REF','orphans':$OJ,'removed':$RJ,'skipped':$SJ,'applied':$APPLIED_PY,'exit_code':0}))"
fi
exit 0
