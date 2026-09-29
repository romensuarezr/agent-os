#!/usr/bin/env bash
# check-session.sh — Detecta si hay una sesión de Antigravity abierta.
# Uso: bash scripts/agent/check-session.sh
# Salida:
#   exit 0 + "NO_ACTIVE_SESSION" → no hay sesión abierta, seguro proceder
#   exit 1 + JSON del lock       → hay sesión sin cerrar, activar Modo Rescate
#   exit 0 + "WARNING: ..."      → no hay lock pero hay cambios en src/ sin commitear
# ==============================================================================
# COMPROBACIÓN DE ACTUALIZACIONES DEL CORE
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/cli-help.sh"
for arg in "$@"; do
  if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
    show_help "check-session.sh" \
      "bash scripts/agent/check-session.sh" \
      "Detecta si existe una sesión de desarrollo activa, verifica el lock .agent-session.lock y el estado del árbol de trabajo." \
      "-h, --help               Muestra este mensaje de ayuda" \
      "ejemplo: bash scripts/agent/check-session.sh"
  fi
done

# Pre-flight de dependencias básicas
for cmd in git bash sed awk date; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "❌ ERROR: Dependencia requerida no encontrada: $cmd" >&2
    exit 1
  fi
done
if [ -f "$SCRIPT_DIR/lib/date-utils.sh" ]; then
  source "$SCRIPT_DIR/lib/date-utils.sh"
fi
if [ -f "$SCRIPT_DIR/lib/portable-timeout.sh" ]; then
  source "$SCRIPT_DIR/lib/portable-timeout.sh"
fi

DEFAULT_CORE="$(cd "$SCRIPT_DIR/../.." && pwd)"
AGENT_OS_CORE_DIR="${AGENT_OS_PATH:-}"
if [ -z "$AGENT_OS_CORE_DIR" ]; then
  if [ -d "$DEFAULT_CORE/.git" ] && git -C "$DEFAULT_CORE" remote -v 2>/dev/null | grep -q "agent-os"; then
    AGENT_OS_CORE_DIR="$DEFAULT_CORE"
  fi
fi

# Omitir si estamos dentro del propio repositorio core de agent-os (incluso en worktrees)
CURRENT_REPO_RAW=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
CURRENT_REPO_NAME=""
[ -n "$CURRENT_REPO_RAW" ] && CURRENT_REPO_NAME=$(basename "$CURRENT_REPO_RAW" 2>/dev/null || echo "")

REAL_CURRENT=$(pwd -P)
REAL_CORE=""
if [ -n "$AGENT_OS_CORE_DIR" ]; then
  REAL_CORE=$( (cd "$AGENT_OS_CORE_DIR" 2>/dev/null && pwd -P) || echo "$AGENT_OS_CORE_DIR" )
fi

GIT_COMMON_RAW=$(git rev-parse --git-common-dir 2>/dev/null || echo "")
GIT_COMMON_DIR=""
if [ -n "$GIT_COMMON_RAW" ]; then
  GIT_COMMON_DIR=$( (cd "$GIT_COMMON_RAW" 2>/dev/null && pwd -P) || echo "$GIT_COMMON_RAW" )
fi

ORIGIN_URL=$(git config --get remote.origin.url 2>/dev/null || git remote get-url origin 2>/dev/null || echo "")

if [ "$CURRENT_REPO_NAME" = "agent-os" ] || \
   { [ -n "$REAL_CORE" ] && [ "$REAL_CURRENT" = "$REAL_CORE" ]; } || \
   [[ "$GIT_COMMON_DIR" == *"agent-os/.git"* ]] || \
   [[ "$ORIGIN_URL" =~ romensuarezr/agent-os(\.git)?$ ]] || \
   [[ "$ORIGIN_URL" =~ /agent-os(\.git)?$ ]]; then
  is_core=true
else
  is_core=false
fi

