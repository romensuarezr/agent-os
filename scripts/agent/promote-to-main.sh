#!/bin/bash
# ==============================================================================
# promote-to-main.sh — Automatización determinista de promoción y cierre de ciclo
# ==============================================================================
# Uso:
#   bash scripts/agent/promote-to-main.sh [--source <rama>] [--target <rama>] [--push] [--json]
#
# Opciones:
#   --source <rama>   Rama origen a promover (por defecto: rama activa actual).
#   --target <rama>   Rama destino (por defecto: main).
#   --push            Sube los cambios consolidados a origin <target>.
#   --skip-tests      Omite la ejecución de tests/validate-control-plane.sh.
#   --json            Emite un digest JSON estricto en stdout (logs a stderr).
#   -h, --help        Muestra esta ayuda.
# ==============================================================================

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SOURCE=""
TARGET="main"
PUSH=false
JSON_MODE=false
SKIP_TESTS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE="$2"
      shift 2
      ;;
    --target)
      TARGET="$2"
      shift 2
      ;;
    --push)
      PUSH=true
      shift
      ;;
    --skip-tests)
      SKIP_TESTS=true
      shift
      ;;
    --json)
      JSON_MODE=true
      shift
      ;;
    -h|--help)
      echo "Uso: bash scripts/agent/promote-to-main.sh [--source <rama>] [--target <rama>] [--push] [--json]"
      exit 0
      ;;
    *)
      echo "Argumento no reconocido: $1" >&2
      exit 1
      ;;
  esac
done

# Resolver rama origen por defecto si no se especificó
if [ -z "$SOURCE" ]; then
  SOURCE="$(git branch --show-current 2>/dev/null || git rev-parse --short HEAD)"
fi

log() {
  if [ "$JSON_MODE" = true ]; then
    echo -e "$*" >&2
  else
    echo -e "$*"
  fi
}

err() {
  echo -e "$*" >&2
}

emit_json() {
  local status="$1"
  local merged="$2"
  local pushed="$3"
  local commit_sha="$4"
  local target_wt="$5"
  local msg="$6"
  local code="$7"

  cat <<EOF
{
  "status": "$status",
  "source": "$SOURCE",
  "target": "$TARGET",
  "merged": $merged,
  "pushed": $pushed,
  "commit": "$commit_sha",
  "target_worktree": "$target_wt",
  "message": "$msg",
  "exit_code": $code
}
EOF
}

log "${BLUE}======================================================${NC}"
log "${BLUE}  PROMOCIÓN DETERMINISTA: ${SOURCE} ➔ ${TARGET}${NC}"
log "${BLUE}======================================================${NC}"

# 1. Comprobar que el working tree actual está limpio
log "🔍 [1/4] Verificando estado del working tree actual..."
DIRTY_FILES="$(git status --porcelain 2>/dev/null || true)"
if [ -n "$DIRTY_FILES" ]; then
  err "${RED}❌ ERROR: El working tree actual contiene archivos modificados o sin trackear:${NC}"
  err "$DIRTY_FILES"
  if [ "$JSON_MODE" = true ]; then
    emit_json "FAIL" false false "" "" "Working tree actual sucio" 1
  fi
  exit 1
fi
log "  ✅ Working tree actual limpio."

# 2. Localizar worktree donde target esté activo (si aplica)
log "🔍 [2/4] Resolviendo destino en topología de worktrees..."
find_target_worktree() {
  local target_ref="refs/heads/$1"
  local current_wt=""
  while IFS= read -r line; do
    if [[ "$line" =~ ^worktree[[:space:]]+(.*)$ ]]; then
      current_wt="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^branch[[:space:]]+(.*)$ ]]; then
      if [ "${BASH_REMATCH[1]}" = "$target_ref" ]; then
        echo "$current_wt"
        return 0
      fi
    fi
  done < <(git worktree list --porcelain)
  return 1
}

TARGET_WT="$(find_target_worktree "$TARGET" || true)"
CURRENT_WT="$(git rev-parse --show-toplevel)"

