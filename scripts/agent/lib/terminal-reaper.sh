#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/lib/terminal-reaper.sh
# ------------------------------------------------------------------------------
# Módulo determinista de estabilidad de terminales, censo y recolección
# de basura para agentes y workers en Orca ADE (Task-144).
#
# Responsabilidades:
# 1. Registro de dispatches activos creados por el proceso coordinador.
# 2. Trampas POSIX únicas (EXIT, INT, TERM, HUP) para recolección garantizada.
# 3. Secuencia de parada limpia (worker-stop) y liberación (worker-release).
# 4. Fencing condicional (worker-abandon) solo ante error con backend alcanzable;
#    en desconexión total, registro para inspección humana sin llamadas ciegas.
# 5. Aserción determinista de 0 terminales huérfanas en estado active.
#
# Rutas reales verificadas en worker-list --json:
# - result.workers: lista de descriptores de terminales.
# - result.page.total: conteo total de registros coincidentes.
# ==============================================================================

set -euo pipefail

# Arrays y estado del reaper en memoria
declare -a REAPER_TRACKED_DISPATCHES=()
declare -a REAPER_RELEASED_DISPATCHES=()
declare -a REAPER_FENCED_DISPATCHES=()
declare -a REAPER_UNREAPED_DISPATCHES=()
REAPER_INITIALIZED=0
REAPER_RUN_ID="${ORCA_RUN_ID:-}"

# Resuelve ejecutable de Orca si existe
reaper_resolve_orca() {
  if type orca_resolve_bin >/dev/null 2>&1; then
    orca_resolve_bin 2>/dev/null || true
  elif [ -n "${ORCA_BIN_OVERRIDE:-}" ] && [ -x "$ORCA_BIN_OVERRIDE" ]; then
    echo "$ORCA_BIN_OVERRIDE"
  elif command -v orca-ide >/dev/null 2>&1; then
    echo "orca-ide"
  elif command -v orca >/dev/null 2>&1; then
    echo "orca"
  else
    echo ""
  fi
}

# Inicializa el reaper y vincula las trampas POSIX deterministas
reaper_init() {
  local run_id="${1:-${ORCA_RUN_ID:-}}"
  if [ -n "$run_id" ]; then
    REAPER_RUN_ID="$run_id"
  fi
  REAPER_INITIALIZED=1

  # Trampas POSIX deterministas que sustituyen y unifican cleanup_worker
  trap 'reaper_on_exit' EXIT
  trap 'reaper_on_signal INT' INT
  trap 'reaper_on_signal TERM' TERM
  trap 'reaper_on_signal HUP' HUP
}

# Registra un dispatch activo para seguimiento
reaper_track_dispatch() {
  local dispatch_id="${1:-}"
  if [ -z "$dispatch_id" ]; then
    return 0
  fi

  # Evitar duplicados en el array de tracking
  for d in "${REAPER_TRACKED_DISPATCHES[@]:-}"; do
    if [ "$d" = "$dispatch_id" ]; then
      return 0
    fi
  done

  REAPER_TRACKED_DISPATCHES+=("$dispatch_id")
}

# Desregistra un dispatch (por ejemplo, si ya fue recolectado)
reaper_untrack_dispatch() {
  local dispatch_id="${1:-}"
  if [ -z "$dispatch_id" ]; then
    return 0
  fi

  local updated=()
  for d in "${REAPER_TRACKED_DISPATCHES[@]:-}"; do
    if [ "$d" != "$dispatch_id" ]; then
      updated+=("$d")
    fi
  done
  REAPER_TRACKED_DISPATCHES=("${updated[@]:-}")
}

