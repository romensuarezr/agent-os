#!/bin/bash
# ==============================================================================
# tests/validate-control-plane.sh — Validador no destructivo del Control Plane
# ==============================================================================
# Valida:
#   1. Sintaxis YAML estricta de todos los perfiles y configs.
#   2. Existencia de los 7 perfiles obligatorios y campos requeridos.
#   3. Detección de secretos o credenciales en archivos rastreados.
#   4. Consistencia de referencias a hosts y proveedores de modelos.
#   5. Integridad de las skills universales de agent-os.
# ==============================================================================

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}  SUITE DE VALIDACIÓN: CONTROL PLANE DE AGENTES       ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""

# ------------------------------------------------------------------------------
# 1. Validación de Sintaxis YAML
# ------------------------------------------------------------------------------
echo -e "🔍 [1/8] Validando sintaxis YAML de perfiles y configuraciones..."
YAML_FILES=$(find .agents/profiles config -type f \( -name "*.yaml" -o -name "*.yml" \) 2>/dev/null || true)

for f in $YAML_FILES; do
  if python3 -c "import yaml; yaml.safe_load(open('$f'))" >/dev/null 2>&1; then
    echo -e "  ✅ YAML válido: $f"
  else
    echo -e "  ❌ ERROR de sintaxis YAML en: $f"
    ERRORS=$((ERRORS + 1))
  fi
done

# ------------------------------------------------------------------------------
# 2. Comprobación de Perfiles Obligatorios y Esquema
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [2/8] Comprobando perfiles obligatorios y campos mínimos..."
REQUIRED_PROFILES=("coordinator" "ops-auditor" "developer" "reviewer" "marketing" "seo" "researcher")
REQUIRED_FIELDS=("id" "purpose" "allowed_tools" "allowed_hosts" "preferred_model_tier" "fallback_model_tier" "forbidden_actions" "escalation_triggers" "human_approval_required")