if [ -n "$TARGET_WT" ]; then
  log "  ℹ️  Rama '${TARGET}' detectada en worktree: ${TARGET_WT}"
  # Validar que TARGET_WT no tenga cambios sin commitear
  TARGET_DIRTY="$(git -C "$TARGET_WT" status --porcelain 2>/dev/null || true)"
  if [ -n "$TARGET_DIRTY" ]; then
    err "${RED}❌ ERROR: El worktree destino (${TARGET_WT}) contiene cambios pendientes:${NC}"
    err "$TARGET_DIRTY"
    if [ "$JSON_MODE" = true ]; then
      emit_json "FAIL" false false "" "$TARGET_WT" "Worktree destino sucio" 1
    fi
    exit 1
  fi
else
  log "  ℹ️  Rama '${TARGET}' no está en uso por ningún otro worktree."
fi

# 3. Comprobar que target puede avanzar fast-forward a source
if git rev-parse --verify "refs/heads/$TARGET" >/dev/null 2>&1; then
  if ! git merge-base --is-ancestor "$TARGET" "$SOURCE" 2>/dev/null; then
    err "${RED}❌ ERROR: '${TARGET}' no es ancestro de '${SOURCE}'. Se requiere rebase antes de --ff-only.${NC}"
    if [ "$JSON_MODE" = true ]; then
      emit_json "FAIL" false false "" "$TARGET_WT" "Requiere rebase, target no es ancestro" 1
    fi
    exit 1
  fi
  log "  ✅ Verificación fast-forward superada (${TARGET} es ancestro de ${SOURCE})."
fi

# 4. Ejecutar tests del control plane (si existen)
if [ "$SKIP_TESTS" = false ]; then
  if [ -f "$ROOT/tests/validate-control-plane.sh" ]; then
    log "🔍 [3/4] Ejecutando suite de validación determinista del Control Plane..."
    if ! bash "$ROOT/tests/validate-control-plane.sh" >&2; then
      err "${RED}❌ ERROR: Fallaron las pruebas del Control Plane. Promoción abortada.${NC}"
      if [ "$JSON_MODE" = true ]; then
        emit_json "FAIL" false false "" "$TARGET_WT" "Pruebas del control plane fallidas" 1
      fi
      exit 1
    fi
    log "  ✅ Control Plane 100% verificado."
  fi
else
  log "⚠️  [3/4] Tests omitidos por flag --skip-tests."
fi

# 5. Ejecutar merge fast-forward
log "🚀 [4/4] Ejecutando consolidación fast-forward en '${TARGET}'..."
MERGED_COMMIT=""

if [ -n "$TARGET_WT" ]; then
  git -C "$TARGET_WT" merge --ff-only "$SOURCE"
  MERGED_COMMIT="$(git -C "$TARGET_WT" rev-parse HEAD)"
  log "  ✅ Consolidado fast-forward en ${TARGET_WT} -> ${MERGED_COMMIT}"
  
  if [ "$PUSH" = true ]; then
    log "  📤 Empujando '${TARGET}' hacia 'origin' desde ${TARGET_WT}..."
    git -C "$TARGET_WT" push origin "$TARGET"
    log "  ✅ Push completado con éxito."
  fi
else
  ORIGINAL_BRANCH="$(git branch --show-current 2>/dev/null || true)"
  git checkout "$TARGET"
  git merge --ff-only "$SOURCE"
  MERGED_COMMIT="$(git rev-parse HEAD)"
  log "  ✅ Consolidado fast-forward en ${TARGET} -> ${MERGED_COMMIT}"

  if [ "$PUSH" = true ]; then
    log "  📤 Empujando '${TARGET}' hacia 'origin'..."
    git push origin "$TARGET"
    log "  ✅ Push completado con éxito."
  fi

  if [ -n "$ORIGINAL_BRANCH" ] && [ "$ORIGINAL_BRANCH" != "$TARGET" ]; then
    git checkout "$ORIGINAL_BRANCH"
    log "  ↩️  Restaurada rama activa: ${ORIGINAL_BRANCH}"
  fi
fi

log ""
log "${GREEN}======================================================${NC}"
log "${GREEN}  ✅ PROMOCIÓN COMPLETADA EXITOSAMENTE               ${NC}"
log "${GREEN}  Rama:   ${TARGET}                                   ${NC}"
log "${GREEN}  Commit: ${MERGED_COMMIT}                            ${NC}"
log "${GREEN}  Push:   ${PUSH}                                     ${NC}"
log "${GREEN}======================================================${NC}"

if [ "$JSON_MODE" = true ]; then
  emit_json "PASS" true "$PUSH" "$MERGED_COMMIT" "$TARGET_WT" "Promoción completada exitosamente" 0
fi

exit 0
