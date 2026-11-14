#!/usr/bin/env bash
# ==============================================================================
# audit-next.sh - Auditoría pre-build determinista para Next.js en Coolify
# ==============================================================================
# Diagnostica la tipología de proyecto (flat vs monorepo), el gestor de paquetes,
# la presencia de 'output: standalone', dependencias y la plantilla Dockerfile idónea.
# ==============================================================================

set -euo pipefail

PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

echo "================================================="
echo "🔍 Ejecutando auditoría de Next.js para Coolify..."
echo "📁 Directorio objetivo: $PROJECT_DIR"
echo "================================================="

ERRORS=0
WARNINGS=0

# 1. Detección de tipología de repositorio (flat vs monorepo)
echo -n "1. Detectando tipología de repositorio... "
REPO_TYPE="flat"
APP_SUBDIR=""

if [ -f "$PROJECT_DIR/pnpm-workspace.yaml" ] || [ -f "$PROJECT_DIR/turbo.json" ] || [ -f "$PROJECT_DIR/lerna.json" ]; then
  REPO_TYPE="monorepo"
elif [ -d "$PROJECT_DIR/apps/web" ] || [ -d "$PROJECT_DIR/apps/frontend" ]; then
  REPO_TYPE="monorepo"
fi

if [ "$REPO_TYPE" = "monorepo" ]; then
  if [ -d "$PROJECT_DIR/apps/web" ]; then
    APP_SUBDIR="apps/web"
  elif [ -d "$PROJECT_DIR/apps/frontend" ]; then
    APP_SUBDIR="apps/frontend"
  fi
  echo "📦 [MONOREPO] Detectado monorepo (subdirectorio web: ${APP_SUBDIR:-raíz})"
else
  echo "📄 [FLAT] Aplicación Next.js estándar en la raíz"
fi

# 2. Detección de Package Manager
echo -n "2. Detectando gestor de paquetes... "
PKG_MANAGER="npm"
LOCK_FILE=""

if [ -f "$PROJECT_DIR/pnpm-lock.yaml" ]; then
  PKG_MANAGER="pnpm"
  LOCK_FILE="pnpm-lock.yaml"
elif [ -f "$PROJECT_DIR/package-lock.json" ]; then
  PKG_MANAGER="npm"
  LOCK_FILE="package-lock.json"
elif [ -f "$PROJECT_DIR/yarn.lock" ]; then
  PKG_MANAGER="yarn"
  LOCK_FILE="yarn.lock"
elif [ -f "$PROJECT_DIR/bun.lockb" ] || [ -f "$PROJECT_DIR/bun.lock" ]; then
  PKG_MANAGER="bun"
  LOCK_FILE="bun.lock"
fi
echo "🛠️ Gestor: $PKG_MANAGER ($LOCK_FILE)"

# 3. Comprobar output: 'standalone' en next.config
echo -n "3. Verificando next.config (output: 'standalone')... "
CONFIG_DIR="$PROJECT_DIR"
if [ "$REPO_TYPE" = "monorepo" ] && [ -n "$APP_SUBDIR" ] && [ -d "$PROJECT_DIR/$APP_SUBDIR" ]; then
  CONFIG_DIR="$PROJECT_DIR/$APP_SUBDIR"
fi

CONFIG_FILE=""
for cfg in next.config.ts next.config.mjs next.config.js; do
  if [ -f "$CONFIG_DIR/$cfg" ]; then
    CONFIG_FILE="$CONFIG_DIR/$cfg"
    break
  fi
done

if [ -n "$CONFIG_FILE" ]; then
  if grep -q "output:[[:space:]]*['\"]standalone['\"]" "$CONFIG_FILE"; then
    echo "✅ [OK] Configurado en $(basename "$CONFIG_FILE")"
  else
    echo "❌ [ERROR] 'output: standalone' NO encontrado en $(basename "$CONFIG_FILE")"
    echo "   💡 Sugerencia: Añade 'output: \"standalone\"' a $(basename "$CONFIG_FILE") para compilación Docker multi-stage."
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "⚠️ [WARN] No se encontró next.config.* en $CONFIG_DIR"
  WARNINGS=$((WARNINGS + 1))
fi

