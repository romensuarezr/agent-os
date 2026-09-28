#!/usr/bin/env bash
# generate-digest.sh — Genera un digest LLM-friendly de una subcarpeta del repo
# Uso: bash scripts/agent/generate-digest.sh --filter <subpath>
# Ejemplo: bash scripts/agent/generate-digest.sh --filter src/components/propuestas
#
# Formato de nombre del digest:
#   [project-name]_YYYYMMDD_<rama>_<sha7>_<slug-del-commit>.txt
#   Ejemplo: kanarii_20260529_main_a3f7c2b_fix-auth-roles.txt
#
# Salida: docs/llm-context/<nombre>.txt
# Los digest NO se versionen en Git (.gitignore los excluye).
# Úsalos como contexto para redactar task files, nunca como firewall.

set -euo pipefail

for cmd in git awk sed tr cut wc; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "❌ Error: Dependencia requerida '$cmd' no encontrada." >&2
    echo "💡 Guía: Instálala mediante: apt-get install -y $cmd (Linux) o brew install $cmd (macOS)." >&2
    exit 1
  }
done

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUT_DIR="$ROOT/docs/llm-context"

# Cargar biblioteca de detección de stack
source "$(dirname "$0")/lib/detect-stack.sh"
detect_stack "$ROOT"

if [[ "$AGENT_OS_STACK" == "unknown" ]]; then
  echo "ℹ️  Aviso: Stack detectado como 'unknown'. Usando filtros agnósticos por defecto."
  if [[ -n "${STACK_GUIDE:-}" ]]; then
    echo "💡 $STACK_GUIDE"
  fi
fi

if [[ "$SRC_DIR" == "$ROOT" || "$SRC_DIR" == "$ROOT/" || -z "$SRC_DIR" ]]; then
  FILTER="."
else
  FILTER="${SRC_DIR#$ROOT/}"
  FILTER="${FILTER#/}"
  [[ -z "$FILTER" ]] && FILTER="."
fi

EXCLUDE_PATTERNS=("${DIGEST_EXCLUDE[@]}")

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

FILENAME="${PROJECT_NAME}_${DATE}_${BRANCH}_${SHA}_${COMMIT_SLUG}.txt"
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
if [[ "$FILTER" == "." || "$FILTER" == "./" ]]; then
  TARGET_PATH="$ROOT"
elif [[ "$FILTER" = /* ]]; then
  TARGET_PATH="$FILTER"
else
  TARGET_PATH="$ROOT/$FILTER"
fi

if [ ! -d "$TARGET_PATH" ] && [ ! -f "$TARGET_PATH" ]; then
  echo "❌ Directorio o archivo no encontrado: $TARGET_PATH"
  exit 1
fi

echo "⚙️  Generando digest local de $FILTER..."

# Construir expresión de exclusión para find
FIND_EXCLUDES=("!" "-path" "$OUT_DIR/*" "!" "-path" "*/.git/*" "!" "-path" "*/.git")
for pat in "${EXCLUDE_PATTERNS[@]}"; do
  if [[ "$pat" == *"/"* ]]; then
    clean_pat="${pat#/}"
    clean_pat="${clean_pat%/}"
    FIND_EXCLUDES+=("!" "-path" "*/$clean_pat/*" "!" "-path" "*/$clean_pat")
  else
    FIND_EXCLUDES+=("!" "-name" "$pat")
  fi
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
  if [ -f "$TARGET_PATH" ]; then
    echo "$FILTER"
  else
    find "$TARGET_PATH" -type f \( "${CODE_EXTS_FIND[@]}" \) \
      "${FIND_EXCLUDES[@]}" 2>/dev/null \
      | sed "s|$ROOT/||" | sort
  fi
  echo '```'
  echo ""
  echo "## File Contents"
  if [ -f "$TARGET_PATH" ]; then
    echo ""
    echo "### $FILTER"
    echo "\`\`\`${DIGEST_LANG}"
    cat "$TARGET_PATH"
    echo "\`\`\`"
  else
    find "$TARGET_PATH" -type f \( "${CODE_EXTS_FIND[@]}" \) \
      "${FIND_EXCLUDES[@]}" 2>/dev/null | sort | while IFS= read -r f; do
      REL="${f#$ROOT/}"
      echo ""
      echo "### $REL"
      echo "\`\`\`${DIGEST_LANG}"
      cat "$f"
      echo "\`\`\`"
    done
  fi
} > "$OUT_FILE"

TOKEN_ESTIMATE=$(wc -w < "$OUT_FILE" | awk '{printf "%dk", $1/750}')
echo "✅ Digest local generado: $FILENAME (~$TOKEN_ESTIMATE tokens estimados)"
echo "   Ruta: $OUT_FILE"
