#!/usr/bin/env bash
# audit-mvp-tracker.sh — Audita los criterios del MVP-TRACKER contra el código real

set -euo pipefail

for cmd in git grep wc cut; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "❌ Error: Dependencia requerida '$cmd' no encontrada." >&2
    echo "💡 Guía: Instálala mediante: apt-get install -y $cmd (Linux) o brew install $cmd (macOS)." >&2
    exit 1
  }
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/lib/find-tracker.sh" ]; then
  source "$SCRIPT_DIR/lib/find-tracker.sh"
else
  echo "❌ No se encuentra el helper lib/find-tracker.sh"
  exit 1
fi

ROOT="$(git rev-parse --show-toplevel)"
SRC="$ROOT/src"
TRACKER="$(find_tracker "$ROOT")"

if [ -z "$TRACKER" ]; then
  # Por defecto si no existe ninguno
  TRACKER="$ROOT/docs/mvp-tracker.md"
fi

DIGEST_SCRIPT="$ROOT/scripts/agent/generate-digest.sh"
MODE="fast"

# ── Parsear argumentos ────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --fast)   MODE="fast";   shift ;;
    --digest) MODE="digest"; shift ;;
    *) echo "❌ Argumento desconocido: $1"; echo "Uso: $0 [--fast|--digest]"; exit 1 ;;
  esac
done

# ── Verificar prerequisitos ───────────────────────────────────────────────────
if [ ! -f "$TRACKER" ]; then
  echo "❌ No se encuentra $TRACKER"
  exit 1
fi

# ── Tabla declarativa de símbolos auditables ──────────────────────────────────
# Formato: "C#:descripción|SÍMBOLO|SCOPE_EN_SRC"
# SCOPE vacío → busca en src/ completo
# SCOPE con valor → busca SOLO en src/SCOPE (detecta falta de integración real)
#
# Regla clave: si un componente puede existir en components/ pero necesita
# estar *usado* en pages/ para considerarse integrado, usa SCOPE="pages".
AUDIT_SYMBOLS=(
  # "C1:Ejemplo de criterio|SímboloAGrear|"
)

# ── Colores (degradan graciosamente si no hay tty) ────────────────────────────
# shellcheck disable=SC2034
if [ -t 1 ]; then
  RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
  CYAN='\033[0;36m'; RESET='\033[0m'
else
  RED=''; YELLOW=''; GREEN=''; CYAN=''; RESET=''
fi

echo ""
echo "=== MVP TRACKER AUDIT ==="
echo "Modo: $MODE | $(date '+%Y-%m-%d %H:%M')"
echo "Tracker: $TRACKER"
echo ""
echo "=== VERIFICACIÓN DE SÍMBOLOS ==="
echo ""

