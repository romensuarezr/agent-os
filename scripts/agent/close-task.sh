#!/bin/bash
# close-task.sh — Commit atómico de cierre de tarea
# Uso: bash scripts/agent/close-task.sh
# El script deriva TASK_ID y mensaje del nombre de la rama activa.
# Formato de rama esperado: feat/T-026-descripcion-de-la-tarea
# PREREQUISITO: El agente ya editó sprint-XX.md y task-XXX.md antes de llamar a este script.
# Para saltar la guardia de sprint: SKIP_SPRINT_CHECK=1 bash scripts/agent/close-task.sh

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
BRANCH=$(git -C "$ROOT" branch --show-current)

# Derivar TASK_NUM desde la rama (feat/T-026-... → 026)
TASK_NUM=$(echo "$BRANCH" | grep -oP '(?<=T-)\d+')
if [ -z "$TASK_NUM" ]; then
  RED='\033[0;31m'
  NC='\033[0m'
  echo -e "${RED}❌ ERROR: No se puede derivar el TASK_ID desde la rama: $BRANCH${NC}"
  echo -e "${RED}Guía: Cambia el nombre de la rama actual usando: git branch -m feat/T-XXX-descripcion${NC}"
  exit 1
fi
TASK_ID="T-${TASK_NUM}"

# Derivar mensaje desde la rama (feat/T-026-marketplace-acuerdo-detail → feat: marketplace acuerdo detail (T-026))
SCOPE=$(echo "$BRANCH" | sed "s|feat/T-${TASK_NUM}-||" | tr '-' ' ')
MESSAGE="feat: ${SCOPE}(${TASK_ID})"

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

# 1b. Guardia: verificar que la tarea está marcada como completada en el sprint activo
if [ "${SKIP_SPRINT_CHECK:-0}" != "1" ]; then
  SPRINT_ACTIVE=$(ls "$ROOT/docs/sprints"/sprint-[0-9][0-9]*.md 2>/dev/null \
    | grep -v "research" | sort -V | tail -1 || true)
  if [ -n "$SPRINT_ACTIVE" ]; then
    if grep -q "^| ${TASK_ID}" "$SPRINT_ACTIVE" 2>/dev/null; then
      if ! grep "^| ${TASK_ID}" "$SPRINT_ACTIVE" | grep -qE "✅|🟢 Completada"; then
        YELLOW='\033[0;33m'
        NC='\033[0m'
        echo ""
        echo -e "${YELLOW}⚠️  GUARDIA SPRINT: $TASK_ID no está marcada como completada en $(basename $SPRINT_ACTIVE)${NC}"
        echo -e "${YELLOW}Guía: Abre el sprint file y marca la tarea con ✅ en lugar de ⬜ o ⏸. Si es intencionadamente, ejecuta: SKIP_SPRINT_CHECK=1 bash scripts/agent/close-task.sh${NC}"
        echo ""
        exit 1
      else
        echo "✅ Sprint check: $TASK_ID marcada como completada en $(basename $SPRINT_ACTIVE)"
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

# 5. Commit atómico único
git -C "$ROOT" commit -m "$MESSAGE"
echo "✅ Commit realizado: $MESSAGE"

echo ""
git -C "$ROOT" status --short || true
echo ""
echo "✅ $TASK_ID cerrada correctamente."
echo "   Rama: $BRANCH"
echo "   Siguiente paso: merge a main o iniciar nueva tarea con /session-start"
