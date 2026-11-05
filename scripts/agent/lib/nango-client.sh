#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/lib/nango-client.sh — Cliente determinista CLI para Nango
# ==============================================================================
# Cliente ligero en Bash POSIX para interactuar con la plataforma de integración
# y pasarela de autenticación unificada Nango (<nodo-orquestacion>:3003).
#
# Principios:
#   - Semántica estricta de disponibilidad: exit 0 si está activo y accesible;
#     degrada limpiamente con código 2 si está inactivo/no configurado.
#   - Cero exposición de secretos en argv o disco; resolución segura de
#     credenciales a través de variables de entorno o Infisical vault.
#   - Soporte para verificación de salud (--check), inspección de integraciones
#     (--list-integrations, --list-connections), y consumo proxy delegado (--proxy).
#   - Formato determinista por stdout en Markdown estructurado o JSON (--json).
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/agent/lib/cli-help.sh
source "$SCRIPT_DIR/cli-help.sh" 2>/dev/null || {
  show_help() { echo "$@"; exit 0; }
}

for arg in "$@"; do
  if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
    show_help "nango-client.sh" \
      "bash scripts/agent/lib/nango-client.sh [--check] [--list-integrations] [--list-connections] [--proxy <PATH>] [--provider <KEY>] [--connection <ID>] [--timeout <SEC>] [--json]" \
      "Cliente determinista CLI para interactuar con la plataforma unificada Nango." \
      "--check                    Sonda de salud: exit 0 si activo/alcanzable, exit 2 si inactivo/no-configurado" \
      "--list-integrations        Lista las integraciones activas configuradas en Nango" \
      "--list-connections         Lista las conexiones autorizadas activas en Nango" \
      "--proxy <path>             Ejecuta una petición proxy autenticada hacia la API externa delegada" \
      "--provider <key>           Provider config key para peticiones proxy (ej: cloudflare-dns)" \
      "--connection <id>          Connection ID para peticiones proxy (ej: romensuarez-com)" \
      "--method <GET|POST|...>    Método HTTP para petición proxy (defecto: GET)" \
      "--timeout <seg>            Timeout máximo en segundos (defecto: 10s para proxy, 3s para check)" \
      "--json                     Emite salida estructurada JSON por stdout" \
      "-h, --help                 Muestra este mensaje de ayuda" \
      "ejemplo: bash scripts/agent/lib/nango-client.sh --check" \
      "ejemplo: bash scripts/agent/lib/nango-client.sh --list-connections" \
      "ejemplo: bash scripts/agent/lib/nango-client.sh --proxy '/v4/zones' --provider cloudflare-dns --connection romensuarez-com"
  fi
done

CHECK_MODE=false
LIST_INTEGRATIONS=false
LIST_CONNECTIONS=false
PROXY_PATH=""
PROVIDER_KEY=""
CONNECTION_ID=""
HTTP_METHOD="GET"
TIMEOUT=""
JSON_MODE=false

while [ $# -gt 0 ]; do
  case "$1" in
    --check)
      CHECK_MODE=true
      shift
      ;;
    --list-integrations)
      LIST_INTEGRATIONS=true
      shift
      ;;
    --list-connections)
      LIST_CONNECTIONS=true
      shift
      ;;
    --proxy)
      PROXY_PATH="${2:-}"
      shift 2
      ;;
    --provider)
      PROVIDER_KEY="${2:-}"
      shift 2
      ;;
    --connection)
      CONNECTION_ID="${2:-}"
      shift 2
      ;;
    --method)
      HTTP_METHOD="${2:-GET}"
      shift 2
      ;;
    --timeout)
      TIMEOUT="${2:-}"
      shift 2
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

