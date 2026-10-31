#!/usr/bin/env bash
# close-sprint.sh — Archiva un sprint completado en docs/sprints/_archived/
# Uso: bash scripts/agent/close-sprint.sh sprint-07
#
# Solo archiva si TODAS las tareas del sprint están marcadas como ✅ o 🟢 Completada.
# Archiva también el archivo -research.md si existe.
# Si changelog.md fue modificado por update-changelog.sh, lo incluye en el mismo commit.
#
# PREREQUISITO: El sprint-XX.md ya tiene estado "✅ Completado" en la sección ## Estado.
# PREREQUISITO OPCIONAL: Haber ejecutado update-changelog.sh antes para que changelog.md
#   esté modificado y listo para incluirse en este commit.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/cli-help.sh"
for arg in "$@"; do
  if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
    show_help "close-sprint.sh" \
      "bash scripts/agent/close-sprint.sh <nombre-sprint|--auto>" \
      "Archiva un sprint completado en docs/sprints/_archived/ y sus tareas asociadas, verificando guardias de finalización." \
      "<nombre-sprint>          Nombre o archivo del sprint a archivar (ej: sprint-11 o docs/sprints/sprint-11-core.md)" \
      "--auto                   Busca y archiva automáticamente los sprints marcados como completados" \
      "-h, --help               Muestra este mensaje de ayuda" \
      "ejemplo: bash scripts/agent/close-sprint.sh sprint-11" \
      "ejemplo: bash scripts/agent/close-sprint.sh --auto"
  fi
done

# Pre-flight: verificación determinista de dependencias
for cmd in git grep mkdir basename wc; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ ERROR: Dependencia requerida no encontrada: $cmd" >&2
    echo "Guía: Instala $cmd en tu sistema antes de continuar." >&2
    exit 1
  fi
done

ROOT="$(git rev-parse --show-toplevel)"
SPRINTS_DIR="$ROOT/docs/sprints"
ARCHIVE_DIR="$ROOT/docs/sprints/_archived"
if [ -f "$ROOT/CHANGELOG.md" ] && [ ! -f "$ROOT/changelog.md" ]; then
  CHANGELOG="$ROOT/CHANGELOG.md"
else
  CHANGELOG="$ROOT/changelog.md"
fi


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
    [[ "$f" == *"-report.md" ]] && continue
    [[ "$f" == *"-research.md" ]] && continue
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

# Normalización del identificador y ruta del sprint (Precision 1 T-146)
SPRINT_ARG="$1"
SPRINT_NAME_INPUT="$(basename "$SPRINT_ARG" .md)"

if [ -f "$SPRINT_ARG" ]; then
  SPRINT_FILE="$SPRINT_ARG"
elif [ -f "$SPRINTS_DIR/${SPRINT_NAME_INPUT}.md" ]; then
  SPRINT_FILE="$SPRINTS_DIR/${SPRINT_NAME_INPUT}.md"
elif [ -f "$SPRINTS_DIR/${SPRINT_NAME_INPUT}-core.md" ]; then
  SPRINT_FILE="$SPRINTS_DIR/${SPRINT_NAME_INPUT}-core.md"
else
  SPRINT_FILE="$SPRINTS_DIR/${SPRINT_NAME_INPUT}.md"
fi

if [ ! -f "$SPRINT_FILE" ]; then
  RED='\033[0;31m'
  NC='\033[0m'
  echo -e "${RED}❌ ERROR: No encontrado: $SPRINT_FILE${NC}"
  echo -e "${RED}Guía: Asegúrate de que el nombre del sprint es correcto y que el archivo .md correspondiente está en docs/sprints/.${NC}"
  exit 1
fi

SPRINT_FULL="$(basename "$SPRINT_FILE" .md)"
SPRINT_BASE="${SPRINT_FULL%-core}"

# --- Verificar que el sprint está completado antes de archivar ---
TOTAL=$( (grep -E "^\| T-|^-[[:space:]]*\[[ x/]\]" "$SPRINT_FILE" 2>/dev/null || true) | wc -l | tr -d '[:space:]')
DONE=$( (grep -E "^\| T-|^-[[:space:]]*\[[ x/]\]" "$SPRINT_FILE" 2>/dev/null || true) | (grep -E "✅|🟢 Completada|\[x\]" 2>/dev/null || true) | wc -l | tr -d '[:space:]')

if [ "$TOTAL" -eq 0 ]; then
  YELLOW='\033[0;33m'
  NC='\033[0m'
  echo -e "${YELLOW}⚠️  WARNING: No se encontraron tareas (filas | T-XXX | o items - [ ] T-XXX) en $SPRINT_FULL.${NC}"
  echo -e "${YELLOW}Guía: Verifica que las tareas estén formateadas en tablas o listas en el archivo del sprint.${NC}"
  exit 1
