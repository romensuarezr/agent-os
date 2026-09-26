#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/import-secrets.sh — Importación y migración masiva de secretos a Infisical
# ==============================================================================
# Uso:
#   bash scripts/agent/import-secrets.sh [DIRECTORIO] [OPCIONES]
#
# Opciones:
#   --dry-run         (Por defecto) Escanea, audita y valida liveness sin tocar Infisical.
#   --apply           Aplica los cambios: sube los secretos válidos/locales a Infisical.
#   --env=<env>       Entorno destino en Infisical: dev, staging, prod (default: dev).
#   --skip-liveness   Omite las comprobaciones de red contra APIs públicas (offline).
#   --clean-env       (Solo con --apply) Renombra los archivos .env a .env.backup tras subir.
#   --json            Emite la salida en formato JSON estructurado.
#   -h, --help        Muestra esta ayuda.
# ==============================================================================

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

TARGET_DIR="."
APPLY_MODE=false
SKIP_LIVENESS=false
JSON_MODE=false
CLEAN_ENV=false
ENV_TARGET="dev"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_ENGINE="$SCRIPT_DIR/lib/verify-secrets.py"

# Parseo de argumentos
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      APPLY_MODE=true
      shift
      ;;
    --dry-run)
      APPLY_MODE=false
      shift
      ;;
    --skip-liveness)
      SKIP_LIVENESS=true
      shift
      ;;
    --clean-env)
      CLEAN_ENV=true
      shift
      ;;
    --json)
      JSON_MODE=true
      shift
      ;;
    --env=*)
      ENV_TARGET="${1#*=}"
      shift
      ;;
    -h|--help)
      sed -n '2,17p' "$0" | sed 's/^# //'
      exit 0
      ;;
    *)
      if [[ -d "$1" ]]; then
        TARGET_DIR="$1"
      else
        echo -e "${RED}❌ Parámetro o directorio desconocido: $1${NC}"
        exit 1
      fi
      shift
      ;;
  esac
done

if [ ! -f "$PYTHON_ENGINE" ]; then
  echo -e "${RED}❌ No se encontró el motor Python de análisis: $PYTHON_ENGINE${NC}"
  exit 1
fi

# 1. Cargar credenciales de entorno si faltan
if [ -z "${INFISICAL_API_URL:-}" ] || [ -z "${INFISICAL_CLIENT_ID:-}" ] || [ -z "${INFISICAL_CLIENT_SECRET:-}" ] || [ -z "${INFISICAL_PROJECT_ID:-}" ]; then
  if [ -f "$HOME/.bashrc" ]; then
    # Extraer variables de Infisical desde ~/.bashrc sin ejecutar subshells invasivos
    eval "$(grep -E '^export INFISICAL_' "$HOME/.bashrc" 2>/dev/null || true)"
  fi
fi

# Fallback desde config/fleet.yaml si existe
FLEET_CONFIG="$SCRIPT_DIR/../../config/fleet.yaml"
if [ -f "$FLEET_CONFIG" ]; then
  if [ -z "${INFISICAL_API_URL:-}" ]; then
    INFISICAL_API_URL=$(python3 -c "import yaml; data=yaml.safe_load(open('$FLEET_CONFIG')); print(data.get('nodes',{}).get('oracle',{}).get('services',{}).get('infisical',{}).get('api_url',''))" 2>/dev/null || echo "")
  fi
  if [ -z "${INFISICAL_PROJECT_ID:-}" ]; then
    INFISICAL_PROJECT_ID=$(python3 -c "import yaml; data=yaml.safe_load(open('$FLEET_CONFIG')); print(data.get('nodes',{}).get('oracle',{}).get('services',{}).get('infisical',{}).get('project_id',''))" 2>/dev/null || echo "")
  fi
fi

# Si se requiere --apply, verificar que tengamos todo lo necesario
if [ "$APPLY_MODE" = true ]; then
  if [ -z "${INFISICAL_API_URL:-}" ] || [ -z "${INFISICAL_CLIENT_ID:-}" ] || [ -z "${INFISICAL_CLIENT_SECRET:-}" ] || [ -z "${INFISICAL_PROJECT_ID:-}" ]; then
    echo -e "${RED}❌ ERROR: Para ejecutar con --apply se requieren las credenciales de Infisical:${NC}"
    echo "  - INFISICAL_API_URL"
    echo "  - INFISICAL_CLIENT_ID"
    echo "  - INFISICAL_CLIENT_SECRET"
    echo "  - INFISICAL_PROJECT_ID"
    echo -e "${YELLOW}Guía: Configúralas en tu entorno o en ~/.bashrc.${NC}"
    exit 1
  fi
fi

# 2. Ejecutar análisis determinista con verify-secrets.py
PY_ARGS=("$TARGET_DIR")
if [ "$SKIP_LIVENESS" = true ]; then
  PY_ARGS+=("--skip-liveness")
fi

if [ "$APPLY_MODE" = false ]; then
  # Modo Dry-run
  if [ "$JSON_MODE" = true ]; then
    python3 "$PYTHON_ENGINE" "${PY_ARGS[@]}" --json
  else
    python3 "$PYTHON_ENGINE" "${PY_ARGS[@]}"
    echo -e "${CYAN}💡 Modo DRY-RUN completado. Ningún cambio fue aplicado en Infisical.${NC}"
    echo -e "   Para volcar los secretos válidos/locales en el entorno ${YELLOW}${ENV_TARGET}${NC}, ejecuta:"
    echo -e "   ${GREEN}bash $0 $TARGET_DIR --apply --env=${ENV_TARGET}${NC}\n"
  fi
  exit 0
fi