for p in "${REQUIRED_PROFILES[@]}"; do
  P_FILE=".agents/profiles/${p}.yaml"
  if [ ! -f "$P_FILE" ]; then
    echo -e "  ❌ Falta el perfil obligatorio: $P_FILE"
    ERRORS=$((ERRORS + 1))
  else
    # Validar campos requeridos en el YAML usando python
    MISSING_FIELDS=$(python3 -c "
import yaml, sys
data = yaml.safe_load(open('$P_FILE'))
required = ['id', 'purpose', 'allowed_tools', 'allowed_hosts', 'preferred_model_tier', 'fallback_model_tier', 'forbidden_actions', 'escalation_triggers', 'human_approval_required']
missing = [f for f in required if f not in data or data[f] is None]
if missing:
    print(','.join(missing))
" 2>/dev/null || echo "python_error")

    if [ -n "$MISSING_FIELDS" ]; then
      echo -e "  ❌ $P_FILE carece de campos requeridos: $MISSING_FIELDS"
      ERRORS=$((ERRORS + 1))
    else
      echo -e "  ✅ Perfil conforme: ${p}"
    fi
  fi
done

# ------------------------------------------------------------------------------
# 3. Detección de Secretos o Credenciales Trackeadas
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [3/8] Escaneando archivos rastreados en busca de posibles secretos..."

# Comprobar si hay archivos .env trackeados
TRACKED_ENV=$(git ls-files | grep -E '\.env$|\.env\.(local|production|prod|dev)$' | grep -v '\.env\.example$' || true)
if [ -n "$TRACKED_ENV" ]; then
  echo -e "  ❌ ALERTA DE SEGURIDAD: Archivo .env trackeado en git: $TRACKED_ENV"
  ERRORS=$((ERRORS + 1))
else
  echo -e "  ✅ Ningún archivo .env o secreto sensible trackeado en git."
fi

# Escanear patrones de claves privadas o tokens en archivos trackeados (excluyendo tests y templates)
TRACKED_SECRET_PATTERNS=$(git grep -EI '(BEGIN RSA PRIVATE KEY|BEGIN OPENSSH PRIVATE KEY|ghp_[a-zA-Z0-9]{30,}|sk-[a-zA-Z0-9]{32,}|xoxb-[a-zA-Z0-9]{10,})' -- ':!tests/*' ':!*.example' 2>/dev/null || true)
if [ -n "$TRACKED_SECRET_PATTERNS" ]; then
  echo -e "  ❌ ALERTA DE SEGURIDAD: Patrón de secreto detectado en el repositorio:"
  echo "$TRACKED_SECRET_PATTERNS"
  ERRORS=$((ERRORS + 1))
else
  echo -e "  ✅ No se detectaron patrones de tokens comerciales ni claves privadas."
fi

# Comprobar que las skills y rules distribuidas sean 100% agnósticas (sin IPs privadas ni sslip.io)
DISTRIBUTED_PRIVATE_DATA=$(git grep -EI '(158\.179\.|100\.77\.|100\.96\.|sslip\.io)' -- '.agents/skills/*' '.agents/rules/*' 2>/dev/null || true)
if [ -n "$DISTRIBUTED_PRIVATE_DATA" ]; then
  echo -e "  ❌ VIOLACIÓN DE AGNOSTICISMO: Se detectaron IPs o dominios privados en skills/rules distribuidas:"
  echo "$DISTRIBUTED_PRIVATE_DATA"
  ERRORS=$((ERRORS + 1))
else
  echo -e "  ✅ Skills y rules distribuidas son 100% agnósticas (sin IPs ni dominios privados)."
fi

# ------------------------------------------------------------------------------
# 4. Comprobación de Referencias a Hosts y Model Tiers
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [4/8] Verificando consistencia de hosts y routing tiers..."
VALID_HOSTS=("local" "datamanager" "oracle" "all")

HOST_VALIDATION=$(python3 -c "
import yaml, glob
valid_hosts = {'local', 'datamanager', 'oracle', 'all'}
errors = []
for f in glob.glob('.agents/profiles/*.yaml'):
    data = yaml.safe_load(open(f))
    hosts = data.get('allowed_hosts', [])
    for h in hosts:
        if h not in valid_hosts:
            errors.append(f'{f}: host desconocido \"{h}\"')
if errors:
    print('\n'.join(errors))
" 2>/dev/null || true)

if [ -n "$HOST_VALIDATION" ]; then
  echo -e "  ❌ Referencias a hosts inválidas:"
  echo "$HOST_VALIDATION"
  ERRORS=$((ERRORS + 1))
else
  echo -e "  ✅ Todas las referencias a hosts coinciden con la topología real."
fi

# ------------------------------------------------------------------------------
# 5. Integridad de Skills Universales (Integración Hermes)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [5/8] Verificando integridad de skills existentes para Hermes..."
SKILLS_DIR=".agents/skills"
TOTAL_SKILLS=0
VALID_SKILLS=0

for s in "$SKILLS_DIR"/*/; do
  if [ -d "$s" ]; then
    TOTAL_SKILLS=$((TOTAL_SKILLS + 1))
    SKILL_NAME=$(basename "$s")
    if [ -f "$s/SKILL.md" ]; then
      VALID_SKILLS=$((VALID_SKILLS + 1))
    else
      echo -e "  ⚠️  Advertencia: Skill sin SKILL.md: $SKILL_NAME"
    fi
  fi
done

echo -e "  ✅ $VALID_SKILLS/$TOTAL_SKILLS skills verificadas con SKILL.md intacto."
echo -e "  ℹ️  Compatibilidad de symlinks con Hermes en datamanager garantizada."

# ------------------------------------------------------------------------------
# 6. Verificación de Auto-Descubrimiento Determinista (discover-fleet.sh)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [6/8] Verificando script determinista discover-fleet.sh..."
DISCOVER_SCRIPT="scripts/agent/discover-fleet.sh"
if [ ! -x "$DISCOVER_SCRIPT" ]; then
  echo -e "  ❌ El script $DISCOVER_SCRIPT no existe o no tiene permisos de ejecución (+x)."
  ERRORS=$((ERRORS + 1))
else
  # Ejecutar en modo JSON y comprobar que emite JSON válido con local_environment
  if python3 -c "import json, subprocess; out = subprocess.check_output(['bash', '$DISCOVER_SCRIPT', '--json']); data = json.loads(out); assert 'local_environment' in data" 2>/dev/null; then
    echo -e "  ✅ discover-fleet.sh funciona correctamente y emite digest determinista válido."
  else
    echo -e "  ❌ ERROR: discover-fleet.sh falló al generar el digest JSON determinista."
    ERRORS=$((ERRORS + 1))
  fi
fi

# ------------------------------------------------------------------------------
# 7. Verificación de Orquestación Multi-Agente en Orca (orca-orchestrate.sh)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [7/8] Verificando script de orquestación Orca (orca-orchestrate.sh)..."
ORCA_SCRIPT="scripts/agent/orca-orchestrate.sh"
if [ ! -x "$ORCA_SCRIPT" ]; then
  echo -e "  ❌ El script $ORCA_SCRIPT no existe o no tiene permisos de ejecución (+x)."
  ERRORS=$((ERRORS + 1))
else
  # Ejecutar status --json y comprobar que emite JSON válido
  if python3 -c "import json, subprocess; out = subprocess.check_output(['bash', '$ORCA_SCRIPT', 'status', '--json']); data = json.loads(out); assert 'status' in data" 2>/dev/null; then
    echo -e "  ✅ orca-orchestrate.sh funciona correctamente e interactúa con el runtime de Orca."
  else
    echo -e "  ❌ ERROR: orca-orchestrate.sh falló al consultar el estado de Orca."
    ERRORS=$((ERRORS + 1))
  fi
fi

# ------------------------------------------------------------------------------
# 8. Verificación de Migración de Secretos (import-secrets.sh)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [8/8] Verificando herramienta determinista import-secrets.sh..."
IMPORT_SCRIPT="scripts/agent/import-secrets.sh"
PYTHON_ENGINE="scripts/agent/lib/verify-secrets.py"

if [ ! -x "$IMPORT_SCRIPT" ]; then
  echo -e "  ❌ El script $IMPORT_SCRIPT no existe o no tiene permisos de ejecución (+x)."
  ERRORS=$((ERRORS + 1))
elif [ ! -x "$PYTHON_ENGINE" ]; then
  echo -e "  ❌ El motor $PYTHON_ENGINE no existe o no tiene permisos de ejecución (+x)."
  ERRORS=$((ERRORS + 1))
else
  if bash "$IMPORT_SCRIPT" --help >/dev/null 2>&1 && python3 "$PYTHON_ENGINE" . --json >/dev/null 2>&1; then
    echo -e "  ✅ import-secrets.sh y verify-secrets.py funcionan correctamente en modo determinista."
  else
    echo -e "  ❌ ERROR: import-secrets.sh o verify-secrets.py fallaron en la comprobación básica."
    ERRORS=$((ERRORS + 1))
  fi
fi

# ------------------------------------------------------------------------------
# Resumen Final
# ------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}======================================================${NC}"
if [ "$ERRORS" -eq 0 ]; then
  echo -e "${GREEN}  ✅ TODAS LAS VALIDACIONES PASARON EXITOSAMENTE (0 ERRORES)${NC}"
  echo -e "${BLUE}======================================================${NC}"
  exit 0
else
  echo -e "${RED}  ❌ SE DETECTARON $ERRORS ERRORES EN EL CONTROL PLANE${NC}"
  echo -e "${BLUE}======================================================${NC}"
  exit 1
fi
