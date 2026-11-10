#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/check-tooling-updates.sh — Agent OS
# Sonda determinista de actualización de herramientas multi-registro ($0 tokens)
#
# Consulta registros oficiales (npm, GitHub releases, PyPI) con mapeo de fuentes
# verídicas, normalización semver y degradación limpia ante cuotas (429/403) u offline.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || pwd)"

if [ -f "$SCRIPT_DIR/lib/cli-help.sh" ]; then
  source "$SCRIPT_DIR/lib/cli-help.sh"
fi

SHOW_HELP=false
TARGET_TOOL=""
CHECK_MODE=false
JSON_OUTPUT=false

for arg in "$@"; do
  if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
    SHOW_HELP=true
    break
  fi
done

if [ "$SHOW_HELP" = true ]; then
  if type show_help >/dev/null 2>&1; then
    show_help "check-tooling-updates.sh" \
      "bash scripts/agent/check-tooling-updates.sh [--tool <nombre>] [--check] [--json]" \
      "Inspecciona de forma determinista las versiones disponibles de las herramientas de la flota en registros oficiales (npm, GitHub, PyPI)." \
      "--tool <nombre>   Filtra la inspección a una herramienta concreta (ej: opencode, hermes, orca, infisical)." \
      "--check           Modo auditoría: devuelve exit code 1 si hay actualizaciones disponibles, 2 ante error/rate limit, 0 si todo está al día." \
      "--json            Emite el informe estructurado en formato JSON." \
      "ejemplo: bash scripts/agent/check-tooling-updates.sh" \
      "ejemplo: bash scripts/agent/check-tooling-updates.sh --tool opencode --json" \
      "ejemplo: bash scripts/agent/check-tooling-updates.sh --check"
  else
    echo "Uso: bash scripts/agent/check-tooling-updates.sh [--tool <nombre>] [--check] [--json] [-h|--help]"
    exit 0
  fi
fi

while [ $# -gt 0 ]; do
  case "$1" in
    --tool)
      TARGET_TOOL="${2:-}"
      shift 2
      ;;
    --check)
      CHECK_MODE=true
      shift
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    -h|--help)
      exit 0
      ;;
    *)
      echo "❌ Parámetro desconocido: $1" >&2
      echo "💡 Ejecuta con --help para ver las opciones disponibles." >&2
      exit 64
      ;;
  esac
done

# ------------------------------------------------------------------------------
# Detección de versiones instaladas o declaradas en la flota
# ------------------------------------------------------------------------------
extract_semver() {
  local text="$1"
  # Extrae la primera ocurrencia de X.Y.Z o vX.Y.Z
  echo "$text" | grep -oE 'v?[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 | tr -d 'v[:space:]'
}

detect_installed_version() {
  local tool="$1"
  local ver=""

  case "$tool" in
    opencode)
      if command -v opencode >/dev/null 2>&1; then
        ver="$(extract_semver "$(opencode --version 2>/dev/null || true)")"
      fi
      if [ -z "$ver" ] && [ -f "$ROOT_DIR/.agents/config/fleet.example.yaml" ]; then
        ver="$(python3 -c "
import yaml
try:
    d = yaml.safe_load(open('$ROOT_DIR/.agents/config/fleet.example.yaml'))
    print(d.get('local_environment', {}).get('installed_clis', {}).get('opencode', {}).get('version', ''))
except Exception:
    pass
" 2>/dev/null || true)"
      fi
      [ -z "$ver" ] && ver="2.2.6"
      ;;
    hermes)
      if command -v hermes >/dev/null 2>&1; then
        ver="$(extract_semver "$(hermes --version 2>/dev/null || true)")"
      fi
      [ -z "$ver" ] && ver="0.22.7"
      ;;
    orca)
      if command -v orca-ide >/dev/null 2>&1; then
        ver="$(extract_semver "$(orca-ide --version 2>/dev/null || true)")"
      fi
      [ -z "$ver" ] && ver="1.4.255"
      ;;
    infisical)
      if command -v infisical >/dev/null 2>&1; then
        ver="$(extract_semver "$(infisical --version 2>/dev/null || true)")"
      fi
      [ -z "$ver" ] && ver="0.43.0"
      ;;
    *)
      ver="unknown"
      ;;
  esac

  echo "$ver" | tr -d 'v[:space:]'
}

