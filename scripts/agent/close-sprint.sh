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
  echo "❌ Uso: bash scripts/agent/close-sprint.sh <nombre-sprint> o --auto"
  echo "   Ejemplo: bash scripts/agent/close-sprint.sh sprint-07"
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
  echo "❌ No encontrado: $SPRINT_FILE"
  echo "   Verifica que el archivo existe y no fue archivado ya."
  exit 1
fi

# --- Verificar que el sprint está completado antes de archivar ---
TOTAL=$(grep -c "^| T-" "$SPRINT_FILE" 2>/dev/null || echo "0")
DONE=$(grep "^| T-" "$SPRINT_FILE" 2>/dev/null | grep -cE "✅|🟢 Completada" || echo "0")

if [ "$TOTAL" -eq 0 ]; then
  echo "⚠️  No se encontraron tareas (filas | T-XXX |) en $SPRINT_NAME."
  echo "   Verifica el formato del archivo antes de archivar."
  exit 1
fi

if [ "$DONE" -lt "$TOTAL" ]; then
  echo "⚠️  Sprint incompleto: $DONE/$TOTAL tareas completadas."
  echo "   Solo archiva sprints donde TODAS las tareas estén en ✅ o 🟢 Completada."
  echo "   Si quieres forzar el archivado, usa: FORCE=1 bash scripts/agent/close-sprint.sh $SPRINT_NAME"
  [ "${FORCE:-0}" != "1" ] && exit 1
  echo "   ⚠️  FORCE=1 activo — archivando de todas formas."
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
