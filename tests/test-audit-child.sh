#!/usr/bin/env bash
# ==============================================================================
# tests/test-audit-child.sh — Suite de pruebas de auditoría y ledger (T-088)
# ==============================================================================
# Valida:
#   1. Inspección estática y contrato anti-telemetría (100% offline, cero red).
#   2. Satélite sano / nominal (✅ CONFORME, exit 0).
#   3. Detección de drift por configuraciones obsoletas en config/ (⚠️ DRIFT, exit 0).
#   4. Cálculo de días y umbrales de desactualización temporal (7 y 14 días).
#   5. Compatibilidad retrocompatible con formato legacy en last-sync.md.
#   6. Detección de divergencia con la versión canónica del core.
#   7. Detección de onboarding genérico / no personalizado.
#   8. Satélite no conforme por falta de estructura o permisos (❌ NO CONFORME, exit 1).
#   9. Cableado del pre-flight en la plantilla AGENT_ONBOARDING.project.md.
#  10. Generación de ledger enriquecido en install.sh y sync.sh.
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
echo -e "${BLUE}  SUITE DE PRUEBAS: AUDIT-CHILD & VERSION LEDGER (T-088) ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""

AUDIT_SCRIPT="$ROOT_DIR/scripts/agent/audit-child.sh"

# ------------------------------------------------------------------------------
# 1. Inspección Estática, Contrato Anti-telemetría y Assets Manifest
# ------------------------------------------------------------------------------
echo -e "🔍 [1/8] Verificando contrato estático, anti-telemetría y manifiesto..."

if [ -f "$AUDIT_SCRIPT" ] && [ -x "$AUDIT_SCRIPT" ]; then
  log_pass "scripts/agent/audit-child.sh existe y cuenta con permisos de ejecución (+x)."
else
  log_fail "scripts/agent/audit-child.sh falta o no es ejecutable."
fi

# Anti-telemetría: comprobar que no hay comandos ni invocaciones de red
NETWORK_CALLS=$(grep -E '\b(curl|wget|nc|git fetch|git push|git ls-remote|git clone)\b' "$AUDIT_SCRIPT" || true)
if [ -z "$NETWORK_CALLS" ]; then
  log_pass "audit-child.sh es 100% offline (cero llamadas de red: curl/wget/git network)."
else
  log_fail "audit-child.sh contiene llamadas de red prohibidas: $NETWORK_CALLS"
fi

# Constantes nombradas de drift
if grep -q "DRIFT_WARN_DAYS=7" "$AUDIT_SCRIPT" && grep -q "DRIFT_CRITICAL_DAYS=14" "$AUDIT_SCRIPT"; then
  log_pass "Constantes nombradas DRIFT_WARN_DAYS=7 y DRIFT_CRITICAL_DAYS=14 definidas al inicio."
else
  log_fail "Faltan las constantes nombradas DRIFT_WARN_DAYS=7 y/o DRIFT_CRITICAL_DAYS=14."
fi

# Manifiesto de assets
if grep -q "scripts/agent/audit-child.sh" "$ROOT_DIR/scripts/agent/assets-manifest.txt"; then
  log_pass "scripts/agent/audit-child.sh registrado en assets-manifest.txt."
else
  log_fail "scripts/agent/audit-child.sh no figura en assets-manifest.txt."
fi

