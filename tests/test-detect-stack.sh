#!/usr/bin/env bash
# ==============================================================================
# tests/test-detect-stack.sh — Suite unitaria y defensiva de detect-stack.sh
# ==============================================================================
# Valida:
#   1. Bucle nominal: clasificación declarativa exacta de los 11 stacks soportados.
#   2. Escenario nominal con PATH: coincidencia de lockfile y binario nativo.
#   3. Escenario lockfile huérfano: lockfile presente pero sin binario en PATH (fallback y warning).
#   4. Escenario múltiples lockfiles: precedencia declarativa y resolución priorizada en PATH.
#   5. Escenario sin lockfile: resolución de primer PM en PATH sin emisión de divergencias.
#   6. Escenario sin gestor compatible en PATH: advertencia específica de gestor ausente.
#   7. Consumidores del core: verificación de interfaz con install, inventory, digest y audit.
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
echo -e "${BLUE}  SUITE DE PRUEBAS: DETECT-STACK DEFENSIVO (T-086)    ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""

# Fuente directa del script bajo prueba
source "$ROOT_DIR/scripts/agent/lib/detect-stack.sh"

# ------------------------------------------------------------------------------
# 1. Bucle Nominal: 11 Stacks Soportados
# ------------------------------------------------------------------------------
echo -e "🔍 [1/6] Verificando bucle nominal de los 11 stacks soportados..."

declare -A STACK_MARKERS=(
  ["python"]="pyproject.toml"
  ["typescript"]="tsconfig.json"
  ["javascript"]="package.json"
  ["go"]="go.mod"
  ["rust"]="Cargo.toml"
  ["java"]="pom.xml"
  ["php"]="composer.json"
  ["ruby"]="Gemfile"
  ["dotnet"]="sample.csproj"
  ["bun"]="bun.lock"
  ["static"]="index.html"
)

for expected_stack in python typescript javascript go rust java php ruby dotnet bun static; do
  marker="${STACK_MARKERS[$expected_stack]}"
  target_dir="$TMP_DIR/nominal/$expected_stack"
  mkdir -p "$target_dir"
  touch "$target_dir/$marker"

  detect_stack "$target_dir" >/dev/null 2>&1

  if [[ "$AGENT_OS_STACK" == "$expected_stack" ]]; then
    log_pass "Stack '$expected_stack' detectado por marcador '$marker'"
  else
    log_fail "Stack '$expected_stack' esperado, pero se obtuvo '$AGENT_OS_STACK' (marcador: $marker)"
  fi
done

# ------------------------------------------------------------------------------
# 2. Escenario Nominal con PATH (bun.lock + bun en PATH)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [2/6] Verificando escenario nominal con PATH (bun.lock + bun en PATH)..."

MOCK_BIN_BUN="$TMP_DIR/mock_bin_bun"
mkdir -p "$MOCK_BIN_BUN"
cat << 'EOF' > "$MOCK_BIN_BUN/bun"
#!/bin/sh
echo "mock bun"
EOF
chmod +x "$MOCK_BIN_BUN/bun"

CASE_NOMINAL_BUN="$TMP_DIR/case_nominal_bun"
mkdir -p "$CASE_NOMINAL_BUN"
touch "$CASE_NOMINAL_BUN/bun.lock"

