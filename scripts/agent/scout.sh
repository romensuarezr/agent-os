#!/usr/bin/env bash
# scout.sh — Prospección tecnológica determinista pre-código (0 tokens de inferencia)
# Uso: bash scripts/agent/scout.sh "<keywords>" [--limit N]
#
# Propósito: Consultar repositorios OSS (GitHub REST API), paquetes del ecosistema (NPM Registry API)
# y discusiones técnicas comunitarias (Hacker News Algolia API) de forma rápida y determinista.
# El agente sólo lee el digest final (10-15 líneas), evitando búsquedas web masivas y alucinaciones.

set -euo pipefail

KEYWORDS="${1:-}"
LIMIT=3

if [ -z "$KEYWORDS" ]; then
  echo "❌ Error: Debes especificar al menos una palabra clave para la prospección."
  echo "Uso: bash scripts/agent/scout.sh \"<keywords>\" [--limit N]"
  echo "Ejemplo: bash scripts/agent/scout.sh \"hotel booking nextjs\""
  exit 1
fi

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit)
      LIMIT="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# Requisitos básicos
for cmd in curl jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "❌ Error: Se requiere '$cmd' en el sistema."
    exit 1
  fi
done

# URL encode sencillo (reemplazar espacios por +)
ENCODED_QUERY=$(echo "$KEYWORDS" | tr ' ' '+' | tr -d '\n\r')

CURL_OPTS=(-s --connect-timeout 4 --max-time 6 -H "User-Agent: agent-os-scout")

echo "=== 🔎 SCOUT: \"$KEYWORDS\" ==="
echo ""

# 1. GITHUB REPOSITORIES (OSS)
echo "📦 TOP GITHUB REPOS (OSS):"
GH_RESP=$(curl "${CURL_OPTS[@]}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/search/repositories?q=${ENCODED_QUERY}&sort=stars&order=desc&per_page=${LIMIT}" 2>/dev/null || echo "{}")

if echo "$GH_RESP" | jq -e '.items and (.items | length > 0)' >/dev/null 2>&1; then
  echo "$GH_RESP" | jq -r --argjson lim "$LIMIT" '
    .items[:$lim][] |
    "- \(.full_name) (\(.stargazers_count)⭐ | \(.license.spdx_id // "No lic")): \((.description // "Sin descripción") | split("\n")[0] | .[0:90]) (\(.html_url))"
  '
else
  echo "  (No se encontraron repositorios relevantes o límite de API alcanzado)"
fi

echo ""

# 2. NPM PACKAGES (Ecosistema JS/TS)
echo "📚 TOP PACKAGES (NPM / Ecosistema):"
NPM_RESP=$(curl "${CURL_OPTS[@]}" \
  "https://registry.npmjs.org/-/v1/search?text=${ENCODED_QUERY}&size=${LIMIT}" 2>/dev/null || echo "{}")

if echo "$NPM_RESP" | jq -e '.objects and (.objects | length > 0)' >/dev/null 2>&1; then
  echo "$NPM_RESP" | jq -r --argjson lim "$LIMIT" '
    .objects[:$lim][] |
    "- \(.package.name) (v\(.package.version)): \((.package.description // "Sin descripción") | split("\n")[0] | .[0:90]) (\(.package.links.npm))"
  '
else
  echo "  (No se encontraron paquetes relevantes en NPM)"
fi

echo ""

# 3. COMMUNITY DISCUSSIONS (Hacker News Algolia)
echo "💬 COMMUNITY DISCUSSIONS (Hacker News / Arquitectura):"
HN_RESP=$(curl "${CURL_OPTS[@]}" \
  "https://hn.algolia.com/api/v1/search?query=${ENCODED_QUERY}&tags=story&hitsPerPage=${LIMIT}" 2>/dev/null || echo "{}")

if echo "$HN_RESP" | jq -e '.hits and (.hits | length > 0)' >/dev/null 2>&1; then
  echo "$HN_RESP" | jq -r --argjson lim "$LIMIT" '
    .hits[:$lim][] |
    "- \"\((.title // "Sin título") | .[0:80])\" (\(.points // 0) pts, \(.num_comments // 0) coms): https://news.ycombinator.com/item?id=\(.objectID)"
  '
else
  echo "  (Sin discusiones recientes en Hacker News)"
fi

echo ""
echo "=== FIN SCOUT (0 tokens de inferencia en prospección) ==="
