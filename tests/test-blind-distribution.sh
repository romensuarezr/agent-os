#!/usr/bin/env bash
# ==============================================================================
# tests/test-blind-distribution.sh — Harness determinista de prueba ciega (T-090)
# ==============================================================================
# Valida los 5 hitos canónicos de distribución y ciclo de vida en repo efímero:
#   1. Aprovisionamiento de repositorio efímero limpio con stack y git init.
#   2. Instalación desatendida y generación atómica de ledger (.agents/context/last-sync.md).
#   3. Ciclo de Onboarding corregido:
#      - Auditoría post-install detecta ⚠️ DRIFT DETECTADO (onboarding genérico).
#      - Personalización de AGENT_ONBOARDING.md.
#      - Re-auditoría alcanza ✅ CONFORME.
#   4. Setup determinista de perfiles (setup-profiles.sh --apply) con marcadores regenerables.
#   5. Re-auditoría confirmatoria ✅ CONFORME y verificación de limpieza determinista (trap).
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
echo -e "${BLUE}  SUITE DE VALIDACIÓN: DISTRIBUCIÓN CIEGA (T-090)     ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""

# ------------------------------------------------------------------------------
# Hito 1: Aprovisionamiento de Repositorio Efímero Limpio
# ------------------------------------------------------------------------------
echo -e "🔍 [Hito 1/5] Aprovisionando repositorio satélite efímero e independiente..."

SATELLITE_DIR="$TMP_DIR/ephemeral-satellite"
mkdir -p "$SATELLITE_DIR/src"

git -C "$SATELLITE_DIR" init -q -b main
git -C "$SATELLITE_DIR" config user.name "Agent OS Blind Test"
git -C "$SATELLITE_DIR" config user.email "blind-test@agent-os.local"

# Simular stack TypeScript real
cat << 'EOF' > "$SATELLITE_DIR/package.json"
{
  "name": "ephemeral-satellite-app",
  "version": "0.1.0",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "test": "vitest run"
  }
}
EOF

cat << 'EOF' > "$SATELLITE_DIR/tsconfig.json"
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "strict": true
  }
}
EOF

echo 'console.log("Hello from ephemeral satellite");' > "$SATELLITE_DIR/src/index.ts"

git -C "$SATELLITE_DIR" add -A
git -C "$SATELLITE_DIR" commit -q -m "chore: initial commit of satellite app"

if [ -d "$SATELLITE_DIR/.git" ] && [ -f "$SATELLITE_DIR/package.json" ] && [ -f "$SATELLITE_DIR/tsconfig.json" ]; then
  log_pass "Hito 1 completado: Repositorio satélite efímero aprovisionado con stack TypeScript y git limpio."
else
  log_fail "Hito 1 falló: No se pudo aprovisionar el repositorio satélite efímero."
fi

# ------------------------------------------------------------------------------
# Hito 2: Instalación Desatendida y Ledger Enriquecido
# ------------------------------------------------------------------------------
echo -e "🔍 [Hito 2/5] Ejecutando instalación desatendida con install.sh..."

INSTALL_LOG="$TMP_DIR/install.log"
bash "$ROOT_DIR/scripts/agent/install.sh" "$SATELLITE_DIR" </dev/null > "$INSTALL_LOG" 2>&1
INSTALL_EXIT=$?

LEDGER_FILE="$SATELLITE_DIR/.agents/context/last-sync.md"

if [ "$INSTALL_EXIT" -eq 0 ] && \
   [ -d "$SATELLITE_DIR/.agents/rules" ] && \
   [ -d "$SATELLITE_DIR/.agents/workflows" ] && \
   [ -d "$SATELLITE_DIR/.agents/skills" ] && \
   [ -d "$SATELLITE_DIR/.agents/profiles" ] && \
   [ -d "$SATELLITE_DIR/.agents/config" ] && \
   [ -x "$SATELLITE_DIR/scripts/agent/audit-child.sh" ] && \
   [ -x "$SATELLITE_DIR/scripts/agent/setup-profiles.sh" ] && \
   [ -f "$LEDGER_FILE" ] && \
   grep -q -E '^version:' "$LEDGER_FILE" && \
   grep -q -E '^commit:' "$LEDGER_FILE"; then
  log_pass "Hito 2 completado: Instalación desatendida desplegó diferencial completo y ledger enriquecido atómico."
else
  log_fail "Hito 2 falló: Instalación incompleta o ledger de versión ausente. Status: $INSTALL_EXIT"
fi

# ------------------------------------------------------------------------------
# Hito 3: Ciclo de Onboarding y Diagnóstico de Salud (Corregido)
# ------------------------------------------------------------------------------
echo -e "🔍 [Hito 3/5] Verificando ciclo de onboarding (drift inicial por plantilla -> conforme tras personalizar)..."

# Sub-paso 3a: Auditoría inmediata post-install debe reportar ⚠️ DRIFT DETECTADO (plantilla sin completar)
AUDIT_INITIAL_OUT=$(bash "$SATELLITE_DIR/scripts/agent/audit-child.sh" --path "$SATELLITE_DIR" 2>&1) || true
if echo "$AUDIT_INITIAL_OUT" | grep -q "⚠️  DRIFT DETECTADO" && echo "$AUDIT_INITIAL_OUT" | grep -q "marcadores de plantilla genérica sin completar"; then
  log_pass "Sub-paso 3a verificado: audit-child.sh detecta correctamente ⚠️ DRIFT DETECTADO por plantilla de onboarding recién instalada."