WARNINGS=()
VERIFIED=0
TOTAL_CHECKS=${#AUDIT_SYMBOLS[@]}
DIGEST_SCOPES=()  # Subcarpetas únicas a digerir si MODE=digest

for ENTRY in "${AUDIT_SYMBOLS[@]}"; do
  # Parsear los tres campos
  CAPACIDAD=$(echo "$ENTRY" | cut -d'|' -f1)
  SYMBOL_RAW=$(echo "$ENTRY" | cut -d'|' -f2)
  SCOPE=$(echo "$ENTRY" | cut -d'|' -f3)

  # Determinar dónde buscar
  if [ -n "$SCOPE" ]; then
    SEARCH_PATH="$SRC/$SCOPE"
    SCOPE_LABEL="src/$SCOPE/"
    DIGEST_KEY="src/$SCOPE"
  else
    SEARCH_PATH="$SRC"
    SCOPE_LABEL="src/"
    DIGEST_KEY="src"
  fi

  # Acumular scopes únicos para el digest
  # shellcheck disable=SC2076
  if [[ ! " ${DIGEST_SCOPES[*]:-} " =~ " ${DIGEST_KEY} " ]]; then
    DIGEST_SCOPES+=("$DIGEST_KEY")
  fi

  # Ejecutar git grep (--extended-regexp para soportar \| como OR)
  FOUND=$(git -C "$ROOT" grep -rlE "$SYMBOL_RAW" -- "$SEARCH_PATH" 2>/dev/null || true)

  if [ -n "$FOUND" ]; then
    FILE_COUNT=$(echo "$FOUND" | wc -l | tr -d ' ')
    echo -e "${GREEN}✅ VERIFICADO${RESET}   ${CAPACIDAD}"
    echo   "             Símbolo: '$SYMBOL_RAW' → $FILE_COUNT archivo(s) en $SCOPE_LABEL"
    if [ -n "$SCOPE" ]; then
      echo   "   🔍 REVISAR MANUAL: verificar que la integración es correcta (no solo importado)"
    fi
    VERIFIED=$((VERIFIED + 1))
  else
    echo -e "${YELLOW}⚠️  FALSO POSITIVO${RESET} ${CAPACIDAD}"
    echo   "             Símbolo: '$SYMBOL_RAW' NO encontrado en $SCOPE_LABEL"
    echo   "             → Criterio posiblemente marcado [x] antes de implementarse"
    WARNINGS+=("$CAPACIDAD")
  fi
  echo ""
done

# ── AUDIT SUMMARY ─────────────────────────────────────────────────────────────
echo "=== AUDIT SUMMARY ==="
echo "Verificados:      $VERIFIED / $TOTAL_CHECKS"
echo "Falsos positivos: ${#WARNINGS[@]}"
echo ""

if [ ${#WARNINGS[@]} -eq 0 ]; then
  echo -e "${GREEN}✅ Sin advertencias. Todos los símbolos auditables están presentes en el código.${RESET}"
  echo "   Recuerda que ✅ en símbolo ≠ ✅ en calidad de integración."
  echo "   Usa --digest para generar contexto LLM de revisión profunda."
else
  echo -e "${YELLOW}⚠️  ADVERTENCIAS (${#WARNINGS[@]}):${RESET}"
  for W in "${WARNINGS[@]}"; do
    echo "   • $W"
  done
  echo ""
  echo "   Antes de actualizar porcentajes en MVP-TRACKER.md:"
  echo "   1. Revisa si el criterio está realmente implementado o marcado por error"
  echo "   2. Corrige el criterio ([x] → [ ]) o implementa el símbolo faltante"
  echo "   3. Vuelve a correr este script para confirmar"
  echo ""
  echo "   Para contexto LLM profundo: bash scripts/agent/audit-mvp-tracker.sh --digest"
fi

echo ""
echo "=== END AUDIT ==="

# ── Modo --digest: generar digests por cada scope único ──────────────────────
if [ "$MODE" = "digest" ]; then
  echo ""
  echo "=== GENERANDO DIGESTS LLM ==="

  if [ ! -f "$DIGEST_SCRIPT" ]; then
    echo "❌ No encontrado: $DIGEST_SCRIPT"
    echo "   El modo --digest requiere generate-digest.sh en scripts/agent/"
    exit 1
  fi

  DIGESTS_GENERADOS=()
  for SCOPE_KEY in "${DIGEST_SCOPES[@]}"; do
    echo ""
    echo "⚙️  Generando digest para: $SCOPE_KEY"
    if bash "$DIGEST_SCRIPT" --filter "$SCOPE_KEY" 2>&1; then
      DIGESTS_GENERADOS+=("$SCOPE_KEY")
    else
      echo "⚠️  Fallo al generar digest para $SCOPE_KEY — continua con el siguiente"
    fi
  done

  echo ""
  echo "=== INSTRUCCIONES DE REVISIÓN MANUAL ==="
  echo ""
  echo "Se generaron ${#DIGESTS_GENERADOS[@]} digest(s) en docs/llm-context/"
  echo "Usa el digest junto con los criterios del tracker para revisar:"
  echo ""
  echo "Criterios que requieren revisión de integración (símbolo encontrado pero no verificado):"
  for ENTRY in "${AUDIT_SYMBOLS[@]}"; do
    CAPACIDAD=$(echo "$ENTRY" | cut -d'|' -f1)
    SCOPE=$(echo "$ENTRY" | cut -d'|' -f3)
    if [ -n "$SCOPE" ]; then
      echo "   🔍 $CAPACIDAD"
      echo "      Pregunta: ¿El símbolo se usa en src/$SCOPE/ con el comportamiento esperado?"
      echo "      ¿Está conectado al contexto de comunidad (comunidadId) correctamente?"
    fi
  done

  if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo ""
    echo "Criterios con falso positivo (símbolo ausente — no digerir, corregir primero):"
    for W in "${WARNINGS[@]}"; do
      echo "   ❌ $W"
    done
  fi

  echo ""
  echo "   Para actualizar el tracker tras la revisión:"
  echo "   bash scripts/agent/update-mvp-tracker.sh"
  echo ""
  echo "=== END DIGEST ==="
fi