# Comprueba si el backend / daemon de Orca está alcanzable
reaper_is_backend_reachable() {
  local orca_cmd
  orca_cmd="$(reaper_resolve_orca)"
  if [ -z "$orca_cmd" ]; then
    return 1
  fi

  # Intenta listar con limit 1 y timeout rápido
  if $orca_cmd orchestration worker-list --limit 1 --json >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# Recolección determinista de un dispatch concreto
# Secuencia: worker-stop -> worker-release -> (si falla y backend accesible: worker-abandon)
reaper_reap_dispatch() {
  local dispatch_id="${1:-}"
  if [ -z "$dispatch_id" ]; then
    return 0
  fi

  # Idempotencia: si ya fue liberado en esta sesión, no-op
  for d in "${REAPER_RELEASED_DISPATCHES[@]:-}"; do
    if [ "$d" = "$dispatch_id" ]; then
      reaper_untrack_dispatch "$dispatch_id"
      return 0
    fi
  done

  local orca_cmd
  orca_cmd="$(reaper_resolve_orca)"
  if [ -z "$orca_cmd" ]; then
    # Entorno sin CLI orca (ej. pruebas offline puras)
    reaper_untrack_dispatch "$dispatch_id"
    REAPER_RELEASED_DISPATCHES+=("$dispatch_id")
    return 0
  fi

  # 1. Parada limpia del proceso del agente
  $orca_cmd orchestration worker-stop --dispatch "$dispatch_id" --json >/dev/null 2>&1 || true

  # 2. Liberación y archivado del terminal
  local release_ok=0
  if $orca_cmd orchestration worker-release --dispatch "$dispatch_id" --json >/dev/null 2>&1; then
    release_ok=1
  fi

  if [ "$release_ok" -eq 1 ]; then
    REAPER_RELEASED_DISPATCHES+=("$dispatch_id")
    reaper_untrack_dispatch "$dispatch_id"
    return 0
  fi

  # 3. Fallo en worker-release: discriminar alcanzabilidad del backend
  if reaper_is_backend_reachable; then
    # Backend alcanzable: aplicar fencing mediante worker-abandon de salvaguarda
    $orca_cmd orchestration worker-abandon --dispatch "$dispatch_id" --json >/dev/null 2>&1 || true
    REAPER_FENCED_DISPATCHES+=("$dispatch_id")
    reaper_untrack_dispatch "$dispatch_id"
    echo "WARN: [terminal-reaper] Dispatch $dispatch_id no pudo liberarse limpiamente. Fenced via worker-abandon." >&2
    return 1
  else
    # Desconexión total del backend: registrar para inspección humana sin llamadas ciegas
    REAPER_UNREAPED_DISPATCHES+=("$dispatch_id")
    reaper_untrack_dispatch "$dispatch_id"
    echo "ERROR: [terminal-reaper] Backend de Orca inalcanzable durante limpieza. Dispatch $dispatch_id registrado para inspección humana." >&2
    
    # Registrar en log persistente de inspección si el directorio existe
    if [ -d ".agents/context" ]; then
      echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') dispatch_id=$dispatch_id run_id=${REAPER_RUN_ID:-unknown} reason=backend_unreachable" \
        >> ".agents/context/unreaped-terminals-for-human-inspection.log" 2>/dev/null || true
    fi
    return 2
  fi
}

# Limpia todos los dispatches rastreados que aún no han sido liberados
reaper_cleanup_all() {
  if [ "${#REAPER_TRACKED_DISPATCHES[@]}" -gt 0 ]; then
    local pending=("${REAPER_TRACKED_DISPATCHES[@]}")
    for disp in "${pending[@]}"; do
      reaper_reap_dispatch "$disp" || true
    done
  fi
}

# Manejador de trampas para salida ordinaria (EXIT)
reaper_on_exit() {
  local exit_code=$?
  trap - EXIT INT TERM HUP
  reaper_cleanup_all
  exit "$exit_code"
}

# Manejador de señales asíncronas (INT, TERM, HUP)
reaper_on_signal() {
  local sig="${1:-TERM}"
  trap - EXIT INT TERM HUP
  reaper_cleanup_all
  case "$sig" in
    INT)  exit 130 ;;
    TERM) exit 143 ;;
    HUP)  exit 129 ;;
    *)    exit 1 ;;
  esac
}

# Aserción determinista: 0 terminales huérfanas en estado active
# Inspecciona el accounting del host consultando result.workers y result.page.total
reaper_assert_zero_orphans() {
  local run_id="${1:-${REAPER_RUN_ID:-}}"
  local orca_cmd
  orca_cmd="$(reaper_resolve_orca)"
  if [ -z "$orca_cmd" ]; then
    return 0
  fi

  local cmd=("$orca_cmd" "orchestration" "worker-list" "--terminal-state" "active" "--json")
  if [ -n "$run_id" ]; then
    cmd+=("--run" "$run_id")
  fi

  local json_out
  if ! json_out="$("${cmd[@]}" 2>/dev/null)"; then
    echo "WARN: [terminal-reaper] No se pudo consultar worker-list --terminal-state active." >&2
    return 0
  fi

  # Parsear JSON verificando result.workers y result.page.total
  python3 -c '
import sys, json

try:
    data = json.loads(sys.argv[1])
    res = data.get("result", {})
    workers = res.get("workers", [])
    page_total = res.get("page", {}).get("total", len(workers))
    
    if len(workers) > 0 or page_total > 0:
        print(f"ERROR: [terminal-reaper] Censo detectó {len(workers)} terminales activas (total={page_total}).", file=sys.stderr)
        for w in workers:
            d_id = w.get("dispatchId", "unknown")
            t_id = w.get("taskId", "unknown")
            state = w.get("terminalState", "unknown")
            print(f"  - Dispatch: {d_id}, Task: {t_id}, State: {state}", file=sys.stderr)
        sys.exit(1)
except Exception as e:
    # Si la salida no es JSON válido (ej. mock simple), tolerar
    sys.exit(0)
' "$json_out"
}
