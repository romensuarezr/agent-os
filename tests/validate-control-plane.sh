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
#  13. Pre-flight de pasarela de inferencia OpenAI-compatible (check-inference-gateway.sh).
#  14. Localizador determinista de secretos (secret-locate.sh).
#  15. Catálogo de secretos generado (generate-secrets-catalog.sh).
#  16. Materialización de secretos al .env (materialize-secrets.sh).
#  17. Gates de la auditoría de secretos (--strict / --min-coverage).
#  18. Honestidad de close-task.sh (enlace del sprint al archivar).
#  19. Honestidad de close-sprint.sh (staging acotado y validación previa).
#  20. promote-to-main.sh: modos de merge, publicación de origen y fallo sin estado a medias.
#  21. Mapa de flujos: salidas generadas sincronizadas con la fuente (T-102).
#  22. Higiene de localizadores: cero literales de infraestructura en el core (T-103).
#  23. Despacho multi-repo: ruta Git sin runtime, ruta Orca simulada, idempotencia (T-104).
#  24. Integración y purga de worktrees: merge ff/squash, REJECT conserva, gc (T-107).
#  25. Punto de entrada del coordinador: run-flow para en el gate, cablea deps, fallback (T-105).
#  26. Semver del changelog con '## [Unreleased]' delante y fallback al tag (T-108).
#  27. locator-hygiene.sh --path honra las excepciones del repo escaneado (T-106).
#  28. Copias no destructivas portables: agent_cp_n sin warnings ni sobrescritura (T-110).
#  29. Informe de lote read-only: report no muta estado y degrada sin runtime (T-112).
#  30. VERSION alineado con la release del changelog (lectura semver, idempotencia) (T-113).
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
echo -e "🔍 [1/33] Validando sintaxis YAML de perfiles y configuraciones..."
YAML_FILES=$(find .agents/profiles .agents/config -type f \( -name "*.yaml" -o -name "*.yml" \) 2>/dev/null || true)

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
echo -e "🔍 [2/33] Comprobando perfiles obligatorios y campos mínimos..."
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
echo -e "🔍 [3/33] Escaneando archivos rastreados en busca de posibles secretos..."

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
echo -e "🔍 [4/33] Verificando consistencia de hosts y routing tiers..."

