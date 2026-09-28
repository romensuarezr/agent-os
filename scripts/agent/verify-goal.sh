#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/verify-goal.sh — Verificador determinista de metas a 0 tokens
# ==============================================================================
# Audita de forma determinista (sin consumo de inferencia):
#   1. Working tree limpio (git status --porcelain).
#   2. Caja de Archivos Autorizados (git diff contra allowlist).
#   3. Ejecución de suite de pruebas (validate-control-plane o test runner).
#
# Salida JSON compatible con orquestadores:
#   {"task_id": "...", "status": "PASS|FAIL", "allowlist_pass": bool, "tests_pass": bool, "violations": [...], "exit_code": int}
# ==============================================================================

set -uo pipefail

# Pre-flight: verificación determinista de dependencias
for cmd in git python3 sed sort cut xargs cat; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ ERROR: Dependencia requerida no encontrada: $cmd" >&2
    echo "Guía: Instala $cmd en tu sistema antes de continuar." >&2
    exit 1
  fi
done

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR" || exit 1

# Argumentos por defecto
TASK_ID=""
BASE=""
ALLOWLIST_ARG=""
ALLOWLIST_FILE=""
JSON_MODE=false
SKIP_TESTS=false
ALLOW_DIRTY=false
TEST_CMD=""

show_help() {
  cat << 'EOF'
Uso: scripts/agent/verify-goal.sh [OPCIONES]

Opciones:
  --task-id <ID>          ID de la tarea o meta (ej: T-054).
  --base <REF>            Rama o commit base para calcular el diff.
  --allowlist <LISTA>     Lista separada por comas o espacios de archivos autorizados.
  --allowlist-file <PATH> Archivo con rutas autorizadas (una por línea, JSON o markdown).
  --test-cmd <CMD>        Comando para ejecutar tests (ej: "npm test").
  --skip-tests            Omite la ejecución de tests.
  --allow-dirty           Permite working tree con cambios sin commitear (modo WIP).
  --json                  Emite únicamente JSON plano a stdout.
  -h, --help              Muestra esta ayuda.
EOF
}

# Parseo de flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --task-id)
      TASK_ID="$2"
      shift 2
      ;;
    --base)
      BASE="$2"
      shift 2
      ;;
    --allowlist)
      ALLOWLIST_ARG="$2"
      shift 2
      ;;
    --allowlist-file)
      ALLOWLIST_FILE="$2"
      shift 2
      ;;
    --test-cmd)
      TEST_CMD="$2"
      shift 2
      ;;
    --skip-tests)
      SKIP_TESTS=true
      shift
      ;;
    --allow-dirty)
      ALLOW_DIRTY=true
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

# Resolver TASK_ID si no se proporcionó
if [ -z "$TASK_ID" ]; then
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  if [[ "$CURRENT_BRANCH" =~ feat/([A-Za-z0-9_-]+) ]]; then
    TASK_ID="${BASH_REMATCH[1]}"
  elif [ -f ".agent-session.lock" ]; then
    TASK_ID=$(python3 -c "import json; print(json.load(open('.agent-session.lock')).get('task', 'UNKNOWN'))" 2>/dev/null || echo "UNKNOWN")
  else
    TASK_ID="GOAL-UNKNOWN"
  fi
fi

# Resolución de fallback determinista solicitada
BASE_REF="${BASE:-$(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main 2>/dev/null || git rev-parse HEAD~1 2>/dev/null || echo "HEAD")}"

log() {
  if [ "$JSON_MODE" = false ]; then
    echo -e "$@"
  else
    echo -e "$@" >&2
  fi
}

log "🔍 [verify-goal] Iniciando verificación determinista para '$TASK_ID'..."
log "   Rama actual: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'detached')"
log "   Base ref:    $BASE_REF"

# ------------------------------------------------------------------------------
# 1. Comprobación de Working Tree Limpio
# ------------------------------------------------------------------------------
UNCOMMITTED_CHANGES=$(git status --porcelain -uall 2>/dev/null || true)
WORKING_TREE_CLEAN=true
if [ -n "$UNCOMMITTED_CHANGES" ]; then
  WORKING_TREE_CLEAN=false
  log "⚠️  Working tree NO está limpio (archivos modificados o untracked pendientes):"
  while IFS= read -r line; do
    log "     $line"
  done <<< "$UNCOMMITTED_CHANGES"
else
  log "✅ Working tree limpio (0 cambios pendientes)."
fi

