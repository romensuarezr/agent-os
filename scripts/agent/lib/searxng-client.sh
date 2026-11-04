#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/lib/searxng-client.sh — Cliente determinista CLI para SearXNG
# ==============================================================================
# Cliente ligero en Bash POSIX para interactuar con el motor de meta-búsqueda
# soberana SearXNG ($0 tokens, privacidad garantizada).
#
# Principios:
#   - Salida primaria por stdout en formato Markdown estructurado.
#   - Semántica estricta de disponibilidad: exit 0 si está activo y accesible;
#     degrada limpiamente con código 2 si está inactivo/no configurado.
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
    show_help "searxng-client.sh" \
      "bash scripts/agent/lib/searxng-client.sh [--query <TEXT>] [--timeout <SEC>] [--output <FILE>] [--check] [--json]" \
      "Cliente determinista CLI para interactuar con el motor de meta-búsqueda soberano SearXNG ($0)." \
      "--query <string>      Texto de la consulta técnica a buscar (emite Markdown por stdout)" \
      "--timeout <seg>       Timeout máximo en segundos (defecto: 10s para query, 3s para check)" \
      "--output <path>       Ruta opcional donde guardar el resultado en Markdown" \
      "--check               Sonda de salud: exit 0 si activo/alcanzable, exit 2 si inactivo/no-configurado" \
      "--json                Emite salida estructurada JSON con metadatos" \
      "-h, --help            Muestra este mensaje de ayuda" \
      "ejemplo: bash scripts/agent/lib/searxng-client.sh --check" \
      "ejemplo: bash scripts/agent/lib/searxng-client.sh --query 'Arquitectura micro frontends Next.js 15'" \
      "ejemplo: bash scripts/agent/lib/searxng-client.sh --query 'Deep research' --output /tmp/res.md"
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

# Resolver URL de SearXNG (entorno o fleet.yaml)
resolve_searxng_url() {
  if [ -n "${SEARXNG_API_URL:-}" ]; then
    echo "$SEARXNG_API_URL"
    return 0
  fi
  if [ -n "${BANE_API_URL:-}" ]; then
    echo "$BANE_API_URL"
    return 0
  fi
  local root fleet_file
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  fleet_file="${FLEET_FILE:-$root/.agents/config/fleet.yaml}"
  if [ -f "$fleet_file" ]; then
    local u
    u=$(python3 -c "
import yaml
try:
    d = yaml.safe_load(open('$fleet_file')) or {}
    nodes = d.get('nodes', {})
    for nname, ndata in nodes.items():
        svcs = ndata.get('services', {})
        if 'searxng' in svcs:
            s = svcs['searxng']
            if isinstance(s, dict):
                print(s.get('endpoint') or s.get('url') or '')
                exit(0)
            elif isinstance(s, str):
                print(s)
                exit(0)
        if 'bane' in svcs:
            b = svcs['bane']
            if isinstance(b, dict):
                print(b.get('endpoint') or b.get('url') or '')
                exit(0)
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
  SEARCH_URL="$(resolve_searxng_url || true)"

  if [ -z "$SEARCH_URL" ]; then
    if [ "$JSON_MODE" = true ]; then
      python3 -c '
import json
print(json.dumps({"status": "inactive", "active": False, "reason": "not_configured"}))
'
    else
      echo "[INACTIVO] SearXNG no está configurado (defina SEARXNG_API_URL o declare en fleet.yaml)." >&2
    fi
    exit 2
  fi

  # Probar conectividad HTTP rápida (healthz o raíz)
  HTTP_CODE=0
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m "$CHECK_TIMEOUT" "$SEARCH_URL/healthz" 2>/dev/null || true)
  if [ "$HTTP_CODE" -eq 0 ] || [ "$HTTP_CODE" -ge 400 ]; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m "$CHECK_TIMEOUT" "$SEARCH_URL/" 2>/dev/null || true)
  fi

  if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 400 ]; then
    if [ "$JSON_MODE" = true ]; then
      python3 -c "
import json
print(json.dumps({'status': 'active', 'active': True, 'url': '$SEARCH_URL', 'http_code': $HTTP_CODE}))
"
    else
      echo "[ACTIVO] SearXNG responde en $SEARCH_URL (HTTP $HTTP_CODE)."
    fi
    exit 0
  else
    if [ "$JSON_MODE" = true ]; then
      python3 -c "
