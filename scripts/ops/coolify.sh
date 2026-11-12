#!/usr/bin/env bash
# ==============================================================================
# scripts/ops/coolify.sh — CLI determinista para la API de Coolify (Agent OS)
# ==============================================================================
# Uso:
#   bash scripts/ops/coolify.sh list [--json]
#   bash scripts/ops/coolify.sh get <uuid>
#   bash scripts/ops/coolify.sh deploy <uuid>
#   bash scripts/ops/coolify.sh update-compose <uuid> <archivo_compose>
#
# Gestión de Credenciales y Endpoints:
#   Prioridad 1: Variable de entorno COOLIFY_TOKEN (o COOLIFY_ACCESS_TOKEN / COOLIFY_API_TOKEN)
#                Permite ejecución con: infisical run -- bash scripts/ops/coolify.sh ...
#   Fallback 2:  $HOME/.config/agent-os/api_keys.env
#   Endpoint:    COOLIFY_BASE_URL / COOLIFY_API_URL / COOLIFY_URL > .agents/config/fleet.yaml
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../.." && pwd))"

CLI_HELP="$ROOT_DIR/scripts/agent/lib/cli-help.sh"
if [ -f "$CLI_HELP" ]; then
  # shellcheck source=scripts/agent/lib/cli-help.sh
  source "$CLI_HELP"
fi

for cmd in curl jq python3; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "❌ Error: Dependencia requerida '$cmd' no encontrada." >&2
    echo "💡 Guía: Instálala mediante el gestor de paquetes de tu sistema antes de continuar." >&2
    exit 1
  }
done

