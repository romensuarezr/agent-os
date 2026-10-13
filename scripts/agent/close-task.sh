#!/usr/bin/env bash
# close-task.sh — Commit atómico de cierre de tarea
# Uso: bash scripts/agent/close-task.sh
# El script deriva TASK_ID y mensaje del nombre de la rama activa.
# Formato de rama esperado: feat/T-026-descripcion-de-la-tarea
# PREREQUISITO: El agente ya editó sprint-XX.md y task-XXX.md antes de llamar a este script.
# Para saltar la guardia de sprint: SKIP_SPRINT_CHECK=1 bash scripts/agent/close-task.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/cli-help.sh"
for arg in "$@"; do
  if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
    show_help "close-task.sh" \
      "bash scripts/agent/close-task.sh [TASK_ID] [mensaje]" \
      "Ejecuta el cierre formal y commit atómico de una tarea, archivando su task file y liberando el lock de sesión." \
      "[TASK_ID]                Identificador opcional de la tarea (por defecto se deduce del nombre de la rama feat/T-XXX-...)" \
      "[mensaje]                Mensaje opcional de commit (por defecto: 'tipo(TASK_ID): descripcion')" \
      "-m, --message            Flag alternativo para especificar el mensaje de commit" \
      "-h, --help               Muestra este mensaje de ayuda" \
      "ejemplo: bash scripts/agent/close-task.sh" \
      "ejemplo: bash scripts/agent/close-task.sh \"feat(scope): descripcion\"" \
      "ejemplo: bash scripts/agent/close-task.sh T-026 \"feat(marketplace): acuerdo detail\"" \
      "ejemplo: SKIP_SPRINT_CHECK=1 bash scripts/agent/close-task.sh"
  fi
done

ROOT="$(git rev-parse --show-toplevel)"
BRANCH=$(git -C "$ROOT" branch --show-current)

CUSTOM_MSG=""
EXPLICIT_TASK_ID=""

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      # Ya atendido por show_help
      exit 0
      ;;
    -m|--message)
      shift
      CUSTOM_MSG="${1:-}"
      shift
      ;;
    T-[0-9]*|[0-9]*)
      if [ -z "$EXPLICIT_TASK_ID" ]; then
        EXPLICIT_TASK_ID="$1"
      else
        CUSTOM_MSG="${CUSTOM_MSG:+${CUSTOM_MSG} }$1"
      fi
      shift
      ;;
    *)
      CUSTOM_MSG="${CUSTOM_MSG:+${CUSTOM_MSG} }$1"
      shift
      ;;
  esac
done

# Derivar TASK_NUM y TASK_ID (explícito o deducido de la rama)
if [ -n "$EXPLICIT_TASK_ID" ]; then
  TASK_NUM=$(echo "$EXPLICIT_TASK_ID" | sed 's/^T-//')
  TASK_ID="T-${TASK_NUM}"
else
  TASK_NUM=$(echo "$BRANCH" | sed -n 's/.*T-\([0-9][0-9]*\).*/\1/p')
  if [ -z "$TASK_NUM" ]; then
    RED='\033[0;31m'
    NC='\033[0m'
    echo -e "${RED}❌ ERROR: No se puede derivar el TASK_ID desde la rama: $BRANCH${NC}"
    echo -e "${RED}Guía: Cambia el nombre de la rama actual usando: git branch -m feat/T-XXX-descripcion o pásalo como argumento: bash scripts/agent/close-task.sh T-XXX${NC}"
    exit 1
  fi
  TASK_ID="T-${TASK_NUM}"
fi

# Derivar mensaje de commit (personalizado o convención estándar tipo(scope): descripción)
if [ -n "$CUSTOM_MSG" ]; then
  if echo "$CUSTOM_MSG" | grep -q "$TASK_ID"; then
    MESSAGE="$CUSTOM_MSG"
  else
    MESSAGE="${CUSTOM_MSG} (${TASK_ID})"
  fi
