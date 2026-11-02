#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/lib/portable-timeout.sh — Ejecución con timeout portable (Linux + macOS)
# ==============================================================================
# Uso:
#   source "$(dirname "$0")/lib/portable-timeout.sh"
#   portable_timeout <segundos> <comando> [argumentos...]
#
# Variables de entorno:
#   PORTABLE_TIMEOUT_KILL_GRACE: Tiempo de gracia entre SIGTERM y SIGKILL (por defecto: 1s).
#
# Comportamiento:
#   - Si existe 'timeout' (GNU coreutils en Linux) o 'gtimeout' (macOS con coreutils), lo usa con escalado -k.
#   - Si no existe 'timeout', utiliza un wrapper determinista con python3 (dependencia base) con escalado a SIGKILL.
#   - Devuelve código 124 si termina tras SIGTERM, o 137 si requiere escalado forzoso a SIGKILL.
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

  local grace="${PORTABLE_TIMEOUT_KILL_GRACE:-1s}"
  grace="${grace%s}"

  if command -v timeout >/dev/null 2>&1; then
    timeout -k "${grace}s" "$duration" "$@"
    return $?
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout -k "${grace}s" "$duration" "$@"
    return $?
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c '
import sys, subprocess, os, signal

try:
    duration = float(sys.argv[1])
    kill_grace = float(sys.argv[2])
    cmd = sys.argv[3:]
    proc = subprocess.Popen(cmd, start_new_session=True)
    try:
        ret = proc.wait(timeout=duration)
        sys.exit(ret)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(proc.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        try:
            proc.wait(timeout=kill_grace)
            sys.exit(124)
        except subprocess.TimeoutExpired:
            try:
                os.killpg(proc.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            try:
                proc.wait(timeout=1.0)
            except Exception:
                pass
            sys.exit(137)
except Exception:
    sys.exit(1)
' "$duration" "$grace" "$@"
    return $?
  else
    # Fallback básico con subshell si ni timeout ni python3 estuviesen disponibles
    (
      "$@" &
      child=$!
      (
        sleep "$duration"
        kill -TERM "$child" 2>/dev/null || true
        sleep "$grace"
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
