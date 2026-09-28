#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/lib/date-utils.sh — Utilidades de fecha portables (Linux + macOS)
# ==============================================================================

portable_iso_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

portable_epoch() {
  local date_str="${1:-}"
  if [[ -z "$date_str" ]]; then
    date +%s
    return 0
  fi

  # Fallback universal y portable via python3
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import datetime, sys
val = '$date_str'.strip().rstrip('Z')
for fmt in ('%Y-%m-%d', '%Y-%m-%dT%H:%M:%S', '%Y-%m-%d %H:%M:%S'):
    try:
        dt = datetime.datetime.strptime(val, fmt)
        print(int(dt.replace(tzinfo=datetime.timezone.utc).timestamp()))
        sys.exit(0)
    except Exception:
        pass
sys.exit(1)
" 2>/dev/null && return 0
  fi

  echo 0
}

portable_week_num() {
  local date_str="${1:-}"
  if [[ -z "$date_str" ]]; then
    date +%Y-W%V
    return 0
  fi

  # Fallback universal y portable via python3
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import datetime
try:
    d = datetime.date.fromisoformat('$date_str')
    iso = d.isocalendar()
    print(f'{iso[0]}-W{iso[1]:02d}')
except Exception:
    pass
" 2>/dev/null && return 0
  fi

  echo "unknown"
}
