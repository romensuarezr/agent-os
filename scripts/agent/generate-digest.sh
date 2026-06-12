#!/bin/bash
# generate-digest.sh — Genera un digest LLM-friendly de una subcarpeta del repo
# Uso: bash scripts/agent/generate-digest.sh --filter <subpath>
# Ejemplo: bash scripts/agent/generate-digest.sh --filter src/components/propuestas
#
# Formato de nombre del digest:
#   kanarii_YYYYMMDD_<rama>_<sha7>_<slug-del-commit>.txt
#   Ejemplo: kanarii_20260529_main_a3f7c2b_fix-auth-roles.txt
#
# Salida: docs/llm-context/<nombre>.txt
# Los digest NO se versionen en Git (.gitignore los excluye).
# Úsalos como contexto para redactar task files, nunca como firewall.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUT_DIR="$ROOT/docs/llm-context"
FILTER="src"
EXCLUDE_PATTERNS=("*.test.*" "*.spec.*" "*.stories.*")

# ── Parsear argumentos ────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --filter)
      FILTER="$2"
      shift 2
      ;;
    --exclude-pattern)
      IFS=' ' read -ra EXTRA_EXCLUDES <<< "$2"
      EXCLUDE_PATTERNS+=("${EXTRA_EXCLUDES[@]}")
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# ── Metadatos del commit para el nombre del archivo ──────────────────────────
DATE=$(date +%Y%m%d)
BRANCH=$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null | tr '/' '-' || echo "unknown")
SHA=$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo "0000000")
COMMIT_MSG=$(git -C "$ROOT" log -1 --pretty=%s 2>/dev/null || echo "no-commit")
# Slug: minúsculas, solo alfanuméricos y guiones, máx 40 chars
COMMIT_SLUG=$(echo "$COMMIT_MSG" | tr '[:upper:]' '[:lower:]' \
  | sed 's/[^a-z0-9]/-/g' \
  | sed 's/--*/-/g' \
  | sed 's/^-//;s/-$//' \
  | cut -c1-40)

FILENAME="kanarii_${DATE}_${BRANCH}_${SHA}_${COMMIT_SLUG}.txt"
mkdir -p "$OUT_DIR"
OUT_FILE="$OUT_DIR/$FILENAME"

echo "=== GENERATE DIGEST ==="
echo "  Filtro:  $ROOT/$FILTER"
echo "  Salida:  $OUT_FILE"
echo ""

# ── Intento 1: gitingest CLI (si está disponible) ────────────────────────────
if command -v gitingest &>/dev/null; then
  echo "⚙️  Usando gitingest CLI..."
  gitingest "$ROOT" --output "$OUT_FILE" --path "$FILTER" 2>/dev/null && {
    echo "✅ Digest generado con gitingest: $FILENAME"
    exit 0
  }
  echo "⚠️  gitingest falló, usando fallback local..."
fi

# ── Intento 2: gitingest vía URL (si el repo es público y hay curl) ──────────
REMOTE_URL=$(git -C "$ROOT" remote get-url origin 2>/dev/null || echo "")
if echo "$REMOTE_URL" | grep -q "github.com"; then
  REPO_PATH=$(echo "$REMOTE_URL" | sed 's|.*github.com[:/]||;s|\.git$||')
  INGEST_URL="https://gitingest.com/$REPO_PATH"
  echo "⚙️  Intentando gitingest.com para $REPO_PATH..."
  HTTP_BODY=$(curl -sf --max-time 15 \
    -X POST "$INGEST_URL" \
    -d "include_patterns=$FILTER" \
    2>/dev/null || echo "")
  if [ -n "$HTTP_BODY" ] && echo "$HTTP_BODY" | grep -q "Directory structure"; then
    echo "$HTTP_BODY" > "$OUT_FILE"
    echo "✅ Digest generado vía gitingest.com: $FILENAME"
    exit 0
  fi
  echo "⚠️  gitingest.com no disponible, usando fallback local..."
fi

# ── Fallback local: árbol + contenido filtrado ───────────────────────────────
TARGET_PATH="$ROOT/$FILTER"
if [ ! -d "$TARGET_PATH" ]; then
  echo "❌ Directorio no encontrado: $TARGET_PATH"
  exit 1
fi

echo "⚙️  Generando digest local de $FILTER..."

# Construir expresión de exclusión para find
FIND_EXCLUDES=()
for pat in "${EXCLUDE_PATTERNS[@]}"; do
  FIND_EXCLUDES+=("!" "-name" "$pat")
done

{
  echo "# ${PROJECT_NAME} — LLM Context Digest"
  echo "# Generado: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "# Rama: $BRANCH | SHA: $SHA | Commit: $COMMIT_MSG"
  echo "# Filtro: $FILTER"
  echo "# Excluidos: ${EXCLUDE_PATTERNS[*]}"
  echo ""
  echo "## Directory Structure"
  echo '```'
  find "$TARGET_PATH" -type f \( -name "*.ts" -o -name "*.tsx" \) \
    "${FIND_EXCLUDES[@]}" 2>/dev/null \
    | sed "s|$ROOT/||" | sort
  echo '```'
  echo ""
  echo "## File Contents"
  find "$TARGET_PATH" -type f \( -name "*.ts" -o -name "*.tsx" \) \
    "${FIND_EXCLUDES[@]}" 2>/dev/null | sort | while IFS= read -r f; do
    REL="${f#$ROOT/}"
    echo ""
    echo "### $REL"
    echo '```typescript'
    cat "$f"
    echo '```'
  done
} > "$OUT_FILE"

TOKEN_ESTIMATE=$(wc -w < "$OUT_FILE" | awk '{printf "%dk", $1/750}')
echo "✅ Digest local generado: $FILENAME (~$TOKEN_ESTIMATE tokens estimados)"
echo "   Ruta: $OUT_FILE"
ados)"
echo "   Ruta: $OUT_FILE"