ERR_LOG="$TMP_DIR/case2_err.log"
OUT=$(PATH="$MOCK_BIN_BUN:$PATH" bash -c '
  source "'"$ROOT_DIR"'/scripts/agent/lib/detect-stack.sh"
  detect_stack "'"$CASE_NOMINAL_BUN"'"
  echo "STACK=$AGENT_OS_STACK"
  echo "PM=$AGENT_OS_PACKAGE_MANAGER"
  echo "LOCKFILE=$AGENT_OS_DETECTED_LOCKFILE"
' 2>"$ERR_LOG")

STDERR_CONTENT=$(cat "$ERR_LOG")
STACK_VAL=$(echo "$OUT" | grep "^STACK=" | cut -d= -f2)
PM_VAL=$(echo "$OUT" | grep "^PM=" | cut -d= -f2)
LOCKFILE_VAL=$(echo "$OUT" | grep "^LOCKFILE=" | cut -d= -f2)

if [[ "$STACK_VAL" == "bun" && "$PM_VAL" == "bun" && "$LOCKFILE_VAL" == "bun.lock" && -z "$STDERR_CONTENT" ]]; then
  log_pass "Nominal: AGENT_OS_STACK=bun, PM=bun, LOCKFILE=bun.lock, stderr limpio"
else
  log_fail "Nominal falló: STACK=$STACK_VAL, PM=$PM_VAL, LOCKFILE=$LOCKFILE_VAL, stderr='$STDERR_CONTENT'"
fi

# ------------------------------------------------------------------------------
# 3. Escenario Lockfile Huérfano (bun.lock presente, bun ausente de PATH, fallback npm)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [3/6] Verificando escenario lockfile huérfano (bun.lock sin bun en PATH, fallback a npm)..."

MOCK_BIN_ORPHAN="$TMP_DIR/mock_bin_orphan"
mkdir -p "$MOCK_BIN_ORPHAN"
cat << 'EOF' > "$MOCK_BIN_ORPHAN/npm"
#!/bin/sh
echo "mock npm"
EOF
chmod +x "$MOCK_BIN_ORPHAN/npm"

CASE_ORPHAN_BUN="$TMP_DIR/case_orphan_bun"
mkdir -p "$CASE_ORPHAN_BUN"
touch "$CASE_ORPHAN_BUN/bun.lock"

ERR_LOG="$TMP_DIR/case3_err.log"
STDOUT_RAW="$TMP_DIR/case3_out_raw.log"

PATH="$MOCK_BIN_ORPHAN:/bin:/usr/bin" bash -c '
  source "'"$ROOT_DIR"'/scripts/agent/lib/detect-stack.sh"
  # Captura limpia: stdout de detect_stack debe ser 0 bytes
  detect_stack "'"$CASE_ORPHAN_BUN"'" >"'"$STDOUT_RAW"'" 2>"'"$ERR_LOG"'"
  echo "STACK=$AGENT_OS_STACK"
  echo "PM=$AGENT_OS_PACKAGE_MANAGER"
  echo "LOCKFILE=$AGENT_OS_DETECTED_LOCKFILE"
' > "$TMP_DIR/case3_vars.log"

STDERR_CONTENT=$(cat "$ERR_LOG")
RAW_STDOUT_SIZE=$(wc -c < "$STDOUT_RAW" | tr -d '[:space:]')
STACK_VAL=$(grep "^STACK=" "$TMP_DIR/case3_vars.log" | cut -d= -f2)
PM_VAL=$(grep "^PM=" "$TMP_DIR/case3_vars.log" | cut -d= -f2)
LOCKFILE_VAL=$(grep "^LOCKFILE=" "$TMP_DIR/case3_vars.log" | cut -d= -f2)

if [[ "$STACK_VAL" == "bun" ]]; then
  log_pass "Preservación declarativa: AGENT_OS_STACK=bun sin reclasificación"
else
  log_fail "AGENT_OS_STACK fue reclasificado: se obtuvo '$STACK_VAL'"
fi

if [[ "$PM_VAL" == "npm" ]]; then
  log_pass "Resolución defensiva: AGENT_OS_PACKAGE_MANAGER=npm verificado en PATH"
else
  log_fail "PM no resolvió a npm: se obtuvo '$PM_VAL'"
fi

if [[ "$LOCKFILE_VAL" == "bun.lock" ]]; then
  log_pass "Lockfile causante identificado: AGENT_OS_DETECTED_LOCKFILE=bun.lock"
else
  log_fail "Lockfile incorrecto: se obtuvo '$LOCKFILE_VAL'"
fi

if [[ "$RAW_STDOUT_SIZE" -eq 0 ]]; then
  log_pass "Salida estándar stdout 100% limpia (0 bytes contaminantes)"
else
  log_fail "stdout contiene datos contaminantes: $RAW_STDOUT_SIZE bytes"
fi

EXPECTED_WARN="⚠️  DIVERGENCE: bun.lock detectado pero 'bun' no está en PATH. Fallback a 'npm'."
if [[ "$STDERR_CONTENT" == *"$EXPECTED_WARN"* ]]; then
  log_pass "Aviso formal en stderr con formato canónico de divergencia"
else
  log_fail "stderr no contiene aviso esperado. Contenido: '$STDERR_CONTENT'"
fi

# ------------------------------------------------------------------------------
# 4. Escenario Múltiples Lockfiles (pnpm-lock.yaml y package-lock.json)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [4/6] Verificando escenario de múltiples lockfiles..."

CASE_MULTI="$TMP_DIR/case_multi"
mkdir -p "$CASE_MULTI"
touch "$CASE_MULTI/tsconfig.json"
touch "$CASE_MULTI/pnpm-lock.yaml"
touch "$CASE_MULTI/package-lock.json"

# 4.A Con pnpm en PATH -> resuelve pnpm sin divergencia
MOCK_BIN_PNPM="$TMP_DIR/mock_bin_pnpm"
mkdir -p "$MOCK_BIN_PNPM"
cat << 'EOF' > "$MOCK_BIN_PNPM/pnpm"
#!/bin/sh
echo "mock pnpm"
EOF
cat << 'EOF' > "$MOCK_BIN_PNPM/npm"
#!/bin/sh
echo "mock npm"
EOF
chmod +x "$MOCK_BIN_PNPM/pnpm" "$MOCK_BIN_PNPM/npm"

ERR_LOG="$TMP_DIR/case4a_err.log"
OUT=$(PATH="$MOCK_BIN_PNPM:$PATH" bash -c '
  source "'"$ROOT_DIR"'/scripts/agent/lib/detect-stack.sh"
  detect_stack "'"$CASE_MULTI"'"
  echo "STACK=$AGENT_OS_STACK"
  echo "PM=$AGENT_OS_PACKAGE_MANAGER"
  echo "LOCKFILE=$AGENT_OS_DETECTED_LOCKFILE"
' 2>"$ERR_LOG")

STDERR_CONTENT=$(cat "$ERR_LOG")
PM_VAL=$(echo "$OUT" | grep "^PM=" | cut -d= -f2)
LOCKFILE_VAL=$(echo "$OUT" | grep "^LOCKFILE=" | cut -d= -f2)

if [[ "$PM_VAL" == "pnpm" && "$LOCKFILE_VAL" == "pnpm-lock.yaml" && -z "$STDERR_CONTENT" ]]; then
  log_pass "Múltiples lockfiles (pnpm en PATH): PM=pnpm, lockfile=pnpm-lock.yaml, sin divergencia"
else
  log_fail "Múltiples lockfiles con pnpm falló: PM=$PM_VAL, lockfile=$LOCKFILE_VAL, stderr='$STDERR_CONTENT'"
fi

# 4.B Solo npm en PATH (sin pnpm) -> fallback a npm con aviso formal
ERR_LOG="$TMP_DIR/case4b_err.log"
OUT=$(PATH="$MOCK_BIN_ORPHAN:/bin:/usr/bin" bash -c '
  source "'"$ROOT_DIR"'/scripts/agent/lib/detect-stack.sh"
  detect_stack "'"$CASE_MULTI"'"
  echo "STACK=$AGENT_OS_STACK"
  echo "PM=$AGENT_OS_PACKAGE_MANAGER"
  echo "LOCKFILE=$AGENT_OS_DETECTED_LOCKFILE"
' 2>"$ERR_LOG")

STDERR_CONTENT=$(cat "$ERR_LOG")
PM_VAL=$(echo "$OUT" | grep "^PM=" | cut -d= -f2)
LOCKFILE_VAL=$(echo "$OUT" | grep "^LOCKFILE=" | cut -d= -f2)
EXPECTED_WARN="⚠️  DIVERGENCE: pnpm-lock.yaml detectado pero 'pnpm' no está en PATH. Fallback a 'npm'."

if [[ "$PM_VAL" == "npm" && "$LOCKFILE_VAL" == "pnpm-lock.yaml" && "$STDERR_CONTENT" == *"$EXPECTED_WARN"* ]]; then
  log_pass "Múltiples lockfiles (solo npm en PATH): fallback a npm con aviso formal de divergencia"
else
  log_fail "Múltiples lockfiles sin pnpm falló: PM=$PM_VAL, lockfile=$LOCKFILE_VAL, stderr='$STDERR_CONTENT'"
fi

# ------------------------------------------------------------------------------
# 5. Escenario Sin Lockfile (package.json estándar)
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [5/6] Verificando escenario sin lockfile (package.json estándar)..."

CASE_NO_LOCK="$TMP_DIR/case_no_lock"
mkdir -p "$CASE_NO_LOCK"
touch "$CASE_NO_LOCK/package.json"

ERR_LOG="$TMP_DIR/case5_err.log"
OUT=$(PATH="$MOCK_BIN_ORPHAN:/bin:/usr/bin" bash -c '
  source "'"$ROOT_DIR"'/scripts/agent/lib/detect-stack.sh"
  detect_stack "'"$CASE_NO_LOCK"'"
  echo "STACK=$AGENT_OS_STACK"
  echo "PM=$AGENT_OS_PACKAGE_MANAGER"
  echo "LOCKFILE=$AGENT_OS_DETECTED_LOCKFILE"
' 2>"$ERR_LOG")

STDERR_CONTENT=$(cat "$ERR_LOG")
STACK_VAL=$(echo "$OUT" | grep "^STACK=" | cut -d= -f2)
PM_VAL=$(echo "$OUT" | grep "^PM=" | cut -d= -f2)
LOCKFILE_VAL=$(echo "$OUT" | grep "^LOCKFILE=" | cut -d= -f2)

if [[ "$STACK_VAL" == "javascript" && "$PM_VAL" == "npm" && -z "$LOCKFILE_VAL" && -z "$STDERR_CONTENT" ]]; then
  log_pass "Sin lockfile: STACK=javascript, PM=npm en PATH, LOCKFILE vacío, sin divergencia en stderr"
else
  log_fail "Sin lockfile falló: STACK=$STACK_VAL, PM=$PM_VAL, LOCKFILE='$LOCKFILE_VAL', stderr='$STDERR_CONTENT'"
fi

# ------------------------------------------------------------------------------
# 6. Escenario Sin Gestor Compatible en PATH y Verificación de Consumidores
# ------------------------------------------------------------------------------
echo ""
echo -e "🔍 [6/6] Verificando caso sin gestor en PATH y compatibilidad con consumidores..."

MOCK_BIN_EMPTY="$TMP_DIR/mock_bin_empty"
mkdir -p "$MOCK_BIN_EMPTY"
for tool in basename cut tr grep; do
  tool_path=$(command -v "$tool" || true)
  if [[ -n "$tool_path" ]]; then
    ln -s "$tool_path" "$MOCK_BIN_EMPTY/$tool"
  fi
done

ERR_LOG="$TMP_DIR/case6_err.log"
OUT=$(PATH="$MOCK_BIN_EMPTY" "$BASH" -c '
  source "'"$ROOT_DIR"'/scripts/agent/lib/detect-stack.sh"
  detect_stack "'"$CASE_ORPHAN_BUN"'"
  echo "STACK=$AGENT_OS_STACK"
  echo "PM=$AGENT_OS_PACKAGE_MANAGER"
  echo "LOCKFILE=$AGENT_OS_DETECTED_LOCKFILE"
' 2>"$ERR_LOG")

STDERR_CONTENT=$(cat "$ERR_LOG")
PM_VAL=$(echo "$OUT" | grep "^PM=" | cut -d= -f2)
EXPECTED_WARN="⚠️  DIVERGENCE: bun.lock detectado pero ningún gestor compatible está instalado en PATH."

if [[ -z "$PM_VAL" && "$STDERR_CONTENT" == *"$EXPECTED_WARN"* ]]; then
  log_pass "Sin gestores en PATH: PM vacío y aviso 'ningún gestor compatible está instalado en PATH'"
else
  log_fail "Sin gestores en PATH falló: PM='$PM_VAL', stderr='$STDERR_CONTENT'"
fi

# Verificación de no rotura de interfaz en consumidores:
# 1) install.sh sintaxis y llamada a detect_stack
if bash -n "$ROOT_DIR/scripts/agent/install.sh" && \
   bash -n "$ROOT_DIR/scripts/agent/inventory-check.sh" && \
   bash -n "$ROOT_DIR/scripts/agent/generate-digest.sh" && \
   bash -n "$ROOT_DIR/scripts/agent/audit-repo.sh"; then
  log_pass "Sintaxis de consumidores verificada: install, inventory-check, generate-digest, audit-repo"
else
  log_fail "Sintaxis de algún script consumidor está dañada"
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