# 4. Comprobar uso de next/image y dependencia sharp
echo -n "4. Verificando optimización de imágenes (sharp)... "
SEARCH_DIRS=()
[ -d "$CONFIG_DIR/app" ] && SEARCH_DIRS+=("$CONFIG_DIR/app")
[ -d "$CONFIG_DIR/components" ] && SEARCH_DIRS+=("$CONFIG_DIR/components")
[ -d "$CONFIG_DIR/src" ] && SEARCH_DIRS+=("$CONFIG_DIR/src")

USES_NEXT_IMAGE=""
if [ "${#SEARCH_DIRS[@]}" -gt 0 ]; then
  USES_NEXT_IMAGE=$(grep -rn "next/image" "${SEARCH_DIRS[@]}" 2>/dev/null | head -n 1 || true)
fi

TARGET_PKG_JSON="$CONFIG_DIR/package.json"
[ ! -f "$TARGET_PKG_JSON" ] && TARGET_PKG_JSON="$PROJECT_DIR/package.json"

if [ -n "$USES_NEXT_IMAGE" ]; then
  if [ -f "$TARGET_PKG_JSON" ] && grep -q '"sharp"' "$TARGET_PKG_JSON"; then
    echo "✅ [OK] Detectado next/image y 'sharp' presente."
  else
    echo "⚠️ [RECOMMENDED] Detectado next/image pero 'sharp' no está en package.json. Se recomienda instalar para optimización standalone."
    WARNINGS=$((WARNINGS + 1))
  fi
else
  echo "ℹ️ [INFO] No se detectó uso intensivo de next/image."
fi

# 5. Escaneo de variables de entorno (.env*)
echo "5. Escaneando archivos de entorno (.env*)..."
FOUND_ENV=0
for env_file in .env.local .env.production .env.dev .env; do
  if [ -f "$CONFIG_DIR/$env_file" ] || [ -f "$PROJECT_DIR/$env_file" ]; then
    echo "   📄 Encontrado: $env_file"
    FOUND_ENV=$((FOUND_ENV + 1))
  fi
done
if [ "$FOUND_ENV" -eq 0 ]; then
  echo "   ⚠️ [WARN] No se encontró ningún archivo .env*"
  WARNINGS=$((WARNINGS + 1))
fi

# 6. Verificación de directorio public/
echo -n "6. Verificando directorio public/... "
PUBLIC_DIR="$CONFIG_DIR/public"
if [ ! -d "$PUBLIC_DIR" ]; then
  mkdir -p "$PUBLIC_DIR"
  touch "$PUBLIC_DIR/.gitkeep"
  echo "✅ [OK] Creado directorio public/ con .gitkeep"
elif [ ! -f "$PUBLIC_DIR/.gitkeep" ] && [ -z "$(ls -A "$PUBLIC_DIR" 2>/dev/null || true)" ]; then
  touch "$PUBLIC_DIR/.gitkeep"
  echo "✅ [OK] Creado .gitkeep en public/"
else
  echo "✅ [OK] Directorio public/ presente."
fi

# 7. Estado de Docker local
echo -n "7. Comprobando servicio de Docker local... "
if docker ps >/dev/null 2>&1; then
  echo "✅ [OK] Daemon de Docker activo."
else
  echo "ℹ️ [INFO] Docker inactivo localmente (no bloqueante para despliegues remotos en Coolify)."
fi

# 8. Recomendación de plantilla Dockerfile
echo ""
echo "-------------------------------------------------"
echo "🎯 RECOMENDACIÓN DE PLANTILLA DOCKERFILE:"
if [ "$REPO_TYPE" = "monorepo" ]; then
  echo "  📦 Tipo: Monorepo ($PKG_MANAGER)"
  echo "  👉 Usa: .agents/skills/coolify-nextjs-deploy/templates/Dockerfile.monorepo.template"
  echo "     Destino: $PROJECT_DIR/Dockerfile"
else
  echo "  📄 Tipo: Flat ($PKG_MANAGER)"
  echo "  👉 Usa: .agents/skills/coolify-nextjs-deploy/templates/Dockerfile.flat.template"
  echo "     Destino: $PROJECT_DIR/Dockerfile"
fi
echo "-------------------------------------------------"

echo "📋 Resumen: $ERRORS error(es), $WARNINGS advertencia(s)."
if [ "$ERRORS" -gt 0 ]; then
  echo "❌ La auditoría ha detectado impedimentos bloqueantes para el despliegue."
  exit 1
else
  echo "✅ Auditoría completada con éxito. Proyecto preparado para compilación Docker standalone."
  exit 0
fi