if [ "$is_core" = "false" ]; then
  LAST_SYNC_FILE=".agents/context/last-sync.md"
  CHANGELOG_FILE=".agents/context/agent-os-changelog.md"
  
  # 1. Leer fecha de última sync (primer token de la primera línea para retrocompatibilidad)
  LAST_SYNC_DATE=""
  if [ -f "$LAST_SYNC_FILE" ]; then
    LAST_SYNC_DATE=$(head -n 1 "$LAST_SYNC_FILE" 2>/dev/null | sed 's/skipped: //g' | awk '{print $1}' || echo "")
  fi
  
  REQUIRES_CHECK_BY_TIME=false
  if [ -z "$LAST_SYNC_DATE" ]; then
    REQUIRES_CHECK_BY_TIME=true
  fi
  
  # Calcular días transcurridos si hay fecha
  if [ "$REQUIRES_CHECK_BY_TIME" = "false" ]; then
    LAST_SYNC_EPOCH=$(portable_epoch "$LAST_SYNC_DATE" 2>/dev/null || echo 0)
    CURRENT_EPOCH=$(date +%s)
    DIFF_SECONDS=$((CURRENT_EPOCH - LAST_SYNC_EPOCH))
    DIFF_DAYS=$((DIFF_SECONDS / 86400))
    if [ "$DIFF_DAYS" -ge 7 ]; then
      REQUIRES_CHECK_BY_TIME=true
    fi
  fi

  # 2. Obtener hash de commit local registrado
  LOCAL_COMMIT=""
  if [ -f "$LAST_SYNC_FILE" ]; then
    LOCAL_COMMIT=$(grep -E '^commit:' "$LAST_SYNC_FILE" 2>/dev/null | awk '{print $2}' || echo "")
  fi
  if [ -z "$LOCAL_COMMIT" ] && [ -f "$CHANGELOG_FILE" ]; then
    LOCAL_COMMIT=$(head -n 1 "$CHANGELOG_FILE" 2>/dev/null | grep -E -o '[0-9a-f]{40}' || echo "")
  fi
  if [ -z "$LOCAL_COMMIT" ] && [ -n "$AGENT_OS_CORE_DIR" ] && [ -d "$AGENT_OS_CORE_DIR/.git" ]; then
    LOCAL_COMMIT=$(git -C "$AGENT_OS_CORE_DIR" rev-parse HEAD 2>/dev/null || echo "")
  fi

  # 3. Consultar commit remoto (con timeout portable estricto de 3s)
  AGENT_OS_URL="https://github.com/romensuarezr/agent-os.git"
  if [ -n "$AGENT_OS_CORE_DIR" ] && [ -d "$AGENT_OS_CORE_DIR/.git" ]; then
    DETECTED_URL=$(git -C "$AGENT_OS_CORE_DIR" remote get-url origin 2>/dev/null || echo "")
    [ -n "$DETECTED_URL" ] && AGENT_OS_URL="$DETECTED_URL"
  fi

  REMOTE_COMMIT=""
  if command -v portable_timeout >/dev/null 2>&1; then
    REMOTE_COMMIT=$(portable_timeout 3 git ls-remote "$AGENT_OS_URL" HEAD 2>/dev/null | awk '{print $1}' || echo "")
  else
    REMOTE_COMMIT=$(git ls-remote "$AGENT_OS_URL" HEAD 2>/dev/null | awk '{print $1}' || echo "")
  fi

  HAS_NEW_COMMIT=false
  if [ -n "$REMOTE_COMMIT" ] && [ -n "$LOCAL_COMMIT" ] && [ "$REMOTE_COMMIT" != "$LOCAL_COMMIT" ]; then
    HAS_NEW_COMMIT=true
  fi

  # 4. Decidir si se requiere alertar de actualización
  if [ "$HAS_NEW_COMMIT" = "true" ] || [ "$REQUIRES_CHECK_BY_TIME" = "true" ]; then
    YELLOW='\033[0;33m'
    NC='\033[0m'
    echo -e "${YELLOW}⚠️  ACTUALIZACIÓN: Hay una nueva versión de Agent OS disponible o han pasado más de 7 días sin sincronizar.${NC}"
    
    # Mostrar cambios recientes si están disponibles
    if [ -f "$AGENT_OS_CORE_DIR/changelog.md" ]; then
      echo "Cambios recientes del core:"
      head -n 15 "$AGENT_OS_CORE_DIR/changelog.md"
    elif [ -f "$CHANGELOG_FILE" ]; then
      echo "Cambios registrados en el changelog local:"
      head -n 15 "$CHANGELOG_FILE"
    fi
    echo ""
    
    # Preguntar de forma interactiva
    echo -n "¿Actualizar agent-os ahora? (sync / skip): "
    # timeout de 10 segundos para lectura por si se ejecuta de forma no interactiva
    if read -r -t 10 response; then
      response=$(echo "$response" | tr '[:upper:]' '[:lower:]' | xargs)
    else
      response="skip"
      echo "skip (timeout)"
    fi
    
    if [ "$response" = "sync" ] && [ -f "scripts/agent/sync.sh" ]; then
      echo "Ejecutando sincronización..."
      bash scripts/agent/sync.sh .
    else
      # Registrar skipped en last-sync.md
      mkdir -p "$(dirname "$LAST_SYNC_FILE")"
      echo "skipped: $(date +%Y-%m-%d)" > "$LAST_SYNC_FILE"
      echo "Sincronización pospuesta."
    fi
    echo "--------------------------------------------------------"
  fi

  # 5. Comprobar si existen archivos deprecados conocidos
  DEPRECATED_KNOWN=("docs/IMPLEMENTED.md" ".agents/workflows/core-planning.md")
  FOUND_DEPRECATED_KNOWN=()
  for dep_k in "${DEPRECATED_KNOWN[@]}"; do
    if [ -f "$dep_k" ]; then
      FOUND_DEPRECATED_KNOWN+=("$dep_k")
    fi
  done

  if [ "${#FOUND_DEPRECATED_KNOWN[@]}" -gt 0 ]; then
    YELLOW='\033[0;33m'
    NC='\033[0m'
    echo -e "${YELLOW}⚠️  WARNING: Se detectaron archivos deprecados de Agent OS en este proyecto:${NC}"
    for dep_k in "${FOUND_DEPRECATED_KNOWN[@]}"; do
      echo "    - $dep_k"
    done
    echo "Guía: Ejecuta la sincronización con limpieza para eliminarlos de forma segura:"
    echo "    bash scripts/agent/sync.sh . --cleanup"
    echo "---"
  fi
