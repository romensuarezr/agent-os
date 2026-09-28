#!/usr/bin/env bash
# check-lazy-planning.sh — Verifica violaciones de lazy-planning en la sesión activa
# Uso: bash scripts/agent/check-lazy-planning.sh [T-XXX]

set -euo pipefail

for cmd in git grep; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "❌ Error: Dependencia requerida '$cmd' no encontrada." >&2
    echo "💡 Guía: Instálala mediante: apt-get install -y $cmd (Linux) o brew install $cmd (macOS)." >&2
    exit 1
  }
done

ROOT="$(git rev-parse --show-toplevel)"
LOCK="$ROOT/.agent-session.lock"
TASK_ID="${1:-}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 CHECK LAZY-PLANNING"
[ -n "$TASK_ID" ] && echo "    Tarea: $TASK_ID"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 1. Estado de sesión ──────────────────────────────────────────────────────
if [ ! -f "$LOCK" ]; then
  echo "ℹ️  No hay sesión activa (.agent-session.lock no encontrado)."
  echo "   Este script es más útil durante o justo después de /session-start."
else
  echo "🔒 Sesión activa:"
  cat "$LOCK"
fi
echo ""

# ── 2. Rama activa y commits recientes ───────────────────────────────────────
BRANCH=$(git -C "$ROOT" branch --show-current)
echo "🌿 Rama activa: $BRANCH"
echo ""
echo "📜 Últimos 5 commits:"
git -C "$ROOT" log -5 --oneline
echo ""

# ── 3. Campo de auditoría en implementation_plan.md ──────────────────────────
IMPLEMENTATION_PLAN="$ROOT/implementation_plan.md"
if [ -f "$IMPLEMENTATION_PLAN" ]; then
  echo "📋 Campo de auditoría (implementation_plan.md):"
  echo "---"
  grep -A 6 "ARCHIVOS LEÍDOS" "$IMPLEMENTATION_PLAN" 2>/dev/null || echo "   (campo no encontrado)"
  echo "---"
else
  echo "⚠️  implementation_plan.md no encontrado — el agente puede no haber generado el plan todavía."
fi
echo ""

# ── 4. Task file (si se pasó T-XXX) ──────────────────────────────────────────
if [ -n "$TASK_ID" ]; then
  TASK_FILE="$ROOT/.agents/tasks/$TASK_ID.md"
  ARCHIVED_FILE="$ROOT/.agents/tasks/_archived/$TASK_ID.md"
  if [ -f "$TASK_FILE" ]; then
    echo "📄 Task file: $TASK_FILE"
  elif [ -f "$ARCHIVED_FILE" ]; then
    echo "📄 Task file (archivado): $ARCHIVED_FILE"
    TASK_FILE="$ARCHIVED_FILE"
  else
    echo "⚠️  Task file no encontrado para $TASK_ID — verifica el ID."
    TASK_FILE=""
  fi
  echo ""
fi

# ── 5. Guía de verificación manual ───────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧭 VERIFICACIÓN MANUAL — qué buscar en el log del agente:"
echo ""
echo "  Archivos PROHIBIDOS antes de APROBADO:"
echo "    ❌ 'Viewed src/...' o 'Viewed lib/...'     → código fuente"
echo "    ❌ 'Viewed SKILL.md' o 'Viewed _template.md' → docs de referencia"
echo "    ❌ 'Viewed [cualquier .md fuera de task/sprint/research]'"
echo "    ❌ 'Searched for ...' en src/ o lib/       → búsqueda en código"
echo "    ❌ 'Listed directory src/' o subdirectorios"
echo "    ✅ 'test -f ...' sin Viewed                → solo existencia (permitido)"
echo ""
echo "  Checkpoint en el log:"
echo "    Busca el bloque: 📋 CHECKPOINT LAZY-PLANNING — T-XXX"
echo "    Si NO aparece → checkpoint ausente (violación)"
echo "    Si aparece con Opción A pero hay Viewed prohibidos → mentira declarativa"
echo ""
echo "  Campo de auditoría en el plan:"
echo "    Busca: 📂 ARCHIVOS LEÍDOS ANTES DE ESTA APROBACIÓN"
echo "    Debe ser copia textual exacta del checkpoint"
echo "    Si difiere en cualquier palabra → violación doble"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚡ FRASES EXACTAS PARA SEÑALAR AL AGENTE:"
echo ""
echo "  Checkpoint ausente:    'Checkpoint ausente. Repite Fase 2.5 con formato exacto.'"
echo "  Formato incorrecto:    'Checkpoint inválido. Usa formato exacto.'"
echo "  Inconsistencia:        'Violación doble. Corrige para que sea idéntico.'"
echo "  Mentira declarativa:   'Violación grave de protocolo. Aborta y reinicia /session-start.'"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