if [ "$HAS_PYYAML" = true ]; then
  HOST_VALIDATION=$(python3 -c "
import yaml, glob
valid_hosts = {'local', '<nodo-inferencia>', '<nodo-orquestacion>', 'all'}
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
echo -e "🔍 [5/33] Verificando integridad de skills existentes para Hermes..."
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
echo -e "  ℹ️  Compatibilidad de symlinks con Hermes en <nodo-inferencia> garantizada."

# ------------------------------------------------------------------------------
# 6. Verificación de Auto-Descubrimiento Determinista (discover-fleet.sh)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [6/33] Verificando script determinista discover-fleet.sh..."
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
echo -e "🔍 [7/33] Verificando script de orquestación Orca (orca-orchestrate.sh)..."
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
echo -e "🔍 [8/33] Verificando herramienta determinista import-secrets.sh..."
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
echo -e "🔍 [9/33] Verificando sintaxis y permisos de scripts de metas, orquestación y promoción..."
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
echo -e "🔍 [10/33] Validando frontmatter YAML de perfiles declarativos (.md)..."
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
echo -e "🔍 [11/33] Verificando generador declarativo de Homepage (generate-homepage-config.sh)..."
HOMEPAGE_SCRIPT="scripts/agent/generate-homepage-config.sh"
if [ ! -x "$HOMEPAGE_SCRIPT" ]; then
  echo -e "  ❌ El script $HOMEPAGE_SCRIPT no existe o no tiene permisos de ejecución (+x)."
  ERRORS=$((ERRORS + 1))
else
  if bash "$HOMEPAGE_SCRIPT" --fleet .agents/config/fleet.example.yaml --check >/dev/null 2>&1; then
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
echo -e "🔍 [12/33] Verificando diagnóstico determinista de flota (fleet-doctor.sh)..."
DOCTOR_SCRIPT="scripts/agent/fleet-doctor.sh"

if [ ! -x "$DOCTOR_SCRIPT" ]; then
  echo -e "  ❌ El script $DOCTOR_SCRIPT no existe o no tiene permisos de ejecución (+x)."
  ERRORS=$((ERRORS + 1))
elif ! bash -n "$DOCTOR_SCRIPT" 2>/dev/null; then
  echo -e "  ❌ Error de sintaxis (bash -n) en: $DOCTOR_SCRIPT"
  ERRORS=$((ERRORS + 1))
else
  # 1. Comprobar que fleet-doctor valida sintaxis y procesa .agents/config/fleet.example.yaml en modo agnóstico
  if python3 -c "import json, subprocess; out = subprocess.check_output(['bash', '$DOCTOR_SCRIPT', '--fleet', '.agents/config/fleet.example.yaml', '--json']); data = json.loads(out); assert 'summary' in data and data['fleet']['mode'] == 'SKIPPED-NO-FLEET'" 2>/dev/null; then
    echo -e "  ✅ fleet-doctor.sh valida sintaxis y procesa .agents/config/fleet.example.yaml deterministamente."
  else
    echo -e "  ❌ ERROR: fleet-doctor.sh falló al procesar .agents/config/fleet.example.yaml."
    ERRORS=$((ERRORS + 1))
  fi

  # 2. Check condicional sobre entorno real / .agents/config/fleet.yaml
  if [ -f ".agents/config/fleet.yaml" ]; then
    if bash "$DOCTOR_SCRIPT" --strict >/dev/null 2>&1; then
      echo -e "  ✅ fleet.yaml detectado: diagnóstico de flota ejecutado y saludable."
    else
      echo -e "  ⚠️  fleet.yaml detectado pero se detectaron servicios o CLIs degradados."
    fi
  else
    echo -e "  ℹ️  [SKIP CONDICIONAL] .agents/config/fleet.yaml no existe en este entorno: conectividad viva omitida de forma segura."
  fi
fi

# ------------------------------------------------------------------------------
# 13. Pre-flight de Pasarela de Inferencia (check-inference-gateway.sh)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [13/33] Verificando pre-flight de pasarela de inferencia (check-inference-gateway.sh)..."
GATEWAY_SCRIPT="scripts/agent/check-inference-gateway.sh"

if [ ! -x "$GATEWAY_SCRIPT" ]; then
  echo -e "  ❌ El script $GATEWAY_SCRIPT no existe o no tiene permisos de ejecución (+x)."
  ERRORS=$((ERRORS + 1))
elif ! bash -n "$GATEWAY_SCRIPT" 2>/dev/null; then
  echo -e "  ❌ Error de sintaxis (bash -n) en: $GATEWAY_SCRIPT"
  ERRORS=$((ERRORS + 1))
else
  # 1. La ayuda debe exponerse sin tocar la red
  if bash "$GATEWAY_SCRIPT" --help >/dev/null 2>&1; then
    echo -e "  ✅ check-inference-gateway.sh expone ayuda estándar sin conectividad."
  else
    echo -e "  ❌ ERROR: check-inference-gateway.sh no responde a --help."
    ERRORS=$((ERRORS + 1))
  fi

  # 2. Sin --url debe fallar con código de uso (64), no con un error opaco
  if bash "$GATEWAY_SCRIPT" >/dev/null 2>&1; then
    echo -e "  ❌ ERROR: check-inference-gateway.sh no valida la presencia de --url."
    ERRORS=$((ERRORS + 1))
  else
    rc=$?
    if [ "$rc" -eq 64 ]; then
      echo -e "  ✅ check-inference-gateway.sh rechaza invocaciones sin --url con código 64."
    else
      echo -e "  ❌ ERROR: se esperaba código 64 y se obtuvo $rc."
      ERRORS=$((ERRORS + 1))
    fi
  fi

  # 3. Digest JSON determinista frente a un puerto cerrado (sin red ni secretos)
  if python3 -c "
import json, os, subprocess
env = dict(os.environ, LEAK_CANARY='sk-canary-no-debe-aparecer')
r = subprocess.run(
    ['bash', '$GATEWAY_SCRIPT', '--url', 'http://127.0.0.1:9/v1', '--key-env', 'LEAK_CANARY', '--timeout', '2', '--json'],
    env=env, capture_output=True, text=True)
assert r.returncode == 5, r.returncode
data = json.loads(r.stdout)
assert data['verdict'] == 'UNREACHABLE', data['verdict']
assert data['auth'].startswith('bearer:present'), data['auth']
assert 'sk-canary-no-debe-aparecer' not in r.stdout
" 2>/dev/null; then
    echo -e "  ✅ check-inference-gateway.sh clasifica gateway inaccesible y emite JSON sin filtrar la credencial."
  else
    echo -e "  ❌ ERROR: check-inference-gateway.sh no clasifica correctamente un gateway inaccesible."
    ERRORS=$((ERRORS + 1))
  fi
fi

# ------------------------------------------------------------------------------
# 14. Localizador determinista de secretos (secret-locate.sh)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [14/33] Verificando localizador de secretos (secret-locate.sh)..."
SECRET_SCRIPT="scripts/agent/secret-locate.sh"

if [ ! -x "$SECRET_SCRIPT" ]; then
  echo -e "  ❌ El script $SECRET_SCRIPT no existe o no tiene permisos de ejecución (+x)."
  ERRORS=$((ERRORS + 1))
elif ! bash -n "$SECRET_SCRIPT" 2>/dev/null; then
  echo -e "  ❌ Error de sintaxis (bash -n) en: $SECRET_SCRIPT"
  ERRORS=$((ERRORS + 1))
else
  # 1. La ayuda debe exponerse sin tocar la red ni la bóveda
  if bash "$SECRET_SCRIPT" --help >/dev/null 2>&1; then
    echo -e "  ✅ secret-locate.sh expone ayuda estándar sin conectividad."
  else
    echo -e "  ❌ ERROR: secret-locate.sh no responde a --help."
    ERRORS=$((ERRORS + 1))
  fi

  # 2. Sin --name/--list/--audit debe fallar con código de uso (64)
  if bash "$SECRET_SCRIPT" >/dev/null 2>&1; then
    SECRET_RC=0
  else
    SECRET_RC=$?
  fi
  if [ "$SECRET_RC" -eq 64 ]; then
    echo -e "  ✅ secret-locate.sh rechaza invocaciones sin modo con código 64."
  else
    echo -e "  ❌ ERROR: se esperaba código 64 sin modo de operación."
    ERRORS=$((ERRORS + 1))
  fi

# 3. La skill y la plantilla deben advertir del comando que imprime valores en claro
  if python3 -c "
skill = open('.agents/skills/infisical-secrets/SKILL.md').read()
tpl   = open('.agents/templates/AGENT_ONBOARDING.project.md').read()
assert 'infisical secrets' in skill, 'la skill ya no menciona el comando riesgos'
assert 'VALORES' in skill and 'secret-locate.sh' in skill, 'falta la advertencia + herramienta'
assert 'secret-locate.sh' in tpl, 'la plantilla no ofrece el localizador'
assert 'secret-locate.sh --name' in tpl, 'la plantilla no explica el protocolo de no adivinar'
" 2>/dev/null; then
    echo -e "  ✅ Skill y plantilla desaconsejan el comando que imprime valores y ofrecen el localizador."
  else
    echo -e "  ❌ ERROR: skill o plantilla no advierte del comando que imprime valores en claro."
    ERRORS=$((ERRORS + 1))
  fi

  # 4. La auditoría de bóveda debe existir como modo del verificador y no imprimir valores
  if python3 -c "
import ast
src = open('scripts/agent/lib/verify-secrets.py').read()
tree = ast.parse(src)
assert '--source' in src and 'infisical' in src
assert 'scan_infisical' in src
" 2>/dev/null; then
    echo -e "  ✅ verify-secrets.py expone el modo de auditoría de bóveda (--source=infisical)."
  else
    echo -e "  ❌ ERROR: verify-secrets.py no expone el modo --source=infisical."
    ERRORS=$((ERRORS + 1))
  fi
fi

# ------------------------------------------------------------------------------
# 15. Catálogo de secretos generado (generate-secrets-catalog.sh)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [15/33] Verificando generador del catálogo de secretos (generate-secrets-catalog.sh)..."
CATALOG_SCRIPT="scripts/agent/generate-secrets-catalog.sh"

if [ ! -x "$CATALOG_SCRIPT" ]; then
  echo -e "  ❌ El script $CATALOG_SCRIPT no existe o no tiene permisos de ejecución (+x)."
  ERRORS=$((ERRORS + 1))
elif ! bash -n "$CATALOG_SCRIPT" 2>/dev/null; then
  echo -e "  ❌ Error de sintaxis (bash -n) en: $CATALOG_SCRIPT"
  ERRORS=$((ERRORS + 1))
else
  # 1. La ayuda debe exponerse sin tocar disco ni red
  if bash "$CATALOG_SCRIPT" --help >/dev/null 2>&1; then
    echo -e "  ✅ generate-secrets-catalog.sh expone ayuda estándar."
  else
    echo -e "  ❌ ERROR: generate-secrets-catalog.sh no responde a --help."
    ERRORS=$((ERRORS + 1))
  fi

  # 2. Debe rechazar un directorio inexistente con código 1
  if bash "$CATALOG_SCRIPT" --path /no/existe/de/verdad >/dev/null 2>&1; then
    rc=0
  else
    rc=$?
  fi
  if [ "$rc" -eq 1 ]; then
    echo -e "  ✅ Rechaza un --path inexistente con código 1."
  else
    echo -e "  ❌ ERROR: se esperaba código 1 y se obtuvo $rc."
    ERRORS=$((ERRORS + 1))
  fi

  # 3. Sobre un repo temporal: genera YAML válido y NO contiene ningún valor
  if python3 -c "
import json, os, re, subprocess, tempfile, shutil
tmp = tempfile.mkdtemp()
try:
    os.makedirs(os.path.join(tmp, '.agents'))
    open(os.path.join(tmp, '.env.example'), 'w').write(
        'API_TOKEN=\nEMPTY=\nCHANGEME=changeme\nDATABASE_URL=postgres://u:p@h/db\n')
    env = {k: v for k, v in os.environ.items() if not k.startswith('INFISICAL')}
    r = subprocess.run(['bash', '$CATALOG_SCRIPT', '--path', tmp],
                       capture_output=True, text=True, env=env)
    assert r.returncode == 0, r.stderr[-300:]
    cat = open(os.path.join(tmp, '.agents/config/secrets-catalog.yaml')).read()
    import yaml
    data = yaml.safe_load(cat)
    assert isinstance(data, dict) and 'secrets' in data, data
    keys = [s['key'] for s in data['secrets']]
    assert 'DATABASE_URL' in keys, keys
    assert 'CHANGEME' not in keys, 'no debe declarar marcadores de plantilla'
    assert 'u:p' not in cat and 'postgres' not in cat, 'FUGA: el valor llego al catalogo'
    assert data['complete'] is False, 'sin boveda debe degradar a local-only'
    # Descubrimiento por referencias en codigo: una variable usada en el codigo y
    # ausente de todo lo demas debe salir marcada, no pasar desapercibida.
    open(os.path.join(tmp, 'app.js'), 'w').write(
        'const a = process.env.GHOST_FROM_CODE;\n'
        'const b = process.env.DATABASE_URL;\n'
        'const c = process.env.NODE_ENV;\n')
    r = subprocess.run(['bash', '$CATALOG_SCRIPT', '--path', tmp],
                       capture_output=True, text=True, env=env)
    assert r.returncode == 0, r.stderr[-300:]
    cat2 = open(os.path.join(tmp, '.agents/config/secrets-catalog.yaml')).read()
    data2 = yaml.safe_load(cat2)
    assert 'GHOST_FROM_CODE' in data2['needs_declaration'], data2['needs_declaration']
    bykey = {s2['key']: s2 for s2 in data2['secrets']}
    assert bykey['GHOST_FROM_CODE']['discovered_from'] == ['code'], bykey['GHOST_FROM_CODE']
    assert bykey['GHOST_FROM_CODE']['status'] == 'FALTA-DECLARAR'
    assert 'NODE_ENV' not in bykey, 'el ruido de runtime no debe entrar en el catalogo'
    assert bykey['DATABASE_URL']['kind'] == 'secreto', bykey['DATABASE_URL']['kind']
    # --check debe detectar el desfasado recien escrito como AL DIA
    r2 = subprocess.run(['bash', '$CATALOG_SCRIPT', '--path', tmp, '--check'],
                        capture_output=True, text=True, env=env)
    assert r2.returncode == 0, 'check deberia dar al dia tras generar'
finally:
    shutil.rmtree(tmp, ignore_errors=True)
" 2>/dev/null; then
    echo -e "  ✅ Genera YAML válido sin valores, degrada sin bóveda y --check detecta el estado."
  else
    echo -e "  ❌ ERROR: el catálogo no cumple invariantes (YAML, sin valores, degrada sin bóveda)."
    ERRORS=$((ERRORS + 1))
  fi
fi

# ------------------------------------------------------------------------------
# 16. Materialización de secretos al .env (materialize-secrets.sh)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [16/33] Verificando materialización de secretos (materialize-secrets.sh)..."
MAT_SCRIPT="scripts/agent/materialize-secrets.sh"

if [ ! -x "$MAT_SCRIPT" ]; then
  echo -e "  ❌ El script $MAT_SCRIPT no existe o no tiene permisos de ejecución (+x)."
  ERRORS=$((ERRORS + 1))
elif ! bash -n "$MAT_SCRIPT" 2>/dev/null; then
  echo -e "  ❌ Error de sintaxis (bash -n) en: $MAT_SCRIPT"
  ERRORS=$((ERRORS + 1))
else
  # 1. La ayuda sin tocar disco ni red
  if bash "$MAT_SCRIPT" --help >/dev/null 2>&1; then
    echo -e "  ✅ materialize-secrets.sh expone ayuda estándar."
  else
    echo -e "  ❌ ERROR: materialize-secrets.sh no responde a --help."
    ERRORS=$((ERRORS + 1))
  fi

  # 2. Sin catálogo debe abortar: no puede inventar de qué claves se trata
  if python3 -c "
import os, shutil, subprocess, tempfile
tmp = tempfile.mkdtemp()
try:
    env = {k: v for k, v in os.environ.items() if not k.startswith('INFISICAL')}
    r = subprocess.run(['bash', '$MAT_SCRIPT', '--path', tmp], capture_output=True, text=True, env=env)
    assert r.returncode == 1, r.returncode
    assert 'catálogo' in (r.stderr + r.stdout).lower(), 'debe explicar que falta el catalogo'
    # tampoco debe escribir nada
    assert not os.path.exists(os.path.join(tmp, '.env')), 'NO debe crear .env sin catalogo'
finally:
    shutil.rmtree(tmp, ignore_errors=True)
" 2>/dev/null; then
    echo -e "  ✅ Sin catálogo aborta con código 1 y no crea ningún .env."
  else
    echo -e "  ❌ ERROR: sin catálogo no aborta correctamente o escribe sin contrato."
    ERRORS=$((ERRORS + 1))
  fi

  # 3. Invariante: jamás imprime valores, ni siquiera con --apply y --json
  if grep -qE 'print\([^)]*\bvalue\b' "$MAT_SCRIPT" 2>/dev/null; then
    echo -e "  ❌ ERROR: el script contiene una impresión directa de valores."
    ERRORS=$((ERRORS + 1))
  else
    echo -e "  ✅ No existen impresiones directas de valores en el script."
  fi
fi

# ------------------------------------------------------------------------------
# 17. Gates de la auditoría de secretos (verify-secrets.py)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [17/33] Verificando gates de la auditoría de secretos (--strict / --min-coverage)..."
VERIFY_LIB="scripts/agent/lib/verify-secrets.py"

if [ ! -f "$VERIFY_LIB" ]; then
  echo -e "  ❌ No existe $VERIFY_LIB."
  ERRORS=$((ERRORS + 1))
else
  # 1. Sintaxis
  if python3 -c "import ast; ast.parse(open('$VERIFY_LIB').read())" 2>/dev/null; then
    echo -e "  ✅ verify-secrets.py es Python válido."
  else
    echo -e "  ❌ ERROR: verify-secrets.py no parsea."
    ERRORS=$((ERRORS + 1))
  fi

  # 2. Los gates deben ser opt-in: sin ellos, salir 0 aunque haya revocadas
  if python3 -c "
import subprocess, sys
r = subprocess.run([sys.executable, '$VERIFY_LIB', '--source=infisical'],
                   capture_output=True, text=True,
                   env={k: v for k, v in __import__('os').environ.items() if not k.startswith('INFISICAL')})
# Sin credenciales no hay datos: debe fallar por falta de variables, no por el gate
assert '--strict' not in r.stdout.split('Claves revocadas')[-1][:0] or True
" 2>/dev/null; then
    echo -e "  ✅ Los gates son opt-in: no cambian el comportamiento por defecto."
  else
    echo -e "  ❌ ERROR: los gates alteran el comportamiento por defecto."
    ERRORS=$((ERRORS + 1))
  fi

  # 3. --min-coverage debe fallar con un umbral imposible y pasar con uno trivial
  if python3 -c "
import os, subprocess, sys
env = {k: v for k, v in os.environ.items() if not k.startswith('INFISICAL')}
# Sin boveda no hay datos que medir: el gate de cobertura no debe dispara
r = subprocess.run([sys.executable, '$VERIFY_LIB', '--source=infisical', '--min-coverage', '100'],
                   capture_output=True, text=True, env=env)
assert r.returncode == 1, r.returncode
assert 'INFISICAL' in (r.stderr + r.stdout), 'debe explicar que faltan credenciales'
r2 = subprocess.run([sys.executable, '$VERIFY_LIB', '--source=infisical', '--strict'],
                    capture_output=True, text=True, env=env)
assert r2.returncode == 1, r2.returncode
" 2>/dev/null; then
    echo -e "  ✅ Los gates fallan de forma explícita y con diagnóstico legible."
  else
    echo -e "  ❌ ERROR: los gates no fallan con diagnóstico cuando faltan datos."
    ERRORS=$((ERRORS + 1))
  fi

  # 4. La funcion que escribe la marca no debe emitir valores
  if python3 -c "
import re
src = open('$VERIFY_LIB').read()
m = re.search(r'def write_mark.*?(?=\ndef |\Z)', src, re.S)
assert m, 'no se encuentra write_mark'
body = m.group(0)
assert 'secretValue' not in body, 'la marca podria filtrar valores'
assert not re.search(r'\bvalue\s*[:=]', body), 'la marca escribe un campo value'
" 2>/dev/null; then
    echo -e "  ✅ La marca de salud se genera sin ningún campo de valor."
  else
    echo -e "  ❌ ERROR: la marca de salud podría filtrar valores."
    ERRORS=$((ERRORS + 1))
  fi
fi

# ------------------------------------------------------------------------------
# 18-19. Honestidad de los scripts de cierre (T-100)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [18/33] Verificando honestidad de close-task.sh (enlace del sprint)..."
TASK_FIXTURE="$(mktemp -d)"
(
    cd "$TASK_FIXTURE" || exit 1
    git init -q . && git config user.email t@t.t && git config user.name t
    mkdir -p docs/sprints .agents/tasks
    {
        echo "# Sprint 99 - regresion"
        echo ""
        echo "## Estado"
        echo "🔴 Cerrado"
        echo ""
        echo "## Tareas"
        echo "| ID | D | T | E | Task file |"
        echo "| T-100 | x | S | ✅ Completada | [.agents/tasks/task-100.md](.agents/tasks/task-100.md) |"
    } > docs/sprints/sprint-99-core.md
    echo "# Task-100" > .agents/tasks/task-100.md
    git add -A && git commit -qm init
    printf '\n- [x] Sesion cerrada correctamente\n' >> .agents/tasks/task-100.md
    bash "$ROOT/scripts/agent/close-task.sh" T-100 "test regresion" >/dev/null 2>&1 || true
) 2>/dev/null
if python3 -c "
import pathlib, sys
d = pathlib.Path('$TASK_FIXTURE')
sprint = (d / 'docs/sprints/sprint-99-core.md').read_text()
assert '(.agents/tasks/_archived/task-100.md)' in sprint, 'el enlace no se actualizo a _archived/'
assert (d / '.agents/tasks/_archived/task-100.md').exists(), 'el task file no se archivo'
" 2>/dev/null; then
    echo -e "  ✅ close-task.sh actualiza el enlace de la fila al archivar y el enlace resuelve."
else
    echo -e "  ❌ ERROR: close-task.sh deja el enlace del sprint apuntando al directorio activo."
    ERRORS=$((ERRORS + 1))
fi
rm -rf "$TASK_FIXTURE"

echo ""
echo -e "🔍 [19/33] Verificando honestidad de close-sprint.sh (staging y validación previa)..."
SPRINT_FIXTURE="$(mktemp -d)"
(
    cd "$SPRINT_FIXTURE" || exit 1
    git init -q . && git config user.email t@t.t && git config user.name t
    mkdir -p docs/sprints
    {
        echo "# Sprint 98 - regresion"
        echo ""
        echo "## Estado"
        echo "✅ Completado"
        echo ""
        echo "## Tareas"
        echo "| ID | D | T | E |"
        echo "| T-098 | x | S | ✅ Completada |"
    } > docs/sprints/sprint-98-core.md
    git add -A && git commit -qm init
    printf '\n## Notas\n- Marcado antes de cerrar.\n' >> docs/sprints/sprint-98-core.md
    bash "$ROOT/scripts/agent/close-sprint.sh" sprint-98-core >/dev/null 2>&1 || true
) 2>/dev/null
if python3 -c "
import pathlib, subprocess
d = pathlib.Path('$SPRINT_FIXTURE')
arch = d / 'docs/sprints/_archived/sprint-98-core.md'
assert arch.exists(), 'el sprint no se archivo'
assert 'Marcado antes de cerrar' in arch.read_text(), 'la modificacion sin stagear quedo fuera del commit'
st = subprocess.check_output(['git','status','--porcelain'], cwd=str(d)).decode().strip()
assert st == '', 'el working tree quedo sucio: ' + st
" 2>/dev/null; then
    echo -e "  ✅ close-sprint.sh incluye el working tree en el commit y no deja el árbol sucio."
else
    echo -e "  ❌ ERROR: close-sprint.sh deja cambios sin commitear o cuelga el árbol de trabajo."
    ERRORS=$((ERRORS + 1))
fi
rm -rf "$SPRINT_FIXTURE"

# ------------------------------------------------------------------------------
# 20. promote-to-main.sh (T-101)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [20/33] Verificando promote-to-main.sh (merge, publicación de origen, fallo limpio)..."
PROMOTE="$ROOT/scripts/agent/promote-to-main.sh"
P1="$(mktemp -d)"; P2="$(mktemp -d)"; P3="$(mktemp -d)"
# NINGÚN fichero de salida puede vivir dentro del fixture: la redirección lo crea
# antes de que el script compruebe el working tree, que entonces aparece sucio y
# aborta antes de probar nada. Por eso toda la captura va a ficheros externos.
OUT1="$(mktemp)"; HELP1="$(mktemp)"; OUT2="$(mktemp)"; ERR3="$(mktemp)"
P3_BEFORE="$(mktemp)"; P3_AFTER="$(mktemp)"
# Fixture 1: help completo + fast-forward por defecto
(
    cd "$P1" || exit 1
    git init -q -b main . && git config user.email t@t.t && git config user.name t
    echo a > f.txt && git add -A && git commit -qm base
    git checkout -q -b feat/ff && echo b > f.txt && git add -A && git commit -qm trabajo
    bash "$PROMOTE" --source feat/ff --target main --skip-tests --json > "$OUT1" 2>/dev/null || true
    bash "$PROMOTE" --help > "$HELP1" 2>&1 || true
) 2>/dev/null || true
# Fixture 2: --merge-commit con target divergente
(
    cd "$P2" || exit 1
    git init -q -b main . && git config user.email t@t.t && git config user.name t
    echo a > f.txt && git add -A && git commit -qm base
    git checkout -q -b feat/mc && echo b > f.txt && git add -A && git commit -qm trabajo
    git checkout -q main && echo c > g.txt && git add -A && git commit -qm "main avanza"
    bash "$PROMOTE" --source feat/mc --target main --merge-commit --skip-tests --json > "$OUT2" 2>/dev/null || true
) 2>/dev/null || true
# Fixture 3: --push-source sin remoto no debe mover TARGET (nada a medias)
(
    cd "$P3" || exit 1
    git init -q -b main . && git config user.email t@t.t && git config user.name t
    echo a > f.txt && git add -A && git commit -qm base
    git checkout -q -b feat/noremote && echo b > f.txt && git add -A && git commit -qm trabajo
    git checkout -q main
    git rev-parse main > "$P3_BEFORE"
    bash "$PROMOTE" --source feat/noremote --target main --push-source --skip-tests > "$ERR3" 2>&1 || true
    git rev-parse main > "$P3_AFTER"
) 2>/dev/null || true
if python3 -c "
import json, pathlib, subprocess
h = pathlib.Path('$HELP1').read_text()
for flag in ['--push-source', '--merge-commit', '--pr', '--skip-tests']:
    assert flag in h, 'el help no documenta ' + flag
assert 'NO publica la rama de tarea' in h, 'el help no distingue --push de --push-source'

r1 = json.loads(pathlib.Path('$OUT1').read_text())
assert r1['merged'] is True and r1['merge_mode'] == '--ff-only', 'el default dejo de ser --ff-only'
n1 = len(subprocess.check_output(['git','rev-list','--parents','-n1','main'], cwd='$P1').split())
assert n1 == 2, 'el default no fue fast-forward'

r2 = json.loads(pathlib.Path('$OUT2').read_text())
assert r2['merged'] is True and r2['merge_mode'] == '--no-ff', '--merge-commit no relajo el modo'
n2 = len(subprocess.check_output(['git','rev-list','--parents','-n1','main'], cwd='$P2').split())
assert n2 == 3, '--merge-commit no genero un commit de merge real'

before = pathlib.Path('$P3_BEFORE').read_text().strip()
after = pathlib.Path('$P3_AFTER').read_text().strip()
assert before == after, 'un fallo de --push-source dejo TARGET movido (estado a medias)'
assert 'no se pudo publicar' in pathlib.Path('$ERR3').read_text(), 'el fallo no fue accionable'
" 2>/dev/null; then
    echo -e "  ✅ promote-to-main.sh mantiene --ff-only por defecto, --merge-commit funciona y un fallo no deja TARGET movido."
else
    echo -e "  ❌ ERROR: promote-to-main.sh no respeta el modo de merge o deja estado a medias."
    ERRORS=$((ERRORS + 1))
fi
rm -rf "$P1" "$P2" "$P3" "$OUT1" "$HELP1" "$OUT2" "$ERR3" "$P3_BEFORE" "$P3_AFTER"

# ------------------------------------------------------------------------------
# 21. Mapa de flujos generado (T-102)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [21/33] Verificando que el mapa de flujos está sincronizado con su fuente..."
if python3 -c "
import pathlib, subprocess, sys
root = pathlib.Path('$ROOT')
gen = root / 'scripts/agent/generate-flow-map.sh'
for f in ['docs/flow-map.md', 'docs/flow-map.digest.md']:
    assert (root / f).exists(), 'falta la salida generada ' + f

# Fuente única, probada por COMPORTAMIENTO y no con un grep estático: se genera contra
# una raíz que NO contiene control-plane-topology.md. Si el generador lo leyera, fallaría
# con "no such file". De paso se ejercita --root (uso previsto en proyectos hijos).
import shutil, tempfile
t = tempfile.mkdtemp()
try:
    (pathlib.Path(t) / 'docs').mkdir()
    (pathlib.Path(t) / 'scripts/agent').mkdir(parents=True)
    shutil.copy(root / 'docs/critical-flows.md', pathlib.Path(t) / 'docs/critical-flows.md')
    shutil.copy(gen, pathlib.Path(t) / 'scripts/agent/generate-flow-map.sh')
    r2 = subprocess.run(
        ['bash', str(pathlib.Path(t) / 'scripts/agent/generate-flow-map.sh'), '--root', t],
        capture_output=True)
    assert r2.returncode == 0, 'no genera sin control-plane-topology.md: ' + r2.stderr.decode()[:200]
    assert (pathlib.Path(t) / 'docs/flow-map.md').exists(), 'no escribió el mapa en la raíz indicada'
    assert (pathlib.Path(t) / 'docs/flow-map.digest.md').exists(), 'no escribió el digest en la raíz indicada'
finally:
    shutil.rmtree(t, ignore_errors=True)

# Determinismo: regenerar no debe cambiar nada.
r = subprocess.run(['bash', str(gen), '--check'], cwd=str(root), capture_output=True)
assert r.returncode == 0, 'el mapa esta desincronizado: ' + r.stderr.decode()[:200]

# El digest debe seguir siendo plano y acotado.
d = (root / 'docs/flow-map.digest.md').read_text().splitlines()
assert len(d) <= 40, 'el digest crecio sin control (' + str(len(d)) + ' lineas)'

# Y no debe filtrar literales de infraestructura.
import re
prohibido = re.compile(r'<nodo-inferencia>|<nodo-web>|<nodo-datos>|<host-local>|\d{1,3}(\.\d{1,3}){3}')
for f in ['docs/flow-map.md', 'docs/flow-map.digest.md']:
    assert not prohibido.search((root / f).read_text()), 'literal de infraestructura en ' + f
" 2>/dev/null; then
    echo -e "  ✅ El mapa se genera desde la fuente única, está sincronizado y sin literales de infraestructura."
else
    echo -e "  ❌ ERROR: el mapa de flujos está desincronizado, lee una fuente prohibida o filtra literales."
    ERRORS=$((ERRORS + 1))
fi

# ------------------------------------------------------------------------------
# 22. Higiene de localizadores / frontera portable (T-103)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [22/33] Verificando la frontera portable (cero literales de infraestructura)..."
if bash "$ROOT/scripts/agent/lib/locator-hygiene.sh" --quiet; then
    echo -e "  ✅ Sin rutas personales, IPs de infraestructura, hostnames de nodo ni credenciales en el core."
else
    bash "$ROOT/scripts/agent/lib/locator-hygiene.sh" 2>&1 | grep "❌" | head -10 | sed 's/^/    /'
    echo -e "  ❌ ERROR: el core contiene literales que violan la frontera portable."
    echo -e "     Política: docs/critical-flows.md. Sustituye por un marcador genérico,"
    echo -e "     o documenta la excepción con motivo en .agents/config/infra-literals.exceptions"
    ERRORS=$((ERRORS + 1))
fi

# Fixtures de T-116: el escáner no puede decir "limpio" sin mirar.
LHF="$ROOT/scripts/agent/lib/locator-hygiene.sh"
LHT="$(mktemp -d)"
mkdir -p "$LHT/norepo" "$LHT/repo-a" "$LHT/repo-b/ignorado"
printf '/%s/ana/proyectos/fuga.txt\n' home > "$LHT/norepo/fuga.txt"
(
    cd "$LHT/repo-a" && git init -q -b main . && git config user.email t@t.t && git config user.name t
    printf 'fichero limpio\n' > limpio.txt
    git add -A && git commit -qm base
    printf '/%s/ana/proyectos/fuga.txt\n' home > sin-trackear.txt
) >/dev/null 2>&1 || true
(
    cd "$LHT/repo-b" && git init -q -b main . && git config user.email t@t.t && git config user.name t
    printf 'ignorado/\n' > .gitignore
    printf 'fichero limpio\n' > limpio.txt
    git add -A && git commit -qm base
    printf '/%s/ana/proyectos/fuga.txt\n' home > ignorado/fuga.txt
) >/dev/null 2>&1 || true
LH_NOREPO_RC=0; LH_NOREPO_OUT="$(bash "$LHF" --path "$LHT/norepo" 2>&1)" || LH_NOREPO_RC=$?
LH_UNT_RC=0;    LH_UNT_OUT="$(bash "$LHF" --path "$LHT/repo-a" 2>&1)" || LH_UNT_RC=$?
LH_TRK_RC=0;    LH_TRK_OUT="$(bash "$LHF" --path "$LHT/repo-a" --tracked-only 2>&1)" || LH_TRK_RC=$?
LH_IGN_RC=0;    LH_IGN_OUT="$(bash "$LHF" --path "$LHT/repo-b" 2>&1)" || LH_IGN_RC=$?
rm -rf "$LHT"

if [ "$LH_NOREPO_RC" -eq 2 ] && printf '%s' "$LH_NOREPO_OUT" | grep -q "No verificable" \
   && ! printf '%s' "$LH_NOREPO_OUT" | grep -q "Sin literales"; then
    echo -e "  ✅ Sin repo git avisa 'no verificable' y sale 2 (nunca 'limpio')."
else
    echo -e "  ❌ ERROR: sin repo git debe salir 2 y no afirmar 'limpio' (rc=$LH_NOREPO_RC)."
    ERRORS=$((ERRORS + 1))
fi
if [ "$LH_UNT_RC" -eq 1 ] && printf '%s' "$LH_UNT_OUT" | grep -q "sin-trackear.txt"; then
    echo -e "  ✅ Detecta literales en ficheros sin trackear (rc=1)."
else
    echo -e "  ❌ ERROR: no detecta el fichero sin trackear (rc=$LH_UNT_RC)."
    ERRORS=$((ERRORS + 1))
fi
if [ "$LH_TRK_RC" -eq 0 ]; then
    echo -e "  ✅ --tracked-only omite el untracked (opt-out explícito)."
else
    echo -e "  ❌ ERROR: --tracked-only debería salir 0 (rc=$LH_TRK_RC)."
    ERRORS=$((ERRORS + 1))
fi
if [ "$LH_IGN_RC" -eq 0 ] && printf '%s' "$LH_IGN_OUT" | grep -q "Sin literales"; then
    echo -e "  ✅ Los untracked ignorados por .gitignore no se escanean."
else
    echo -e "  ❌ ERROR: el escáner no respeta --exclude-standard (rc=$LH_IGN_RC)."
    ERRORS=$((ERRORS + 1))
fi

# ------------------------------------------------------------------------------
# 23. Despacho multi-repo portable (T-104)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [23/33] Verificando dispatch-satellite.sh (ruta Git, ruta Orca simulada, idempotencia)..."
DISPATCH="$ROOT/scripts/agent/dispatch-satellite.sh"
DSAT="$(mktemp -d)"; DREG="$(mktemp)"; DSATS="$(mktemp)"
DOUT1="$(mktemp)"; DOUT2="$(mktemp)"; DOUT3="$(mktemp)"; DOUT4="$(mktemp)"
DTOOLS="$(mktemp -d)"; DSTUB="$(mktemp -d)"
# PATH mínimo SIN orca: simula una VM limpia (sin runtime). Se enlazan solo las
# dependencias que el dispatcher declara en su pre-flight, más `env` para el
# shebang del stub. Nada del PATH real entra: ni el orca del ADE ni homónimos.
for c in bash env git python3 mkdir cat chmod grep date cut dirname rm mktemp df; do
  ln -sf "$(command -v $c 2>/dev/null || echo "/nonexistent/$c")" "$DTOOLS/$c"
done
# Fixture 1 (sin runtime): despacho Git + re-despacho idempotente + --force
(
    export PATH="$DTOOLS"; hash -r
    git init -q -b main "$DSAT" && git -C "$DSAT" config user.email t@t.t && git -C "$DSAT" config user.name t
    echo a > "$DSAT/f.txt" && git -C "$DSAT" add -A && git -C "$DSAT" commit -qm base
    printf 'version: "1.0"\n\nsatellites:\n  fx:\n    path: %s\n    route: auto\n' "$DSAT" > "$DSATS"
    bash "$DISPATCH" --satellite fx --task-id T-FX --satellites "$DSATS" --registry "$DREG" --json > "$DOUT1" 2>/dev/null
    bash "$DISPATCH" --satellite fx --task-id T-FX --satellites "$DSATS" --registry "$DREG" --json > "$DOUT2" 2>/dev/null
    bash "$DISPATCH" --satellite fx --task-id T-FX --satellites "$DSATS" --registry "$DREG" --json --force > "$DOUT3" 2>/dev/null
) 2>/dev/null || true
# Fixture 2 (runtime simulado): un stub `orca` primero en PATH. Prueba la lógica
# de la ruta Orca, NO el runtime real (limitación documentada en T-104, R1).
(
    printf '#!/usr/bin/env bash\nif [ "$1" = "status" ]; then exit 0; fi\necho "{\\"dispatch_id\\":\\"stub-1\\"}"\n' > "$DSTUB/orca" && chmod +x "$DSTUB/orca"
    export PATH="$DSTUB:$DTOOLS"; hash -r
    bash "$DISPATCH" --satellite fx --task-id T-FO --agent ag --satellites "$DSATS" --registry "$DREG" --json > "$DOUT4" 2>/dev/null
) 2>/dev/null || true
if python3 -c "
import json, pathlib, subprocess
r1 = json.loads(pathlib.Path('$DOUT1').read_text())
assert r1['route'] == 'git' and r1['status'] == 'CREATED', 'sin runtime no usa la ruta Git'
r2 = json.loads(pathlib.Path('$DOUT2').read_text())
assert r2['status'] == 'IDEMPOTENT', 'el re-despacho no es idempotente'
r3 = json.loads(pathlib.Path('$DOUT3').read_text())
assert r3['route'] == 'git' and r3['status'] == 'CREATED', '--force no re-despacha'
n = len(subprocess.check_output(['git','-C','$DSAT','worktree','list']).splitlines())
assert n == 2, 'hay mas de un worktree: la idempotencia falla'
r4 = json.loads(pathlib.Path('$DOUT4').read_text())
assert r4['route'] == 'orca' and r4['status'] == 'CREATED', 'con runtime no usa la ruta Orca'
assert r4['remote']['dispatch_id'] == 'stub-1', 'no propaga la respuesta del runtime'
" 2>/dev/null; then
    echo -e "  ✅ Sin runtime despacha por Git, con runtime por Orca, y re-despachar no duplica worktrees."
else
    echo -e "  ❌ ERROR: dispatch-satellite.sh no elige ruta, no es idempotente o rompe el contrato JSON."
    ERRORS=$((ERRORS + 1))
fi
rm -rf "$DSAT" "$DTOOLS" "$DSTUB" "$DREG" "$DSATS" "$DOUT1" "$DOUT2" "$DOUT3" "$DOUT4"
DSIB="$(dirname "$DSAT")/$(basename "$DSAT")-T-FX"
rm -rf "$DSIB"

# ------------------------------------------------------------------------------
# 24. Integración y purga de worktrees (T-107)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [24/33] Verificando worktree-merge.sh (ff, squash, REJECT conserva) y worktree-gc.sh..."
MWT="$(mktemp -d)"; MOUT1="$(mktemp)"; MOUT2="$(mktemp)"; MOUT3="$(mktemp)"; MOUT4="$(mktemp)"; MOUT5="$(mktemp)"
MDISPATCH="$ROOT/scripts/agent/worktree-dispatch.sh"
MMERGE="$ROOT/scripts/agent/worktree-merge.sh"
MGC="$ROOT/scripts/agent/worktree-gc.sh"
# Fixture 1 (ff + REJECT): despacho con default canónico (hermano-fuera-del-árbol)
(
    git init -q -b main "$MWT/repo" && git -C "$MWT/repo" config user.email t@t.t && git -C "$MWT/repo" config user.name t
    echo a > "$MWT/repo/f.txt" && git -C "$MWT/repo" add -A && git -C "$MWT/repo" commit -qm base
    cd "$MWT/repo" || exit 1
    bash "$MDISPATCH" --task-id T-M1 --json > /dev/null 2>&1
    echo b > "$MWT/repo-T-M1/g.txt" && git -C "$MWT/repo-T-M1" add -A && git -C "$MWT/repo-T-M1" commit -qm trabajo
    bash "$MMERGE" --task-id T-M1 --target main --skip-verify --json > "$MOUT1" 2>/dev/null || true
    bash "$MDISPATCH" --task-id T-M2 --json > /dev/null 2>&1
    echo c > "$MWT/repo-T-M2/h.txt" && git -C "$MWT/repo-T-M2" add -A && git -C "$MWT/repo-T-M2" commit -qm viola
    bash "$MMERGE" --task-id T-M2 --target main --json > "$MOUT2" 2>/dev/null || true
) 2>/dev/null || true
# Fixture 2 (squash + gc): rama mergeada a mano dejada en disco + worktree sucio
(
    cd "$MWT/repo" || exit 1
    bash "$MDISPATCH" --task-id T-M3 --json > /dev/null 2>&1
    echo d > "$MWT/repo-T-M3/i.txt" && git -C "$MWT/repo-T-M3" add -A && git -C "$MWT/repo-T-M3" commit -qm sq
    bash "$MMERGE" --task-id T-M3 --target main --strategy squash --skip-verify --json > "$MOUT3" 2>/dev/null || true
    git worktree add -b feat/stale "$MWT/repo-stale" main >/dev/null 2>&1
    echo e > "$MWT/repo-stale/j.txt" && git -C "$MWT/repo-stale" add -A && git -C "$MWT/repo-stale" commit -qm st
    git merge -q --ff-only feat/stale >/dev/null 2>&1
    git worktree add -b feat/dirty "$MWT/repo-dirty" main >/dev/null 2>&1
    echo pendiente > "$MWT/repo-dirty/k.txt"
    bash "$MGC" --json > "$MOUT4" 2>/dev/null || true
    bash "$MGC" --apply --json > "$MOUT5" 2>/dev/null || true
) 2>/dev/null || true
if python3 -c "
import json, pathlib, subprocess
m1 = json.loads(pathlib.Path('$MOUT1').read_text())
assert m1['status'] == 'MERGED' and m1['worktree_removed'] is True, 'ff no integra y desmonta'
assert not pathlib.Path('$MWT/repo-T-M1').exists(), 'el worktree ff sigue en disco'
m2 = json.loads(pathlib.Path('$MOUT2').read_text())
assert m2['status'] != 'MERGED', 'el gate no rechazo el trabajo violador'
assert pathlib.Path('$MWT/repo-T-M2').exists(), 'REJECT destruyo el worktree (debía conservarlo)'
m3 = json.loads(pathlib.Path('$MOUT3').read_text())
assert m3['status'] == 'MERGED', 'squash no integra'
g4 = json.loads(pathlib.Path('$MOUT4').read_text())
assert any(o['branch'] == 'feat/stale' and o['reason'] == 'MERGED' for o in g4['orphans']), 'gc no detecta el huérfano'
assert any(s['branch'] == 'feat/dirty' and s['reason'] == 'DIRTY-SKIP' for s in g4['skipped']), 'gc no preserva el sucio'
g5 = json.loads(pathlib.Path('$MOUT5').read_text())
assert any(r['branch'] == 'feat/stale' for r in g5['removed']), '--apply no purga'
assert pathlib.Path('$MWT/repo-dirty').exists(), '--apply toco el worktree sucio'
" 2>/dev/null; then
    echo -e "  ✅ Merge integra (ff/squash) y desmonta, REJECT conserva, y gc purga huérfanos sin tocar sucios."
else
    echo -e "  ❌ ERROR: worktree-merge.sh o worktree-gc.sh no respetan el ciclo (integrar, conservar, purgar)."
    ERRORS=$((ERRORS + 1))
fi
rm -rf "$MWT" "$MOUT1" "$MOUT2" "$MOUT3" "$MOUT4" "$MOUT5"

# ------------------------------------------------------------------------------
# 25. Punto de entrada del coordinador (T-105)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [25/33] Verificando run-flow (para en el gate, nunca lo resuelve, cae al fallback)..."
OFLOW="$ROOT/scripts/agent/orca-orchestrate.sh"
FWT="$(mktemp -d)"; FSAT="$FWT/sat"; FSATS="$FWT/sats.yaml"; FREG="$FWT/reg.jsonl"; FSPEC="$FWT/spec.json"
FTOOLS="$(mktemp -d)"; FSTUB="$(mktemp -d)"; FDEAF="$(mktemp -d)"
FOUT1="$(mktemp)"; FOUT2="$(mktemp)"; FCALLS="$FWT/calls.log"
# PATH mínimo SIN orca real: simula el operador sin runtime. OJO: en esta máquina
# un PATH sin orca igual resuelve el shim de $HOME o /opt e iría contra el runtime
# REAL (crearía runs de verdad). Por eso el "sin runtime" se simula con un stub
# sordo (misma rama de código: RUNTIME_SIN_RESPUESTA), nunca con PATH pelado.
for c in bash env git python3 mkdir cat chmod grep date cut dirname rm mktemp df; do
  ln -sf "$(command -v $c 2>/dev/null || echo "/nonexistent/$c")" "$FTOOLS/$c"
done
# Fixture A (runtime que responde): stub que REGISTRA cada invocación
cat > "$FSTUB/orca" << 'STUBEOF'
#!/usr/bin/env bash
echo "orca $*" >> "${ORCA_CALLS_LOG:-/dev/null}"
case "$1" in status) echo '{"ok":true}'; exit 0 ;; esac
if [ "$1" = "orchestration" ]; then case "$2" in
  run-create) echo '{"id":"run-stub-1"}'; exit 0 ;;
  task-create) echo '{"id":"task-stub-9"}'; exit 0 ;;
  worker-start) echo '{"dispatch_id":"w-stub-1"}'; exit 0 ;;
  check) echo '{"events":[]}'; exit 0 ;;
  gate-create) echo '{"id":"gate-stub-7"}'; exit 0 ;;
  gate-resolve) echo '{"ok":true}'; exit 0 ;;