else
  BRANCH_TYPE=$(echo "$BRANCH" | sed -n 's|^\([a-zA-Z0-9_-]*\)/T-.*|\1|p')
  [ -z "$BRANCH_TYPE" ] && BRANCH_TYPE="feat"
  BRANCH_DESC=$(echo "$BRANCH" | sed -n "s|.*T-${TASK_NUM}-\(.*\)|\1|p" | tr '-' ' ')
  [ -z "$BRANCH_DESC" ] && BRANCH_DESC="cierre de tarea"

  MESSAGE="${BRANCH_TYPE}(${TASK_ID}): ${BRANCH_DESC}"
fi

TASK_FILE="$ROOT/.agents/tasks/task-${TASK_NUM}.md"
ARCHIVE_DIR="$ROOT/.agents/tasks/_archived"
LOCK="$ROOT/.agent-session.lock"

echo "🔄 Cerrando $TASK_ID desde rama $BRANCH..."

# 1. Verificar que el task file existe
if [ ! -f "$TASK_FILE" ]; then
  RED='\033[0;31m'
  NC='\033[0m'
  echo -e "${RED}❌ ERROR: No encontrado: $TASK_FILE${NC}"
  echo -e "${RED}Guía: Verifica si la tarea ya fue archivada en .agents/tasks/_archived/ o si el número en el nombre de la rama es correcto.${NC}"
  exit 1
fi

# 1b. Guardia: verificar que la tarea está marcada como completada en su sprint file
if [ "${SKIP_SPRINT_CHECK:-0}" != "1" ]; then
  # Localizar dinámicamente el sprint file que contiene la tarea (en docs/sprints/ activo o archivado)
  SPRINT_ACTIVE=$(grep -l "^| ${TASK_ID}" "$ROOT/docs/sprints"/sprint-*.md 2>/dev/null | grep -v "research" | head -1 || true)
  if [ -z "$SPRINT_ACTIVE" ]; then
    SPRINT_ACTIVE=$(grep -l "^| ${TASK_ID}" "$ROOT/docs/sprints/_archived"/sprint-*.md 2>/dev/null | grep -v "research" | head -1 || true)
  fi
  if [ -z "$SPRINT_ACTIVE" ]; then
    # Fallback al sprint más reciente si no se encuentra explícitamente
    SPRINT_ACTIVE=$(ls "$ROOT/docs/sprints"/sprint-[0-9][0-9]*.md 2>/dev/null \
      | grep -v "research" | sort -V | tail -1 || true)
  fi

  if [ -n "$SPRINT_ACTIVE" ]; then
    if grep -q "^| ${TASK_ID}" "$SPRINT_ACTIVE" 2>/dev/null; then
      if ! grep "^| ${TASK_ID}" "$SPRINT_ACTIVE" | grep -qiE "✅|🟢[[:space:]]*(Completad[oa]|Done|Hecho)|(Completad[oa]|Done)"; then
        YELLOW='\033[0;33m'
        NC='\033[0m'
        echo ""
        echo -e "${YELLOW}⚠️  GUARDIA SPRINT: $TASK_ID no está marcada como completada en $(basename "$SPRINT_ACTIVE")${NC}"
        echo -e "${YELLOW}Guía: Abre el sprint file y marca la tarea con ✅ en lugar de ⬜ o ⏸. Si es intencionadamente, ejecuta: SKIP_SPRINT_CHECK=1 bash scripts/agent/close-task.sh${NC}"
        echo ""
        exit 1
      else
        echo "✅ Sprint check: $TASK_ID marcada como completada en $(basename "$SPRINT_ACTIVE")"
      fi
    fi
  fi
else
  YELLOW='\033[0;33m'
  NC='\033[0m'
  echo -e "${YELLOW}⚠️  SKIP_SPRINT_CHECK=1 activo — guardia de sprint omitida.${NC}"
fi

# 1c. Eliminar lock ANTES del stage (evita que quede incluido en el commit)
if [ -f "$LOCK" ]; then
  rm "$LOCK"
  echo "🔓 Lock eliminado antes del stage"
fi