# ------------------------------------------------------------------------------
# Consulta de registros remotos con timeout estricto (≤5s) y captura fail-soft
# ------------------------------------------------------------------------------
fetch_latest_version() {
  local tool="$1"
  local registry="$2"
  local endpoint="$3"

  local raw=""
  local ver=""
  local status="ok"

  raw="$(curl -s --connect-timeout 3 --max-time 5 -H "User-Agent: agent-os-probe" "$endpoint" 2>/dev/null || true)"

  if [ -z "$raw" ]; then
    echo "null|unreachable"
    return 0
  fi

  case "$registry" in
    npm)
      ver="$(echo "$raw" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    if 'error' in d:
        print('null|not_found')
    else:
        v = d.get('version', '')
        print(f\"{v}|ok\" if v else 'null|parse_error')
except Exception:
    print('null|parse_error')
" 2>/dev/null || echo "null|parse_error")"
      ;;
    github)
      ver="$(echo "$raw" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    if isinstance(d, dict) and 'message' in d and 'rate limit' in d['message'].lower():
        print('null|rate_limited')
    elif isinstance(d, dict) and 'tag_name' in d:
        t = d['tag_name'].lstrip('v').strip()
        print(f\"{t}|ok\")
    else:
        print('null|not_found')
except Exception:
    print('null|parse_error')
" 2>/dev/null || echo "null|parse_error")"
      ;;
    pypi)
      ver="$(echo "$raw" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    v = d.get('info', {}).get('version', '')
    print(f\"{v}|ok\" if v else 'null|parse_error')
except Exception:
    print('null|parse_error')
" 2>/dev/null || echo "null|parse_error")"
      ;;
    *)
      ver="null|unknown_registry"
      ;;
  esac

  echo "$ver"
}

# Catálogo declarativo de herramientas monitoreadas
# Formato: tool_id|nombre_mostrado|registry_type|endpoint
declare -a CATALOG=(
  "opencode|OpenCode CLI|npm|https://registry.npmjs.org/@opencode/cli/latest"
  "hermes|Hermes Agent|github|https://api.github.com/repos/NousResearch/hermes-agent/releases/latest"
  "orca|Orca IDE|github|https://api.github.com/repos/stablyai/orca/releases/latest"
  "infisical|Infisical CLI|github|https://api.github.com/repos/Infisical/infisical/releases/latest"
)

TOTAL_INSPECTED=0
UPDATES_AVAILABLE_COUNT=0
NETWORK_ERRORS_COUNT=0

# Buffer de resultados para JSON / texto
PYTHON_PAYLOAD="$(mktemp /tmp/tooling_probe_XXXXXX.json)"
cat << 'EOF' > "$PYTHON_PAYLOAD"
[]
EOF

for item in "${CATALOG[@]}"; do
  IFS='|' read -r t_id t_name t_reg t_url <<< "$item"

  if [ -n "$TARGET_TOOL" ] && [ "$TARGET_TOOL" != "$t_id" ]; then
    continue
  fi

  TOTAL_INSPECTED=$((TOTAL_INSPECTED + 1))
  INSTALLED="$(detect_installed_version "$t_id")"
  UPSTREAM_RES="$(fetch_latest_version "$t_id" "$t_reg" "$t_url")"
  LATEST="$(echo "$UPSTREAM_RES" | cut -d'|' -f1)"
  STATUS="$(echo "$UPSTREAM_RES" | cut -d'|' -f2)"

  if [ "$STATUS" != "ok" ] || [ "$LATEST" = "null" ]; then
    NETWORK_ERRORS_COUNT=$((NETWORK_ERRORS_COUNT + 1))
    UPDATE_AVAIL=false
    DIFF_SUMMARY="error ($STATUS)"
  else
    # Comparación semver normalizada
    COMP_RES="$(python3 -c "
import sys

def parse_v(v):
    v = v.lstrip('v').strip().split('-')[0]
    parts = []
    for p in v.split('.'):
        try:
            parts.append(int(p))
        except ValueError:
            parts.append(0)
    return tuple(parts)

try:
    inst = parse_v('$INSTALLED')
    lat = parse_v('$LATEST')
    if lat > inst:
        print('update_available')
    elif lat == inst:
        print('up_to_date')
    else:
        print('ahead')
except Exception:
    print('unknown')
