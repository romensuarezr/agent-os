#!/usr/bin/env bash
set -e

# ==============================================================================
# cloudflare-dns.sh - Aprovisionamiento DNS determinista en Cloudflare
# Uso: ./cloudflare-dns.sh <dominio> [vps_ip] [--proxied|--unproxied]
# ==============================================================================

DOMAIN="$1"
TARGET_IP="$2"
PROXY_FLAG="true"

# Procesar banderas opcionales de proxy
for arg in "$@"; do
  if [ "$arg" == "--unproxied" ]; then
    PROXY_FLAG="false"
  elif [ "$arg" == "--proxied" ]; then
    PROXY_FLAG="true"
  fi
done

if [ -z "$DOMAIN" ]; then
  echo "❌ Error: Debe especificar un dominio."
  echo "Uso: $0 <dominio> [vps_ip] [--proxied|--unproxied]"
  exit 1
fi

echo "================================================="
echo "🌐 Aprovisionamiento DNS Cloudflare: $DOMAIN"
echo "================================================="

# 1. Cargar tokens desde la jerarquía de archivos .env*
CF_TOKEN=""
for env_file in .env.local .env.production .env.dev .env; do
  if [ -f "$env_file" ]; then
    FOUND_TOKEN=$(grep -E "^(CLOUDFLARE_API_TOKEN|CLOUDFLARE_DNS_API_TOKEN)=" "$env_file" | head -n 1 | cut -d'=' -f2- | tr -d '"' | tr -d "'" || true)
    if [ -n "$FOUND_TOKEN" ]; then
      CF_TOKEN="$FOUND_TOKEN"
      echo "✅ Token de Cloudflare leído desde $env_file"
      break
    fi
  fi
done

if [ -z "$CF_TOKEN" ]; then
  CF_TOKEN="${CLOUDFLARE_API_TOKEN:-$CLOUDFLARE_DNS_API_TOKEN}"
fi

if [ -z "$CF_TOKEN" ]; then
  echo "❌ [ERROR] No se encontró CLOUDFLARE_API_TOKEN ni CLOUDFLARE_DNS_API_TOKEN en archivos .env* ni en el entorno."
  exit 1
fi

# 2. Determinar la IP pública del VPS si no fue provista
if [ -z "$TARGET_IP" ] || [[ "$TARGET_IP" == --* ]]; then
  echo -n "🔍 Obteniendo IP pública del VPS... "
  TARGET_IP=$(curl -s --max-time 5 https://api.ipify.org || echo "")
  if [ -z "$TARGET_IP" ]; then
    echo "❌ No se pudo determinar la IP. Especifica la IP manualmente."
    exit 1
  fi
  echo "IP VPS: $TARGET_IP"
fi

# 3. Obtener Zone ID de Cloudflare
echo -n "🔍 Consultando Zone ID para $DOMAIN... "
ZONES_RESP=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json")

ZONE_ID=$(echo "$ZONES_RESP" | grep -o '"id":"[^"]*"' | head -n 1 | cut -d'"' -f4 || true)

if [ -z "$ZONE_ID" ]; then
  echo "❌ [ERROR] No se encontró la zona '$DOMAIN' en Cloudflare o el token no tiene permisos."
  echo "Respuesta API: $ZONES_RESP"
  exit 1
fi
echo "Zone ID: $ZONE_ID"

# 4. Crear o actualizar Registro A (@)
echo "📝 Configurando Registro A (@ -> $TARGET_IP, proxied: $PROXY_FLAG)..."
EXISTING_A=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$DOMAIN&type=A" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json")

A_ID=$(echo "$EXISTING_A" | grep -o '"id":"[^"]*"' | head -n 1 | cut -d'"' -f4 || true)

if [ -n "$A_ID" ]; then
  # Actualizar
  curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$A_ID" \
    -H "Authorization: Bearer $CF_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$DOMAIN\",\"content\":\"$TARGET_IP\",\"ttl\":1,\"proxied\":$PROXY_FLAG}" >/dev/null
  echo "✅ Registro A actualizado correctamente."
else
  # Crear
  curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
    -H "Authorization: Bearer $CF_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$DOMAIN\",\"content\":\"$TARGET_IP\",\"ttl\":1,\"proxied\":$PROXY_FLAG}" >/dev/null
  echo "✅ Registro A creado correctamente."
fi

# 5. Crear o actualizar Registro CNAME (www)
WWW_DOMAIN="www.$DOMAIN"
echo "📝 Configurando Registro CNAME (www -> $DOMAIN, proxied: $PROXY_FLAG)..."
EXISTING_CNAME=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$WWW_DOMAIN&type=CNAME" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json")

CNAME_ID=$(echo "$EXISTING_CNAME" | grep -o '"id":"[^"]*"' | head -n 1 | cut -d'"' -f4 || true)

if [ -n "$CNAME_ID" ]; then
  # Actualizar
  curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$CNAME_ID" \
    -H "Authorization: Bearer $CF_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"CNAME\",\"name\":\"www\",\"content\":\"$DOMAIN\",\"ttl\":1,\"proxied\":$PROXY_FLAG}" >/dev/null
  echo "✅ Registro CNAME (www) actualizado correctamente."
else
  # Crear
  curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
    -H "Authorization: Bearer $CF_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"CNAME\",\"name\":\"www\",\"content\":\"$DOMAIN\",\"ttl\":1,\"proxied\":$PROXY_FLAG}" >/dev/null
  echo "✅ Registro CNAME (www) creado correctamente."
fi

echo "🎉 Registros DNS configurados exitosamente en Cloudflare ($DOMAIN -> $TARGET_IP)."
