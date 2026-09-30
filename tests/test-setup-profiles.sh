#!/usr/bin/env bash
# ==============================================================================
# tests/test-setup-profiles.sh — Suite de pruebas de setup-profiles (T-089)
# ==============================================================================
# Valida:
#   1. Inspección estática y presencia en assets-manifest.txt.
#   2. Modo --check (dry-run): cero modificaciones en disco.
#   3. Matriz de adaptación automática por marcadores en disco:
#      - TypeScript (package.json + tsconfig.json)
#      - Python (pyproject.toml)
#      - Rust (Cargo.toml)
#      - Go (go.mod)
#   4. Override explícito vía --stack <override> (mecanismo reparado en Fase 0).
#   5. Idempotencia absoluta con --apply: re-ejecución sin duplicar bloques.
#   6. Conformidad estricta del perfil generado con el esquema de validate-control-plane.
#   7. Enriquecimiento de comandos en AGENT_ONBOARDING.md.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
TESTS_RUN=0

log_pass() {
  echo -e "  ${GREEN}✅ PASS:${NC} $1"
  TESTS_RUN=$((TESTS_RUN + 1))
}

log_fail() {
  echo -e "  ${RED}❌ FAIL:${NC} $1"
  ERRORS=$((ERRORS + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}  SUITE DE PRUEBAS: SETUP-PROFILES SEGÚN STACK (T-089)  ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""

SETUP_SCRIPT="$ROOT_DIR/scripts/agent/setup-profiles.sh"

# ------------------------------------------------------------------------------
# 1. Inspección Estática y Manifiesto de Assets
# ------------------------------------------------------------------------------
echo -e "🔍 [1/6] Verificando contrato estático y registro en manifiesto..."

if [ -f "$SETUP_SCRIPT" ] && [ -x "$SETUP_SCRIPT" ]; then
  log_pass "scripts/agent/setup-profiles.sh existe y cuenta con permisos de ejecución (+x)."
else
  log_fail "scripts/agent/setup-profiles.sh falta o no es ejecutable."
fi

if grep -q "scripts/agent/setup-profiles.sh" "$ROOT_DIR/scripts/agent/assets-manifest.txt"; then
  log_pass "scripts/agent/setup-profiles.sh registrado en assets-manifest.txt."
else
  log_fail "scripts/agent/setup-profiles.sh no figura en assets-manifest.txt."
fi

# ------------------------------------------------------------------------------
# 2. Modo --check (Dry-run / Simulación)
# ------------------------------------------------------------------------------
echo -e "🔍 [2/6] Verificando modo --check (cero escrituras en disco)..."

CHECK_TARGET="$TMP_DIR/check_target"
mkdir -p "$CHECK_TARGET"
touch "$CHECK_TARGET/pyproject.toml"

OUT_CHECK=$(bash "$SETUP_SCRIPT" --check --path "$CHECK_TARGET" 2>&1)
EXIT_CHECK=$?

if [ "$EXIT_CHECK" -eq 0 ] && [ ! -d "$CHECK_TARGET/.agents" ]; then
  log_pass "--check retorna exit 0 y no crea carpetas ni escribe archivos en disco."
else
  log_fail "--check falló o modificó disco inesperadamente. Status: $EXIT_CHECK"
fi

# ------------------------------------------------------------------------------
# 3. Matriz de Adaptación por Marcadores (TypeScript, Python, Rust, Go)
# ------------------------------------------------------------------------------
echo -e "🔍 [3/6] Verificando matriz de stacks soportados (TS, Python, Rust, Go)..."

test_stack_adaptation() {
  local stack_name="$1"
  local marker_file="$2"
  local expected_cmd="$3"
  local target="$TMP_DIR/matrix_$stack_name"
  mkdir -p "$target"
  touch "$target/$marker_file"

  # Copiar base de developer.yaml del core si existe
  mkdir -p "$target/.agents/profiles"
  cp "$ROOT_DIR/.agents/profiles/developer.yaml" "$target/.agents/profiles/developer.yaml"

  bash "$SETUP_SCRIPT" --apply --path "$target" >/dev/null 2>&1

  local dev_yaml="$target/.agents/profiles/developer.yaml"
  if [ -f "$dev_yaml" ] && \
     grep -q "stack: \"$stack_name\"" "$dev_yaml" && \
     grep -q "$expected_cmd" "$dev_yaml" && \
     grep -q "# BEGIN AGENT-OS-GENERATED-STACK" "$dev_yaml" && \
     grep -q "# END AGENT-OS-GENERATED-STACK" "$dev_yaml"; then
    log_pass "Stack '$stack_name': adaptado correctamente con marcadores canónicos y comando '$expected_cmd'."
  else
    log_fail "Stack '$stack_name': adaptación falló o faltan marcadores en $dev_yaml."
  fi
}

test_stack_adaptation "typescript" "tsconfig.json" "test"
test_stack_adaptation "python" "pyproject.toml" "pytest"
test_stack_adaptation "rust" "Cargo.toml" "cargo test"
test_stack_adaptation "go" "go.mod" "go test"

# ------------------------------------------------------------------------------
# 4. Override Manual vía --stack <override> (Validación del Fix Fase 0)
# ------------------------------------------------------------------------------
echo -e "🔍 [4/6] Verificando override explícito con --stack <override>..."

OVERRIDE_TARGET="$TMP_DIR/override_target"
mkdir -p "$OVERRIDE_TARGET/.agents/profiles"
# Crear marcador de static en disco, pero forzar --stack python
touch "$OVERRIDE_TARGET/index.html"
cp "$ROOT_DIR/.agents/profiles/developer.yaml" "$OVERRIDE_TARGET/.agents/profiles/developer.yaml"

bash "$SETUP_SCRIPT" --apply --path "$OVERRIDE_TARGET" --stack python >/dev/null 2>&1

DEV_OVERRIDE_YAML="$OVERRIDE_TARGET/.agents/profiles/developer.yaml"
if grep -q "stack: \"python\"" "$DEV_OVERRIDE_YAML" && grep -q "pytest" "$DEV_OVERRIDE_YAML"; then
  log_pass "--stack python anula marcador index.html y genera configuración de Python (Fase 0 verificada)."
else
  log_fail "--stack python falló al forzar el stack. Contenido:\n$(cat "$DEV_OVERRIDE_YAML" 2>/dev/null)"
fi

# ------------------------------------------------------------------------------
# 5. Idempotencia y Política de Artefacto Regenerable (Re-ejecuciones limpias)
# ------------------------------------------------------------------------------
echo -e "🔍 [5/6] Verificando idempotencia de marcadores (# BEGIN/END AGENT-OS-GENERATED-STACK)..."

IDEMPOTENT_TARGET="$TMP_DIR/idempotent_target"
mkdir -p "$IDEMPOTENT_TARGET/.agents/profiles"
touch "$IDEMPOTENT_TARGET/Cargo.toml"
cp "$ROOT_DIR/.agents/profiles/developer.yaml" "$IDEMPOTENT_TARGET/.agents/profiles/developer.yaml"

# Primera ejecución con Rust
bash "$SETUP_SCRIPT" --apply --path "$IDEMPOTENT_TARGET" >/dev/null 2>&1
# Segunda ejecución re-aplicando Rust
bash "$SETUP_SCRIPT" --apply --path "$IDEMPOTENT_TARGET" >/dev/null 2>&1
# Tercera ejecución alternando a Go
bash "$SETUP_SCRIPT" --apply --path "$IDEMPOTENT_TARGET" --stack go >/dev/null 2>&1

DEV_IDEMPOTENT="$IDEMPOTENT_TARGET/.agents/profiles/developer.yaml"

BEGIN_COUNT=$(grep -c "# BEGIN AGENT-OS-GENERATED-STACK" "$DEV_IDEMPOTENT" || echo 0)
END_COUNT=$(grep -c "# END AGENT-OS-GENERATED-STACK" "$DEV_IDEMPOTENT" || echo 0)

if [ "$BEGIN_COUNT" -eq 1 ] && [ "$END_COUNT" -eq 1 ]; then
  if grep -q "stack: \"go\"" "$DEV_IDEMPOTENT" && ! grep -q "stack: \"rust\"" "$DEV_IDEMPOTENT"; then
    log_pass "Idempotencia estricta: exactamente 1 bloque de marcadores tras 3 ejecuciones; regeneración a 'go' limpia."
  else
    log_fail "Fallo al sustituir limpiamente el bloque previo de marcadores."
  fi
else
  log_fail "Bloques duplicados detectados: BEGIN_COUNT=$BEGIN_COUNT, END_COUNT=$END_COUNT en $DEV_IDEMPOTENT."
fi

# ------------------------------------------------------------------------------
# 6. Conformidad con el Esquema de Control Plane y Enriquecimiento de Onboarding
# ------------------------------------------------------------------------------
echo -e "🔍 [6/6] Verificando conformidad del esquema YAML y onboarding..."

SCHEMA_TARGET="$TMP_DIR/schema_target"
mkdir -p "$SCHEMA_TARGET/.agents/profiles"
touch "$SCHEMA_TARGET/package.json"
cp "$ROOT_DIR/.agents/profiles/developer.yaml" "$SCHEMA_TARGET/.agents/profiles/developer.yaml"

# Crear onboarding previo con comando genérico
mkdir -p "$SCHEMA_TARGET/.agents"
cat << 'EOF' > "$SCHEMA_TARGET/.agents/AGENT_ONBOARDING.md"
# Onboarding Mock
## 🛠️ Comandos Frecuentes
- npm run dev: Arrancar entorno.
- npm test: Correr tests.
EOF

bash "$SETUP_SCRIPT" --apply --path "$SCHEMA_TARGET" --stack python >/dev/null 2>&1

DEV_SCHEMA_YAML="$SCHEMA_TARGET/.agents/profiles/developer.yaml"

# 1. Validar sintaxis YAML estricta
if command -v python3 >/dev/null 2>&1; then
  YAML_VALID=$(python3 -c "
import yaml, sys
try:
    with open('$DEV_SCHEMA_YAML', 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f)
    assert data['id'] == 'developer'
    assert 'stack_context' in data
    assert data['stack_context']['stack'] == 'python'
    assert 'allowed_tools' in data
    print('VALID')
except Exception as e:
    print(f'INVALID: {e}')
" 2>/dev/null || echo "ERROR")

  if [ "$YAML_VALID" = "VALID" ]; then
    log_pass "developer.yaml resultante cumple la sintaxis y campos requeridos por el control plane."
  else
    log_fail "developer.yaml no superó validación de esquema: $YAML_VALID"
  fi
fi

# 2. Validar enriquecimiento de onboarding
ONBOARD_CONTENT=$(cat "$SCHEMA_TARGET/.agents/AGENT_ONBOARDING.md")
if echo "$ONBOARD_CONTENT" | grep -q "python main.py" && echo "$ONBOARD_CONTENT" | grep -q "pytest"; then
  log_pass "AGENT_ONBOARDING.md enriquecido con comandos habituales de Python (dev/test)."
else
  log_fail "AGENT_ONBOARDING.md no fue actualizado correctamente:\n$ONBOARD_CONTENT"
fi

echo ""
echo -e "${BLUE}======================================================${NC}"
if [[ "$ERRORS" -eq 0 ]]; then
  echo -e "  ${GREEN}✅ TODAS LAS PRUEBAS PASARON EXITOSAMENTE ($TESTS_RUN/$TESTS_RUN)${NC}"
  echo -e "${BLUE}======================================================${NC}"
  exit 0
else
  echo -e "  ${RED}❌ PRUEBAS CON ERRORES: $ERRORS de $TESTS_RUN fallaron${NC}"
  echo -e "${BLUE}======================================================${NC}"
  exit 1
fi