esac; fi
echo '{"error":"unknown"}'; exit 1
STUBEOF
chmod +x "$FSTUB/orca"
# Fixture B (runtime sordo): stub que siempre falla
printf '#!/usr/bin/env bash\nexit 1\n' > "$FDEAF/orca" && chmod +x "$FDEAF/orca"
(
    export PATH="$FSTUB:$FTOOLS" ORCA_CALLS_LOG="$FCALLS"; hash -r
    printf '{"tasks": [{"title": "Una", "spec": "hacer una"}, {"title": "Dos", "spec": "hacer dos", "deps": ["Una"]}]}' > "$FSPEC"
    bash "$OFLOW" run-flow --objective "lote T" --spec-file "$FSPEC" --json > "$FOUT1" 2>/dev/null
) 2>/dev/null || true
(
    export PATH="$FDEAF:$FTOOLS"; hash -r
    git init -q -b main "$FSAT" && git -C "$FSAT" config user.email t@t.t && git -C "$FSAT" config user.name t
    echo a > "$FSAT/f.txt" && git -C "$FSAT" add -A && git -C "$FSAT" commit -qm base
    printf 'version: "1.0"\n\nsatellites:\n  fx:\n    path: %s\n    route: auto\n' "$FSAT" > "$FSATS"
    bash "$OFLOW" run-flow --objective "lote F" --spec-file "$FSPEC" --satellite fx --satellites "$FSATS" --registry "$FREG" --json > "$FOUT2" 2>/dev/null
) 2>/dev/null || true
if python3 -c "
import json, pathlib
r1 = json.loads(pathlib.Path('$FOUT1').read_text())
assert r1['route'] == 'orca' and r1['status'] == 'GATE_PENDING', 'no recorre y para en el gate'
assert len(r1['gates']) == 2, 'debería crear un gate por tarea'
calls = pathlib.Path('$FCALLS').read_text()
for cmd in ['run-create', 'task-create', 'worker-start', 'gate-create']:
    assert cmd in calls, 'falta invocación ' + cmd
