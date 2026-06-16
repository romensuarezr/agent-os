#!/bin/bash
# close-sprint.sh — Archiva un sprint completado en docs/sprints/_archived/
# Uso: bash scripts/agent/close-sprint.sh sprint-07
#
# Solo archiva si TODAS las tareas del sprint están marcadas como ✅ o 🟢 Completada.
# Archiva también el archivo -research.md si existe.
# Si CHANGELOG.md fue modificado por update-changelog.sh, lo incluye en el mismo commit.
#
# PREREQUISITO: El sprint-XX.md ya tiene estado "✅ Completado" en la sección ## Estado.
# PREREQUISITO OPCIONAL: Haber ejecutado update-changelog.sh antes para que CHANGELOG.md
#   esté modificado y listo para incluirse en este commit.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
SPRINTS_DIR="$ROOT/docs/sprints"
ARCHIVE_DIR="$ROOT/docs/sprints/_archived"
CHANGELOG="$ROOT/CHANGELOG.md"

# --- Validar argumento ---
if [ -z "${1:-}" ]; then
  RED='\033[0;31m'
  NC='\033[0m'
  echo -e "${RED}❌ ERROR: Uso incorrecto: bash scripts/agent/close-sprint.sh <nombre-sprint> o --auto${NC}"
  echo -e "${RED}Guía: Proporciona el identificador del sprint (ej: sprint-02) o usa --auto para detectar sprints marcados como completados.${NC}"
  exit 1
fi

if [ "$1" = "--auto" ]; then
  echo "🔍 Buscando sprints completados en $SPRINTS_DIR..."
  FOUND_ANY=0
  shopt -s nullglob
  for f in "$SPRINTS_DIR"/sprint-*.md; do
    [ -f "$f" ] || continue
    SPRINT_NAME_BASE=$(basename "$f" .md)
    if grep -q "✅ Completado" "$f"; then
      echo "🚀 Detectado sprint completado: $SPRINT_NAME_BASE. Archivando..."
      bash "$0" "$SPRINT_NAME_BASE"
      FOUND_ANY=1
    fi
  done
  shopt -u nullglob

  if [ "$FOUND_ANY" -eq 0 ]; then
    echo "✅ No hay sprints completados pendientes de archivar"
  fi
  exit 0
fi

SPRINT_NAME="$1"
SPRINT_FILE="$SPRINTS_DIR/${SPRINT_NAME}.md"

if [ ! -f "$SPRINT_FILE" ]; then
  RED='\033[0;31m'
  NC='\033[0m'
  echo -e "${RED}❌ ERROR: No encontrado: $SPRINT_FILE${NC}"
  echo -e "${RED}Guía: Asegúrate de que el nombre del sprint es correcto y que el archivo .md correspondiente está en docs/sprints/.${NC}"
  exit 1
fi

# --- Verificar que el sprint está completado antes de archivar ---
TOTAL=$(grep -c "^| T-" "$SPRINT_FILE" 2>/dev/null || echo "0")
DONE=$(grep "^| T-" "$SPRINT_FILE" 2>/dev/null | grep -cE "✅|🟢 Completada" || echo "0")

if [ "$TOTAL" -eq 0 ]; then
  YELLOW='\033[0;33m'
  NC='\033[0m'
  echo -e "${YELLOW}⚠️  WARNING: No se encontraron tareas (filas | T-XXX |) en $SPRINT_NAME.${NC}"
  echo -e "${YELLOW}Guía: Verifica que las tareas estén formateadas en tablas usando '| T-XXX |' en el archivo del sprint.${NC}"
  exit 1
fi

if [ "$DONE" -lt "$TOTAL" ]; then
  YELLOW='\033[0;33m'
  NC='\033[0m'
  echo -e "${YELLOW}⚠️  WARNING: Sprint incompleto: $DONE/$TOTAL tareas completadas.${NC}"
  echo -e "${YELLOW}Guía: Asegúrate de completar todas las tareas pendientes del sprint. Si deseas archivar de todas formas, ejecuta: FORCE=1 bash scripts/agent/close-sprint.sh $SPRINT_NAME${NC}"
  if [ "${FORCE:-0}" != "1" ]; then
    exit 1
  fi
  echo -e "${YELLOW}   ⚠️  FORCE=1 activo — archivando de todas formas.${NC}"
fi

# --- Detectar versión sugerida en CHANGELOG (para el mensaje de commit) ---
CHANGELOG_MODIFIED=false
VERSION_TAG=""

if [ -f "$CHANGELOG" ]; then
  # Comprueba si CHANGELOG.md tiene cambios no commiteados (staged o unstaged)
  if ! git -C "$ROOT" diff --quiet "$CHANGELOG" 2>/dev/null || \
     ! git -C "$ROOT" diff --cached --quiet "$CHANGELOG" 2>/dev/null; then
    CHANGELOG_MODIFIED=true
    # Extrae la versión de la primera entrada del changelog
    VERSION_TAG=$(grep -m1 '^## \[' "$CHANGELOG" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
    echo "📝 CHANGELOG.md modificado detectado — se incluirá en el commit."
    [ -n "$VERSION_TAG" ] && echo "   Versión detectada: v${VERSION_TAG}"
  fi
fi

# --- Archivar ---
mkdir -p "$ARCHIVE_DIR"
git -C "$ROOT" mv "$SPRINT_FILE" "$ARCHIVE_DIR/"
echo "📦 Archivado: $SPRINT_NAME.md → docs/sprints/_archived/"

# Archivar también el research file si existe
RESEARCH_FILE="$SPRINTS_DIR/${SPRINT_NAME}-research.md"
if [ -f "$RESEARCH_FILE" ]; then
  git -C "$ROOT" mv "$RESEARCH_FILE" "$ARCHIVE_DIR/"
  echo "📦 Archivado: ${SPRINT_NAME}-research.md → docs/sprints/_archived/"
fi

# --- Incluir CHANGELOG.md si fue modificado por update-changelog.sh ---
if [ "$CHANGELOG_MODIFIED" = true ]; then
  git -C "$ROOT" add "$CHANGELOG"
  echo "📋 CHANGELOG.md añadido al stage."
fi

# --- Commit atómico ---
if [ -n "$VERSION_TAG" ]; then
  COMMIT_MSG="chore: archive ${SPRINT_NAME} [v${VERSION_TAG}]"
else
  COMMIT_MSG="chore: archive ${SPRINT_NAME}"
fi

git -C "$ROOT" commit -m "$COMMIT_MSG"

echo ""
echo "✅ $SPRINT_NAME archivado y commiteado ($DONE/$TOTAL tareas ✅)."
echo "   Commit: $COMMIT_MSG"
if [ "$CHANGELOG_MODIFIED" = true ]; then
  echo "   CHANGELOG.md incluido en el commit."
fi
