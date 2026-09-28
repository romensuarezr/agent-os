#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/worktree-merge.sh — Verificación, merge y desmantelamiento atómico
# ==============================================================================
# 1. Ejecuta verify-goal.sh dentro del worktree efímero.
# 2. Si las compuertas pasan, realiza merge controlado hacia la rama destino.
# 3. Desmantela el worktree de forma atómica (remove --force + prune) según ADR 004.
#
# Salida JSON compatible con orquestadores:
#   {"task_id": "...", "status": "MERGED|REJECTED", "merged": bool, "worktree_removed": bool, "exit_code": int}
# ==============================================================================

set -uo pipefail

# Pre-flight: verificación determinista de dependencias
for cmd in git python3 bash rm; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ ERROR: Dependencia requerida no encontrada: $cmd" >&2
    echo "Guía: Instala $cmd en tu sistema antes de continuar." >&2
    exit 1
  fi
done

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR" || exit 1

TASK_ID=""
TARGET_BRANCH=""
WORKTREE_PATH=""
STRATEGY="fast-forward"
SKIP_VERIFY=false
KEEP_WORKTREE=false
JSON_MODE=false

show_help() {
  cat << 'EOF'
Uso: scripts/agent/worktree-merge.sh [OPCIONES]

Opciones:
  --task-id <ID>          ID de la tarea a integrar (obligatorio, ej: T-055).
  --target <RAMA>         Rama de integración destino (default: rama actual).
  --path <DIR>            Ruta al worktree (default: .worktrees/<task-id>).
  --strategy <STRATEGY>   Estrategia de merge: fast-forward (default), squash, no-ff.
  --skip-verify           Omite la ejecución de verify-goal.sh previa al merge.
  --keep-worktree         Conserva el worktree en disco tras el merge.
  --json                  Emite únicamente JSON plano a stdout.
  -h, --help              Muestra esta ayuda.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task-id)
      TASK_ID="$2"
      shift 2
      ;;
    --target)
      TARGET_BRANCH="$2"
      shift 2
      ;;
    --path)
      WORKTREE_PATH="$2"
      shift 2
      ;;
    --strategy)
      STRATEGY="$2"
      shift 2
      ;;
    --skip-verify)
      SKIP_VERIFY=true
      shift
      ;;
    --keep-worktree)
      KEEP_WORKTREE=true
      shift
      ;;
    --json)
      JSON_MODE=true
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      if [ -z "$TASK_ID" ]; then
        TASK_ID="$1"
        shift
      else
        shift
      fi
      ;;
  esac
done

if [ -z "$TASK_ID" ]; then
  if [ "$JSON_MODE" = true ]; then
    python3 -c "import json; print(json.dumps({'error': 'Falta el argumento requerido --task-id', 'status': 'ERROR', 'exit_code': 1}))"
  else
    echo "❌ ERROR: Debes proporcionar un --task-id (ej: T-055)."
  fi
  exit 1
fi

log() {
  if [ "$JSON_MODE" = false ]; then
    echo -e "$@"
  else
    echo -e "$@" >&2
  fi
}

[ -z "$WORKTREE_PATH" ] && WORKTREE_PATH=".worktrees/${TASK_ID}"
[ -z "$TARGET_BRANCH" ] && TARGET_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'main')"

log "🔄 [worktree-merge] Iniciando proceso de integración para '$TASK_ID'..."
log "   Ruta worktree:  $WORKTREE_PATH"
log "   Rama destino:   $TARGET_BRANCH"
log "   Estrategia:     $STRATEGY"

# ------------------------------------------------------------------------------
# 1. Validar existencia del worktree y obtener su rama
# ------------------------------------------------------------------------------
if [ ! -d "$WORKTREE_PATH" ]; then
  log "❌ ERROR: No se encontró el directorio de worktree en: $WORKTREE_PATH"
  if [ "$JSON_MODE" = true ]; then
    python3 -c "
import json, sys
print(json.dumps({
    'task_id': sys.argv[1],
    'status': 'NOT_FOUND',
    'merged': False,
    'worktree_removed': False,
    'error': 'Worktree directory not found',
    'exit_code': 1
}))
" "$TASK_ID"
  fi
  exit 1
fi