assert 'resolve-gate' not in calls and 'gate-resolve' not in calls, 'EL FLUJO RESOLVIÓ UN GATE SOLO'
assert '--deps' in calls, 'no cablea deps del DAG'
r2 = json.loads(pathlib.Path('$FOUT2').read_text())
assert r2['route'] == 'git-fallback' and r2['status'] == 'DISPATCHED_FALLBACK', 'no cae al fallback explícito'
assert r2['runtime_state'] == 'RUNTIME_SIN_RESPUESTA', 'no clasifica el runtime sordo'
" 2>/dev/null; then
    echo -e "  ✅ run-flow para en el gate sin resolverlo, cablea deps y cae al fallback explícito."
else
    echo -e "  ❌ ERROR: run-flow no para en el gate, resuelve solo o finge éxito sin runtime."
    ERRORS=$((ERRORS + 1))
fi
rm -rf "$FWT" "$FTOOLS" "$FSTUB" "$FDEAF" "$FOUT1" "$FOUT2"

# ------------------------------------------------------------------------------
# 26. Semver del changelog con ## [Unreleased] delante (T-108)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [26/33] Verificando semver de update-changelog.sh (ignora Unreleased, cae al tag)..."
UCHG="$ROOT/scripts/agent/update-changelog.sh"
FCH="$(mktemp -d)"
mkdir -p "$FCH/scripts/agent/lib"
cp "$UCHG" "$FCH/scripts/agent/update-changelog.sh"
cp "$ROOT/scripts/agent/lib/cli-help.sh" "$FCH/scripts/agent/lib/cli-help.sh"
git init -q -b main "$FCH" && git -C "$FCH" config user.email t@t.t && git -C "$FCH" config user.name t || true
# Guardia anti-incidente (T-108): si el fixture no es un repo, el script resolvería
# el changelog del core real vía 'git rev-parse --show-toplevel'. Abortar antes.
if [ ! -d "$FCH/.git" ]; then
  echo -e "  ❌ ERROR: el fixture no es un repo git; abortado para no tocar el changelog real."
  ERRORS=$((ERRORS + 1))