# ------------------------------------------------------------------------------
# Función auxiliar: Crear mock base de satélite sano
# ------------------------------------------------------------------------------
create_mock_satellite() {
  local target="$1"
  mkdir -p "$target/.agents/rules/global"
  mkdir -p "$target/.agents/workflows"
  mkdir -p "$target/.agents/skills"
  mkdir -p "$target/.agents/profiles"
  mkdir -p "$target/.agents/config"
  mkdir -p "$target/.agents/context"
  mkdir -p "$target/scripts/agent/lib"

  # Copiar detect-stack y crear un script ejecutable
  cp "$ROOT_DIR/scripts/agent/lib/detect-stack.sh" "$target/scripts/agent/lib/detect-stack.sh"
  chmod +x "$target/scripts/agent/lib/detect-stack.sh"
  
  cat << 'EOF' > "$target/scripts/agent/mock-tool.sh"
#!/usr/bin/env bash
echo "mock"
EOF
  chmod +x "$target/scripts/agent/mock-tool.sh"

  # Onboarding personalizado
  cat << 'EOF' > "$target/.agents/AGENT_ONBOARDING.md"
# Onboarding Proyecto Satélite de Prueba
Stack: Node.js con TypeScript
Repo real configurado sin plantillas genéricas.
EOF

  # Marcador de stack
  cat << 'EOF' > "$target/package.json"
{
  "name": "test-satellite",
  "version": "1.0.0"
}
EOF

  # Ledger de versión actual
  local cur_date
  cur_date=$(date -u +%Y-%m-%d)
  local cur_ver
  cur_ver=$(tr -d '[:space:]' < "$ROOT_DIR/VERSION" 2>/dev/null || echo "1.11.0")
  {
    echo "$cur_date"
    echo "version: $cur_ver"
    echo "tag: v$cur_ver"
    echo "commit: abc1234def5678"
  } > "$target/.agents/context/last-sync.md"
}

# ------------------------------------------------------------------------------
# 2. Escenario Satélite Sano (✅ CONFORME)
# ------------------------------------------------------------------------------
echo -e "🔍 [2/8] Validando satélite sano (salida CONFORME, exit 0)..."

HEALTHY_DIR="$TMP_DIR/satellite-healthy"
create_mock_satellite "$HEALTHY_DIR"

OUTPUT_HEALTHY=""
STATUS_HEALTHY=0
OUTPUT_HEALTHY=$(bash "$AUDIT_SCRIPT" --path "$HEALTHY_DIR" 2>&1) || STATUS_HEALTHY=$?

if [ "$STATUS_HEALTHY" -eq 0 ]; then
  if echo "$OUTPUT_HEALTHY" | grep -q "✅ CONFORME"; then
    log_pass "Satélite sano evaluado con éxito (exit code 0 y semáforo ✅ CONFORME)."
  else
    log_fail "Satélite sano devolvió exit 0 pero falta el semáforo ✅ CONFORME. Output:\n$OUTPUT_HEALTHY"
  fi
else
  log_fail "Satélite sano falló con código $STATUS_HEALTHY. Output:\n$OUTPUT_HEALTHY"
fi

# ------------------------------------------------------------------------------
# 3. Escenario Drift de Configuración Obsoleta (⚠️ DRIFT DETECTADO)
# ------------------------------------------------------------------------------
echo -e "🔍 [3/8] Validando detección de drift de rutas obsoletas (config/fleet.yaml)..."

DRIFT_CFG_DIR="$TMP_DIR/satellite-drift-cfg"
create_mock_satellite "$DRIFT_CFG_DIR"
mkdir -p "$DRIFT_CFG_DIR/config"
touch "$DRIFT_CFG_DIR/config/fleet.yaml"

OUTPUT_DRIFT_CFG=""
STATUS_DRIFT_CFG=0
OUTPUT_DRIFT_CFG=$(bash "$AUDIT_SCRIPT" --path "$DRIFT_CFG_DIR" 2>&1) || STATUS_DRIFT_CFG=$?

if [ "$STATUS_DRIFT_CFG" -eq 0 ]; then
  if echo "$OUTPUT_DRIFT_CFG" | grep -q "⚠️  DRIFT DETECTADO" && echo "$OUTPUT_DRIFT_CFG" | grep -q "CONFIG-DRIFT"; then
    log_pass "Drift por config/fleet.yaml detectado correctamente (exit 0 y semáforo ⚠️  DRIFT DETECTADO)."
  else
    log_fail "Fallo al clasificar drift de configuración obsoleta. Output:\n$OUTPUT_DRIFT_CFG"
  fi
