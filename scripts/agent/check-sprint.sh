#!/bin/bash
# check-sprint.sh — Contexto determinista para /sprint-planning
# Uso: bash scripts/agent/check-sprint.sh
# Devuelve: ruta ROADMAP, estado sprint anterior, spillover, inbox, git log, system check.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SPRINTS_DIR="$ROOT/docs/sprints"
INBOX_DIR="$ROOT/docs/idea-inbox"
ROADMAP_PATH=""
if [ -f "$ROOT/roadmap.md" ]; then
  ROADMAP_PATH="$ROOT/roadmap.md"
elif [ -f "$ROOT/ROADMAP.md" ]; then
  ROADMAP_PATH="$ROOT/ROADMAP.md"
fi

echo "=== SPRINT CONTEXT ==="

if [ -n "$ROADMAP_PATH" ]; then
  PENDING_GLOBAL=$(grep -c "^- \\[ \\]" "$ROADMAP_PATH" 2>/dev/null || echo "0")
  echo "ROADMAP: $ROADMAP_PATH (✅ Detectado — $PENDING_GLOBAL tareas pendientes)"
else
  echo "ROADMAP: ❌ CRÍTICO — NO ENCONTRADO (debe ser roadmap.md o ROADMAP.md)"
  echo "ACTION_REQUIRED: Crea roadmap.md en la raíz antes de continuar."
  exit 1
fi

# 2. Sprint más reciente (excluye research y _archived)
LAST_SPRINT=$(find "$SPRINTS_DIR" -name "sprint-[0-9][0-9].md" \
  | grep -v -E "research|_archived" | sort -V | tail -1 || true)

if [ -z "$LAST_SPRINT" ]; then
  echo "SPRINT_ACTUAL: ninguno"
  echo "SPRINT_SIGUIENTE: sprint-01"
  echo "SPRINT_MODE: INICIALIZACIÓN"
else
  SPRINT_NAME=$(basename "$LAST_SPRINT" .md)
  SPRINT_NUM=$(echo "$SPRINT_NAME" | grep -oE '[0-9]+$')
  NEXT_NUM=$(printf "%02d" $((10#$SPRINT_NUM + 1)))

  echo "SPRINT_ACTUAL: $LAST_SPRINT"
  echo "SPRINT_SIGUIENTE: sprint-$NEXT_NUM"

  # Conteo real de tareas completadas vs total
  TOTAL=$(grep -c "^| T-" "$LAST_SPRINT" 2>/dev/null || echo "0")
  DONE=$(grep "^| T-" "$LAST_SPRINT" 2>/dev/null | grep -cE "✅|🟢 Completada" || echo "0")
  if [ "$DONE" -eq "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
    echo "SPRINT_ESTADO: COMPLETADO ($DONE/$TOTAL ✅)"
  elif [ "$DONE" -gt 0 ]; then
    echo "SPRINT_ESTADO: PARCIAL ($DONE/$TOTAL completadas)"
  else
    echo "SPRINT_ESTADO: ACTIVO/ABIERTO ($DONE/$TOTAL completadas)"
  fi

  # 3. Spillover — tareas no completadas
  echo ""
  echo "=== SPILLOVER (tareas no completadas) ==="
  PENDIENTES=$(grep "^| T-" "$LAST_SPRINT" 2>/dev/null \
    | grep -vE "✅|🟢 Completada" || true)
  if [ -z "$PENDIENTES" ]; then
    echo "(Ninguna — sprint anterior limpio ✅)"
  else
    echo "$PENDIENTES"
    echo "⚠️  INSTRUCCIÓN: Decide si arrastrar al nuevo sprint o devolver al backlog."
  fi
fi

# 4. Idea inbox
echo ""
echo "=== IDEA INBOX ==="
if [ -d "$INBOX_DIR" ]; then
  mapfile -t INBOX_FILES < <(find "$INBOX_DIR" -maxdepth 1 -name "*.md" -type f ! -path "*/_*" 2>/dev/null | sort)
  if [ ${#INBOX_FILES[@]} -eq 0 ]; then
    echo "(Vacío)"
  else
    for f in "${INBOX_FILES[@]}"; do
      COUNT=$(grep -c "^### " "$f" 2>/dev/null || echo "0")
      echo "📄 $(basename "$f") ($COUNT ideas)"
      grep "^### " "$f" 2>/dev/null | sed 's/^### /  ↳ /' || true
    done
  fi
else
  echo "(Directorio no existe)"
fi

# 5. Git log reciente
echo ""
echo "=== GIT LOG (últimos 10 commits) ==="
git -C "$ROOT" log --oneline -10 2>/dev/null || echo "(no disponible)"

# 6. System check
echo ""
echo "=== SYSTEM CHECK ==="
LOCK="$ROOT/.agent-session.lock"
WARNINGS=0

if [ -f "$LOCK" ]; then
  if grep -q '"status"[[:space:]]*:[[:space:]]*"active"' "$LOCK" 2>/dev/null; then
    echo "⚠️  ALERTA: Sesión activa en .agent-session.lock — ejecuta check-session.sh primero"
    WARNINGS=$((WARNINGS + 1))
  fi
fi

UNSTAGED=$(git -C "$ROOT" diff --name-only 2>/dev/null | grep '^src/' | head -3 || true)
if [ -n "$UNSTAGED" ]; then
  echo "⚠️  GIT: Cambios sin commitear en src/:"
  echo "$UNSTAGED" | sed 's/^/   /'
  WARNINGS=$((WARNINGS + 1))
fi

if [ "$WARNINGS" -eq 0 ]; then
  echo "(Sistema limpio ✅)"
fi

echo ""
echo "=== END CONTEXT ==="