# Resolver URL de Nango (entorno o fleet.yaml)
resolve_nango_url() {
  if [ -n "${NANGO_SERVER_URL:-}" ]; then
    echo "$NANGO_SERVER_URL"
    return 0
  fi
  if [ -n "${NANGO_API_URL:-}" ]; then
    echo "$NANGO_API_URL"
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
        if 'nango' in svcs:
            s = svcs['nango']
            if isinstance(s, dict):
                print(s.get('endpoint') or s.get('url') or '')
                exit(0)
            elif isinstance(s, str):
                print(s)
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

# Resolver Secret Key de Nango (entorno o bóveda Infisical)
resolve_nango_key() {
  if [ -n "${NANGO_SECRET_KEY:-}" ]; then
    echo "$NANGO_SECRET_KEY"
    return 0
  fi
  # Intento de extracción segura desde Infisical si está disponible en el entorno
  if [ -n "${INFISICAL_API_URL:-}" ] && [ -n "${INFISICAL_PROJECT_ID:-}" ] && [ -n "${INFISICAL_CLIENT_ID:-}" ] && [ -n "${INFISICAL_CLIENT_SECRET:-}" ]; then
    local k
    k=$(python3 -c "
import os, json, urllib.request
try:
    api = os.environ['INFISICAL_API_URL'].rstrip('/')
    cid = os.environ['INFISICAL_CLIENT_ID']
    csecret = os.environ['INFISICAL_CLIENT_SECRET']
    pid = os.environ['INFISICAL_PROJECT_ID']
    req = urllib.request.Request(
        f'{api}/v1/auth/universal-auth/login',
        data=json.dumps({'clientId': cid, 'clientSecret': csecret}).encode(),
        headers={'Content-Type': 'application/json'}
    )
    tkn = json.loads(urllib.request.urlopen(req, timeout=4).read())['accessToken']
    for pth in ['/shared', '/']:
        try:
            r2 = urllib.request.Request(
                f'{api}/v3/secrets/raw/NANGO_SECRET_KEY?workspaceId={pid}&environment=dev&secretPath={pth}',
                headers={'Authorization': f'Bearer {tkn}'}
            )
            v = json.loads(urllib.request.urlopen(r2, timeout=4).read())['secret']['secretValue']
            if v:
                print(v)
                exit(0)
        except Exception:
            pass
except Exception:
    pass
" 2>/dev/null || true)
    if [ -n "$k" ]; then
      echo "$k"
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
  NANGO_URL="$(resolve_nango_url || true)"

  if [ -z "$NANGO_URL" ]; then
    if [ "$JSON_MODE" = true ]; then
      python3 -c 'import json; print(json.dumps({"status": "inactive", "active": False, "reason": "not_configured"}))'
    else
      echo "[INACTIVO] Nango no está configurado (defina NANGO_SERVER_URL o declare en fleet.yaml)." >&2
    fi
    exit 2
  fi

  HTTP_CODE=0
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m "$CHECK_TIMEOUT" "$NANGO_URL/health" 2>/dev/null || true)

  if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 400 ]; then
    if [ "$JSON_MODE" = true ]; then
      python3 -c "import json; print(json.dumps({'status': 'active', 'active': True, 'url': '$NANGO_URL', 'http_code': $HTTP_CODE}))"
    else
      echo "[ACTIVO] Nango responde en $NANGO_URL (HTTP $HTTP_CODE)."
    fi
    exit 0
  else
    if [ "$JSON_MODE" = true ]; then
      python3 -c "import json; print(json.dumps({'status': 'inactive', 'active': False, 'url': '$NANGO_URL', 'http_code': $HTTP_CODE, 'reason': 'unreachable'}))"
    else
      echo "[INACTIVO] Nango no responde en $NANGO_URL (HTTP $HTTP_CODE tras ${CHECK_TIMEOUT}s timeout)." >&2
    fi
    exit 2
  fi
fi

# ------------------------------------------------------------------------------
# MODOS OPERATIVOS: Requieren URL y Clave Secreta
# ------------------------------------------------------------------------------
NANGO_URL="$(resolve_nango_url || true)"
[ -n "$NANGO_URL" ] || { echo "❌ Error: Nango no está configurado (defina NANGO_SERVER_URL o fleet.yaml)." >&2; exit 2; }

NANGO_KEY="$(resolve_nango_key || true)"
[ -n "$NANGO_KEY" ] || { echo "❌ Error: Clave secreta de Nango no disponible (defina NANGO_SECRET_KEY o almacene en Infisical)." >&2; exit 2; }

OP_TIMEOUT="${TIMEOUT:-10}"

# --- Modo --list-integrations ---
if [ "$LIST_INTEGRATIONS" = true ]; then
  RAW_RESP=$(curl -s -m "$OP_TIMEOUT" -H "Authorization: Bearer $NANGO_KEY" "$NANGO_URL/integrations" 2>/dev/null || true)
  if [ "$JSON_MODE" = true ]; then
    echo "$RAW_RESP"
    exit 0
  fi
  python3 - "$RAW_RESP" << 'PYEOF'
import sys, json
try:
    data = json.loads(sys.argv[1])
    ints = data.get("data", [])
    print(f"## Integraciones Activas en Nango ({len(ints)})\n")
    if not ints:
        print("_No hay integraciones configuradas._")
    else:
        for item in ints:
            ukey = item.get("unique_key")
            provider = item.get("provider")
            dname = item.get("display_name", provider)
            print(f"- **{ukey}** ({dname}): provider `{provider}`")
except Exception as e:
    print(f"Error procesando respuesta: {e}", file=sys.stderr)
PYEOF
  exit 0
fi

# --- Modo --list-connections ---
if [ "$LIST_CONNECTIONS" = true ]; then
  RAW_RESP=$(curl -s -m "$OP_TIMEOUT" -H "Authorization: Bearer $NANGO_KEY" "$NANGO_URL/connection" 2>/dev/null || true)
  if [ "$JSON_MODE" = true ]; then
    echo "$RAW_RESP"
    exit 0
  fi
  python3 - "$RAW_RESP" << 'PYEOF'
import sys, json
try:
    data = json.loads(sys.argv[1])
    conns = data.get("connections", [])
    print(f"## Conexiones Autorizadas en Nango ({len(conns)})\n")
    if not conns:
        print("_No hay conexiones activas registradas._")
    else:
        for c in conns:
            cid = c.get("connection_id")
            pkey = c.get("provider_config_key")
            prov = c.get("provider")
            print(f"- **Conexión `{cid}`** → Proveedor `{pkey}` ({prov})")
except Exception as e:
    print(f"Error procesando respuesta: {e}", file=sys.stderr)
PYEOF
  exit 0
fi

# --- Modo --proxy ---
if [ -n "$PROXY_PATH" ]; then
  [ -n "$PROVIDER_KEY" ] || { echo "❌ Error: --proxy requiere especificar --provider <KEY>." >&2; exit 1; }
  [ -n "$CONNECTION_ID" ] || { echo "❌ Error: --proxy requiere especificar --connection <ID>." >&2; exit 1; }

  CLEAN_PATH="${PROXY_PATH#/}"
  TARGET_URL="$NANGO_URL/proxy/$CLEAN_PATH"

  RAW_RESP=$(curl -s -m "$OP_TIMEOUT" -X "$HTTP_METHOD" \
    -H "Authorization: Bearer $NANGO_KEY" \
    -H "Provider-Config-Key: $PROVIDER_KEY" \
    -H "Connection-Id: $CONNECTION_ID" \
    "$TARGET_URL" 2>/dev/null || true)

  if [ "$JSON_MODE" = true ]; then
    echo "$RAW_RESP"
    exit 0
  fi

  # Presentación en Markdown estructurado
  python3 - "$RAW_RESP" "$PROVIDER_KEY" "$CONNECTION_ID" "$CLEAN_PATH" << 'PYEOF'
import sys, json
raw, provider, conn_id, path = sys.argv[1:5]
try:
    data = json.loads(raw)
    print(f"## Nango Proxy Response (`{provider}` / `{conn_id}`)\n")
    print(f"**Endpoint**: `/{path}`\n")
    # Si es respuesta de Cloudflare DNS o similar
    if "result" in data and isinstance(data["result"], list):
        items = data["result"]
        print(f"### Resultados recuperados ({len(items)} registros):\n")
        for item in items:
            name = item.get("name", "N/A")
            rtype = item.get("type", "")
            content = item.get("content", "")
            proxied = item.get("proxied", "")
            if rtype:
                print(f"- **{rtype}** `{name}` → `{content}` (Proxied: {proxied})")
            else:
                print(f"- `{name}`: id `{item.get('id', 'N/A')}`")
    else:
        print("```json")
        print(json.dumps(data, indent=2))
        print("```")
except Exception:
    print(raw)
PYEOF
  exit 0
fi

echo "❌ Error: No se especificó ninguna acción (--check, --list-integrations, --list-connections, --proxy)." >&2
echo "Guía: Ejecute 'bash scripts/agent/lib/nango-client.sh --help' para consultar la sintaxis." >&2
exit 1