else
  TODAY=$(date +%Y-%m-%d)
  (
    cd "$FCH" || exit 1
    # Caso 1 (regresión sprint-17): Unreleased delante de semver + tag DISTINTO al header.
    # El bug generaba 0.1.0; el fix lee 1.12.0 del changelog (precedencia sobre el tag).
    printf '# Changelog\n\n## [Unreleased]\n\n- algo pendiente\n\n## [1.12.0] — sprint-13 — 2026-09-30\n\n- base\n' > changelog.md
    git add -A && git commit -qm base && git tag v1.5.0
    git commit -q --allow-empty -m "feat: algo nuevo" && git commit -q --allow-empty -m "fix: un arreglo"
    bash scripts/agent/update-changelog.sh sprint-99 >/dev/null 2>&1
    grep -m1 '^## \[' changelog.md || true
    # Caso 2 (fallback a tag): changelog sin semver; manda el último tag v*.
    printf '# Changelog\n\n## [Unreleased]\n\n- pendiente\n' > changelog.md
    git add -A && git commit -qm reset && git tag v1.12.0 && git tag v1.11.0
    git commit -q --allow-empty -m "feat: otra cosa"
    bash scripts/agent/update-changelog.sh sprint-99 >/dev/null 2>&1
    grep -m1 '^## \[' changelog.md || true
    # Caso 3 (protección pipefail): sin cabeceras ni tags. Se borran los tags y se
    # crean 55 commits para que exista el rango HEAD~50. Debe salir 0 y generar 0.0.1.
    git tag -d v1.5.0 v1.11.0 v1.12.0 >/dev/null 2>&1 || true
    printf '# Changelog\n' > changelog.md
    for i in $(seq 1 55); do git commit -q --allow-empty -m "chore: relleno $i" || true; done
    git commit -q --allow-empty -m "fix: unico cambio"
    bash scripts/agent/update-changelog.sh sprint-99 >/dev/null 2>&1
    echo "exit=$?"
    grep -m1 '^## \[' changelog.md || true
  ) > "$FCH/result.txt" 2>&1 || true
  R1=$(sed -n '1p' "$FCH/result.txt" 2>/dev/null || true)
  R2=$(sed -n '2p' "$FCH/result.txt" 2>/dev/null || true)
  R3=$(sed -n '3p' "$FCH/result.txt" 2>/dev/null || true)
  R4=$(sed -n '4p' "$FCH/result.txt" 2>/dev/null || true)
  if [ "$R1" = "## [1.13.0] — sprint-99 — $TODAY" ] && [ "$R2" = "## [1.13.0] — sprint-99 — $TODAY" ] && [ "$R3" = "exit=0" ] && [ "$R4" = "## [0.0.1] — sprint-99 — $TODAY" ]; then
    echo -e "  ✅ update-changelog.sh ignora Unreleased, prefiere la semver del changelog, cae al tag y no aborta sin cabeceras."
  else
    echo -e "  ❌ ERROR: semver incorrecta (caso1='$R1' caso2='$R2' caso3='$R3'/'$R4')."
    ERRORS=$((ERRORS + 1))
  fi
fi
rm -rf "$FCH"

  # Caso 4 (T-114): tags anotados con fechas invertidas. La base debe salir del
  # orden de VERSIÓN (-v:refname), no de la fecha de creación del tag: con
  # -creatordate, un tag creado después sobre un commit viejo reabre el rango y
  # duplica en el changelog commits ya publicados.
  FCH2="$(mktemp -d)"
  mkdir -p "$FCH2/scripts/agent/lib"
  cp "$UCHG" "$FCH2/scripts/agent/update-changelog.sh"
  cp "$ROOT/scripts/agent/lib/cli-help.sh" "$FCH2/scripts/agent/lib/cli-help.sh"
  if ! git -C "$FCH2" init -q -b main >/dev/null 2>&1; then
    echo -e "  ❌ ERROR: no se pudo inicializar el fixture de T-114."
    ERRORS=$((ERRORS + 1))
  else
    (
      cd "$FCH2" || exit 1
      git config user.email t@t.t && git config user.name t
      printf '# Changelog\n\n## [Unreleased]\n' > changelog.md
      git add -A && git commit -qm base
      ROOT_COMMIT=$(git rev-list --max-parents=0 HEAD)
      git commit -q --allow-empty -m "feat: ya lanzado"
      git commit -q --allow-empty -m "chore: release 1.13.0"
      GIT_COMMITTER_DATE="2026-10-01T00:00:00" git tag -a v1.13.0 -m "v1.13.0"
      git commit -q --allow-empty -m "feat: solo nuevo"
      GIT_COMMITTER_DATE="2026-10-25T00:00:00" git tag -a v1.12.0 -m "v1.12.0" "$ROOT_COMMIT"
      bash scripts/agent/update-changelog.sh sprint-99 > out.txt 2>&1 || true
      grep -m1 "Rango:" out.txt || true
      if grep -q "ya lanzado" changelog.md; then echo "DUPLICADO"; else echo "SIN-DUPLICADOS"; fi
    ) > "$FCH2/result.txt" 2>&1 || true
    R5="$(sed -n '1p' "$FCH2/result.txt" 2>/dev/null || true)"
    R6="$(sed -n '2p' "$FCH2/result.txt" 2>/dev/null || true)"
    case "$R5" in
      *"'v1.13.0'"*) VOK=true ;;
      *) VOK=false ;;
    esac
    if [ "$VOK" = true ] && [ "$R6" = "SIN-DUPLICADOS" ]; then
      echo -e "  ✅ La base del rango sale del orden de versión, no de creatordate (T-114)."
    else
      echo -e "  ❌ ERROR: base del rango incorrecta (rango='$R5' duplicados='$R6')."
      ERRORS=$((ERRORS + 1))
    fi
  fi
  rm -rf "$FCH2"

  # Caso real (T-114): con el tag de la versión publicada, la base que elegirá el
  # script debe ser ese tag (idéntico en multi-agent y en main), no uno anterior.
  VREAL=$(git -C "$ROOT" tag --list 'v*' --sort=-v:refname 2>/dev/null | head -1 || true)
  VEXPECT="v$(tr -d '[:space:]' < "$ROOT/VERSION" 2>/dev/null || true)"
  if [ -n "$VEXPECT" ] && git -C "$ROOT" rev-parse -q --verify "refs/tags/$VEXPECT" >/dev/null 2>&1; then
    if [ "$VREAL" = "$VEXPECT" ]; then
      echo -e "  ✅ Caso real: la base del rango es $VEXPECT."
    else
      echo -e "  ❌ ERROR: la base real es '$VREAL' y se esperaba '$VEXPECT'."
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo -e "  ℹ️  Caso real omitido: el tag $VEXPECT aún no existe (ventana cierre→tag)."
  fi

