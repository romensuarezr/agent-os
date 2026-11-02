#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/lib/bane-client.sh — Cliente determinista CLI para Bane
# ==============================================================================
# Cliente ligero en Bash POSIX para interactuar con el motor de deep research
# Bane (Perplexity Pro open-source).
#
# Principios:
#   - Salida primaria por stdout en formato Markdown.
#   - Semántica estricta de disponibilidad: "ACTIVO" solo si está configurado Y
#     alcanzable dentro del timeout; degrada con código 2 si está inactivo/caído.
#   - Fail-soft: nunca bloquea la ejecución del proceso padre ante errores de red.
#   - Cero dependencias externas (curl + python3 estándar).
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/agent/lib/cli-help.sh
source "$SCRIPT_DIR/cli-help.sh" 2>/dev/null || {
  show_help() { echo "$@"; exit 0; }
}

for arg in "$@"; do
  if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
    show_help "bane-client.sh" \
      "bash scripts/agent/lib/bane-client.sh [--query <TEXT>] [--timeout <SEC>] [--output <FILE>] [--check] [--json]" \
      "Cliente determinista CLI para interactuar con el motor de deep research Bane (Perplexity Pro local)." \
      "--query <string>      Texto de la consulta técnica a investigar (emite Markdown por stdout)" \
      "--timeout <seg>       Timeout máximo en segundos (defecto: 60s para query, 3s para check)" \
      "--output <path>       Ruta opcional donde guardar el resultado en Markdown" \
      "--check               Sonda de salud: exit 0 si activo/alcanzable, exit 2 si inactivo/no-configurado" \
      "--json                Emite salida estructurada JSON con metadatos" \
      "-h, --help            Muestra este mensaje de ayuda" \
      "ejemplo: bash scripts/agent/lib/bane-client.sh --check" \
      "ejemplo: bash scripts/agent/lib/bane-client.sh --query 'Arquitectura micro frontends Next.js 15'" \
      "ejemplo: bash scripts/agent/lib/bane-client.sh --query 'Deep research' --output /tmp/res.md"
  fi
done

QUERY=""
TIMEOUT=""
OUTPUT_FILE=""
CHECK_MODE=false
JSON_MODE=false

while [ $# -gt 0 ]; do
  case "$1" in
    --query)
      QUERY="${2:-}"
      shift 2
      ;;
    --timeout)
      TIMEOUT="${2:-}"
      shift 2
      ;;
    --output)
      OUTPUT_FILE="${2:-}"
      shift 2
      ;;
    --check)
      CHECK_MODE=true
      shift
      ;;
    --json)
      JSON_MODE=true
      shift
      ;;
    -h|--help)
      exit 0
      ;;
    *)
      echo "❌ Error: argumento desconocido '$1'." >&2
      exit 1
      ;;
  esac
done

# Resolver URL de Bane
resolve_bane_url() {
  if [ -n "${BANE_API_URL:-}" ]; then
    echo "$BANE_API_URL"
    return 0
  fi
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  if [ -f "$root/.agents/config/fleet.yaml" ]; then
    local u
    u=$(python3 -c "
import yaml, sys
try:
    d = yaml.safe_load(open('$root/.agents/config/fleet.yaml')) or {}
    srv = d.get('nodes', {}).get('<nodo-inferencia>', {}).get('services', {}).get('bane', {})
    print(srv.get('endpoint') or srv.get('url') or '')
except Exception:
    pass
" 2>/dev/null || true)
    if [ -n "$u" ] && [ "$u" != "None" ]; then
      echo "$u"
      return 0
    fi
  fi
  return 1
}

# ------------------------------------------------------------------------------
# MODO: --check (Sonda de salud fail-soft)
# ------------------------------------------------------------------------------
if [ "$CHECK_MODE" = true ]; then
  CHECK_TIMEOUT="${TIMEOUT:-3}"
  BANE_URL="$(resolve_bane_url || true)"

  if [ -z "$BANE_URL" ]; then
    if [ "$JSON_MODE" = true ]; then
      python3 -c '
import json
print(json.dumps({"status": "inactive", "active": False, "reason": "not_configured"}))
'
    else
      echo "[INACTIVO] Bane no está configurado (defina BANE_API_URL o declare en fleet.yaml)." >&2
    fi
    exit 2
  fi

  # Probar conectividad HTTP rápida
  HTTP_CODE=0
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m "$CHECK_TIMEOUT" "$BANE_URL/health" 2>/dev/null || true)
  if [ "$HTTP_CODE" -eq 0 ] || [ "$HTTP_CODE" -ge 500 ]; then
    # Fallback a raíz si /health no responde
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m "$CHECK_TIMEOUT" "$BANE_URL/" 2>/dev/null || true)
  fi

  if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 400 ]; then
    if [ "$JSON_MODE" = true ]; then
      python3 -c "
