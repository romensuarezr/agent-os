#!/usr/bin/env bash
# update-changelog.sh — Genera entrada de changelog.md al cerrar un sprint
# Uso: bash scripts/agent/update-changelog.sh sprint-08
#
# Comportamiento:
# - Lee los commits desde el sprint anterior (o último tag) hasta HEAD
# - Clasifica por tipo (Conventional Commits)
# - Inserta una nueva sección en changelog.md (NO commitea — lo hace close-sprint.sh)
# - Sugiere bump de versión semver

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/cli-help.sh"
for arg in "$@"; do
  if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
    show_help "update-changelog.sh" \
      "bash scripts/agent/update-changelog.sh <sprint-XX>" \
      "Genera de forma automatizada la entrada correspondiente del sprint en changelog.md agrupando commits y sugiriendo semver." \
      "<sprint-XX>              Identificador del sprint que se cierra (ej: sprint-11)" \
      "-h, --help               Muestra este mensaje de ayuda" \
      "ejemplo: bash scripts/agent/update-changelog.sh sprint-11"
  fi
done

# Pre-flight: verificación determinista de dependencias
for cmd in git grep head sed awk mktemp date mv; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ ERROR: Dependencia requerida no encontrada: $cmd" >&2
    echo "Guía: Instala $cmd en tu sistema antes de continuar." >&2
    exit 1
  fi
done

ROOT="$(git rev-parse --show-toplevel)"
if [ -f "$ROOT/CHANGELOG.md" ] && [ ! -f "$ROOT/changelog.md" ]; then
  CHANGELOG="$ROOT/CHANGELOG.md"
else
  CHANGELOG="$ROOT/changelog.md"
fi
DATE=$(date +%Y-%m-%d)

# ─── 1. Argumento obligatorio ────────────────────────────────────────────────
if [ $# -lt 1 ]; then
  echo "❌ Uso: bash scripts/agent/update-changelog.sh sprint-XX"
  exit 1
fi
# Normalización canónica del identificador del sprint (Precision 1 T-146)
SPRINT_NAME_RAW="$(basename "$1" .md)"
SPRINT_NAME="${SPRINT_NAME_RAW%-core}"  # e.g. sprint-08

# ─── 2. Determinar rango de commits ──────────────────────────────────────────
# Busca el tag del sprint anterior o cae a 'git log' completo.
# La base es la ÚLTIMA VERSIÓN publicada, no el tag creado más recientemente:
# con -creatordate, un tag de parche creado después sobre un commit viejo mueve el
# rango hacia atrás y duplica en el changelog commits ya publicados. -v:refname
# ordena por versión (T-114). No se usa 'git describe': en una rama de trabajo que
# no ha recibido el merge de la release devuelve la última etiqueta ALCANZABLE
# (v1.12.0 en multi-agent mientras main ya estaba en v1.14.0), y eso reabre el
# rango de dos sprints.
PREV_TAG=$(git -C "$ROOT" tag --list 'v*' --sort=-v:refname 2>/dev/null | head -1 || true)
if [ -n "$PREV_TAG" ]; then
  RANGE="${PREV_TAG}..HEAD"
  echo "📌 Rango: desde tag '$PREV_TAG' hasta HEAD"
  COMMITS=$(git -C "$ROOT" log --oneline --no-merges "$RANGE" 2>/dev/null || true)
else
  # Sin tags: usa los últimos commits hasta HEAD sin fallar si el repo tiene <50 commits
  echo "📌 Sin tags previos. Usando últimos commits hasta HEAD."
  COMMITS=$(git -C "$ROOT" log --oneline --no-merges -50 HEAD 2>/dev/null || true)
fi

# ─── 3. Extraer y clasificar commits ─────────────────────────────────────────
if [ -z "$COMMITS" ]; then
  echo "⚠️  No se encontraron commits en el rango. ¿El sprint tiene trabajo?" >&2
  exit 1
fi

FEATS=""
FIXES=""
DOCS=""
REFACTOR=""
CHORES=""
OTHERS=""

HAS_FEAT=false
HAS_FIX=false
HAS_BREAKING=false

while IFS= read -r line; do
  MSG=$(echo "$line" | sed 's/^[a-f0-9]* //')
  case "$MSG" in
    feat!:*|fix!:*|refactor!:*)
      HAS_BREAKING=true
      HAS_FEAT=true
      FEATS="${FEATS}\n- ${MSG}"
      ;;
    feat:*|feat\(*)
      HAS_FEAT=true
      FEATS="${FEATS}\n- ${MSG}"
      ;;
    fix:*|fix\(*)
      HAS_FIX=true
      FIXES="${FIXES}\n- ${MSG}"
      ;;
    docs:*|docs\(*)
      DOCS="${DOCS}\n- ${MSG}"
      ;;
    refactor:*|refactor\(*)
      REFACTOR="${REFACTOR}\n- ${MSG}"
      ;;
    chore:*|chore\(*)
      CHORES="${CHORES}\n- ${MSG}"
      ;;
    *)
      OTHERS="${OTHERS}\n- ${MSG}"
      ;;
  esac