# Verificación post-condición del commit, compartida con close-sprint.sh.
# Cargar con source desde la librería del core: la lógica NO se duplica aquí.
# shellcheck source=scripts/agent/lib/verify-commit.sh
source "$SCRIPT_DIR/lib/verify-commit.sh" 2>/dev/null || {
    echo "ERROR: no se encuentra lib/verify-commit.sh; el cierre no puede verificarse." >&2
    exit 1
}

# 2. Stage de todo lo modificado (código + docs ya editados por el agente)
git -C "$ROOT" add -A

# 3. Verificar que hay algo que commitear
if git -C "$ROOT" diff --quiet --cached; then
  RED='\033[0;31m'
  NC='\033[0m'
  echo -e "${RED}❌ ERROR: Nada en stage. ¿Ya está todo commitado?${NC}"
  echo -e "${RED}Guía: Realiza cambios en los archivos autorizados y asegúrate de que no se hayan commiteado previamente de forma manual.${NC}"
  exit 1
fi

# 4. Archivar task file (git mv preserva historial)
mkdir -p "$ARCHIVE_DIR"
git -C "$ROOT" mv "$TASK_FILE" "$ARCHIVE_DIR/"
echo "📦 Task file archivado en _archived/"

# 4b. Actualizar el ENLACE de la fila del sprint para que apunte a _archived/.
# Sin esto la tabla queda con un enlace roto y obliga a un commit de reparacion manual.
# Reescritura portable: awk POSIX (nunca sed -i, que difiere entre BSD y GNU) + swap
# atomico con mv. Idempotente: si ya apunta al destino nuevo, no se toca nada.
TASK_BASENAME="$(basename "$TASK_FILE")"
OLD_LINK=".agents/tasks/$TASK_BASENAME"
NEW_LINK=".agents/tasks/_archived/$TASK_BASENAME"
LINK_UPDATED=false
if [ -n "$SPRINT_ACTIVE" ] && [ -f "$SPRINT_ACTIVE" ]; then
    if grep -q "($OLD_LINK)" "$SPRINT_ACTIVE" 2>/dev/null; then
        awk -v old="($OLD_LINK)" -v new="($NEW_LINK)" '
            { idx = index($0, old)
              if (idx > 0) $0 = substr($0, 1, idx - 1) new substr($0, idx + length(old))
              print $0 }' "$SPRINT_ACTIVE" > "$SPRINT_ACTIVE.tmp.$$" \
          && mv "$SPRINT_ACTIVE.tmp.$$" "$SPRINT_ACTIVE" 2>/dev/null || rm -f "$SPRINT_ACTIVE.tmp.$$"
        if grep -q "($NEW_LINK)" "$SPRINT_ACTIVE" 2>/dev/null; then
            git -C "$ROOT" add "$SPRINT_ACTIVE"
            LINK_UPDATED=true
            echo "🔗 Enlace de $TASK_ID actualizado a _archived/ en $(basename "$SPRINT_ACTIVE")"
        else
            RED='\033[0;31m'; NC='\033[0m'
            echo -e "${RED}❌ ERROR: no se pudo actualizar el enlace en $(basename "$SPRINT_ACTIVE").${NC}"
            echo -e "${RED}   Arregla la fila a mano antes de commitear; no se archivar con el enlace roto.${NC}"
            exit 1
        fi
    elif grep -q "($NEW_LINK)" "$SPRINT_ACTIVE" 2>/dev/null; then
        LINK_UPDATED=true     # ya correcto: idempotente, no se toca
    fi
fi
# Limitación conocida y asumida: la búsqueda solo encuentra celdas de tabla
# ("| T-XXX |"). Una tarea listada como elemento de lista no actualiza su enlace.

# 5. Commit atómico único, VALIDADO ANTES de mover el ref
if agent_verify_commit "$ROOT" "$MESSAGE" "_archived/$TASK_BASENAME" "archivado del task file a _archived/"; then
    echo "✅ Commit realizado: $MESSAGE"
else
    exit 1
fi

echo ""
git -C "$ROOT" status --short || true
echo ""
echo "✅ $TASK_ID cerrada correctamente."
echo "   Rama: $BRANCH"
echo "   Siguiente paso: merge a main o iniciar nueva tarea con /session-start"