import json
print(json.dumps({'status': 'active', 'active': True, 'url': '$BANE_URL', 'http_code': $HTTP_CODE}))
"
    else
      echo "[ACTIVO] Bane responde en $BANE_URL (HTTP $HTTP_CODE)."
    fi
    exit 0
  else
    if [ "$JSON_MODE" = true ]; then
      python3 -c "
import json
print(json.dumps({'status': 'inactive', 'active': False, 'reason': 'unreachable', 'url': '$BANE_URL', 'http_code': $HTTP_CODE}))
"
    else
      echo "[INACTIVO] Bane inalcanzable en $BANE_URL (HTTP $HTTP_CODE o timeout)." >&2
    fi
    exit 2
  fi
fi

# ------------------------------------------------------------------------------
# MODO: --query (Consulta de Deep Research)
# ------------------------------------------------------------------------------
if [ -z "$QUERY" ]; then
  echo "❌ Error: Debe especificar una consulta con --query o usar --check." >&2
  exit 1
fi

QUERY_TIMEOUT="${TIMEOUT:-60}"
BANE_URL="$(resolve_bane_url || true)"

if [ -z "$BANE_URL" ]; then
  if [ "$JSON_MODE" = true ]; then
    python3 -c '
import json
print(json.dumps({"ok": False, "error": "Bane no configurado"}))
'
  else
    echo "❌ Error: Bane no está configurado en fleet.yaml ni en BANE_API_URL." >&2
  fi
  exit 2
fi

PAYLOAD=$(python3 -c "
import json, sys
print(json.dumps({'query': sys.argv[1]}))
" "$QUERY")

RESPONSE=""
RC_CURL=0
RESPONSE=$(curl -s -f -m "$QUERY_TIMEOUT" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  "$BANE_URL/api/research" 2>/dev/null) || RC_CURL=$?

if [ "$RC_CURL" -ne 0 ] || [ -z "$RESPONSE" ]; then
  # Fallback a endpoint alternativo /api/search
  RC_CURL=0
  RESPONSE=$(curl -s -f -m "$QUERY_TIMEOUT" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "$BANE_URL/api/search" 2>/dev/null) || RC_CURL=$?
fi

if [ "$RC_CURL" -ne 0 ] || [ -z "$RESPONSE" ]; then
  if [ "$JSON_MODE" = true ]; then
    python3 -c "
import json
print(json.dumps({'ok': False, 'error': 'Fallo de comunicacion con Bane', 'exit_code': $RC_CURL}))
"
  else
    echo "❌ Error: No se pudo obtener respuesta de Bane en $BANE_URL (curl exit $RC_CURL)." >&2
  fi
  exit 2
fi

# Extraer Markdown de la respuesta (directo si ya es texto plano, o campo 'result' / 'markdown' si es JSON)
MARKDOWN_OUTPUT=$(python3 -c "
import json, sys
raw = sys.argv[1]
try:
    d = json.loads(raw)
    if isinstance(d, dict):
        print(d.get('result') or d.get('markdown') or d.get('answer') or raw)
    else:
        print(raw)
except Exception:
    print(raw)
" "$RESPONSE")

# Salida primaria por stdout
if [ "$JSON_MODE" = true ]; then
  python3 -c "
import json, sys
res = sys.argv[1]
q = sys.argv[2]
print(json.dumps({'ok': True, 'query': q, 'result': res}))
" "$MARKDOWN_OUTPUT" "$QUERY"
else
  printf "%s\n" "$MARKDOWN_OUTPUT"
fi

# Volcado opcional a archivo si se especificó --output
if [ -n "$OUTPUT_FILE" ]; then
  mkdir -p "$(dirname "$OUTPUT_FILE")"
  printf "%s\n" "$MARKDOWN_OUTPUT" > "$OUTPUT_FILE"
fi

exit 0
