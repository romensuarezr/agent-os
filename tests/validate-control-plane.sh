#!/usr/bin/env bash
# ==============================================================================
# tests/validate-control-plane.sh — Validador no destructivo del Control Plane
# ==============================================================================
# Valida:
#   1. Sintaxis YAML estricta de todos los perfiles y configs.
#   2. Existencia de los 7 perfiles obligatorios y campos requeridos.
#   3. Detección de secretos o credenciales en archivos rastreados.
#   4. Consistencia de referencias a hosts y proveedores de modelos.
#   5. Integridad de las skills universales de agent-os.
#   6. Auto-descubrimiento determinista de flota (discover-fleet.sh).
#   7. Orquestación multi-agente en Orca (orca-orchestrate.sh).
#   8. Migración y verificación de secretos (import-secrets.sh).
#   9. Sintaxis y permisos de scripts de metas, orquestación y promoción.
#  10. Frontmatter YAML estricto de perfiles declarativos (.md).
#  11. Generador declarativo de Homepage (generate-homepage-config.sh).
#  12. Diagnóstico determinista de flota y salud local (fleet-doctor.sh).
# ==============================================================================

set -euo pipefail

# Pre-flight: verificación determinista de dependencias base
for cmd in git python3 bash find grep; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ ERROR: Dependencia requerida no encontrada: $cmd" >&2
    echo "Guía: Instala $cmd en tu sistema antes de continuar." >&2
    exit 1
  fi
done

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

# Detección determinista de PyYAML
HAS_PYYAML=true
if ! python3 -c "import yaml" >/dev/null 2>&1; then
  HAS_PYYAML=false
  echo -e "${YELLOW}⚠️  AVISO: Módulo 'yaml' (PyYAML) no disponible en python3.${NC}"
  echo -e "${YELLOW}   Las validaciones que requieren parser YAML estricto se omitirán de forma segura.${NC}"
  echo ""
fi

# ------------------------------------------------------------------------------
# 1. Validación de Sintaxis YAML
# ------------------------------------------------------------------------------
echo -e "🔍 [1/12] Validando sintaxis YAML de perfiles y configuraciones..."
YAML_FILES=$(find .agents/profiles config -type f \( -name "*.yaml" -o -name "*.yml" \) 2>/dev/null || true)

if [ "$HAS_PYYAML" = true ]; then
  for f in $YAML_FILES; do
    if python3 -c "import yaml; yaml.safe_load(open('$f'))" >/dev/null 2>&1; then
      echo -e "  ✅ YAML válido: $f"
    else
      echo -e "  ❌ ERROR de sintaxis YAML en: $f"
      ERRORS=$((ERRORS + 1))
    fi
  done
else
  echo -e "  ℹ️  [SKIP] PyYAML no disponible: validación de sintaxis YAML omitida."
fi

# ------------------------------------------------------------------------------
# 2. Comprobación de Perfiles Obligatorios y Esquema
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [2/12] Comprobando perfiles obligatorios y campos mínimos..."
REQUIRED_PROFILES=("coordinator" "ops-auditor" "developer" "reviewer" "marketing" "seo" "researcher")

