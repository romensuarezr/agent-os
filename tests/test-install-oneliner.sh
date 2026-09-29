#!/usr/bin/env bash
# ==============================================================================
# tests/test-install-oneliner.sh — Suite de distribución universal y one-liner (T-087)
# ==============================================================================
# Valida:
#   1. Fuente canónica de versión (VERSION) y ADR-006.
#   2. Instalación en repositorio limpio desde clon local.
#   3. Reejecución idempotente (mv-no-rm): no sobreescritura de onboarding,
#      no duplicación de bloques en .gitignore, preservación de archivos locales.
#   4. Aprovisionamiento efímero autónomo (simulación de ejecución remota curl|bash).
#   5. Limpieza determinista de directorios temporales (trap).
#   6. Preservación del diferencial completo (gobernanza, reglas, perfiles, etc.).
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
echo -e "${BLUE}  SUITE DE PRUEBAS: DISTRIBUCIÓN UNIVERSAL (T-087)   ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""

# ------------------------------------------------------------------------------
# 1. Verificación de Fuente Canónica de Versión y ADR-006
# ------------------------------------------------------------------------------
echo -e "🔍 [1/5] Verificando fuente canónica de versión (VERSION) y ADR-006..."

if [ -f "$ROOT_DIR/VERSION" ]; then
  CANONICAL_VER=$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")
  if [[ "$CANONICAL_VER" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    log_pass "VERSION existe en raíz y contiene semver válido: $CANONICAL_VER"
  else
    log_fail "VERSION no contiene formato semver válido: '$CANONICAL_VER'"
  fi
else
  log_fail "Archivo VERSION no encontrado en la raíz del core"
fi

ADR_FILE="$ROOT_DIR/docs/adrs/adr-006-universal-distribution.md"
ADR_README="$ROOT_DIR/docs/adrs/README.md"
if [ -f "$ADR_FILE" ] && grep -q "ADR 006" "$ADR_FILE"; then
  if grep -q "006" "$ADR_README" && grep -q "adr-006-universal-distribution.md" "$ADR_README"; then
    log_pass "ADR-006 documentado e indexado en docs/adrs/README.md"
  else
    log_fail "ADR-006 existe pero no está indexado correctamente en docs/adrs/README.md"
  fi
else
  log_fail "ADR-006 no encontrado en docs/adrs/adr-006-universal-distribution.md"
fi

# ------------------------------------------------------------------------------
# 2. Instalación en Repositorio Limpio (Modo Local con VERSION)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [2/5] Verificando instalación en proyecto limpio desde clon local..."

CHILD_1="$TMP_DIR/child_local"
mkdir -p "$CHILD_1"
git -C "$CHILD_1" init -q

bash "$ROOT_DIR/scripts/agent/install.sh" --minimal "$CHILD_1" >/dev/null 2>&1

# Verificar diferencial completo instalado
DIFFERENTIAL_OK=true
for dir in ".agents/rules" ".agents/workflows" ".agents/skills" ".agents/profiles" ".agents/config" "scripts/agent" "docs/sprints" "docs/adrs"; do
  if [ ! -d "$CHILD_1/$dir" ]; then
    DIFFERENTIAL_OK=false
    log_fail "Directorio del diferencial no creado: $dir"
  fi
done

if [ "$DIFFERENTIAL_OK" = true ]; then
  log_pass "Diferencial de arquitectura desplegado al 100% en proyecto hijo"
fi

if [ -f "$CHILD_1/.agents/AGENT_ONBOARDING.md" ] && [ -f "$CHILD_1/scripts/agent/install.sh" ]; then
  log_pass "Archivos operativos clave presentes (AGENT_ONBOARDING.md, scripts/agent/install.sh)"
else
  log_fail "Faltan archivos operativos en destino"
fi

# ------------------------------------------------------------------------------
# 3. Reejecución Idempotente y Preservación de Personalizaciones (mv-no-rm)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [3/5] Verificando idempotencia ante reejecución en proyecto existente..."

# Simular personalizaciones locales del hijo
echo "CUSTOM_LOCAL_RULE" > "$CHILD_1/.agents/rules/custom-local.md"
echo "<!-- CUSTOM_ONBOARDING_DATA -->" >> "$CHILD_1/.agents/AGENT_ONBOARDING.md"
echo "custom_secret: test" > "$CHILD_1/.agents/config/custom-local.yaml"
echo "custom_ignore_pattern" >> "$CHILD_1/.gitignore"

INITIAL_GITIGNORE_COUNT=$(grep -c "# Agent OS — generated context files" "$CHILD_1/.gitignore" || true)

# Re-ejecutar instalación sobre el mismo proyecto
bash "$ROOT_DIR/scripts/agent/install.sh" --minimal "$CHILD_1" >/dev/null 2>&1

# Verificar preservación
if [ -f "$CHILD_1/.agents/rules/custom-local.md" ] && grep -q "CUSTOM_LOCAL_RULE" "$CHILD_1/.agents/rules/custom-local.md"; then
  log_pass "Reglas locales personalizadas preservadas intactas"
else
  log_fail "Reglas locales personalizadas fueron alteradas o eliminadas"
fi

if grep -q "CUSTOM_ONBOARDING_DATA" "$CHILD_1/.agents/AGENT_ONBOARDING.md"; then
  log_pass "AGENT_ONBOARDING.md local no fue sobreescrito"
else
  log_fail "AGENT_ONBOARDING.md local fue sobreescrito por la plantilla"
fi

if [ -f "$CHILD_1/.agents/config/custom-local.yaml" ]; then
  log_pass "Configuraciones locales en .agents/config/ preservadas intactas"
else
  log_fail "Configuraciones locales en .agents/config/ eliminadas"
fi

NEW_GITIGNORE_COUNT=$(grep -c "# Agent OS — generated context files" "$CHILD_1/.gitignore" || true)
if [ "$NEW_GITIGNORE_COUNT" -eq "$INITIAL_GITIGNORE_COUNT" ] && [ "$NEW_GITIGNORE_COUNT" -eq 1 ]; then
  log_pass ".gitignore idempotente: bloque de Agent OS no duplicado ($NEW_GITIGNORE_COUNT bloque)"
else
  log_fail "Bloque de .gitignore duplicado: inicial=$INITIAL_GITIGNORE_COUNT, nuevo=$NEW_GITIGNORE_COUNT"
fi

# ------------------------------------------------------------------------------
# 4. Aprovisionamiento Efímero Autónomo (Simulación de One-Liner Remoto)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [4/5] Verificando aprovisionamiento efímero autónomo (ejecución remota)..."

# Crear mock git core repo local etiquetado con tag canónico
MOCK_REMOTE_CORE="$TMP_DIR/mock_remote_core"
mkdir -p "$MOCK_REMOTE_CORE"
cp -r "$ROOT_DIR"/. "$MOCK_REMOTE_CORE/"
rm -rf "$MOCK_REMOTE_CORE/.git"
git -C "$MOCK_REMOTE_CORE" init -q
git -C "$MOCK_REMOTE_CORE" config user.email "test@agent-os.local"
git -C "$MOCK_REMOTE_CORE" config user.name "Test Agent"
git -C "$MOCK_REMOTE_CORE" add -A
git -C "$MOCK_REMOTE_CORE" commit -q -m "initial core release commit"
git -C "$MOCK_REMOTE_CORE" tag "v1.11.0"

# Aislar install.sh fuera del core para forzar _has_local_core_assets = false
ISOLATED_DIR="$TMP_DIR/isolated_bin"
mkdir -p "$ISOLATED_DIR"
cp "$ROOT_DIR/scripts/agent/install.sh" "$ISOLATED_DIR/install.sh"
chmod +x "$ISOLATED_DIR/install.sh"

CHILD_2="$TMP_DIR/child_remote"
mkdir -p "$CHILD_2"

# Contar directorios efímeros existentes antes de correr
INITIAL_TEMP_COUNT=$(find /tmp -maxdepth 1 -name "agent-os-core-*" 2>/dev/null | wc -l || echo 0)

# Ejecutar el script aislado apuntando al mock git remoto con --tag v1.11.0
AGENT_OS_CORE_URL="file://$MOCK_REMOTE_CORE" \
  bash "$ISOLATED_DIR/install.sh" --tag v1.11.0 --minimal "$CHILD_2" >/dev/null 2>&1

FINAL_TEMP_COUNT=$(find /tmp -maxdepth 1 -name "agent-os-core-*" 2>/dev/null | wc -l || echo 0)

if [ -d "$CHILD_2/.agents" ] && [ -d "$CHILD_2/scripts/agent" ] && [ -f "$CHILD_2/scripts/agent/install.sh" ]; then
  log_pass "Instalación remota autónoma completada con éxito desde tag pineado"
else
  log_fail "Instalación remota autónoma falló o no instaló assets en destino"
fi

if [ "$FINAL_TEMP_COUNT" -le "$INITIAL_TEMP_COUNT" ]; then
  log_pass "Limpieza determinista de assets efímeros (trap EXIT verificado: 0 fugas en /tmp)"
else
  log_fail "Fuga de directorios temporales detectada tras la ejecución: inicial=$INITIAL_TEMP_COUNT, final=$FINAL_TEMP_COUNT"
fi

# ------------------------------------------------------------------------------
# 5. Validación de Restricciones de Tag (Aviso ante main/latest)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [5/5] Verificando advertencias de pineado ante tags no inmutables..."

CHILD_3="$TMP_DIR/child_warn"
mkdir -p "$CHILD_3"
ERR_LOG="$TMP_DIR/warn_tag.log"

bash "$ROOT_DIR/scripts/agent/install.sh" --tag main --check "$CHILD_3" >/dev/null 2>"$ERR_LOG" || true

if grep -q "ADVERTENCIA: Se especificó 'main'" "$ERR_LOG"; then
  log_pass "Advertencia formal emitida al intentar usar branch flotante 'main' en vez de tag inmutable"
else
  log_fail "No se emitió advertencia ante uso de --tag main. Stderr: $(cat "$ERR_LOG")"
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
