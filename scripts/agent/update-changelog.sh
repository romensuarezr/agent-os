#!/usr/bin/env bash
# update-changelog.sh — Genera entrada de CHANGELOG.md al cerrar un sprint
# Uso: bash scripts/agent/update-changelog.sh sprint-08
#
# Comportamiento:
# - Lee los commits desde el sprint anterior (o último tag) hasta HEAD
# - Clasifica por tipo (Conventional Commits)
# - Inserta una nueva sección en CHANGELOG.md (NO commitea — lo hace close-sprint.sh)
# - Sugiere bump de versión semver

set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
CHANGELOG="$ROOT/CHANGELOG.md"
DATE=$(date +%Y-%m-%d)

# ─── 1. Argumento obligatorio ────────────────────────────────────────────────
if [ $# -lt 1 ]; then
  echo "❌ Uso: bash scripts/agent/update-changelog.sh sprint-XX"
  exit 1
fi
SPRINT_NAME="$1"  # e.g. sprint-08

# ─── 2. Determinar rango de commits ──────────────────────────────────────────
# Busca el tag del sprint anterior o cae a 'git log' completo
PREV_TAG=$(git -C "$ROOT" tag --sort=-creatordate | head -1 2>/dev/null || true)
if [ -n "$PREV_TAG" ]; then
  RANGE="${PREV_TAG}..HEAD"
  echo "📌 Rango: desde tag '$PREV_TAG' hasta HEAD"
else
  # Sin tags: usa los últimos 50 commits como fallback razonable
  RANGE="HEAD~50..HEAD"
  echo "📌 Sin tags previos. Usando últimos 50 commits."
fi

# ─── 3. Extraer y clasificar commits ─────────────────────────────────────────
COMMITS=$(git -C "$ROOT" log --oneline --no-merges "$RANGE" 2>/dev/null || true)

if [ -z "$COMMITS" ]; then
  echo "⚠️  No se encontraron commits en el rango '$RANGE'. ¿El sprint tiene trabajo?"
  exit 0
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
CURRENT_VERSION=$(grep -m1 '^## \[' "$CHANGELOG" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "0.0.0")
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

if [ "$HAS_BREAKING" = true ]; then
  NEW_VERSION="$((MAJOR + 1)).0.0"
  BUMP_REASON="breaking change detectado"
elif [ "$HAS_FEAT" = true ]; then
  NEW_VERSION="${MAJOR}.$((MINOR + 1)).0"
  BUMP_REASON="nuevas features (feat:)"
elif [ "$HAS_FIX" = true ]; then
  NEW_VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))"
  BUMP_REASON="solo fixes"
else
  NEW_VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))"
  BUMP_REASON="docs/refactor/chore"
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

# ─── 6. Insertar en CHANGELOG.md ─────────────────────────────────────────────
if [ ! -f "$CHANGELOG" ]; then
  # Crear CHANGELOG.md si no existe
  printf '# Changelog\n\nTodos los cambios notables se documentan aquí.\nFormato basado en [Keep a Changelog](https://keepachangelog.com/).\nVersionado según [Semantic Versioning](https://semver.org/).\n\n' > "$CHANGELOG"
  echo "📄 CHANGELOG.md creado."
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
echo "✅ CHANGELOG.md actualizado"
echo "   Sprint  : $SPRINT_NAME"
echo "   Versión : $CURRENT_VERSION → $NEW_VERSION ($BUMP_REASON)"
echo "   Fecha   : $DATE"
echo ""
echo "ℹ️  El archivo está modificado pero NO commitado."
echo "   Se incluirá en el commit de 'close-sprint.sh' automáticamente."
echo "   Para ver los cambios: git diff CHANGELOG.md"