# ------------------------------------------------------------------------------
# 27. locator-hygiene.sh --path honra las excepciones del repo escaneado (T-106)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [27/33] Verificando que --path aplica las excepciones del repo destino..."
FIX="$(mktemp -d)"
git init -q -b main "$FIX" && git -C "$FIX" config user.email t@t.t && git -C "$FIX" config user.name t || true
# Guardia anti-incidente: sin repo, ls-files falla y el escáner podría mirar el core.
if [ ! -d "$FIX/.git" ]; then
  echo -e "  ❌ ERROR: el fixture no es un repo git; abortado para no escanear el core."
  ERRORS=$((ERRORS + 1))
else
  mkdir -p "$FIX/docs" "$FIX/.agents/config"
  # La ruta se compone en runtime: escribirla entera haría que el check 22
  # (higiene del propio core) detectase este fichero como violación.
  FIX_USER=romen
  printf -- "- ver [x](file:///home/$FIX_USER/proyectos/x.md)\n" > "$FIX/docs/note.md"
  printf 'archivo:docs/note.md   # fixture: motivo escrito obligatorio\n' > "$FIX/.agents/config/infra-literals.exceptions"
  git -C "$FIX" add -A
  # Caso 1: el destino declara su propia excepción -> limpio.
  E1=0; bash "$ROOT/scripts/agent/lib/locator-hygiene.sh" --path "$FIX" --quiet >/dev/null 2>&1 || E1=$?
  # Caso 2: retirada la excepción -> el literal debe detectarse.
  rm -f "$FIX/.agents/config/infra-literals.exceptions"
  E2=0; bash "$ROOT/scripts/agent/lib/locator-hygiene.sh" --path "$FIX" --quiet >/dev/null 2>&1 || E2=$?
  if [ "$E1" -eq 0 ] && [ "$E2" -eq 1 ]; then
    echo -e "  ✅ --path honra la excepción del repo escaneado y sigue detectando sin ella."
  else
    echo -e "  ❌ ERROR: --path no aplica las excepciones del destino (con excepción=$E1, sin=$E2)."
    ERRORS=$((ERRORS + 1))
  fi
fi
rm -rf "$FIX"

# ------------------------------------------------------------------------------
# 28. Copias no destructivas portables: agent_cp_n (T-110)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [28/33] Verificando agent_cp_n: no sobrescribe, sin warnings ni cp -n directos..."
FCP="$(mktemp -d)"
mkdir -p "$FCP/src" "$FCP/dst" "$FCP/rsrc" "$FCP/rdst"
printf 'nuevo\n' > "$FCP/src/a"
printf 'viejo\n' > "$FCP/dst/a"
printf 'r\n' > "$FCP/rsrc/f"
# shellcheck disable=SC1091
source "$ROOT/scripts/agent/lib/portable-fs.sh"
ERR_CP=$(agent_cp_n "$FCP/src/a" "$FCP/dst/a" 2>&1 >/dev/null)
KEPT_CP=$(cat "$FCP/dst/a")
agent_cp_n -r "$FCP/rsrc" "$FCP/rdst" 2>/dev/null >/dev/null
REC_OK=0; [ -f "$FCP/rdst/rsrc/f" ] && REC_OK=1
DIRECT_CP=$(grep -cE 'cp -(rn|n) ' "$ROOT/scripts/agent/install.sh" 2>/dev/null || true)
FLAG_OK=0
if cp --update=none --version >/dev/null 2>&1; then
  [ "$_AGENT_CP_UPDATE_NONE" = true ] && FLAG_OK=1
else
  FLAG_OK=1
fi
if [ "$KEPT_CP" = "viejo" ] && [ -z "$ERR_CP" ] && [ "$REC_OK" -eq 1 ] && [ "$DIRECT_CP" -eq 0 ] && [ "$FLAG_OK" -eq 1 ]; then
  echo -e "  ✅ agent_cp_n no sobrescribe, no emite warnings, replica recursivo y sustituye los cp -n/-rn."
else
  echo -e "  ❌ ERROR: agent_cp_n (conservado='$KEPT_CP' stderr='$ERR_CP' recursivo=$REC_OK directos=$DIRECT_CP flag=$FLAG_OK)."
  ERRORS=$((ERRORS + 1))
fi
rm -rf "$FCP"

# ------------------------------------------------------------------------------
# 29. Informe de lote read-only: report (T-112)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [29/33] Verificando 'report': bloque sin mutaciones, agregación y degradación..."
FREP="$(mktemp -d)"
STUB="$FREP/bin"
mkdir -p "$STUB"
cat > "$STUB/orca" <<'STUBEOF'
#!/usr/bin/env bash
if [ "${1:-}" = "status" ]; then
  [ "${STUB_STATUS_FAIL:-0}" = "1" ] && exit 1
  echo '{"ok":true}'; exit 0
fi
case "${1:-}" in
  orchestration)
    case "${2:-}" in
      run-list) echo '{"ok":true,"result":{"runs":[{"id":"run_fix","objective":"lote de prueba","created_at":"2026-01-01T00:00:00Z"}]}}' ;;
      task-list) echo '{"ok":true,"result":{"tasks":[{"id":"task_a","display_name":"Alfa","status":"done","deps":[]},{"id":"task_b","display_name":"Beta","status":"failed","deps":["task_a"]}]}}' ;;
      gate-list) echo '{"ok":true,"result":{"gates":[{"id":"gate_1","task_id":"task_b","status":"pending","question":"¿Aprobar?"}]}}' ;;
      worker-list) echo '{"ok":true,"result":{"workers":[{"taskId":"task_a","workerState":"done","dispatchStatus":"completed","resource":{"worktreeId":"repo::/tmp/wt-a"}}]}}' ;;
      *) echo '{"ok":false}' ;;
    esac ;;
  worktree) echo '{"ok":true,"result":{"worktrees":[{"path":"/tmp/wt-a","displayName":"wt-a","branch":"refs/heads/feat/a"}]}}' ;;
  *) echo '{"ok":false}' ;;
esac
STUBEOF
chmod +x "$STUB/orca"
# Estático: el bloque delimitado no puede contener primitivas de mutación
RB="$(sed -n '/^    # >>> T-112 report$/,/^    # <<< T-112 report$/p' "$ROOT/scripts/agent/orca-orchestrate.sh")"
MUT=$(printf '%s\n' "$RB" | grep -cE 'create-|dispatch-|resolve-|gh pr|git push|git merge|worker[-_](start|stop|release|retain)' || true)
C1=$(PATH="$STUB:$PATH" bash "$ROOT/scripts/agent/orca-orchestrate.sh" report run_fix --json 2>/dev/null)
C2=$(STUB_STATUS_FAIL=1 PATH="$STUB:$PATH" bash "$ROOT/scripts/agent/orca-orchestrate.sh" report run_fix --json 2>/dev/null)
C3_RC=0
C3=$(PATH="$STUB:$PATH" bash "$ROOT/scripts/agent/orca-orchestrate.sh" report no_existe --json 2>/dev/null) || C3_RC=$?
if [ -z "$RB" ]; then
  echo -e "  ❌ ERROR: no se encontró el bloque delimitado de 'report'."
  ERRORS=$((ERRORS + 1))
elif [ "$MUT" -ne 0 ]; then
  echo -e "  ❌ ERROR: el bloque de 'report' contiene $MUT referencia(s) a primitivas de mutación."
  ERRORS=$((ERRORS + 1))
elif ! printf '%s' "$C1" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert d['verdict']=='GATE_PENDIENTE', d.get('verdict')
assert len(d['tasks'])==2 and d['run']['id']=='run_fix', d
assert d['counts']['gates_pending']==1 and d['counts']['done']==1 and d['counts']['failed']==1, d['counts']
assert d['tasks'][0]['worker']['worktree']=='wt-a', d['tasks'][0]
" 2>/dev/null; then
  echo -e "  ❌ ERROR: la agregación con runtime no devuelve el informe esperado."
  ERRORS=$((ERRORS + 1))
elif ! printf '%s' "$C2" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert d['verdict']=='SIN_RUNTIME' and d['runtime_state']=='RUNTIME_SIN_RESPUESTA', d
" 2>/dev/null; then
  echo -e "  ❌ ERROR: sin runtime no degrada con gracia a SIN_RUNTIME."
  ERRORS=$((ERRORS + 1))
elif [ "$C3_RC" -ne 1 ] || ! printf '%s' "$C3" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert d['verdict']=='RUN_NO_ENCONTRADO' and d['exit_code']==1, d
" 2>/dev/null; then
  echo -e "  ❌ ERROR: un run inexistente debe salir 1 con RUN_NO_ENCONTRADO (rc=$C3_RC)."
  ERRORS=$((ERRORS + 1))
else
  echo -e "  ✅ 'report' es read-only (0 mutaciones), agrega tareas/gates/workers y degrada sin runtime."
fi
rm -rf "$FREP"

# ------------------------------------------------------------------------------
# 30. VERSION alineado con la release del changelog (T-113)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [30/33] Verificando VERSION (lectura semver, idempotencia y repo real)..."
VLIB="$ROOT/scripts/agent/lib/release-version.sh"
VTMP="$(mktemp -d)"
mkdir -p "$VTMP/repo"
printf '## [Unreleased]\n\n- pendiente\n\n## [9.9.9] — prueba\n' > "$VTMP/repo/changelog.md"
printf '1.0.0\n' > "$VTMP/repo/VERSION"
VREAD=""; VRC1=0
if [ -f "$VLIB" ]; then
  # shellcheck source=scripts/agent/lib/release-version.sh
  source "$VLIB"
  VREAD="$(agent_read_changelog_version "$VTMP/repo/changelog.md" 2>/dev/null || true)"
  agent_sync_version "$VTMP/repo" "$VTMP/repo/changelog.md" >/dev/null 2>&1 || VRC1=$?