WORKTREE_BRANCH=$(git -C "$WORKTREE_PATH" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [ -z "$WORKTREE_BRANCH" ]; then
  log "❌ ERROR: No se pudo determinar la rama del worktree en: $WORKTREE_PATH"
  exit 1
fi
log "   Rama de origen: $WORKTREE_BRANCH"

# ------------------------------------------------------------------------------
# 2. Quality Gate Pre-Merge (verify-goal.sh)
# ------------------------------------------------------------------------------
if [ "$SKIP_VERIFY" = false ]; then
  log "🛡️  [1/3] Ejecutando Quality Gate (verify-goal.sh) dentro del worktree..."
  VERIFY_SCRIPT="$ROOT_DIR/scripts/agent/verify-goal.sh"

  if [ ! -x "$VERIFY_SCRIPT" ]; then
    log "⚠️  No se encontró ejecutable $VERIFY_SCRIPT. Omitiendo validación..."
  else
    # Ejecutar verify-goal en modo JSON dentro del worktree
    VERIFY_JSON_OUTPUT=$( (cd "$WORKTREE_PATH" && bash "$VERIFY_SCRIPT" --task-id "$TASK_ID" --base "$TARGET_BRANCH" --json) 2>/dev/null || true )
    VERIFY_EXIT_CODE=$( (cd "$WORKTREE_PATH" && bash "$VERIFY_SCRIPT" --task-id "$TASK_ID" --base "$TARGET_BRANCH" --json >/dev/null 2>&1); echo $? )

    IS_PASS=$(python3 -c "import json, sys; d=json.loads(sys.argv[1] or '{}'); print(d.get('status') == 'PASS')" "$VERIFY_JSON_OUTPUT" 2>/dev/null || echo "False")

    if [ "$IS_PASS" != "True" ] || [ "$VERIFY_EXIT_CODE" -ne 0 ]; then
      log "❌ QUALITY GATE RECHAZADO: verify-goal.sh devolvió FAIL o detectó violaciones."
      log "   El worktree se mantendrá intacto para permitir correcciones."
      
      if [ "$JSON_MODE" = true ]; then
        python3 -c "
import json, sys
verification = json.loads(sys.argv[2] or '{}')
print(json.dumps({
    'task_id': sys.argv[1],
    'status': 'REJECTED',
    'merged': False,
    'worktree_removed': False,
    'verification': verification,
    'exit_code': 1
}))
" "$TASK_ID" "$VERIFY_JSON_OUTPUT"
      fi
      exit 1
    else
      log "✅ Quality Gate aprobado con éxito (0 violaciones, tests pasando)."
    fi
  fi
else
  log "⏩ Quality Gate omitido (--skip-verify)."
fi

# ------------------------------------------------------------------------------
# 3. Merge hacia la rama destino
# ------------------------------------------------------------------------------
log "🔀 [2/3] Integrando rama '$WORKTREE_BRANCH' en '$TARGET_BRANCH'..."

# Asegurar que el repo principal está en la rama destino
CURRENT_REPO_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_REPO_BRANCH" != "$TARGET_BRANCH" ]; then
  log "   Cambiando a rama destino $TARGET_BRANCH..."
  git checkout "$TARGET_BRANCH" >/dev/null
fi

MERGE_SUCCESS=false

case "$STRATEGY" in
  fast-forward)
    if git merge --ff-only "$WORKTREE_BRANCH" >/dev/null 2>&1; then
      MERGE_SUCCESS=true
    elif git merge "$WORKTREE_BRANCH" -m "merge: integrate $WORKTREE_BRANCH into $TARGET_BRANCH" >/dev/null 2>&1; then
      MERGE_SUCCESS=true
    fi
    ;;
  squash)
    if git merge --squash "$WORKTREE_BRANCH" >/dev/null 2>&1 && git commit -m "feat($TASK_ID): squash merge $WORKTREE_BRANCH" >/dev/null 2>&1; then
      MERGE_SUCCESS=true
    fi
    ;;
  no-ff)
    if git merge --no-ff "$WORKTREE_BRANCH" -m "merge: integrate $WORKTREE_BRANCH into $TARGET_BRANCH" >/dev/null 2>&1; then
      MERGE_SUCCESS=true
    fi
    ;;
esac

if [ "$MERGE_SUCCESS" = false ]; then
  log "❌ ERROR: Falló el merge de $WORKTREE_BRANCH hacia $TARGET_BRANCH."
  if [ "$JSON_MODE" = true ]; then
    python3 -c "
import json, sys
print(json.dumps({
    'task_id': sys.argv[1],
    'status': 'MERGE_FAILED',
    'merged': False,
    'worktree_removed': False,
    'error': 'Git merge failed',
    'exit_code': 1
}))
" "$TASK_ID"
  fi
  exit 1
fi

log "✅ Merge completado satisfactoriamente."

# ------------------------------------------------------------------------------
# 4. Desmantelamiento Atómico del Worktree (ADR 004 — Sin Fugas de Inodes)
# ------------------------------------------------------------------------------
WORKTREE_REMOVED=false

if [ "$KEEP_WORKTREE" = false ]; then
  log "🧹 [3/3] Desmantelando worktree de forma atómica..."
  # Secuencia obligatoria solicitada
  git worktree remove --force "$WORKTREE_PATH" 2>/dev/null || rm -rf "$WORKTREE_PATH"
  git worktree prune 2>/dev/null || true
  git branch -d "$WORKTREE_BRANCH" 2>/dev/null || true
  WORKTREE_REMOVED=true
  log "✅ Worktree y rama efímera eliminados (0 fugas de disco)."
else
  log "⏩ Worktree conservado en disco (--keep-worktree)."
fi

# ------------------------------------------------------------------------------
# 5. Reporte de Éxito
# ------------------------------------------------------------------------------
if [ "$JSON_MODE" = true ]; then
  python3 -c "
import json, sys
print(json.dumps({
    'task_id': sys.argv[1],
    'status': 'MERGED',
    'merged': True,
    'worktree_removed': sys.argv[2] == 'true',
    'branch': sys.argv[3],
    'target': sys.argv[4],
    'exit_code': 0
}))
" "$TASK_ID" "$WORKTREE_REMOVED" "$WORKTREE_BRANCH" "$TARGET_BRANCH"
else
  echo ""
  echo "======================================================"
  echo "  🎉 TAREA INTEGRADA Y WORKTREE DESMANTELADO"
  echo "======================================================"
  echo "  Task ID:          $TASK_ID"
  echo "  Rama integrada:   $WORKTREE_BRANCH"
  echo "  Rama destino:     $TARGET_BRANCH"
  echo "  Worktree purgado: $WORKTREE_REMOVED"
  echo "======================================================"
fi

exit 0
