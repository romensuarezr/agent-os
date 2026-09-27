#!/bin/bash
# ==============================================================================
# scripts/agent/worktree-dispatch.sh — Aprovisionamiento de Git Worktrees efímeros
# ==============================================================================
# Aprovisiona un entorno aislado en .worktrees/<task-id>/ con rama
# feat/<task-id>-<profile>, inyectando variables de entorno y contexto operativo.
#
# Salida JSON compatible con orquestadores:
#   {"task_id": "...", "profile": "...", "branch": "...", "base_ref": "...", "worktree_path": "...", "agent_os_root": "...", "status": "CREATED", "exit_code": 0}
# ==============================================================================

set -uo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

TASK_ID=""
PROFILE="coder"
BASE=""
BRANCH=""
WORKTREE_PATH=""
FORCE=false
JSON_MODE=false

show_help() {
  cat << 'EOF'
Uso: scripts/agent/worktree-dispatch.sh [OPCIONES]

Opciones:
  --task-id <ID>          ID de la tarea (obligatorio, ej: T-055).
  --profile <PERFIL>      Perfil del agente asignado (coder, qa-judge, etc. Default: coder).
  --base <REF>            Rama o commit base (default: HEAD actual).
  --branch <RAMA>         Nombre de la rama aislada (default: feat/<task-id>-<profile>).
  --path <DIR>            Ruta del worktree (default: .worktrees/<task-id>).
  --force                 Limpia y recrea el worktree si ya existe.
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
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --base)
      BASE="$2"
      shift 2
      ;;
    --branch)
      BRANCH="$2"
      shift 2
      ;;
    --path)
      WORKTREE_PATH="$2"
      shift 2
      ;;
    --force)
      FORCE=true
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

# Configurar valores derivados por defecto
[ -z "$BRANCH" ] && BRANCH="feat/${TASK_ID}-${PROFILE}"
[ -z "$WORKTREE_PATH" ] && WORKTREE_PATH=".worktrees/${TASK_ID}"
[ -z "$BASE" ] && BASE="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'HEAD')"

log "🚀 [worktree-dispatch] Preparando worktree para '$TASK_ID'..."
log "   Perfil:        $PROFILE"
log "   Rama:          $BRANCH"
log "   Base:          $BASE"
log "   Ruta:          $WORKTREE_PATH"

# ------------------------------------------------------------------------------
# 1. Comprobación preventiva de inconsistencias (git worktree prune)
# ------------------------------------------------------------------------------
log "🧹 [1/4] Ejecutando saneamiento preventivo (git worktree prune)..."
git worktree prune 2>/dev/null || true

# Comprobar si ya existe la ruta en disco o en los metadatos de git
EXISTING_WORKTREES=$(git worktree list --porcelain 2>/dev/null || true)
WORKTREE_ALREADY_EXISTS=false

if [ -d "$WORKTREE_PATH" ] || echo "$EXISTING_WORKTREES" | grep -q "worktree $(realpath "$WORKTREE_PATH" 2>/dev/null || echo "$WORKTREE_PATH")"; then
  WORKTREE_ALREADY_EXISTS=true
fi

if [ "$WORKTREE_ALREADY_EXISTS" = true ]; then
  if [ "$FORCE" = true ]; then
    log "⚠️  El worktree '$WORKTREE_PATH' ya existe. Recreando debido a flag --force..."
    git worktree remove --force "$WORKTREE_PATH" 2>/dev/null || true
    rm -rf "$WORKTREE_PATH" 2>/dev/null || true
    git worktree prune 2>/dev/null || true
  else
    log "❌ ERROR: El worktree '$WORKTREE_PATH' ya existe."
    log "   Usa --force para recrearlo o elimina el anterior con: git worktree remove --force $WORKTREE_PATH"
    if [ "$JSON_MODE" = true ]; then
      python3 -c "
import json, sys
data = {
    'task_id': sys.argv[1],
    'status': 'EXISTS',
    'worktree_path': sys.argv[2],
    'branch': sys.argv[3],
    'error': 'Worktree already exists',
    'exit_code': 1
}
print(json.dumps(data))
" "$TASK_ID" "$WORKTREE_PATH" "$BRANCH"
    fi
    exit 1
  fi
