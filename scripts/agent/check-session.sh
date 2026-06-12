#!/bin/bash
# check-session.sh — Detecta si hay una sesión de Antigravity abierta.
# Uso: bash scripts/agent/check-session.sh
# Salida:
#   exit 0 + "NO_ACTIVE_SESSION" → no hay sesión abierta, seguro proceder
#   exit 1 + JSON del lock       → hay sesión sin cerrar, activar Modo Rescate
#   exit 0 + "WARNING: ..."      → no hay lock pero hay cambios en src/ sin commitear

LOCK_FILE=".agent-session.lock"

if [ -f "$LOCK_FILE" ]; then
  # Verificar que el archivo no es la plantilla comentada (status = "template")
  STATUS=$(grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' "$LOCK_FILE" | grep -o '"[^"]*"$' | tr -d '"')
  if [ "$STATUS" = "template" ] || [ -z "$STATUS" ]; then
    echo "NO_ACTIVE_SESSION"
    exit 0
  fi
  cat "$LOCK_FILE"
  exit 1
else
  # Sin lock activo: comprobar si hay cambios en src/ sin commitear
  # Esto puede indicar que el agente actuó sin haber recibido APROBADO
  if git rev-parse --git-dir > /dev/null 2>&1; then
    UNSTAGED=$(git diff --name-only 2>/dev/null | grep '^src/' | head -5)
    STAGED=$(git diff --cached --name-only 2>/dev/null | grep '^src/' | head -5)
    if [ -n "$UNSTAGED" ] || [ -n "$STAGED" ]; then
      echo "WARNING: Hay cambios en src/ sin lock activo — el agente puede haber actuado sin aprobación."
      echo "Archivos afectados:"
      [ -n "$UNSTAGED" ] && echo "  Sin stagear: $UNSTAGED"
      [ -n "$STAGED" ]   && echo "  Stageados:   $STAGED"
      echo "Revisa con 'git diff' antes de continuar."
      echo "---"
    fi
  fi
  echo "NO_ACTIVE_SESSION"
  exit 0
fi