else
  log_fail "Drift de configuración terminó inesperadamente con error $STATUS_DRIFT_CFG. Output:\n$OUTPUT_DRIFT_CFG"
fi

# ------------------------------------------------------------------------------
# 4. Escenario Umbrales de Desactualización Temporal (7 y 14 días)
# ------------------------------------------------------------------------------
echo -e "🔍 [4/8] Validando cálculo de días y umbrales de sincronización (7 y 14 días)..."

# Subcaso A: 10 días (> 7 días, < 14 días)
DRIFT_TIME_DIR="$TMP_DIR/satellite-drift-time"
create_mock_satellite "$DRIFT_TIME_DIR"

OLD_DATE_10=""
if command -v date >/dev/null 2>&1; then
  OLD_DATE_10=$(date -u -d "10 days ago" +%Y-%m-%d 2>/dev/null || true)
  [ -z "$OLD_DATE_10" ] && OLD_DATE_10=$(date -u -v-10d +%Y-%m-%d 2>/dev/null || true)
fi
if [ -z "$OLD_DATE_10" ] && command -v python3 >/dev/null 2>&1; then
  OLD_DATE_10=$(python3 -c 'import datetime; print((datetime.datetime.utcnow() - datetime.timedelta(days=10)).strftime("%Y-%m-%d"))')
fi

sed -i "1s/.*/$OLD_DATE_10/" "$DRIFT_TIME_DIR/.agents/context/last-sync.md"

OUTPUT_TIME_10=""
STATUS_TIME_10=0
OUTPUT_TIME_10=$(bash "$AUDIT_SCRIPT" --path "$DRIFT_TIME_DIR" 2>&1) || STATUS_TIME_10=$?

if [ "$STATUS_TIME_10" -eq 0 ] && echo "$OUTPUT_TIME_10" | grep -q "Desactualización leve"; then
  log_pass "Umbral de 7 días detectado como Desactualización leve (exit 0)."
else
  log_fail "Fallo al detectar umbral de 7 días. Output:\n$OUTPUT_TIME_10"
fi

# Subcaso B: 20 días (>= 14 días)
OLD_DATE_20=""
if command -v date >/dev/null 2>&1; then
  OLD_DATE_20=$(date -u -d "20 days ago" +%Y-%m-%d 2>/dev/null || true)
  [ -z "$OLD_DATE_20" ] && OLD_DATE_20=$(date -u -v-20d +%Y-%m-%d 2>/dev/null || true)
fi
if [ -z "$OLD_DATE_20" ] && command -v python3 >/dev/null 2>&1; then
  OLD_DATE_20=$(python3 -c 'import datetime; print((datetime.datetime.utcnow() - datetime.timedelta(days=20)).strftime("%Y-%m-%d"))')
fi

sed -i "1s/.*/$OLD_DATE_20/" "$DRIFT_TIME_DIR/.agents/context/last-sync.md"

OUTPUT_TIME_20=""
STATUS_TIME_20=0
OUTPUT_TIME_20=$(bash "$AUDIT_SCRIPT" --path "$DRIFT_TIME_DIR" 2>&1) || STATUS_TIME_20=$?

if [ "$STATUS_TIME_20" -eq 0 ] && echo "$OUTPUT_TIME_20" | grep -q "Desactualización severa"; then
  log_pass "Umbral de 14 días detectado como Desactualización severa (exit 0)."
else
  log_fail "Fallo al detectar umbral de 14 días. Output:\n$OUTPUT_TIME_20"
fi

# ------------------------------------------------------------------------------
# 5. Escenario Formato Legacy y Divergencia de Versión
# ------------------------------------------------------------------------------
echo -e "🔍 [5/8] Validando formato legacy de last-sync.md y divergencia con core..."

