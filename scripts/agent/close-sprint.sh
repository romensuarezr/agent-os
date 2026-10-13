#!/usr/bin/env bash
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
CHANGELOG="$ROOT/CHANGELOG.md"
[ -f "$CHANGELOG" ] || CHANGELOG="$ROOT/changelog.md"


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
TOTAL=$(grep -E "^\| T-|^-[[:space:]]*\[[ x/]\]" "$SPRINT_FILE" 2>/dev/null | wc -l || echo "0")
DONE=$(grep -E "^\| T-|^-[[:space:]]*\[[ x/]\]" "$SPRINT_FILE" 2>/dev/null | grep -E "✅|🟢 Completada|\[x\]" 2>/dev/null | wc -l || echo "0")

if [ "$TOTAL" -eq 0 ]; then
  YELLOW='\033[0;33m'
  NC='\033[0m'
  echo -e "${YELLOW}⚠️  WARNING: No se encontraron tareas (filas | T-XXX | o items - [ ] T-XXX) en $SPRINT_NAME.${NC}"
  echo -e "${YELLOW}Guía: Verifica que las tareas estén formateadas en tablas o listas en el archivo del sprint.${NC}"
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

# --- Staging ACOTADO: solo los ficheros propios de este script ---
# NO se usa `git add -A`: eso se traga cambios ajenos del working tree. Aquí se
# stagean únicamente sprint + research + changelog (si cambió). Cualquier otra
# modificación se avisa y se deja intacta para que el operador decida.
OWN_FILES=""
add_own() {
  local f="$1"
  [ -f "$f" ] || return 0
  git -C "$ROOT" add "$f" && OWN_FILES="$OWN_FILES $f"
}

# Detectar modificaciones ajenas ANTES de stagear, para avisar sin mezclar
# Sin ancla $ al final: con ella, "docs/sprints/" solo excluía el directorio exacto y
# cualquier fichero dentro se anunciaba falsamente como cambio ajeno.
FOREIGN_BEFORE=$(git -C "$ROOT" status --porcelain 2>/dev/null | grep -vE "^..[[:space:]]+(docs/sprints/|CHANGELOG\.md|changelog\.md)" || true)
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
add_own "$ARCHIVE_DIR/${SPRINT_NAME}.md"
echo "📦 Archivado: $SPRINT_NAME.md → docs/sprints/_archived/"

# Archivar también el research file si existe
RESEARCH_FILE="$SPRINTS_DIR/${SPRINT_NAME}-research.md"
if [ -f "$RESEARCH_FILE" ]; then
  git -C "$ROOT" mv "$RESEARCH_FILE" "$ARCHIVE_DIR/"
  add_own "$ARCHIVE_DIR/$(basename "$RESEARCH_FILE")"
  echo "📦 Archivado: ${SPRINT_NAME}-research.md → docs/sprints/_archived/"
fi

# --- Incluir CHANGELOG.md si fue modificado por update-changelog.sh ---
if [ "$CHANGELOG_MODIFIED" = true ]; then
  add_own "$CHANGELOG"
  echo "📋 CHANGELOG.md añadido al stage."
fi

# --- Commit atómico ---
if [ -n "$VERSION_TAG" ]; then
  COMMIT_MSG="chore: archive ${SPRINT_NAME} [v${VERSION_TAG}]"
else
  COMMIT_MSG="chore: archive ${SPRINT_NAME}"
fi

# VALIDAR ANTES de mover el ref. Sin esto, `git mv` commitearia solo el rename y las
# modificaciones sin stagear quedarian colgando (ocurrio en el cierre de sprint-14, con un
# commit de 0 insertions / 0 deletions). git update-ref NO dispara hooks de git.
_validate_before_commit() {
  local msg="$1" expect="$2"
  local tmp_index tree sha diff_out
  tmp_index="$(mktemp)"; rm -f "$tmp_index"
  if ! GIT_INDEX_FILE="$tmp_index" git -C "$ROOT" read-tree HEAD 2>/dev/null; then
    rm -f "$tmp_index"; git -C "$ROOT" commit -m "$msg"; return 0
  fi
  local staged_tree; staged_tree="$(git -C "$ROOT" write-tree)"
  GIT_INDEX_FILE="$tmp_index" git -C "$ROOT" read-tree "$staged_tree" 2>/dev/null || true
  tree="$(GIT_INDEX_FILE="$tmp_index" git -C "$ROOT" write-tree)"
  sha="$(printf '%s\n' "$msg" | git -C "$ROOT" commit-tree "$tree" -p HEAD)"
  diff_out="$(git -C "$ROOT" -c core.quotePath=false diff-tree -r --no-commit-id --name-status "$sha" 2>/dev/null || true)"
  if printf '%s' "$diff_out" | grep -q -- "$expect"; then
    git -C "$ROOT" update-ref HEAD "$sha" "$(git -C "$ROOT" rev-parse HEAD)"
    rm -f "$tmp_index"; return 0
  fi
  rm -f "$tmp_index"
  RED='\033[0;31m'; NC='\033[0m'
  echo -e "${RED}❌ ABORTADO: el commit de archivado no contiene $expect.${NC}"
  echo -e "${RED}   No se ha creado ningún commit; el repo queda intacto.${NC}"
  return 1
}

if ! _validate_before_commit "$COMMIT_MSG" "_archived/"; then
  exit 1
fi

echo ""
echo "✅ $SPRINT_NAME archivado y commiteado ($DONE/$TOTAL tareas ✅)."
echo "   Commit: $COMMIT_MSG"
if [ "$CHANGELOG_MODIFIED" = true ]; then
  echo "   CHANGELOG.md incluido en el commit."
fi