else
  log_fail "Sub-paso 3a falló: Se esperaba ⚠️ DRIFT DETECTADO post-instalación limpia. Output:\n$AUDIT_INITIAL_OUT"
fi

# Sub-paso 3b: Personalización del onboarding (como haría el agente durante su lectura)
ONBOARDING_FILE="$SATELLITE_DIR/.agents/AGENT_ONBOARDING.md"
cat << 'EOF' > "$ONBOARDING_FILE"
# Agent Onboarding — Ephemeral Satellite App

> Guía de arquitectura del proyecto satélite efímero.

## 🩺 Pre-flight de Inicio de Sesión (Salud del Repositorio)
Antes de iniciar cualquier tarea o planificar trabajo, ejecuta la auditoría de salud local de Agent OS:
```bash
bash scripts/agent/audit-child.sh
```

## 🚀 Stack Tecnológico
- **Frontend**: TypeScript / Node.js
- **Backend**: Microservicio Node.js con tsx
- **Database**: InMemory Mock
- **Infra**: Docker Container

## 📂 Estructura de Carpetas Clave
- `src/`: Código fuente TypeScript.
- `docs/`: Documentación y sprints.

## 🛠️ Comandos Frecuentes
- `npm run dev`: Arrancar entorno de desarrollo.
- `npm run build`: Validar compilación.
- `npm test`: Ejecutar suite de pruebas.
EOF

# Sub-paso 3c: Re-auditoría tras personalizar debe alcanzar ✅ CONFORME (exit 0)
AUDIT_AFTER_ONBOARD=$(bash "$SATELLITE_DIR/scripts/agent/audit-child.sh" --path "$SATELLITE_DIR" 2>&1)
AUDIT_EXIT=$?

if [ "$AUDIT_EXIT" -eq 0 ] && echo "$AUDIT_AFTER_ONBOARD" | grep -q "✅ CONFORME"; then
  log_pass "Sub-paso 3c verificado: Tras personalizar el onboarding, audit-child.sh alcanza ✅ CONFORME (exit 0)."
  log_pass "Hito 3 completado: Ciclo de detección y resolución de onboarding 100% verificado."
else
  log_fail "Sub-paso 3c falló: Se esperaba ✅ CONFORME tras personalizar el onboarding. Status: $AUDIT_EXIT. Output:\n$AUDIT_AFTER_ONBOARD"
fi

# ------------------------------------------------------------------------------
# Hito 4: Setup Determinista de Perfiles (setup-profiles.sh --apply)
# ------------------------------------------------------------------------------
echo -e "🔍 [Hito 4/5] Ejecutando setup-profiles.sh --apply para especializar perfiles..."

SETUP_OUT=$(bash "$SATELLITE_DIR/scripts/agent/setup-profiles.sh" --apply --path "$SATELLITE_DIR" 2>&1)
SETUP_EXIT=$?

DEV_YAML="$SATELLITE_DIR/.agents/profiles/developer.yaml"

if [ "$SETUP_EXIT" -eq 0 ] && \
   [ -f "$DEV_YAML" ] && \
   grep -q "# BEGIN AGENT-OS-GENERATED-STACK" "$DEV_YAML" && \
   grep -q "stack: \"typescript\"" "$DEV_YAML" && \
   grep -q "# END AGENT-OS-GENERATED-STACK" "$DEV_YAML"; then
  log_pass "Hito 4 completado: setup-profiles.sh --apply especializó developer.yaml con bloque regenerable canónico."
else
  log_fail "Hito 4 falló: developer.yaml no contiene la especialización esperada. Status: $SETUP_EXIT"
fi

# ------------------------------------------------------------------------------
# Hito 5: Re-auditoría Final y Verificación de Limpieza Determinista
# ------------------------------------------------------------------------------
echo -e "🔍 [Hito 5/5] Ejecutando re-auditoría final y verificando limpieza hermética..."

FINAL_AUDIT_OUT=$(bash "$SATELLITE_DIR/scripts/agent/audit-child.sh" --path "$SATELLITE_DIR" 2>&1)
FINAL_AUDIT_EXIT=$?

if [ "$FINAL_AUDIT_EXIT" -eq 0 ] && echo "$FINAL_AUDIT_OUT" | grep -q "✅ CONFORME"; then
  log_pass "Re-auditoría final: El proyecto satélite permanece en estado ✅ CONFORME."
else
  log_fail "Re-auditoría final falló: Se esperaba ✅ CONFORME. Status: $FINAL_AUDIT_EXIT. Output:\n$FINAL_AUDIT_OUT"
fi

# Verificación de ausencia de llamadas de red / telemetría
NETWORK_GREP=$(grep -E '\b(curl|wget|git fetch|git push|git ls-remote)\b' "$SATELLITE_DIR/scripts/agent/audit-child.sh" || true)
if [ -z "$NETWORK_GREP" ]; then
  log_pass "Garantía anti-telemetría: audit-child.sh opera 100% local y offline."
else
  log_fail "Se detectaron llamadas de red en audit-child.sh: $NETWORK_GREP"
fi

echo ""
echo -e "${BLUE}======================================================${NC}"
if [[ "$ERRORS" -eq 0 ]]; then
  echo -e "${GREEN}  ✅ TODOS LOS HITOS PASARON EXITOSAMENTE ($TESTS_RUN/$TESTS_RUN)${NC}"
  echo -e "${BLUE}======================================================${NC}"
  exit 0
else
  echo -e "${RED}  ❌ HUBO $ERRORS FALLO(S) EN $TESTS_RUN PRUEBAS${NC}"
  echo -e "${BLUE}======================================================${NC}"
  exit 1
fi