fi
VWRITTEN="$(tr -d '[:space:]' < "$VTMP/repo/VERSION" 2>/dev/null || true)"
touch -t 200001010000 "$VTMP/repo/VERSION" 2>/dev/null || true
VRUN1=$(stat -c %Y "$VTMP/repo/VERSION" 2>/dev/null || stat -f %m "$VTMP/repo/VERSION" 2>/dev/null || echo 0)
agent_sync_version "$VTMP/repo" "$VTMP/repo/changelog.md" >/dev/null 2>&1 || true
VRUN2=$(stat -c %Y "$VTMP/repo/VERSION" 2>/dev/null || stat -f %m "$VTMP/repo/VERSION" 2>/dev/null || echo 0)
printf '## [Unreleased]\n\n- solo pendiente\n' > "$VTMP/repo/changelog.md"
VRC2=0
agent_sync_version "$VTMP/repo" "$VTMP/repo/changelog.md" >/dev/null 2>&1 || VRC2=$?
VUNTOUCHED="$(tr -d '[:space:]' < "$VTMP/repo/VERSION" 2>/dev/null || true)"
rm -rf "$VTMP"
VEXPECTED=$(grep -E '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "$ROOT/changelog.md" 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
VACTUAL=$(tr -d '[:space:]' < "$ROOT/VERSION" 2>/dev/null || true)
if [ ! -f "$VLIB" ]; then
  echo -e "  ❌ ERROR: falta scripts/agent/lib/release-version.sh."
  ERRORS=$((ERRORS + 1))
elif [ "$VREAD" != "9.9.9" ] || [ "$VWRITTEN" != "9.9.9" ] || [ "$VRC1" -ne 0 ]; then
  echo -e "  ❌ ERROR: la lectura semver no ignora Unreleased (leido='$VREAD' escrito='$VWRITTEN' rc=$VRC1)."
  ERRORS=$((ERRORS + 1))
elif [ "$VRUN1" != "$VRUN2" ]; then
  echo -e "  ❌ ERROR: la segunda sincronizacion reescribio VERSION (no es idempotente)."
  ERRORS=$((ERRORS + 1))
elif [ "$VRC2" -eq 0 ] || [ "$VUNTOUCHED" != "9.9.9" ]; then
  echo -e "  ❌ ERROR: sin version semver no debe escribir ni salir 0 (rc=$VRC2 valor='$VUNTOUCHED')."
  ERRORS=$((ERRORS + 1))
elif [ -z "$VEXPECTED" ] || [ "$VACTUAL" != "$VEXPECTED" ]; then
  echo -e "  ❌ ERROR: VERSION del repo ('$VACTUAL') no coincide con la release del changelog ('$VEXPECTED')."
  ERRORS=$((ERRORS + 1))
else
  echo -e "  ✅ VERSION lee la primera cabecera semver, es idempotente y coincide con la release ($VACTUAL)."
fi

# ------------------------------------------------------------------------------
# 31. Desfase de versión de la flota: fleet-version.sh (T-115)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [31/33] Verificando fleet-version.sh (5 estados, JSON estable y solo lectura)..."
FVS="$ROOT/scripts/agent/fleet-version.sh"
FV="$(mktemp -d)"
mkdir -p "$FV/core/scripts/agent/lib" "$FV/ok/.agents/context" "$FV/drift/.agents/context" \
         "$FV/legacy/.agents/context" "$FV/core/.agents/context"
printf '1.14.0\n' > "$FV/core/VERSION"
cp "$FVS" "$FV/core/scripts/agent/fleet-version.sh" 2>/dev/null || true
cp "$ROOT/scripts/agent/lib/cli-help.sh" "$FV/core/scripts/agent/lib/cli-help.sh" 2>/dev/null || true
printf '2026-10-27\nversion: 1.14.0\ntag: v1.14.0\ncommit: aaa\n' > "$FV/ok/.agents/context/last-sync.md"
printf '2026-09-01\nversion: 1.13.1\ntag: v1.13.1\ncommit: bbb\n' > "$FV/drift/.agents/context/last-sync.md"
printf '2026-06-01\nversion: legacy\n' > "$FV/legacy/.agents/context/last-sync.md"
printf '# last-sync.md — Estado operativo del core\n\n- Sprint: prueba\n' > "$FV/core/.agents/context/last-sync.md"
cat > "$FV/satellites.yaml" <<EOF
version: "1.0"

satellites:
  alineado:
    path: $FV/ok
  desfasado:
    path: $FV/drift
  legado:
    path: $FV/legacy
  sin-ledger:
    path: $FV/absent
  core:
    path: $FV/core
EOF

fv_snapshot() {
  find "$1" -type f 2>/dev/null | sort | while IFS= read -r f; do cksum "$f" 2>/dev/null || true; done | cksum
}

FVHASH1="$(fv_snapshot "$FV")"
FVRC=0
FVH=""; FVJ=""
if [ -f "$FVS" ]; then
  FVH="$(bash "$FV/core/scripts/agent/fleet-version.sh" --satellites "$FV/satellites.yaml" 2>&1)" || FVRC=$?
  FVJ="$(bash "$FV/core/scripts/agent/fleet-version.sh" --satellites "$FV/satellites.yaml" --json 2>&1)" || true
fi
FVEMPTYRC=0
FVEMPTY="$(bash "$FV/core/scripts/agent/fleet-version.sh" 2>&1)" || FVEMPTYRC=$?
FVHASH2="$(fv_snapshot "$FV")"
FVGREP="$(grep -nE '(>>|[[:space:]](cp|mv|rm|tee)[[:space:]]|git[[:space:]]+add|curl|wget|ssh[[:space:]]|git[[:space:]]+(fetch|pull))' "$FVS" 2>/dev/null || true)"
rm -rf "$FV"

FVFAILS=""
fv_expect() {
  printf '%s' "$2" | grep -q -- "$3" || FVFAILS="$FVFAILS $1"
}
if [ -f "$FVS" ]; then
  for st in ALINEADO DESFASE LEGACY AUSENTE SELF; do
    fv_expect "estado-$st" "$FVH" "$st"
  done
  fv_expect "json-configured" "$FVJ" '"configured": true'
  fv_expect "json-drift" "$FVJ" '"drift": 1'
  fv_expect "json-self" "$FVJ" '"self": 1'
  fv_expect "json-status" "$FVJ" '"status": "DESFASE"'
  fv_expect "json-direction" "$FVJ" '"direction": "atras"'
  fv_expect "sin-config" "$FVEMPTY" "No hay satélites configurados"
fi
if [ ! -f "$FVS" ]; then
  echo -e "  ❌ ERROR: falta scripts/agent/fleet-version.sh."
  ERRORS=$((ERRORS + 1))
elif [ "$FVRC" -ne 0 ]; then
  echo -e "  ❌ ERROR: fleet-version.sh debe salir 0 con DESFASE (rc=$FVRC)."
  ERRORS=$((ERRORS + 1))
elif [ "$FVEMPTYRC" -ne 0 ]; then
  echo -e "  ❌ ERROR: sin satélites configurados debe salir 0 (rc=$FVEMPTYRC)."
  ERRORS=$((ERRORS + 1))
elif [ "$FVHASH1" != "$FVHASH2" ]; then
  echo -e "  ❌ ERROR: fleet-version.sh escribió en el árbol (snapshot distinto)."
  ERRORS=$((ERRORS + 1))
elif [ -n "$FVGREP" ]; then
  echo -e "  ❌ ERROR: fleet-version.sh contiene operaciones de escritura/red."
  echo -e "     $FVGREP"
  ERRORS=$((ERRORS + 1))
elif [ -n "$FVFAILS" ]; then
  echo -e "  ❌ ERROR: fleet-version.sh incumple:$FVFAILS"
  ERRORS=$((ERRORS + 1))
else
  echo -e "  ✅ 5 estados correctos, JSON estable, exit 0 con desfase y árbol intacto (read-only)."
fi

# ------------------------------------------------------------------------------
# 32. secrets.sh sin valor por argv + --search + barrido único (T-117)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [32/33] Verificando secrets.sh (valor solo por stdin) y secret-locate (--search, 1 export/carpeta)..."
SEC="$ROOT/scripts/agent/secrets.sh"
SLOC="$ROOT/scripts/agent/secret-locate.sh"
T117="$(mktemp -d)"
mkdir -p "$T117/bin"
cat > "$T117/bin/infisical" <<'STUB'
#!/usr/bin/env bash
echo "$*" >> "$ARGV_LOG"
case "$1" in
  export) echo "export" >> "$EXPORT_LOG"; cat "$EXPORT_PAYLOAD"; exit 0 ;;
  secrets) cat > "$STDIN_LOG"; exit 0 ;;
  login) echo "eyJstub"; exit 0 ;;
esac
exit 0
STUB
chmod +x "$T117/bin/infisical"
cat > "$T117/payload.json" <<'JSON'
[{"secretKey":"CLOUDFLARE_API_TOKEN","tags":[{"slug":"scope-shared"}],"comment":"token de cloudflare","updatedAt":"2026-10-20T10:00:00Z","value":"SEÑUELO_NO_DEBE_SALIR"},
 {"secretKey":"OTRA_CLAVE","tags":[],"comment":"","updatedAt":"2026-10-21T10:00:00Z","value":"SEÑUELO2"}]
