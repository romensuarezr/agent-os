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
#   - Prioridad 1: Utiliza wrapper determinista con python3 para aislamiento de grupo de procesos
#     (start_new_session=True) y matanza garantizada del árbol completo (os.killpg) evitando huérfanos.
#   - Fallback 2: Si no existe python3, utiliza 'timeout' (GNU) o 'gtimeout' (macOS) con escalado -k.
#   - Fallback 3: Subshell básica en bash con traps.
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

  if command -v python3 >/dev/null 2>&1; then
    python3 -c '
import sys, subprocess, os, signal, time

try:
    duration = float(sys.argv[1])
    kill_grace = float(sys.argv[2])
    cmd = sys.argv[3:]
    # start_new_session=True aísla el comando en un nuevo PGID
    proc = subprocess.Popen(cmd, start_new_session=True)
    try:
        ret = proc.wait(timeout=duration)
        if ret < 0:
            sys.exit(128 + abs(ret))
        sys.exit(ret)
    except subprocess.TimeoutExpired:
        # 1. Enviar SIGTERM a todo el grupo de procesos
        try:
            os.killpg(proc.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        
        # Esperar hasta kill_grace
        deadline = time.time() + kill_grace
        terminated = False
        while time.time() < deadline:
            try:
                os.killpg(proc.pid, 0)
                time.sleep(0.05)
            except ProcessLookupError:
                terminated = True
                break
            except Exception:
                break
        
        if not terminated:
            # 2. Forzar SIGKILL a todo el grupo de procesos para erradicar huérfanos
            try:
                os.killpg(proc.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            try:
                proc.wait(timeout=0.5)
            except Exception:
                pass
            sys.exit(137)
        else:
            try:
                proc.wait(timeout=0.5)
            except Exception:
                pass
            sys.exit(124)
except Exception:
    sys.exit(1)
' "$duration" "$grace" "$@"
    return $?
  elif command -v timeout >/dev/null 2>&1; then
    timeout -k "${grace}s" "$duration" "$@"
    return $?
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout -k "${grace}s" "$duration" "$@"
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