LEGACY_DIR="$TMP_DIR/satellite-legacy"
create_mock_satellite "$LEGACY_DIR"
# Formato legacy: solo 2 líneas sin 'version:'
{
  date -u +%Y-%m-%d
  echo "commit: legacy12345"
} > "$LEGACY_DIR/.agents/context/last-sync.md"

OUTPUT_LEGACY=""
STATUS_LEGACY=0
OUTPUT_LEGACY=$(bash "$AUDIT_SCRIPT" --path "$LEGACY_DIR" 2>&1) || STATUS_LEGACY=$?

if echo "$OUTPUT_LEGACY" | grep -q "legacy"; then
  log_pass "Formato legacy en last-sync.md parseado con éxito (fallback 'legacy' activo)."
else
  log_fail "Fallo al interpretar formato legacy de last-sync.md. Output:\n$OUTPUT_LEGACY"
fi

# Divergencia explícita de versión con el core
DIVERGENT_DIR="$TMP_DIR/satellite-divergent"
create_mock_satellite "$DIVERGENT_DIR"
{
  date -u +%Y-%m-%d
  echo "version: 0.9.0"
  echo "tag: v0.9.0"
  echo "commit: ancientcommit1"
} > "$DIVERGENT_DIR/.agents/context/last-sync.md"

OUTPUT_DIVERGENT=""
STATUS_DIVERGENT=0
OUTPUT_DIVERGENT=$(bash "$AUDIT_SCRIPT" --path "$DIVERGENT_DIR" 2>&1) || STATUS_DIVERGENT=$?

if echo "$OUTPUT_DIVERGENT" | grep -q -E '(Desalineado con el core|Divergencia)'; then
  log_pass "Divergencia de versión con el core detectada (satélite=0.9.0 vs core)."
else
  log_fail "Fallo al detectar divergencia de versión con el core. Output:\n$OUTPUT_DIVERGENT"
fi

# ------------------------------------------------------------------------------
# 6. Escenario Integridad de Onboarding
# ------------------------------------------------------------------------------
echo -e "🔍 [6/8] Validando detección de onboarding incompleto..."

ONBOARD_DIR="$TMP_DIR/satellite-onboard-generic"
create_mock_satellite "$ONBOARD_DIR"
# Sobreescribir onboarding con la plantilla sin completar
cat << 'EOF' > "$ONBOARD_DIR/.agents/AGENT_ONBOARDING.md"
# Agent Onboarding Template
## 🚀 Stack Tecnológico
- **Frontend**: [React / Next.js / etc.]
- **Backend**: [Node.js / Python / etc.]
EOF

OUTPUT_ONBOARD=""
STATUS_ONBOARD=0
OUTPUT_ONBOARD=$(bash "$AUDIT_SCRIPT" --path "$ONBOARD_DIR" 2>&1) || STATUS_ONBOARD=$?

if echo "$OUTPUT_ONBOARD" | grep -q "marcadores de plantilla genérica sin completar"; then
  log_pass "Onboarding genérico detectado con advertencia descriptiva."
else
  log_fail "Fallo al detectar onboarding genérico sin completar. Output:\n$OUTPUT_ONBOARD"
fi

# ------------------------------------------------------------------------------
# 7. Escenario No Conforme (❌ Errores Críticos / Exit 1)
# ------------------------------------------------------------------------------
echo -e "🔍 [7/8] Validando casos NO CONFORME (código de salida 1)..."

# Subcaso A: Falta directorio crítico (.agents/rules)
BROKEN_DIR_A="$TMP_DIR/satellite-broken-a"
create_mock_satellite "$BROKEN_DIR_A"
rm -rf "$BROKEN_DIR_A/.agents/rules"

STATUS_BROKEN_A=0
OUTPUT_BROKEN_A=$(bash "$AUDIT_SCRIPT" --path "$BROKEN_DIR_A" 2>&1) || STATUS_BROKEN_A=$?