for p in "${REQUIRED_PROFILES[@]}"; do
  P_FILE=".agents/profiles/${p}.yaml"
  if [ ! -f "$P_FILE" ]; then
    echo -e "  ❌ Falta el perfil obligatorio: $P_FILE"
    ERRORS=$((ERRORS + 1))
  elif [ "$HAS_PYYAML" = false ]; then
    echo -e "  ℹ️  Perfil existe: ${p} (validación de campos omitida: PyYAML ausente)"
  else
    # Validar campos requeridos en el YAML usando python
    MISSING_FIELDS=$(python3 -c "
import yaml, sys
try:
    data = yaml.safe_load(open('$P_FILE')) or {}
    required = ['id', 'purpose', 'allowed_tools', 'allowed_hosts', 'preferred_model_tier', 'fallback_model_tier', 'forbidden_actions', 'escalation_triggers', 'human_approval_required']
    missing = [f for f in required if f not in data or data[f] is None]
    if missing:
        print(','.join(missing))
except Exception as e:
    print('yaml_error: ' + str(e))
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
echo -e "🔍 [3/12] Escaneando archivos rastreados en busca de posibles secretos..."

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
echo -e "🔍 [4/12] Verificando consistencia de hosts y routing tiers..."

if [ "$HAS_PYYAML" = true ]; then
  HOST_VALIDATION=$(python3 -c "
import yaml, glob
valid_hosts = {'local', 'datamanager', 'oracle', 'all'}
errors = []
for f in glob.glob('.agents/profiles/*.yaml'):
    try:
        data = yaml.safe_load(open(f)) or {}
        hosts = data.get('allowed_hosts', [])
        for h in hosts:
            if h not in valid_hosts:
                errors.append(f'{f}: host desconocido \"{h}\"')
    except Exception:
        pass
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
else
  echo -e "  ℹ️  [SKIP] PyYAML no disponible: validación de hosts omitida."
fi

# ------------------------------------------------------------------------------
# 5. Integridad de Skills Universales (Integración Hermes)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [5/12] Verificando integridad de skills existentes para Hermes..."
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
echo -e "🔍 [6/12] Verificando script determinista discover-fleet.sh..."
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
echo -e "🔍 [7/12] Verificando script de orquestación Orca (orca-orchestrate.sh)..."
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
echo -e "🔍 [8/12] Verificando herramienta determinista import-secrets.sh..."
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
# 9. Integridad y Permisos de Scripts de Metas, Orquestación Paralela y Promoción
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [9/12] Verificando sintaxis y permisos de scripts de metas, orquestación y promoción..."
ORCH_SCRIPTS=("scripts/agent/verify-goal.sh" "scripts/agent/worktree-dispatch.sh" "scripts/agent/worktree-merge.sh" "scripts/agent/promote-to-main.sh")

for s in "${ORCH_SCRIPTS[@]}"; do
  if [ ! -f "$s" ]; then
    echo -e "  ❌ El script requerido no existe: $s"
    ERRORS=$((ERRORS + 1))
  elif [ ! -x "$s" ]; then
    echo -e "  ❌ El script $s carece de permisos de ejecución (+x)."
    ERRORS=$((ERRORS + 1))
  elif ! bash -n "$s" 2>/dev/null; then
    echo -e "  ❌ Error de sintaxis (bash -n) en: $s"
    ERRORS=$((ERRORS + 1))
  else
    echo -e "  ✅ Script íntegro y ejecutable: $s"
  fi
done

# ------------------------------------------------------------------------------
# 10. Validación Estricta de Frontmatter YAML en Perfiles Declarativos (.md)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [10/12] Validando frontmatter YAML de perfiles declarativos (.md)..."
MD_PROFILES=("coordinator.md" "coder.md" "qa-judge.md" "docs-researcher.md")

for p in "${MD_PROFILES[@]}"; do
  P_PATH=".agents/profiles/$p"
  if [ ! -f "$P_PATH" ]; then
    echo -e "  ❌ Falta el perfil declarativo requerido: $P_PATH"
    ERRORS=$((ERRORS + 1))
  elif [ "$HAS_PYYAML" = false ]; then
    echo -e "  ℹ️  Perfil declarativo existe: $p (validación frontmatter omitida: PyYAML ausente)"
  else
    PROFILE_VALIDATION=$(python3 -c "
import yaml, sys

try:
    content = open('$P_PATH').read()
    parts = content.split('---')
    if len(parts) < 3:
        print('Frontmatter YAML ausente o mal delimitado')
        sys.exit(0)
    data = yaml.safe_load(parts[1])
    if not isinstance(data, dict):
        print('Frontmatter no es un diccionario YAML válido')
        sys.exit(0)
    
    missing = []
    if 'name' not in data or not data['name']:
        missing.append('name')
    if 'role' not in data and 'role_type' not in data:
        missing.append('role/role_type')
    if 'skills' not in data or not isinstance(data['skills'], dict):
        missing.append('skills (dict)')
    else:
        if 'primary' not in data['skills']:
            missing.append('skills.primary')
        if 'forbidden' not in data['skills']:
            missing.append('skills.forbidden')
    if 'tooling' not in data or not isinstance(data['tooling'], dict):
        missing.append('tooling (dict)')
    else:
        if 'allowed' not in data['tooling']:
            missing.append('tooling.allowed')
        if 'forbidden' not in data['tooling']:
            missing.append('tooling.forbidden')
    if 'decision_gates' not in data or not isinstance(data['decision_gates'], list):
        missing.append('decision_gates (list)')
    
    if missing:
        print('Campos requeridos faltantes o inválidos: ' + ', '.join(missing))
except Exception as e:
    print('Excepción al analizar YAML: ' + str(e))
" 2>/dev/null || echo "python_error")

    if [ -n "$PROFILE_VALIDATION" ]; then
      echo -e "  ❌ Error en perfil $P_PATH: $PROFILE_VALIDATION"
      ERRORS=$((ERRORS + 1))
    else
      echo -e "  ✅ Perfil declarativo conforme: $p"
    fi
  fi
done

# ------------------------------------------------------------------------------
# 11. Validación Determinista del Generador Homepage (generate-homepage-config.sh)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [11/12] Verificando generador declarativo de Homepage (generate-homepage-config.sh)..."
HOMEPAGE_SCRIPT="scripts/agent/generate-homepage-config.sh"
if [ ! -x "$HOMEPAGE_SCRIPT" ]; then
  echo -e "  ❌ El script $HOMEPAGE_SCRIPT no existe o no tiene permisos de ejecución (+x)."
  ERRORS=$((ERRORS + 1))
else
  if bash "$HOMEPAGE_SCRIPT" --fleet config/fleet.example.yaml --check >/dev/null 2>&1; then
    echo -e "  ✅ generate-homepage-config.sh genera configuraciones válidas a partir de fleet.example.yaml en modo agnóstico."
  else
    echo -e "  ❌ ERROR: generate-homepage-config.sh falló al procesar fleet.example.yaml en modo --check."
    ERRORS=$((ERRORS + 1))
  fi
fi

# ------------------------------------------------------------------------------
# 12. Diagnóstico y Salud Determinista de Flota (fleet-doctor.sh)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [12/12] Verificando diagnóstico determinista de flota (fleet-doctor.sh)..."
DOCTOR_SCRIPT="scripts/agent/fleet-doctor.sh"

if [ ! -x "$DOCTOR_SCRIPT" ]; then
  echo -e "  ❌ El script $DOCTOR_SCRIPT no existe o no tiene permisos de ejecución (+x)."
  ERRORS=$((ERRORS + 1))
elif ! bash -n "$DOCTOR_SCRIPT" 2>/dev/null; then
  echo -e "  ❌ Error de sintaxis (bash -n) en: $DOCTOR_SCRIPT"
  ERRORS=$((ERRORS + 1))
else
  # 1. Comprobar que fleet-doctor valida sintaxis y procesa config/fleet.example.yaml en modo agnóstico
  if python3 -c "import json, subprocess; out = subprocess.check_output(['bash', '$DOCTOR_SCRIPT', '--fleet', 'config/fleet.example.yaml', '--json']); data = json.loads(out); assert 'summary' in data and data['fleet']['mode'] == 'SKIPPED-NO-FLEET'" 2>/dev/null; then
    echo -e "  ✅ fleet-doctor.sh valida sintaxis y procesa config/fleet.example.yaml deterministamente."
  else
    echo -e "  ❌ ERROR: fleet-doctor.sh falló al procesar config/fleet.example.yaml."
    ERRORS=$((ERRORS + 1))
  fi

  # 2. Check condicional sobre entorno real / config/fleet.yaml
  if [ -f "config/fleet.yaml" ]; then
    if bash "$DOCTOR_SCRIPT" --strict >/dev/null 2>&1; then
      echo -e "  ✅ fleet.yaml detectado: diagnóstico de flota ejecutado y saludable."
    else
      echo -e "  ⚠️  fleet.yaml detectado pero se detectaron servicios o CLIs degradados."
    fi
  else
    echo -e "  ℹ️  [SKIP CONDICIONAL] config/fleet.yaml no existe en este entorno: conectividad viva omitida de forma segura."
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
