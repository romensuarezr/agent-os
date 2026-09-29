#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/lib/portable-timeout.sh — Ejecución con timeout portable (Linux + macOS)
# ==============================================================================
# Uso:
#   source "$(dirname "$0")/lib/portable-timeout.sh"
#   portable_timeout <segundos> <comando> [argumentos...]
#
# Comportamiento:
#   - Si existe 'timeout' (GNU coreutils en Linux) o 'gtimeout' (macOS con coreutils), lo usa directamente.
#   - Si no existe 'timeout', utiliza un wrapper determinista con python3 (dependencia base).
#   - Devuelve código 124 ante timeout, respetando la convención estándar de GNU timeout.
# ==============================================================================

portable_timeout() {
  local duration="${1:-}"
  if [[ -z "$duration" ]]; then
    echo "❌ ERROR: portable_timeout requiere duración en segundos como primer argumento." >&2
    return 1
  fi
  shift

  # Normalizar sufijo opcional 's' (ej: '3s' -> '3')
  duration="${duration%s}"

  if command -v timeout >/dev/null 2>&1; then
    timeout "$duration" "$@"
    return $?
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$duration" "$@"
    return $?
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c '
import sys, subprocess
try:
    duration = float(sys.argv[1])
    cmd = sys.argv[2:]
    res = subprocess.run(cmd, timeout=duration)
    sys.exit(res.returncode)
except subprocess.TimeoutExpired:
    sys.exit(124)
except Exception:
    sys.exit(1)
' "$duration" "$@"
    return $?
  else
    # Fallback básico con subshell si ni timeout ni python3 estuviesen disponibles
    (
      "$@" &
      child=$!
      (
        sleep "$duration"
        kill -TERM "$child" 2>/dev/null || true
        sleep 0.2
        kill -KILL "$child" 2>/dev/null || true
      ) 2>/dev/null &
      watcher=$!
      wait "$child" 2>/dev/null
      ret=$?
      kill -TERM "$watcher" 2>/dev/null || true
      exit $ret
    )
    return $?
  fi
}