fi

if [ "$DONE" -lt "$TOTAL" ]; then
  YELLOW='\033[0;33m'
  NC='\033[0m'
  echo -e "${YELLOW}⚠️  WARNING: Sprint incompleto: $DONE/$TOTAL tareas completadas.${NC}"
  echo -e "${YELLOW}Guía: Asegúrate de completar todas las tareas pendientes del sprint. Si deseas archivar de todas formas, ejecuta: FORCE=1 bash scripts/agent/close-sprint.sh $SPRINT_FULL${NC}"
  if [ "${FORCE:-0}" != "1" ]; then
    exit 1
  fi
  echo -e "${YELLOW}   ⚠️  FORCE=1 activo — archivando de todas formas.${NC}"
fi

# --- Detección y orquestación determinista de CHANGELOG (T-146) ---
# shellcheck source=scripts/agent/lib/release-version.sh
source "$SCRIPT_DIR/lib/release-version.sh" 2>/dev/null || {
    echo "ERROR: no se encuentra lib/release-version.sh; no puede leerse la versión del changelog." >&2
    exit 1
}
CHANGELOG_MODIFIED=false
VERSION_TAG=""

# 1. Comprobar si changelog.md ya está preparado (modificado en git o con cabecera del sprint)
CHANGELOG_PREPARED=false
if [ -f "$CHANGELOG" ]; then
  if [ -n "$(git -C "$ROOT" status --porcelain "$CHANGELOG" 2>/dev/null)" ]; then
    CHANGELOG_PREPARED=true
  elif grep -q -E "^## \[[0-9]+\.[0-9]+\.[0-9]+\] — (${SPRINT_BASE}|${SPRINT_FULL})([[:space:]]|—|$)" "$CHANGELOG" 2>/dev/null; then
    CHANGELOG_PREPARED=true
  fi
fi

if [ "$CHANGELOG_PREPARED" = true ]; then
  echo "ℹ️  changelog.md ya preparado o con cabecera para $SPRINT_BASE — respetando contenido sin re-generar."
else
  echo "⚙️  Auto-generando entrada determinista en changelog.md para $SPRINT_BASE..."
  # Precision 1: update-changelog.sh se invoca pasando estrictamente SPRINT_BASE
  if ! bash "$SCRIPT_DIR/update-changelog.sh" "$SPRINT_BASE"; then
    RED='\033[0;31m'; NC='\033[0m'
    echo -e "${RED}❌ ERROR: Falló la generación automática del changelog con update-changelog.sh.${NC}" >&2
    # Restaurar changelog si quedó parcialmente modificado (fail-closed)
    [ -f "$CHANGELOG" ] && git -C "$ROOT" checkout -- "$CHANGELOG" 2>/dev/null || true
    exit 1
  fi
fi

if [ -f "$CHANGELOG" ]; then
  if [ -n "$(git -C "$ROOT" status --porcelain "$CHANGELOG" 2>/dev/null)" ] || \
     ! git -C "$ROOT" diff --quiet "$CHANGELOG" 2>/dev/null || \
     ! git -C "$ROOT" diff --cached --quiet "$CHANGELOG" 2>/dev/null; then
    CHANGELOG_MODIFIED=true
    VERSION_TAG=$(agent_read_changelog_version "$CHANGELOG" || true)
    echo "📝 changelog.md modificado detectado — se incluirá en el commit."
    [ -n "$VERSION_TAG" ] && echo "   Versión detectada: v${VERSION_TAG}"
  elif grep -q -E "^## \[[0-9]+\.[0-9]+\.[0-9]+\] — (${SPRINT_BASE}|${SPRINT_FULL})([[:space:]]|—|$)" "$CHANGELOG" 2>/dev/null; then
    VERSION_TAG=$(agent_read_changelog_version "$CHANGELOG" || true)
    [ -n "$VERSION_TAG" ] && echo "   Versión detectada en changelog: v${VERSION_TAG}"
  fi
fi

# Fail-closed: si no estaba preparado y no se generó ninguna modificación en changelog, abortar
if [ "$CHANGELOG_MODIFIED" = false ] && [ "$CHANGELOG_PREPARED" = false ]; then
  RED='\033[0;31m'; NC='\033[0m'
  echo -e "${RED}❌ ERROR: update-changelog.sh no generó cambios en changelog.md para $SPRINT_BASE.${NC}" >&2
  [ -f "$CHANGELOG" ] && git -C "$ROOT" checkout -- "$CHANGELOG" 2>/dev/null || true
  exit 1
fi