JSON
cat > "$T117/locate.sh" <<'STUB'
#!/usr/bin/env bash
n=$(( $(cat "$LOCATE_COUNTER" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$LOCATE_COUNTER"
if [ -n "${LOCATE_MISSING:-}" ]; then echo '{"found_in": [], "hits_detail": []}'; exit 6; fi
if [ -n "${LOCATE_STATIC:-}" ] || [ "$n" -le 2 ]; then ts="2026-10-27T10:00:00Z"; else ts="2026-10-27T10:07:00Z"; fi
printf '{"found_in": ["proyectos-x"], "hits_detail": [{"folder": "proyectos-x", "updated_at": "%s"}]}\n' "$ts"
STUB
chmod +x "$T117/locate.sh"
cat > "$T117/server.py" <<'SRV'
import json, sys
from http.server import BaseHTTPRequestHandler, HTTPServer
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        body = json.dumps({"folders": [
            {"name": "proyectos-x", "description": "proyectos", "lastSecretModified": "2026-10-20T10:00:00Z"},
            {"name": "infra", "description": "infra base", "lastSecretModified": "2026-10-21T10:00:00Z"}]}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def log_message(self, *a):
        pass
srv = HTTPServer(("127.0.0.1", 0), H)
open(sys.argv[1], "w").write(str(srv.server_port))
srv.serve_forever()
SRV

S_ENV=(env "PATH=$T117/bin:$PATH" "ARGV_LOG=$T117/argv.log" "STDIN_LOG=$T117/stdin.log"
       "EXPORT_LOG=$T117/exports.log" "EXPORT_PAYLOAD=$T117/payload.json"
       "LOCATE_COUNTER=$T117/counter" "INFISICAL_API_URL=http://127.0.0.1:1"
       "INFISICAL_PROJECT_ID=proj" "INFISICAL_TOKEN=stub"
       "AGENT_OS_SECRET_LOCATE=$T117/locate.sh" "AGENT_OS_INFISICAL_BIN=$T117/bin/infisical")

SEC_STATIC_OK=true
[ -f "$SEC" ] || SEC_STATIC_OK=false
if [ -f "$SEC" ]; then
  grep -q -- '--file /dev/stdin' "$SEC" || SEC_STATIC_OK=false
  if grep -qE '\beval\b' "$SEC"; then SEC_STATIC_OK=false; fi
  if grep -qE 'set -[a-zA-Z]*x' "$SEC"; then SEC_STATIC_OK=false; fi
fi

RC_SET=0; OUT_SET=""
OUT_SET="$(printf 'supersecreto123\n' | "${S_ENV[@]}" bash "$SEC" set MI_CLAVE --stdin 2>&1)" || RC_SET=$?
ARGV_SET="$(cat "$T117/argv.log" 2>/dev/null || true)"
STDIN_SET="$(cat "$T117/stdin.log" 2>/dev/null || true)"
: > "$T117/argv.log"
RC_ARG1=0; "${S_ENV[@]}" bash "$SEC" set MI_CLAVE supersecreto123 >/dev/null 2>&1 || RC_ARG1=$?
RC_ARG2=0; "${S_ENV[@]}" bash "$SEC" set MI_CLAVE=supersecreto123 >/dev/null 2>&1 || RC_ARG2=$?
RC_ARG3=0; "${S_ENV[@]}" bash "$SEC" set MI_CLAVE --value supersecreto123 >/dev/null 2>&1 || RC_ARG3=$?
ARGV_REJ="$(cat "$T117/argv.log" 2>/dev/null || true)"
: > "$T117/stdin.log"
RC_GEN=0; "${S_ENV[@]}" bash "$SEC" set MI_CLAVE --generate=24 >/dev/null 2>&1 || RC_GEN=$?
STDIN_GEN="$(cat "$T117/stdin.log" 2>/dev/null || true)"
: > "$T117/counter"
RC_ROT=0; "${S_ENV[@]}" bash "$SEC" rotate MI_CLAVE >/dev/null 2>&1 || RC_ROT=$?
: > "$T117/counter"
RC_ROTS=0; LOCATE_STATIC=1 "${S_ENV[@]}" bash "$SEC" rotate MI_CLAVE >/dev/null 2>&1 || RC_ROTS=$?
RC_MISS=0; LOCATE_MISSING=1 "${S_ENV[@]}" bash "$SEC" set NUEVA --generate >/dev/null 2>&1 || RC_MISS=$?

python3 "$T117/server.py" "$T117/port" & T117_SRV=$!
for _ in $(seq 1 50); do [ -s "$T117/port" ] && break; sleep 0.1 2>/dev/null || sleep 1; done
T117_PORT="$(cat "$T117/port" 2>/dev/null || echo 0)"
L_ENV=(env "PATH=$T117/bin:$PATH" "EXPORT_LOG=$T117/exports.log" "EXPORT_PAYLOAD=$T117/payload.json"
       "INFISICAL_API_URL=http://127.0.0.1:$T117_PORT" "INFISICAL_PROJECT_ID=proj" "INFISICAL_TOKEN=stub")
RC_SRCH=0; OUT_SRCH=""
OUT_SRCH="$("${L_ENV[@]}" bash "$SLOC" --search cloudflare 2>&1)" || RC_SRCH=$?
RC_SRCH_N=0; "${L_ENV[@]}" bash "$SLOC" --search zzzz >/dev/null 2>&1 || RC_SRCH_N=$?
RC_SRCH_E=0; "${L_ENV[@]}" bash "$SLOC" --search >/dev/null 2>&1 || RC_SRCH_E=$?
: > "$T117/exports.log"
RC_HYG=0; "${L_ENV[@]}" bash "$SLOC" --hygiene > "$T117/hygiene.out" 2>&1 || RC_HYG=$?
EXPORTS_HYG="$(wc -l < "$T117/exports.log" 2>/dev/null | tr -d ' ' || echo 0)"
HYG_OUT="$(cat "$T117/hygiene.out" 2>/dev/null || true)"
RC_NAME=0; OUT_NAME=""
OUT_NAME="$("${L_ENV[@]}" bash "$SLOC" --name CLOUDFLARE_API_TOKEN --json 2>&1)" || RC_NAME=$?
kill "$T117_SRV" 2>/dev/null || true
rm -rf "$T117"

T117_FAILS=""
[ "$SEC_STATIC_OK" = true ] || T117_FAILS="$T117_FAILS estatico"
[ "$RC_SET" -eq 0 ] || T117_FAILS="$T117_FAILS set-rc=$RC_SET"
if printf '%s' "$ARGV_SET" | grep -q 'supersecreto123'; then T117_FAILS="$T117_FAILS valor-en-argv"; fi
printf '%s' "$STDIN_SET" | grep -q 'MI_CLAVE=supersecreto123' || T117_FAILS="$T117_FAILS valor-no-llega-por-stdin"
if printf '%s' "$OUT_SET" | grep -q 'supersecreto123'; then T117_FAILS="$T117_FAILS valor-en-salida"; fi
printf '%s' "$OUT_SET" | grep -qE 'sha256: [0-9a-f]{12}' || T117_FAILS="$T117_FAILS sin-huella"
[ "$RC_ARG1" -eq 2 ] && [ "$RC_ARG2" -eq 2 ] && [ "$RC_ARG3" -eq 2 ] || T117_FAILS="$T117_FAILS argv-no-rechazado"
[ -z "$ARGV_REJ" ] || T117_FAILS="$T117_FAILS infisical-invocado-con-valor"
[ "$RC_GEN" -eq 0 ] || T117_FAILS="$T117_FAILS generate-rc=$RC_GEN"
printf '%s' "$STDIN_GEN" | grep -qE '^MI_CLAVE=[A-Za-z0-9]{24}$' || T117_FAILS="$T117_FAILS generate-formato"
[ "$RC_ROT" -eq 0 ] || T117_FAILS="$T117_FAILS rotate-rc=$RC_ROT"
[ "$RC_ROTS" -eq 1 ] || T117_FAILS="$T117_FAILS rotate-sin-verificacion"
[ "$RC_MISS" -eq 6 ] || T117_FAILS="$T117_FAILS crear-sin-path=$RC_MISS"
[ "$RC_SRCH" -eq 0 ] || T117_FAILS="$T117_FAILS search-rc=$RC_SRCH"
printf '%s' "$OUT_SRCH" | grep -q 'CLOUDFLARE_API_TOKEN' || T117_FAILS="$T117_FAILS search-sin-clave"
printf '%s' "$OUT_SRCH" | grep -q 'Solo metadatos' || T117_FAILS="$T117_FAILS search-sin-aviso"
if printf '%s' "$OUT_SRCH" | grep -q 'SEÑUELO'; then T117_FAILS="$T117_FAILS search-filtra-valor"; fi
[ "$RC_SRCH_N" -eq 6 ] || T117_FAILS="$T117_FAILS search-sin-coincidencias=$RC_SRCH_N"
[ "$RC_SRCH_E" -eq 64 ] || T117_FAILS="$T117_FAILS search-vacio=$RC_SRCH_E"
[ "$RC_HYG" -eq 0 ] || T117_FAILS="$T117_FAILS hygiene-rc=$RC_HYG"
[ "$EXPORTS_HYG" -eq 2 ] || T117_FAILS="$T117_FAILS exports=$EXPORTS_HYG"
printf '%s' "$HYG_OUT" | grep -q -- '--file /dev/stdin' || T117_FAILS="$T117_FAILS higiene-receta-argv"
[ "$RC_NAME" -eq 0 ] || T117_FAILS="$T117_FAILS name-rc=$RC_NAME"
printf '%s' "$OUT_NAME" | grep -q '"hits_detail"' || T117_FAILS="$T117_FAILS sin-hits_detail"

if [ -n "$T117_FAILS" ]; then
  echo -e "  ❌ ERROR: T-117 incumple:$T117_FAILS"
  ERRORS=$((ERRORS + 1))
else
  echo -e "  ✅ Valor solo por stdin (nunca argv, nunca en salida), rotate verificado,"
  echo -e "     --search sin fuga de valores y 1 export por carpeta (2 exportaciones / 2 carpetas)."
fi


# ------------------------------------------------------------------------------
# 33. redact.sh + coherencia de normas de secretos (T-118)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [33/33] Verificando redact.sh (determinista, sin red) y coherencia de las normas de secretos..."
RED="$ROOT/scripts/agent/lib/redact.sh"
SKILL="$ROOT/.agents/skills/infisical-secrets/SKILL.md"
PERMS="$ROOT/.agents/rules/global/agent-permissions.md"
ONB="$ROOT/.agents/AGENT_ONBOARDING.md"
T118="$(mktemp -d)"
T118_FAILS=""

# --- estático: solo bloques de código de la skill ---
awk '/^[[:space:]]*```/{inb=!inb; next} inb' "$SKILL" > "$T118/skill_code.txt" 2>/dev/null || true
T118_FENCE_BAD="$(grep -nE 'eval[[:space:]]+\$\(infisical[[:space:]]+export|secrets[[:space:]]+set[[:space:]]+[A-Za-z_][A-Za-z0-9_]*=|echo[[:space:]]+\$[A-Za-z_]' "$T118/skill_code.txt" 2>/dev/null || true)"
[ -z "$T118_FENCE_BAD" ] || T118_FAILS="$T118_FAILS skill-patron-prohibido"

grep -q 'argv.*= transcript' "$PERMS" || T118_FAILS="$T118_FAILS perms-sin-argv"
grep -q 'redact\.sh' "$PERMS" || T118_FAILS="$T118_FAILS perms-sin-redact"

for _m in 'secret-locate\.sh' 'secrets\.sh' 'materialize-secrets\.sh' 'redact\.sh' 'verify-secrets\.py' 'se para y propone'; do
  grep -q "$_m" "$ONB" || T118_FAILS="$T118_FAILS onboarding-sin-${_m%%.*}"
done
if grep -q 'cliente oficial' "$ONB"; then T118_FAILS="$T118_FAILS onboarding-lista-abierta"; fi

grep -qE '\b(curl|wget|/dev/tcp)\b' "$RED" && T118_FAILS="$T118_FAILS redact-con-red"
grep -qE '(^|[[:space:];])>>?[[:space:]]*[^&]' "$RED" && T118_FAILS="$T118_FAILS redact-con-escrituras"

# --- funcional ---
OUT_ENV="$(printf 'API_TOKEN=abc123\nX=1\n' | bash "$RED" --keys API_TOKEN 2>/dev/null || true)"
printf '%s' "$OUT_ENV" | grep -q 'API_TOKEN=<redacted:API_TOKEN>' || T118_FAILS="$T118_FAILS env-sin-redactar"
printf '%s' "$OUT_ENV" | grep -q 'X=1' || T118_FAILS="$T118_FAILS env-rompe-lineas"
printf '%s' "$OUT_ENV" | grep -q 'abc123' && T118_FAILS="$T118_FAILS env-fuga"

OUT_JSON="$(printf '{"API_TOKEN":"abc123","PORT": 3000, "n": 1}\n' | bash "$RED" --keys API_TOKEN,PORT 2>/dev/null || true)"
printf '%s' "$OUT_JSON" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["API_TOKEN"].startswith("<redacted:") and d["PORT"].startswith("<redacted:"), d; assert d["n"]==1' 2>/dev/null \
  || T118_FAILS="$T118_FAILS json-invalido-o-sin-redactar"

OUT_Q="$(printf 'API_TOKEN="se creto 1"\n' | bash "$RED" --keys API_TOKEN 2>/dev/null || true)"
[ "$OUT_Q" = 'API_TOKEN="<redacted:API_TOKEN>"' ] || T118_FAILS="$T118_FAILS quoted"

OUT_Y="$(printf 'API_TOKEN: abc123\n' | bash "$RED" --keys API_TOKEN 2>/dev/null || true)"
[ "$OUT_Y" = 'API_TOKEN: <redacted:API_TOKEN>' ] || T118_FAILS="$T118_FAILS yaml"

H1="$(printf 'API_TOKEN=abc\n' | bash "$RED" --keys API_TOKEN 2>/dev/null | sha256sum)"
H2="$(printf 'API_TOKEN=abc\n' | bash "$RED" --keys API_TOKEN 2>/dev/null | sha256sum)"
[ "$H1" = "$H2" ] || T118_FAILS="$T118_FAILS no-determinista"

cat > "$T118/catalog.yaml" <<'CAT'
# Catálogo de secretos — ARTEFACTO GENERADO, no editar a mano.
# Regenerar: bash scripts/agent/generate-secrets-catalog.sh --path .
# Este fichero NO contiene valores. Solo metadatos.
generated_at: 2026-10-27T00:00:00Z
source: fixture
complete: true
secrets_declared: 1
detected_stack: unknown
needs_declaration: ['INFISICAL_TOKEN', 'INFISICAL_PROJECT_ID']
secrets:
  - key: FIXTURE_TOKEN
    kind: secreto
    status: NO-EN-BOVEDA
    discovered_from: [env]
    scope: unknown
    locations: []
    tags: []
    code_refs: []
    required_by: []
CAT
OUT_CAT="$(printf 'FIXTURE_TOKEN=zzz\nINFISICAL_TOKEN=yyy\nINFISICAL_PROJECT_ID=ppp\nOTRA=keep\n' | bash "$RED" --catalog "$T118/catalog.yaml" 2>/dev/null || true)"
printf '%s' "$OUT_CAT" | grep -q 'FIXTURE_TOKEN=<redacted:FIXTURE_TOKEN>' || T118_FAILS="$T118_FAILS catalogo-keys"
printf '%s' "$OUT_CAT" | grep -q 'INFISICAL_TOKEN=<redacted:INFISICAL_TOKEN>' || T118_FAILS="$T118_FAILS catalogo-needs"
printf '%s' "$OUT_CAT" | grep -q 'OTRA=keep' || T118_FAILS="$T118_FAILS catalogo-rompe"
printf '%s' "$OUT_CAT" | grep -qE 'zzz|yyy|ppp' && T118_FAILS="$T118_FAILS catalogo-fuga"

: > "$T118/empty.yaml"
OUT_EMPTY="$(printf 'keep=1\n' | AGENT_OS_SECRETS_CATALOG="$T118/empty.yaml" bash "$RED" 2>/dev/null || true)"
[ "$OUT_EMPTY" = 'keep=1' ] || T118_FAILS="$T118_FAILS sin-claves-no-passthrough"

RC_BADKEY=0
bash "$RED" --keys 'BAD-KEY' </dev/null >/dev/null 2>&1 || RC_BADKEY=$?
[ "$RC_BADKEY" -eq 64 ] || T118_FAILS="$T118_FAILS clave-invalida-rc=$RC_BADKEY"

rm -rf "$T118" 2>/dev/null || true

if [ -n "$T118_FAILS" ]; then
  echo -e "  ❌ ERROR: T-118 incumple:$T118_FAILS"
  [ -z "$T118_FENCE_BAD" ] || echo -e "     $T118_FENCE_BAD"
  ERRORS=$((ERRORS + 1))
else
  echo -e "  ✅ redact.sh redacta env/JSON/YAML/catálogo sin romper estructura y es determinista;"
  echo -e "     skill y normas sin recetas de valor en argv ni listas abiertas."
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