import json
print(json.dumps({'status': 'inactive', 'active': False, 'reason': 'unreachable', 'url': '$SEARCH_URL', 'http_code': $HTTP_CODE}))
"
    else
      echo "[INACTIVO] SearXNG inalcanzable en $SEARCH_URL (HTTP $HTTP_CODE o timeout)." >&2
    fi
    exit 2
  fi
fi

# ------------------------------------------------------------------------------
# MODO: --query (Consulta de Búsqueda Soberana)
# ------------------------------------------------------------------------------
if [ -z "$QUERY" ]; then
  echo "❌ Error: Debe especificar una consulta con --query o usar --check." >&2
  exit 1
fi

QUERY_TIMEOUT="${TIMEOUT:-10}"
SEARCH_URL="$(resolve_searxng_url || true)"

if [ -z "$SEARCH_URL" ]; then
  if [ "$JSON_MODE" = true ]; then
    python3 -c '
import json
print(json.dumps({"ok": False, "error": "SearXNG no configurado"}))
'
  else
    echo "❌ Error: SearXNG no está configurado en fleet.yaml ni en SEARXNG_API_URL." >&2
  fi
  exit 2
fi

RAW_RESPONSE=""
RC_CURL=0
RAW_RESPONSE=$(python3 -c "
import urllib.parse, urllib.request, json, sys

query = sys.argv[1]
base_url = sys.argv[2].rstrip('/')
timeout = float(sys.argv[3])

params = urllib.parse.urlencode({'q': query, 'format': 'json'})
url = f'{base_url}/search?{params}'

req = urllib.request.Request(url, headers={'User-Agent': 'agent-os-searxng-client/1.0'})
try:
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        print(resp.read().decode('utf-8'))
except Exception as e:
    sys.stderr.write(f'HTTP request error: {e}\n')
    sys.exit(2)
" "$QUERY" "$SEARCH_URL" "$QUERY_TIMEOUT") || RC_CURL=$?

if [ "$RC_CURL" -ne 0 ] || [ -z "$RAW_RESPONSE" ]; then
  if [ "$JSON_MODE" = true ]; then
    python3 -c "
import json
print(json.dumps({'ok': False, 'error': 'Fallo de comunicacion con SearXNG', 'exit_code': $RC_CURL}))
"
  else
    echo "❌ Error: No se pudo obtener respuesta de SearXNG en $SEARCH_URL." >&2
  fi
  exit 2
fi

# Formatear Markdown o JSON según modo
OUTPUT_TEXT=$(python3 - "$RAW_RESPONSE" "$QUERY" "$JSON_MODE" <<'PYEOF'
import json, sys

raw = sys.argv[1]
query = sys.argv[2]
json_mode = (sys.argv[3] == 'true')

try:
    data = json.loads(raw)
except Exception:
    if json_mode:
        print(json.dumps({'ok': False, 'error': 'Invalid JSON from engine'}))
    else:
        print(raw)
    sys.exit(0)

results = data.get('results', [])
if json_mode:
    print(json.dumps({
        'ok': True,
        'query': query,
        'count': len(results),
        'results': results[:10]
    }))
else:
    md = [f'## Resultados de Búsqueda Soberana: {query}\n']
    if not results:
        md.append('_No se encontraron resultados relevantes._')
    else:
        for i, r in enumerate(results[:10], 1):
            title = r.get('title', 'Sin título').strip()
            url = r.get('url', '').strip()
            content = r.get('content', '').strip()
            engine = r.get('engine', '')
            engine_tag = f' `[{engine}]`' if engine else ''
            md.append(f'{i}. **[{title}]({url})**{engine_tag}')
            if content:
                md.append(f'   {content}\n')
            else:
                md.append('')
    print('\n'.join(md))
PYEOF
)

# Salida primaria por stdout
printf "%s\n" "$OUTPUT_TEXT"

# Volcado opcional a archivo si se especificó --output
if [ -n "$OUTPUT_FILE" ]; then
  mkdir -p "$(dirname "$OUTPUT_FILE")"
  printf "%s\n" "$OUTPUT_TEXT" > "$OUTPUT_FILE"
fi

exit 0
