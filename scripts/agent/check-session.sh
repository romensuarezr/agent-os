#!/bin/bash
# check-session.sh — Detecta si hay una sesión de Antigravity abierta.
# Uso: bash scripts/agent/check-session.sh
# Salida:
#   exit 0 + "NO_ACTIVE_SESSION" → no hay sesión abierta, seguro proceder
#   exit 1 + JSON del lock       → hay sesión sin cerrar, activar Modo Rescate
#   exit 0 + "WARNING: ..."      → no hay lock pero hay cambios en src/ sin commitear
# ==============================================================================
# COMPROBACIÓN DE ACTUALIZACIONES DEL CORE
# ==============================================================================
# Omitir si estamos dentro del propio repositorio core de agent-os
CURRENT_REPO_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null)
REAL_CURRENT=$(realpath "$(pwd)" 2>/dev/null)
REAL_CORE=$(realpath "/home/romen/Proyectos/agent-os" 2>/dev/null)

if [ "$CURRENT_REPO_NAME" = "agent-os" ] || [ "$REAL_CURRENT" = "$REAL_CORE" ]; then
  is_core=true
else
  is_core=false
fi

if [ "$is_core" = "false" ]; then
  LAST_SYNC_FILE=".agents/context/last-sync.md"
  CHANGELOG_FILE=".agents/context/agent-os-changelog.md"
  
  # 1. Leer fecha de última sync
  LAST_SYNC_DATE=""
  if [ -f "$LAST_SYNC_FILE" ]; then
    LAST_SYNC_DATE=$(cat "$LAST_SYNC_FILE" 2>/dev/null | sed 's/skipped: //g' | xargs)
  fi
  
  REQUIRES_CHECK_BY_TIME=false
  if [ -z "$LAST_SYNC_DATE" ]; then
    REQUIRES_CHECK_BY_TIME=true
  fi
  
  # Calcular días transcurridos si hay fecha
  if [ "$REQUIRES_CHECK_BY_TIME" = "false" ]; then
    LAST_SYNC_EPOCH=$(date -d "$LAST_SYNC_DATE" +%s 2>/dev/null || echo 0)
    CURRENT_EPOCH=$(date +%s)
    DIFF_SECONDS=$((CURRENT_EPOCH - LAST_SYNC_EPOCH))
    DIFF_DAYS=$((DIFF_SECONDS / 86400))
    if [ "$DIFF_DAYS" -ge 7 ]; then
      REQUIRES_CHECK_BY_TIME=true
    fi
  fi

  # 2. Obtener hash de commit local registrado
  LOCAL_COMMIT=$(head -n 1 "$CHANGELOG_FILE" 2>/dev/null | grep -E -o '[0-9a-f]{40}')
  if [ -z "$LOCAL_COMMIT" ] && [ -d "/home/romen/Proyectos/agent-os/.git" ]; then
    LOCAL_COMMIT=$(git -C "/home/romen/Proyectos/agent-os" rev-parse HEAD 2>/dev/null)
  fi

  # 3. Consultar commit remoto (con timeout estricto de 3s)
  AGENT_OS_URL="https://github.com/romensuarezr/agent-os.git"
  if [ -d "/home/romen/Proyectos/agent-os/.git" ]; then
    DETECTED_URL=$(git -C "/home/romen/Proyectos/agent-os" remote get-url origin 2>/dev/null)
    [ -n "$DETECTED_URL" ] && AGENT_OS_URL="$DETECTED_URL"
  fi

  REMOTE_COMMIT=""
  # Usar timeout de 3 segundos para evitar bloqueos si no hay red
  REMOTE_COMMIT=$(timeout 3s git ls-remote "$AGENT_OS_URL" HEAD 2>/dev/null | awk '{print $1}')

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
    if [ -f "/home/romen/Proyectos/agent-os/changelog.md" ]; then
      echo "Cambios recientes del core:"
      head -n 15 "/home/romen/Proyectos/agent-os/changelog.md"
    elif [ -f "$CHANGELOG_FILE" ]; then
      echo "Cambios registrados en el changelog local:"
      head -n 15 "$CHANGELOG_FILE"
    fi
    echo ""
    
    # Preguntar de forma interactiva
    echo -n "¿Actualizar agent-os ahora? (sync / skip): "
    # timeout de 10 segundos para lectura por si se ejecuta de forma no interactiva
    if read -t 10 response; then
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
fi

LOCK_FILE=".agent-session.lock"

if [ -f "$LOCK_FILE" ]; then
  # Verificar que el archivo no es la plantilla comentada (status = "template")
  STATUS=$(grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' "$LOCK_FILE" | grep -o '"[^"]*"$' | tr -d '"')
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
    UNSTAGED=$(git diff --name-only 2>/dev/null | grep '^src/' | head -5)
    STAGED=$(git diff --cached --name-only 2>/dev/null | grep '^src/' | head -5)
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