# ─── Ayuda Estándar ──────────────────────────────────────────────────────────
show_coolify_help() {
  if type show_help >/dev/null 2>&1; then
    show_help "coolify.sh" \
      "bash scripts/ops/coolify.sh <subcomando> [argumentos]" \
      "CLI determinista para la API de Coolify (v4+): listar aplicaciones, inspeccionar estado, actualizar compose y forzar despliegues." \
      "list [--json]                        Lista proyectos y aplicaciones en Coolify." \
      "get <uuid>                           Obtiene los detalles completos de una aplicación." \
      "deploy <uuid>                        Dispara un despliegue forzado (POST /deploy?uuid=<uuid>&force=true)." \
      "update-compose <uuid> <archivo.yml>  Actualiza la definición docker-compose de la app." \
      "-h, --help                           Muestra este mensaje de ayuda." \
      "ejemplo: bash scripts/ops/coolify.sh list" \
      "ejemplo: bash scripts/ops/coolify.sh get 1a2b3c4d" \
      "ejemplo: bash scripts/ops/coolify.sh deploy 1a2b3c4d"
  else
    cat << 'EOF'
Uso: bash scripts/ops/coolify.sh <subcomando> [argumentos]

Subcomandos:
  list [--json]                        Lista proyectos y aplicaciones en Coolify.
  get <uuid>                           Obtiene los detalles completos de una aplicación.
  deploy <uuid>                        Dispara un despliegue forzado (POST /deploy?uuid=<uuid>&force=true).
  update-compose <uuid> <archivo.yml>  Actualiza la definición docker-compose de la app.
  -h, --help                           Muestra este mensaje de ayuda.

Variables de entorno:
  COOLIFY_TOKEN      Token Bearer de Coolify API (o COOLIFY_ACCESS_TOKEN).
  COOLIFY_BASE_URL   URL base de la API (ej: http://127.0.0.1:8000/api/v1).
EOF
  fi
}

for arg in "$@"; do
  if [ "$arg" = "-h" ] || [ "$arg" = "--help" ] || [ "$arg" = "help" ]; then
    show_coolify_help
    exit 0
  fi
done

if [ $# -eq 0 ]; then
  show_coolify_help
  exit 0
fi

# ─── Configuración de Red y API (Resolución Dinámica) ────────────────────────
resolve_coolify_base() {
  local env_url="${COOLIFY_BASE_URL:-${COOLIFY_API_URL:-${COOLIFY_URL:-}}}"
  if [ -n "$env_url" ]; then
    echo "${env_url%/}"
    return 0
  fi

  python3 -c "
import os, sys, yaml

def resolve():
    root = sys.argv[1]
    for cfg in [os.path.join(root, '.agents/config/fleet.yaml'), os.path.expanduser('~/.agents/config/fleet.yaml'), os.path.join(root, '.agents/config/fleet.example.yaml')]:
        if not os.path.isfile(cfg):
            continue
        try:
            with open(cfg, 'r') as f:
                d = yaml.safe_load(f) or {}
            nodes = d.get('nodes', {})
            for name, n in nodes.items():
                svcs = n.get('services', {})
                if 'coolify' in svcs:
                    c = svcs['coolify']
                    if isinstance(c, dict) and c.get('url'):
                        u = c['url'].rstrip('/')
                        if 'example.com' not in u:
                            return (u + '/api/v1') if not u.endswith('/api/v1') else u
                    elif isinstance(c, (int, str)):
                        ip = n.get('ip') or n.get('host') or '127.0.0.1'
                        if 'example.com' not in ip and not str(ip).startswith('203.0.113.'):
                            return f'http://{ip}:{c}/api/v1'
            mcp = d.get('mcpServers', {}).get('coolify', {})
            mcp_url = mcp.get('env', {}).get('COOLIFY_BASE_URL')
            if mcp_url and 'example.com' not in mcp_url:
                return mcp_url.rstrip('/')
        except Exception:
            pass
    return ''

print(resolve())
" "$ROOT_DIR"
}

COOLIFY_API_BASE="$(resolve_coolify_base)"
COOLIFY_API_BASE="${COOLIFY_API_BASE%/}"

if [ -z "$COOLIFY_API_BASE" ]; then
  echo "❌ ERROR: No se encontró la URL base de Coolify API." >&2
  echo "   Configure la variable de entorno COOLIFY_BASE_URL (ej: export COOLIFY_BASE_URL=\"http://127.0.0.1:8000/api/v1\")" >&2
  echo "   o declare el servicio en .agents/config/fleet.yaml." >&2
  exit 1
fi

# ─── Resolución de Token ─────────────────────────────────────────────────────
TOKEN="${COOLIFY_TOKEN:-${COOLIFY_ACCESS_TOKEN:-${COOLIFY_API_TOKEN:-}}}"

if [ -z "$TOKEN" ]; then
  ENV_FILE="${COOLIFY_ENV_FILE:-${HOME:-}/.config/agent-os/api_keys.env}"
  if [ -n "${HOME:-}" ] && [ -f "$ENV_FILE" ]; then
    TOKEN=$(grep -E '^(COOLIFY_TOKEN|COOLIFY_ACCESS_TOKEN|COOLIFY_API_TOKEN)=' "$ENV_FILE" 2>/dev/null | head -1 | cut -d'=' -f2- | tr -d '"'\'' ' || true)
  fi
fi

if [ -z "$TOKEN" ]; then
  echo "❌ ERROR: No se encontró token de autenticación para Coolify." >&2
  echo "   Configure la variable COOLIFY_TOKEN en su entorno o invoque vía:" >&2
  echo "   infisical run -- bash scripts/ops/coolify.sh <subcomando>" >&2
  exit 1
fi

AUTH_HEADER="Authorization: Bearer $TOKEN"

# ─── Subcomandos ─────────────────────────────────────────────────────────────
cmd_list() {
  local json_mode=false
  if [[ "${1:-}" == "--json" ]]; then
    json_mode=true
  fi

  local apps_response
  apps_response=$(curl -fsSL -H "$AUTH_HEADER" "${COOLIFY_API_BASE}/applications" 2>/dev/null || echo "[]")

  if [ "$json_mode" = true ]; then
    echo "$apps_response" | jq '.'
    return 0
  fi

  echo "=========================================================================================="
  printf "%-26s %-20s %-22s %s\n" "UUID" "NOMBRE" "ESTADO" "FQDN"
  echo "=========================================================================================="
  echo "$apps_response" | jq -r '.[] | "\(.uuid)\t\(.name)\t\(.status)\t\(.fqdn // "-")"' | while IFS=$'\t' read -r uuid name status fqdn; do
    printf "%-26s %-20s %-22s %s\n" "$uuid" "$name" "$status" "$fqdn"
  done
  echo "=========================================================================================="
}

cmd_get() {
  local uuid="${1:-}"
  if [ -z "$uuid" ]; then
    echo "❌ ERROR: Se requiere el UUID de la aplicación." >&2
    echo "   Uso: bash scripts/ops/coolify.sh get <uuid>" >&2
    exit 1
  fi

  curl -fsSL -H "$AUTH_HEADER" "${COOLIFY_API_BASE}/applications/${uuid}" | jq '.'
}

cmd_deploy() {
  local uuid="${1:-}"
  if [ -z "$uuid" ]; then
    echo "❌ ERROR: Se requiere el UUID de la aplicación a desplegar." >&2
    echo "   Uso: bash scripts/ops/coolify.sh deploy <uuid>" >&2
    exit 1
  fi

  echo "🚀 Disparando despliegue forzado para aplicación UUID: $uuid..."
  local response
  response=$(curl -fsSL -X POST -H "$AUTH_HEADER" "${COOLIFY_API_BASE}/deploy?uuid=${uuid}&force=true")
  echo "✅ Despliegue iniciado exitosamente:"
  echo "$response" | jq '.' 2>/dev/null || echo "$response"
}

cmd_update_compose() {
  local uuid="${1:-}"
  local compose_file="${2:-}"

  if [ -z "$uuid" ] || [ -z "$compose_file" ]; then
    echo "❌ ERROR: Argumentos incompletos." >&2
    echo "   Uso: bash scripts/ops/coolify.sh update-compose <uuid> <archivo_compose.yml>" >&2
    exit 1
  fi

  if [ ! -f "$compose_file" ]; then
    echo "❌ ERROR: Archivo compose no encontrado: $compose_file" >&2
    exit 1
  fi

  echo "📦 Leyendo y preparando compose: $compose_file..."
  local b64_compose
  b64_compose=$(base64 -w 0 "$compose_file")

  local payload
  payload=$(jq -n \
    --arg b64 "$b64_compose" \
    '{
      build_pack: "dockercompose",
      docker_compose_raw: $b64
    }')

  echo "🔄 Actualizando aplicación $uuid en Coolify (${COOLIFY_API_BASE})..."
  local response
  response=$(curl -fsSL -X PATCH \
    -H "$AUTH_HEADER" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "${COOLIFY_API_BASE}/applications/${uuid}")

  echo "✅ Definición Docker Compose actualizada exitosamente:"
  echo "$response" | jq '{uuid: .uuid, name: .name, build_pack: .build_pack, updated_at: .updated_at}' 2>/dev/null || echo "$response"
}

# ─── Enrutamiento CLI ────────────────────────────────────────────────────────
SUBCOMMAND="${1:-}"
shift || true

case "$SUBCOMMAND" in
  list)
    cmd_list "$@"
    ;;
  get)
    cmd_get "$@"
    ;;
  deploy)
    cmd_deploy "$@"
    ;;
  update-compose)
    cmd_update_compose "$@"
    ;;
  *)
    echo "❌ ERROR: Subcomando no reconocido: $SUBCOMMAND" >&2
    show_coolify_help >&2
    exit 1
    ;;
esac