" 2>/dev/null || echo "unknown")"

    if [ "$COMP_RES" = "update_available" ]; then
      UPDATE_AVAIL=true
      UPDATES_AVAILABLE_COUNT=$((UPDATES_AVAILABLE_COUNT + 1))
      DIFF_SUMMARY="update available ($INSTALLED -> $LATEST)"
    elif [ "$COMP_RES" = "up_to_date" ]; then
      UPDATE_AVAIL=false
      DIFF_SUMMARY="up to date ($INSTALLED)"
    else
      UPDATE_AVAIL=false
      DIFF_SUMMARY="up to date / custom ($INSTALLED)"
    fi
  fi

  # Agregar entrada al payload JSON
  python3 -c "
import json
with open('$PYTHON_PAYLOAD', 'r') as f:
    items = json.load(f)

items.append({
    'tool': '$t_id',
    'name': '$t_name',
    'registry': '$t_reg',
    'installed_version': '$INSTALLED',
    'latest_version': None if '$LATEST' == 'null' else '$LATEST',
    'update_available': True if '$UPDATE_AVAIL' == 'true' else False,
    'status': '$STATUS',
    'summary': '$DIFF_SUMMARY'
})

with open('$PYTHON_PAYLOAD', 'w') as f:
    json.dump(items, f, indent=2)
" 2>/dev/null || true

done

if [ "$JSON_OUTPUT" = true ]; then
  python3 -c "
import json
with open('$PYTHON_PAYLOAD', 'r') as f:
    items = json.load(f)

result = {
    'total_tools_inspected': $TOTAL_INSPECTED,
    'updates_available_count': $UPDATES_AVAILABLE_COUNT,
    'network_errors_count': $NETWORK_ERRORS_COUNT,
    'tools': items
}
print(json.dumps(result, indent=2))
"
  rm -f "$PYTHON_PAYLOAD"
else
  rm -f "$PYTHON_PAYLOAD"
  echo "=============================================================================="
  echo "  SONDA DETERMINISTA DE ACTUALIZACIÓN DE HERRAMIENTAS (AGENT OS)"
  echo "=============================================================================="
  printf "%-12s | %-12s | %-12s | %-8s | %s\n" "HERRAMIENTA" "INSTALADA" "UPSTREAM" "FUENTE" "ESTADO"
  echo "-------------+--------------+--------------+----------+-----------------------"

  for item in "${CATALOG[@]}"; do
    IFS='|' read -r t_id t_name t_reg t_url <<< "$item"
    if [ -n "$TARGET_TOOL" ] && [ "$TARGET_TOOL" != "$t_id" ]; then
      continue
    fi

    INSTALLED="$(detect_installed_version "$t_id")"
    UPSTREAM_RES="$(fetch_latest_version "$t_id" "$t_reg" "$t_url")"
    LATEST="$(echo "$UPSTREAM_RES" | cut -d'|' -f1)"
    STATUS="$(echo "$UPSTREAM_RES" | cut -d'|' -f2)"

    if [ "$STATUS" != "ok" ] || [ "$LATEST" = "null" ]; then
      ICON="⚠️"
      DISP_LATEST="N/A ($STATUS)"
    else
      COMP_RES="$(python3 -c "
def parse_v(v):
    return tuple(int(x) if x.isdigit() else 0 for x in v.lstrip('v').strip().split('-')[0].split('.'))
try:
    print('update' if parse_v('$LATEST') > parse_v('$INSTALLED') else 'ok')
except Exception:
    print('unknown')
" 2>/dev/null || echo "unknown")"
      if [ "$COMP_RES" = "update" ]; then
        ICON="🔔 ACTUALIZACIÓN"
        DISP_LATEST="$LATEST"
      else
        ICON="✅ Al día"
        DISP_LATEST="$LATEST"
      fi
    fi

    printf "%-12s | %-12s | %-12s | %-8s | %s\n" "$t_id" "$INSTALLED" "$DISP_LATEST" "$t_reg" "$ICON"
  done
  echo "=============================================================================="
  echo "Resumen: $TOTAL_INSPECTED herramientas inspeccionadas | $UPDATES_AVAILABLE_COUNT con actualización | $NETWORK_ERRORS_COUNT con aviso de red/cuota."
fi

# Código de salida bajo --check
if [ "$CHECK_MODE" = true ]; then
  if [ "$UPDATES_AVAILABLE_COUNT" -gt 0 ]; then
    exit 1
  elif [ "$NETWORK_ERRORS_COUNT" -gt 0 ]; then
    exit 2
  else
    exit 0
  fi
fi

exit 0
