#!/usr/bin/env bash
set -e

# ==============================================================================
# audit-next.sh - Auditoría pre-build determinista para Next.js en Coolify
# ==============================================================================

echo "================================================="
echo "🔍 Ejecutando auditoría de Next.js para Coolify..."
echo "================================================="

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

ERRORS=0
WARNINGS=0

# 1. Comprobar output: 'standalone' en next.config
echo -n "1. Verificando next.config (output: 'standalone')... "
CONFIG_FILE=""
if [ -f "next.config.ts" ]; then CONFIG_FILE="next.config.ts";
elif [ -f "next.config.js" ]; then CONFIG_FILE="next.config.js";
elif [ -f "next.config.mjs" ]; then CONFIG_FILE="next.config.mjs";
fi

if [ -n "$CONFIG_FILE" ]; then
  if grep -q "output:.*'standalone'" "$CONFIG_FILE" || grep -q 'output:.*"standalone"' "$CONFIG_FILE"; then
    echo "✅ [OK] Configurado en $CONFIG_FILE"
  else
    echo "❌ [ERROR] 'output: standalone' NO encontrado en $CONFIG_FILE"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "⚠️ [WARN] No se encontró archivo next.config.*"
  WARNINGS=$((WARNINGS + 1))
fi

# 2. Comprobar uso de next/image y dependencia sharp
echo -n "2. Verificando optimización de imágenes (sharp)... "
USES_NEXT_IMAGE=$(grep -rn "next/image" app/ components/ 2>/dev/null | head -n 1 || true)
if [ -n "$USES_NEXT_IMAGE" ]; then
  if [ -f "package.json" ] && grep -q '"sharp"' package.json; then
    echo "✅ [OK] Se detectó next/image y 'sharp' está instalado."
  else
    echo "⚠️ [RECOMMENDED] Se usa next/image pero 'sharp' no está en package.json. Añádelo para mejor rendimiento en standalone."
    WARNINGS=$((WARNINGS + 1))
  fi
else
  echo "ℹ️ [INFO] No se detectó uso intensivo de next/image."
fi

# 3. Escaneo de archivos de entorno (.env*)
echo "3. Escaneando archivos de entorno (.env*)..."
FOUND_ENV=0
for env_file in .env.local .env.production .env.dev .env; do
  if [ -f "$env_file" ]; then
    echo "   📄 Encontrado: $env_file"
    FOUND_ENV=$((FOUND_ENV + 1))
  fi
done
if [ "$FOUND_ENV" -eq 0 ]; then
  echo "   ⚠️ [WARN] No se encontró ningún archivo .env*"
  WARNINGS=$((WARNINGS + 1))
fi

# 4. Verificación de directorio public/
echo -n "4. Verificando directorio public/... "
if [ ! -d "public" ]; then
  mkdir -p public
  touch public/.gitkeep
  echo "✅ [OK] Creado directorio public/ con .gitkeep"
elif [ ! -f "public/.gitkeep" ] && [ -z "$(ls -A public)" ]; then
  touch public/.gitkeep
  echo "✅ [OK] Creado .gitkeep en public/"
else
  echo "✅ [OK] Directorio public/ presente."
fi

# 5. Estado de Docker local
echo -n "5. Comprobando servicio de Docker local... "
if docker ps >/dev/null 2>&1; then
  echo "✅ [OK] Daemon de Docker activo."
else
  echo "ℹ️ [INFO] Docker inactivo localmente. Puedes activarlo con: systemctl start docker.socket"
fi

echo "-------------------------------------------------"
echo "📋 Resumen: $ERRORS error(es), $WARNINGS advertencia(s)."
if [ "$ERRORS" -gt 0 ]; then
  echo "❌ La auditoría ha fallado. Revisa los errores antes de construir."
  exit 1
else
  echo "✅ Auditoría completada con éxito. Proyecto listo para Docker Multi-Stage."
  exit 0
fi