# 3. MODO --APPLY: Autenticación y Volcado Jerárquico en Infisical
echo -e "\n${BLUE}======================================================${NC}"
echo -e "${BLUE}  🚀 AGENT OS: MIGRACIÓN A INFISICAL (--apply activo)  ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo -e "🌐 Conectando con Infisical en: ${CYAN}${INFISICAL_API_URL}${NC}"
echo -e "🎯 Entorno destino: ${YELLOW}${ENV_TARGET}${NC} | Proyecto: ${INFISICAL_PROJECT_ID}"

# Obtener token de acceso Universal Auth en memoria
AUTH_TOKEN=$(infisical login \
  --domain="${INFISICAL_API_URL}" \
  --method=universal-auth \
  --client-id="${INFISICAL_CLIENT_ID}" \
  --client-secret="${INFISICAL_CLIENT_SECRET}" \
  --plain 2>/dev/null || echo "")

if [ -z "$AUTH_TOKEN" ]; then
  echo -e "${RED}❌ ERROR: Falló la autenticación Universal Auth con Infisical.${NC}"
  exit 1
fi
echo -e "🔑 Autenticado con éxito (Machine Identity: ${INFISICAL_CLIENT_ID:0:8}...)"

echo -e "🔍 Escaneando y analizando directorio: ${TARGET_DIR}..."
ANALYSIS_JSON=$(python3 "$PYTHON_ENGINE" "${PY_ARGS[@]}" --json)

TOTAL_PROJECTS=$(echo "$ANALYSIS_JSON" | jq -r '.total_projects')
TOTAL_VALID=$(echo "$ANALYSIS_JSON" | jq -r '.valid_secrets_count')
TOTAL_LOCAL=$(echo "$ANALYSIS_JSON" | jq -r '.untested_local_count')
TOTAL_REVOKED=$(echo "$ANALYSIS_JSON" | jq -r '.revoked_secrets_count')

echo -e "📊 Resumen: ${GREEN}${TOTAL_PROJECTS} proyectos${NC}, ${GREEN}$((TOTAL_VALID + TOTAL_LOCAL)) secretos a subir${NC} (${RED}${TOTAL_REVOKED} revocados omitidos${NC}).\n"

UPLOADED_COUNT=0
PROJECT_KEYS=$(echo "$ANALYSIS_JSON" | jq -r '.projects | keys[]')

for PROJ in $PROJECT_KEYS; do
  FOLDER_NAME="$PROJ"
  FOLDER_PATH="/$FOLDER_NAME"
  
  # Contar secretos elegibles
  ELIGIBLE_SECRETS=$(echo "$ANALYSIS_JSON" | jq -r ".projects[\"$PROJ\"].secrets[] | select(.status != \"REVOKED\") | \"\(.key)=\(.value)\"")
  
  if [ -z "$ELIGIBLE_SECRETS" ]; then
    continue
  fi

  echo -e "📁 Procesando proyecto: ${BLUE}${FOLDER_NAME}${NC} (Ruta: ${FOLDER_PATH})"
  
  # Crear carpeta en Infisical si no existe
  infisical secrets folders create \
    --name="${FOLDER_NAME}" \
    --path="/" \
    --domain="${INFISICAL_API_URL}" \
    --projectId="${INFISICAL_PROJECT_ID}" \
    --env="${ENV_TARGET}" \
    --token="${AUTH_TOKEN}" \
    --silent >/dev/null 2>&1 || true

  # Subir secretos de este proyecto
  while IFS= read -r SEC_LINE; do
    if [ -n "$SEC_LINE" ]; then
      K="${SEC_LINE%%=*}"
      V="${SEC_LINE#*=}"
      
      # Subida a Infisical vía CLI con token efímero
      if infisical secrets set "$K=$V" \
        --path="${FOLDER_PATH}" \
        --domain="${INFISICAL_API_URL}" \
        --projectId="${INFISICAL_PROJECT_ID}" \
        --env="${ENV_TARGET}" \
        --token="${AUTH_TOKEN}" \
        --silent >/dev/null 2>&1; then
        echo -e "   ✅ ${K} subido a ${FOLDER_PATH}"
        UPLOADED_COUNT=$((UPLOADED_COUNT + 1))
      else
        echo -e "   ⚠️  Error al subir ${K} a ${FOLDER_PATH}"
      fi
    fi
  done <<< "$ELIGIBLE_SECRETS"
  echo ""
done

# Opción de limpieza de archivos .env a .env.backup
if [ "$CLEAN_ENV" = true ] && [ "$UPLOADED_COUNT" -gt 0 ]; then
  echo -e "🧹 Opción --clean-env activa: Protegiendo archivos .env locales..."
  ALL_ENV_FILES=$(echo "$ANALYSIS_JSON" | jq -r '.projects[].files[]' | sort -u)
  for ef in $ALL_ENV_FILES; do
    if [ -f "$ef" ]; then
      mv "$ef" "${ef}.backup"
      echo -e "   🔒 Respaldado: ${ef} → ${ef}.backup"
    fi
  done
  echo -e "   ${GREEN}Archivos .env renombrados a .backup (fuera de riesgo de filtración).${NC}\n"
fi

echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN}  ✅ MIGRACIÓN COMPLETADA: ${UPLOADED_COUNT} SECRETOS EN INFISICAL  ${NC}"
echo -e "${GREEN}======================================================${NC}"
echo -e "Entorno: ${YELLOW}${ENV_TARGET}${NC} | Proyecto: ${CYAN}${INFISICAL_PROJECT_ID}${NC}"
echo -e "Los secretos ya están disponibles para consumo en memoria vía:"
echo -e "${CYAN}infisical run --env=${ENV_TARGET} --path=\"/<proyecto>\" -- <comando>${NC}\n"