fi

LOCK_FILE=".agent-session.lock"

if [ -f "$LOCK_FILE" ]; then
  # Verificar que el archivo no es la plantilla comentada (status = "template")
  STATUS=$(grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' "$LOCK_FILE" 2>/dev/null | grep -o '"[^"]*"$' | tr -d '"' || echo "")
  if [ "$STATUS" = "template" ] || [ -z "$STATUS" ]; then
    echo "NO_ACTIVE_SESSION"
    exit 0
  fi
  cat "$LOCK_FILE"
  exit 1
else
  # Sin lock activo: comprobar si hay cambios en src/ sin commitear
  # Esto puede indicar que el agente actuó sin haber recibido APROBADO
  if git rev-parse --git-dir > /dev/null 2>&1; then
    UNSTAGED=$(git diff --name-only 2>/dev/null | grep '^src/' | head -5 || true)
    STAGED=$(git diff --cached --name-only 2>/dev/null | grep '^src/' | head -5 || true)
    if [ -n "$UNSTAGED" ] || [ -n "$STAGED" ]; then
      YELLOW='\033[0;33m'
      NC='\033[0m'
      echo -e "${YELLOW}WARNING: Hay cambios en src/ sin lock activo — el agente puede haber actuado sin aprobación.${NC}"
      echo "Archivos afectados:"
      [ -n "$UNSTAGED" ] && echo "  Sin stagear: $UNSTAGED"
      [ -n "$STAGED" ]   && echo "  Stageados:   $STAGED"
      echo -e "${YELLOW}Guía: Revisa con 'git diff' antes de continuar. Si los cambios son válidos, crea la sesión mediante /session-start.${NC}"
      echo "---"
    fi
  fi
  echo "NO_ACTIVE_SESSION"
  exit 0
fi