# ------------------------------------------------------------------------------
# 2. Recopilar Caja de Archivos Autorizados (Allowlist)
# ------------------------------------------------------------------------------
declare -a ALLOWLIST=()

# A. Desde argumento directo
if [ -n "$ALLOWLIST_ARG" ]; then
  IFS=',' read -r -a parsed_args <<< "$ALLOWLIST_ARG"
  for item in "${parsed_args[@]}"; do
    cleaned=$(echo "$item" | xargs)
    [ -n "$cleaned" ] && ALLOWLIST+=("$cleaned")
  done
fi

# B. Desde archivo explícito
if [ -n "$ALLOWLIST_FILE" ] && [ -f "$ALLOWLIST_FILE" ]; then
  while IFS= read -r line; do
    cleaned=$(echo "$line" | sed 's/^[-*][[:space:]]*//; s/`//g; s/"//g; s/'\''//g' | xargs)
    [ -n "$cleaned" ] && ALLOWLIST+=("$cleaned")
  done < "$ALLOWLIST_FILE"
fi

# C. Fallback: desde .agent-session.lock
if [ ${#ALLOWLIST[@]} -eq 0 ] && [ -f ".agent-session.lock" ]; then
  while IFS= read -r item; do
    [ -n "$item" ] && ALLOWLIST+=("$item")
  done < <(python3 -c "
import json
try:
    d = json.load(open('.agent-session.lock'))
    for f in d.get('authorized_files', []):
        print(f)
except Exception:
    pass
" 2>/dev/null || true)
fi

# D. Fallback: desde .agents/tasks/task-${TASK_ID}.md
TASK_FILE=".agents/tasks/task-${TASK_ID}.md"
if [ ${#ALLOWLIST[@]} -eq 0 ] && [ -f "$TASK_FILE" ]; then
  in_box=false
  while IFS= read -r line; do
    if [[ "$line" =~ ^##[[:space:]]*Caja[[:space:]]*de[[:space:]]*archivos ]]; then
      in_box=true
      continue
    elif [[ "$line" =~ ^##[[:space:]] ]] && [ "$in_box" = true ]; then
      break
    fi
    if [ "$in_box" = true ] && [[ "$line" =~ ^[[:space:]]*-[[:space:]]*\`([^\`]+)\` ]]; then
      ALLOWLIST+=("${BASH_REMATCH[1]}")
    fi
  done < "$TASK_FILE"
fi

# Eliminar duplicados en ALLOWLIST
if [ ${#ALLOWLIST[@]} -gt 0 ]; then
  # shellcheck disable=SC2207
  IFS=$'\n' ALLOWLIST=($(sort -u <<<"${ALLOWLIST[*]}"))
  unset IFS
fi

log "📋 Archivos autorizados en allowlist: ${#ALLOWLIST[@]}"
for a in "${ALLOWLIST[@]}"; do
  log "   - $a"
done

# ------------------------------------------------------------------------------
# 3. Cálculo de Diff y Validación de Violaciones de Caja
# ------------------------------------------------------------------------------
declare -a MODIFIED_FILES=()
while IFS= read -r f; do
  [ -n "$f" ] && MODIFIED_FILES+=("$f")
done < <(git diff --name-only "$BASE_REF"...HEAD 2>/dev/null || true)

# Incluir también cualquier archivo en working tree si no está limpio
if [ -n "$UNCOMMITTED_CHANGES" ]; then
  while IFS= read -r line; do
    fname=$(echo "$line" | cut -c4- | xargs)
    if [ -n "$fname" ]; then
      MODIFIED_FILES+=("$fname")
    fi
  done <<< "$UNCOMMITTED_CHANGES"
fi

# Eliminar duplicados en MODIFIED_FILES
if [ ${#MODIFIED_FILES[@]} -gt 0 ]; then
  # shellcheck disable=SC2207
  IFS=$'\n' MODIFIED_FILES=($(sort -u <<<"${MODIFIED_FILES[*]}"))
  unset IFS
fi

log "🔍 Archivos tocados en diff ($BASE_REF...HEAD): ${#MODIFIED_FILES[@]}"

declare -a VIOLATIONS=()

for modified in "${MODIFIED_FILES[@]}"; do
  is_allowed=false
  for allowed in "${ALLOWLIST[@]}"; do
    # Coincidencia exacta o por patrón glob
    if [[ "$modified" == "$allowed" ]] || [[ "$modified" == "$allowed"/* ]]; then
      is_allowed=true
      break
    fi
  done
  if [ "$is_allowed" = false ]; then
    VIOLATIONS+=("$modified")
  fi
done

ALLOWLIST_PASS=true
if [ ${#VIOLATIONS[@]} -gt 0 ]; then
  ALLOWLIST_PASS=false
  log "❌ VIOLACIÓN DETECTADA: Archivos fuera de la caja autorizada:"
  for v in "${VIOLATIONS[@]}"; do
    log "     ❌ $v"
  done
else
  log "✅ Allowlist respetada (0 violaciones de caja)."
fi

# ------------------------------------------------------------------------------
# 4. Ejecución Determinista de la Suite de Pruebas
# ------------------------------------------------------------------------------
TESTS_PASS=true

if [ "$SKIP_TESTS" = false ]; then
  if [ -z "$TEST_CMD" ]; then
    # Auto-detección
    if [ -x "tests/validate-control-plane.sh" ]; then
      TEST_CMD="bash tests/validate-control-plane.sh"
    elif [ -f "package.json" ] && grep -q '"test"' "package.json"; then
      TEST_CMD="npm test"
    elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
      TEST_CMD="pytest"
    fi
  fi

  if [ -n "$TEST_CMD" ]; then
    log "🧪 Ejecutando suite de pruebas: $TEST_CMD"
    if [ "$JSON_MODE" = true ]; then
      TEST_OUTPUT=$($TEST_CMD 2>&1)
      TEST_CODE=$?
      if [ $TEST_CODE -ne 0 ]; then
        TESTS_PASS=false
        log "❌ Suite de pruebas falló (exit code $TEST_CODE)."
        log "$TEST_OUTPUT"
      else
        log "✅ Suite de pruebas exitosa."
      fi
    else
      if $TEST_CMD; then
        log "✅ Suite de pruebas exitosa."
      else
        TESTS_PASS=false
        log "❌ Suite de pruebas falló."
      fi
    fi
  else
    log "ℹ️  Sin runner de tests detectado, compuerta de tests omitida."
  fi
else
  log "⏩ Pruebas omitidas (--skip-tests)."
fi

# ------------------------------------------------------------------------------
# 5. Determinación de Veredicto Final y Código de Salida
# ------------------------------------------------------------------------------
OVERALL_STATUS="PASS"
FINAL_EXIT_CODE=0

if [ "$ALLOWLIST_PASS" = false ] || [ "$TESTS_PASS" = false ] || { [ "$WORKING_TREE_CLEAN" = false ] && [ "$ALLOW_DIRTY" = false ]; }; then
  OVERALL_STATUS="FAIL"
  FINAL_EXIT_CODE=1
fi

# Construir JSON de violaciones
if [ ${#VIOLATIONS[@]} -eq 0 ]; then
  VIOLATIONS_JSON="[]"
else
  VIOLATIONS_JSON=$(python3 -c "import json, sys; print(json.dumps(sys.argv[1:]))" "${VIOLATIONS[@]}")
fi

if [ "$JSON_MODE" = true ]; then
  # Emisión estricta a stdout de JSON plano válido
  python3 -c "
import json, sys
data = {
    'task_id': sys.argv[1],
    'status': sys.argv[2],
    'allowlist_pass': sys.argv[3] == 'true',
    'tests_pass': sys.argv[4] == 'true',
    'violations': json.loads(sys.argv[5]),
    'exit_code': int(sys.argv[6])
}
print(json.dumps(data))
" "$TASK_ID" "$OVERALL_STATUS" "$ALLOWLIST_PASS" "$TESTS_PASS" "$VIOLATIONS_JSON" "$FINAL_EXIT_CODE"
else
  echo ""
  echo "======================================================"
  if [ "$OVERALL_STATUS" = "PASS" ]; then
    echo "  🎉 VEREDICTO DE META: PASS (Todas las compuertas aprobadas)"
  else
    echo "  ❌ VEREDICTO DE META: FAIL (Compuertas no superadas)"
  fi
  echo "======================================================"
  echo "  Task ID:        $TASK_ID"
  echo "  Working tree:   $( [ "$WORKING_TREE_CLEAN" = true ] && echo "Clean" || echo "Dirty" )"
  echo "  Allowlist Pass: $ALLOWLIST_PASS (${#VIOLATIONS[@]} violaciones)"
  echo "  Tests Pass:     $TESTS_PASS"
  echo "  Código salida:  $FINAL_EXIT_CODE"
  echo "======================================================"
fi

exit "$FINAL_EXIT_CODE"