done <<< "$COMMITS"

# ─── 4. Sugerir versión semver ────────────────────────────────────────────────
# Lee la PRIMERA cabecera con semver válida, ignorando ## [Unreleased] y similares
# (T-108: 'grep -m1' caía en Unreleased → fallback 0.0.0 → generaba 0.1.0).
# Sin semver en el changelog: cae al último tag v* (orden semver). Sin tags: 0.0.0.
# Los '|| true' preservan la protección contra grep sin match bajo 'set -euo pipefail'.
CURRENT_VERSION=$(grep -E '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "$CHANGELOG" 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
if [ -z "$CURRENT_VERSION" ]; then
  CURRENT_VERSION=$(git -C "$ROOT" tag --list 'v*' --sort=-v:refname 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
fi
[ -n "$CURRENT_VERSION" ] || CURRENT_VERSION="0.0.0"
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Declaración explícita del cálculo determinista de SemVer (Precision 2 T-146):
# - Breaking changes -> bump MAJOR ((MAJOR+1).0.0)
# - Nuevas features (feat) -> bump MINOR (MAJOR.(MINOR+1).0)
# - Fixes, docs, refactor, chore o gobernanza pura -> bump PATCH (MAJOR.MINOR.(PATCH+1))
# Sin elección interactiva ni prompts.
if [ "$HAS_BREAKING" = true ]; then
  NEW_VERSION="$((MAJOR + 1)).0.0"
  BUMP_REASON="breaking change detectado (MAJOR)"
elif [ "$HAS_FEAT" = true ]; then
  NEW_VERSION="${MAJOR}.$((MINOR + 1)).0"
  BUMP_REASON="nuevas features (feat:) (MINOR)"
elif [ "$HAS_FIX" = true ]; then
  NEW_VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))"
  BUMP_REASON="solo fixes (PATCH)"
else
  NEW_VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))"
  BUMP_REASON="docs/refactor/chore o gobernanza (PATCH)"
fi

# ─── 5. Construir la entrada del changelog ───────────────────────────────────
ENTRY="## [${NEW_VERSION}] — ${SPRINT_NAME} — ${DATE}\n"

if [ -n "$FEATS" ]; then
  ENTRY="${ENTRY}\n### ✨ Features\n${FEATS}\n"
fi
if [ -n "$FIXES" ]; then
  ENTRY="${ENTRY}\n### 🐛 Bug Fixes\n${FIXES}\n"
fi
if [ -n "$REFACTOR" ]; then
  ENTRY="${ENTRY}\n### ♻️ Refactoring\n${REFACTOR}\n"
fi
if [ -n "$DOCS" ]; then
  ENTRY="${ENTRY}\n### 📚 Documentación\n${DOCS}\n"
fi
if [ -n "$CHORES" ]; then
  ENTRY="${ENTRY}\n### 🔧 Mantenimiento\n${CHORES}\n"
fi
if [ -n "$OTHERS" ]; then
  ENTRY="${ENTRY}\n### 📦 Otros\n${OTHERS}\n"
fi

# ─── 6. Insertar en changelog.md ─────────────────────────────────────────────
if [ ! -f "$CHANGELOG" ]; then
  # Crear changelog.md si no existe
  printf '# Changelog\n\nTodos los cambios notables se documentan aquí.\nFormato basado en [Keep a Changelog](https://keepachangelog.com/).\nVersionado según [Semantic Versioning](https://semver.org/).\n\n' > "$CHANGELOG"
  echo "📄 changelog.md creado."
fi

# Insertar después de la primera línea de cabecera (# Changelog ...)
TMP=$(mktemp)
awk -v entry="$(printf '%b' "$ENTRY")" '
  /^## \[/ && !inserted {
    print entry
    print ""
    inserted=1
  }
  { print }
  END { if (!inserted) print entry }
' "$CHANGELOG" > "$TMP"

# Si el archivo no tenía entradas previas, awk END lo habrá añadido al final — bien
mv "$TMP" "$CHANGELOG"

# ─── 7. Resumen ──────────────────────────────────────────────────────────────
echo ""
echo "✅ changelog.md actualizado"
echo "   Sprint  : $SPRINT_NAME"
echo "   Versión : $CURRENT_VERSION → $NEW_VERSION ($BUMP_REASON)"
echo "   Fecha   : $DATE"
echo ""
echo "ℹ️  El archivo está modificado pero NO commitado."
echo "   Se incluirá en el commit de 'close-sprint.sh' automáticamente."
echo "   Para ver los cambios: git diff changelog.md"