# --- Staging ACOTADO: solo los ficheros propios de este script ---
# NO se usa `git add -A`: eso se traga cambios ajenos del working tree. Aquí se
# stagean únicamente sprint + research + changelog (si cambió) + roadmap (si cambió).
OWN_FILES=""
add_own() {
  local f="$1"
  [ -f "$f" ] || return 0
  git -C "$ROOT" add "$f" && OWN_FILES="$OWN_FILES $f"
}

# Detectar modificaciones ajenas ANTES de stagear, para avisar sin mezclar
FOREIGN_BEFORE=$(git -C "$ROOT" status --porcelain 2>/dev/null | grep -vE "^..[[:space:]]+(docs/sprints/|CHANGELOG\.md|changelog\.md|roadmap\.md|ROADMAP\.md)" || true)
if [ -n "$FOREIGN_BEFORE" ]; then
  YELLOW='\033[0;33m'; NC='\033[0m'
  echo -e "${YELLOW}⚠️  Hay cambios AJENOS al cierre de sprint en el working tree:${NC}"
  printf '%s\n' "$FOREIGN_BEFORE" | head -10 | sed 's/^/     /'
  echo -e "${YELLOW}   NO se incluyen en el commit de archivado (staging acotado a los ficheros${NC}"
  echo -e "${YELLOW}   propios del script). Revísalos y commitéalos por separado.${NC}"
fi

# --- Archivar ---
mkdir -p "$ARCHIVE_DIR"
git -C "$ROOT" mv "$SPRINT_FILE" "$ARCHIVE_DIR/"
add_own "$ARCHIVE_DIR/${SPRINT_FULL}.md"
echo "📦 Archivado: ${SPRINT_FULL}.md → docs/sprints/_archived/"

# Archivar también el research file si existe (Precision 1: research = base-research.md)
RESEARCH_FILE="$SPRINTS_DIR/${SPRINT_BASE}-research.md"
[ -f "$RESEARCH_FILE" ] || RESEARCH_FILE="$SPRINTS_DIR/${SPRINT_FULL}-research.md"

if [ -f "$RESEARCH_FILE" ]; then
  git -C "$ROOT" mv "$RESEARCH_FILE" "$ARCHIVE_DIR/"
  add_own "$ARCHIVE_DIR/$(basename "$RESEARCH_FILE")"
  echo "📦 Archivado: $(basename "$RESEARCH_FILE") → docs/sprints/_archived/"
fi

# --- Incluir roadmap.md si fue modificado en este cierre ---
ROADMAP="$ROOT/roadmap.md"
[ -f "$ROADMAP" ] || ROADMAP="$ROOT/ROADMAP.md"
if [ -f "$ROADMAP" ]; then
  if ! git -C "$ROOT" diff --quiet "$ROADMAP" 2>/dev/null || \
     ! git -C "$ROOT" diff --cached --quiet "$ROADMAP" 2>/dev/null; then
    add_own "$ROADMAP"
    echo "🗺️  roadmap.md añadido al stage."
  fi
fi

# --- Incluir changelog.md si fue modificado ---
if [ "$CHANGELOG_MODIFIED" = true ]; then
  add_own "$CHANGELOG"
  echo "📋 changelog.md añadido al stage."
fi

# --- Sincronizar VERSION con la release (T-113) ---
if [ "$CHANGELOG_MODIFIED" = true ]; then
  if agent_sync_version "$ROOT" "$CHANGELOG"; then
    add_own "$ROOT/VERSION"
  else
    echo "   ⚠️  VERSION no se ha modificado." >&2
  fi
else
  echo "ℹ️  changelog.md sin cambios: VERSION no se toca."
fi

# --- Commit atómico ---
if [ -n "$VERSION_TAG" ]; then
  COMMIT_MSG="chore: archive ${SPRINT_FULL} [v${VERSION_TAG}]"
else
  COMMIT_MSG="chore: archive ${SPRINT_FULL}"
fi

# Verificación post-condición del commit, compartida con close-task.sh (regla 8: no duplicar).
# shellcheck source=scripts/agent/lib/verify-commit.sh
source "$SCRIPT_DIR/lib/verify-commit.sh" 2>/dev/null || {
    echo "ERROR: no se encuentra lib/verify-commit.sh; el archivado no puede verificarse." >&2
    exit 1
}

if ! agent_verify_commit "$ROOT" "$COMMIT_MSG" "_archived/" "archivado del sprint a _archived/"; then
  exit 1
fi

echo ""
echo "✅ $SPRINT_FULL archivado y commiteado ($DONE/$TOTAL tareas ✅)."
echo "   Commit: $COMMIT_MSG"
if [ "$CHANGELOG_MODIFIED" = true ]; then
  echo "   changelog.md incluido en el commit."
fi