fi

# Comprobar si la rama ya existe
if git rev-parse --verify "refs/heads/$BRANCH" >/dev/null 2>&1; then
  if [ "$FORCE" = true ]; then
    log "⚠️  La rama '$BRANCH' ya existe. Eliminándola debido a flag --force..."
    git branch -D "$BRANCH" 2>/dev/null || true
  else
    log "ℹ️  La rama '$BRANCH' ya existe. Reutilizando rama..."
  fi
fi

# ------------------------------------------------------------------------------
# 2. Creación del Worktree Efímero
# ------------------------------------------------------------------------------
log "📦 [2/4] Creando worktree en $WORKTREE_PATH..."
mkdir -p "$(dirname "$WORKTREE_PATH")"

if git rev-parse --verify "refs/heads/$BRANCH" >/dev/null 2>&1; then
  # Reutilizar rama existente
  git worktree add "$WORKTREE_PATH" "$BRANCH" >/dev/null
else
  # Crear nueva rama derivada de BASE
  git worktree add -b "$BRANCH" "$WORKTREE_PATH" "$BASE" >/dev/null
fi

if [ ! -d "$WORKTREE_PATH" ]; then
  log "❌ ERROR: Falló la creación del worktree en $WORKTREE_PATH."
  exit 1
fi

# ------------------------------------------------------------------------------
# 3. Inyección de Contexto y Variables de Entorno (AGENT_OS_ROOT)
# ------------------------------------------------------------------------------
log "💉 [3/4] Inyectando contexto operativo y AGENT_OS_ROOT..."
AGENT_OS_ROOT="$(git rev-parse --show-toplevel)"
REAL_WORKTREE_PATH="$(realpath "$WORKTREE_PATH")"

# Inyectar archivo de contexto local en el worktree
mkdir -p "$WORKTREE_PATH/.agents/context"
cat << EOF > "$WORKTREE_PATH/.agents/context/worktree.env"
# ==============================================================================
# Inyección de contexto para Worktree Efímero (agent-os)
# ==============================================================================
export AGENT_OS_ROOT="$AGENT_OS_ROOT"
export AGENT_OS_TASK_ID="$TASK_ID"
export AGENT_OS_PROFILE="$PROFILE"
export AGENT_OS_WORKTREE_PATH="$REAL_WORKTREE_PATH"
export AGENT_OS_BASE_REF="$BASE"
export AGENT_OS_BRANCH="$BRANCH"
EOF

# Crear enlace o asegurar disponibilidad de perfiles y scripts si fuera necesario
chmod +x "$WORKTREE_PATH/.agents/context/worktree.env"

# ------------------------------------------------------------------------------
# 4. Reporte de Éxito
# ------------------------------------------------------------------------------
log "✅ [4/4] Worktree aprovisionado satisfactoriamente."

if [ "$JSON_MODE" = true ]; then
  python3 -c "
import json, sys
data = {
    'task_id': sys.argv[1],
    'profile': sys.argv[2],
    'branch': sys.argv[3],
    'base_ref': sys.argv[4],
    'worktree_path': sys.argv[5],
    'agent_os_root': sys.argv[6],
    'status': 'CREATED',
    'exit_code': 0
}
print(json.dumps(data))
" "$TASK_ID" "$PROFILE" "$BRANCH" "$BASE" "$REAL_WORKTREE_PATH" "$AGENT_OS_ROOT"
else
  echo ""
  echo "======================================================"
  echo "  🌿 WORKTREE APROVISIONADO EXITOSAMENTE"
  echo "======================================================"
  echo "  Task ID:         $TASK_ID"
  echo "  Perfil:          $PROFILE"
  echo "  Rama asignada:   $BRANCH"
  echo "  Base ref:        $BASE"
  echo "  Ruta Worktree:   $REAL_WORKTREE_PATH"
  echo "  AGENT_OS_ROOT:   $AGENT_OS_ROOT"
  echo "======================================================"
  echo "  Para entrar al worktree:"
  echo "    cd $WORKTREE_PATH && source .agents/context/worktree.env"
  echo "======================================================"
fi

exit 0