if [ "$STATUS_BROKEN_A" -eq 1 ] && echo "$OUTPUT_BROKEN_A" | grep -q "❌ NO CONFORME"; then
  log_pass "Directorio ausente (.agents/rules) produce exit code 1 y ❌ NO CONFORME."
else
  log_fail "Directorio ausente no produjo error crítico esperado. Status: $STATUS_BROKEN_A. Output:\n$OUTPUT_BROKEN_A"
fi

# Subcaso B: Script sin permiso de ejecución (+x)
BROKEN_DIR_B="$TMP_DIR/satellite-broken-b"
create_mock_satellite "$BROKEN_DIR_B"
chmod -x "$BROKEN_DIR_B/scripts/agent/mock-tool.sh"

STATUS_BROKEN_B=0
OUTPUT_BROKEN_B=$(bash "$AUDIT_SCRIPT" --path "$BROKEN_DIR_B" 2>&1) || STATUS_BROKEN_B=$?

if [ "$STATUS_BROKEN_B" -eq 1 ] && echo "$OUTPUT_BROKEN_B" | grep -q "PERMISOS"; then
  log_pass "Script sin permiso (+x) produce exit code 1 y ❌ NO CONFORME."
else
  log_fail "Script sin permiso no produjo error crítico esperado. Status: $STATUS_BROKEN_B. Output:\n$OUTPUT_BROKEN_B"
fi

# ------------------------------------------------------------------------------
# 8. Cableado de Pre-flight y Enriquecimiento de Ledger en install.sh/sync.sh
# ------------------------------------------------------------------------------
echo -e "🔍 [8/8] Verificando cableado en AGENT_ONBOARDING.project.md e install.sh..."

PROJECT_TEMPLATE="$ROOT_DIR/.agents/templates/AGENT_ONBOARDING.project.md"
if grep -q "bash scripts/agent/audit-child.sh" "$PROJECT_TEMPLATE" && \
   grep -q "CONFORME" "$PROJECT_TEMPLATE" && \
   grep -q "DRIFT DETECTADO" "$PROJECT_TEMPLATE" && \
   grep -q "deterministic-execution.md" "$PROJECT_TEMPLATE"; then
  log_pass "Pre-flight cableado en AGENT_ONBOARDING.project.md con interpretación canónica."
else
  log_fail "Falta el cableado del pre-flight de audit-child.sh en AGENT_ONBOARDING.project.md."
fi

# Prueba de instalación real para verificar ledger enriquecido generado por install.sh
INSTALL_DEST="$TMP_DIR/fresh-install-target"
mkdir -p "$INSTALL_DEST"
bash "$ROOT_DIR/scripts/agent/install.sh" --minimal "$INSTALL_DEST" >/dev/null 2>&1

INSTALL_LEDGER="$INSTALL_DEST/.agents/context/last-sync.md"
if [ -f "$INSTALL_LEDGER" ] && \
   grep -q -E '^version:' "$INSTALL_LEDGER" && \
   grep -q -E '^tag:' "$INSTALL_LEDGER" && \
   grep -q -E '^commit:' "$INSTALL_LEDGER"; then
  log_pass "install.sh genera .agents/context/last-sync.md con formato enriquecido (version, tag, commit)."
else
  log_fail "install.sh no generó el ledger enriquecido esperado en $INSTALL_LEDGER."
fi

echo ""
echo -e "${BLUE}======================================================${NC}"
if [ "$ERRORS" -eq 0 ]; then
  echo -e "${GREEN}  ✅ TODOS LOS TESTS PASARON ($TESTS_RUN/$TESTS_RUN)${NC}"
  echo -e "${BLUE}======================================================${NC}"
  exit 0
else
  echo -e "${RED}  ❌ HUBO $ERRORS FALLO(S) EN $TESTS_RUN PRUEBAS${NC}"
  echo -e "${BLUE}======================================================${NC}"
  exit 1
fi
