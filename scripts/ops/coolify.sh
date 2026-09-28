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
# Gestión de Credenciales:
#   Prioridad 1: Variable de entorno COOLIFY_TOKEN (o COOLIFY_ACCESS_TOKEN / COOLIFY_API_TOKEN)
#                Permite ejecución con: infisical run -- bash scripts/ops/coolify.sh ...
#   Fallback 2:  $HOME/.config/agent-os/api_keys.env
# ==============================================================================

set -euo pipefail

for cmd in curl jq; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "❌ Error: Dependencia requerida '$cmd' no encontrada." >&2
    echo "💡 Guía: Instálala mediante: apt-get install -y $cmd (Linux) o brew install $cmd (macOS)." >&2
    exit 1
  }
done

# ─── Configuración de Red y API ──────────────────────────────────────────────
COOLIFY_API_BASE="${COOLIFY_BASE_URL:-${COOLIFY_API_URL:-https://coolify.example.com/api/v1}}"
# Asegurar que no termine en '/'
COOLIFY_API_BASE="${COOLIFY_API_BASE%/}"

# ─── Resolución de Token ─────────────────────────────────────────────────────
TOKEN="${COOLIFY_TOKEN:-${COOLIFY_ACCESS_TOKEN:-${COOLIFY_API_TOKEN:-}}}"

if [ -z "$TOKEN" ]; then
  ENV_FILE="${COOLIFY_ENV_FILE:-$HOME/.config/agent-os/api_keys.env}"
  if [ -f "$ENV_FILE" ]; then
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

# ─── Función de Ayuda ────────────────────────────────────────────────────────
show_help() {
  cat << 'EOF'
Uso: bash scripts/ops/coolify.sh <subcomando> [argumentos]

Subcomandos:
  list [--json]                        Lista proyectos y aplicaciones en Coolify.
  get <uuid>                           Obtiene los detalles completos de una aplicación.
  deploy <uuid>                        Dispara un despliegue forzado (POST /deploy?force=true).
  update-compose <uuid> <archivo.yml>  Actualiza la definición docker-compose de la app.
  help, -h, --help                     Muestra este mensaje de ayuda.

Variables de entorno:
  COOLIFY_TOKEN      Token Bearer de Coolify API (o COOLIFY_ACCESS_TOKEN).
  COOLIFY_BASE_URL   URL base de la API (por defecto: https://coolify.example.com/api/v1).
EOF
}

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
  help|-h|--help|"")
    show_help
    exit 0
    ;;
  *)
    echo "❌ ERROR: Subcomando no reconocido: $SUBCOMMAND" >&2
    show_help >&2
    exit 1
    ;;
esac
