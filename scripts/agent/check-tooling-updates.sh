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
GENERATE_INBOX=false

for arg in "$@"; do
  if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
    SHOW_HELP=true
    break
  fi
done

if [ "$SHOW_HELP" = true ]; then
  if type show_help >/dev/null 2>&1; then
    show_help "check-tooling-updates.sh" \
      "bash scripts/agent/check-tooling-updates.sh [--tool <nombre>] [--check] [--json] [--generate-inbox]" \
      "Inspecciona de forma determinista las versiones disponibles de las herramientas de la flota en registros oficiales (npm, GitHub, PyPI)." \
      "--tool <nombre>      Filtra la inspección a una herramienta concreta (ej: opencode, hermes, orca, infisical, glances)." \
      "--check              Modo auditoría: devuelve exit code 1 si hay actualizaciones disponibles, 2 ante error/rate limit, 0 si todo está al día." \
      "--json               Emite el informe estructurado en formato JSON." \
      "--generate-inbox     Genera borradores estructurados en docs/idea-inbox/ para herramientas con actualización pendiente (\$0 tokens)." \
      "ejemplo: bash scripts/agent/check-tooling-updates.sh" \
      "ejemplo: bash scripts/agent/check-tooling-updates.sh --tool opencode --json" \
      "ejemplo: bash scripts/agent/check-tooling-updates.sh --check" \
      "ejemplo: bash scripts/agent/check-tooling-updates.sh --generate-inbox"
  else
    echo "Uso: bash scripts/agent/check-tooling-updates.sh [--tool <nombre>] [--check] [--json] [--generate-inbox] [-h|--help]"
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
    --generate-inbox)
      GENERATE_INBOX=true
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
REMOTE_HERMES_VERSION=""

extract_semver() {
  local text="$1"
  # Extrae la primera ocurrencia de X.Y.Z o vX.Y.Z
  echo "$text" | grep -oE 'v?[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 | tr -d 'v[:space:]'
}

detect_remote_hermes_version() {
  local fleet_file=""
  if [ -f "$ROOT_DIR/.agents/config/fleet.yaml" ]; then
    fleet_file="$ROOT_DIR/.agents/config/fleet.yaml"
  elif [ -f "$ROOT_DIR/config/fleet.yaml" ]; then
    fleet_file="$ROOT_DIR/config/fleet.yaml"
  fi
  [ -z "$fleet_file" ] && return 0

  local remote_target=""
  remote_target="$(python3 -c "
import yaml
try:
    with open('$fleet_file') as f:
        d = yaml.safe_load(f) or {}
    nodes = d.get('nodes', {})
    for node_id, node_cfg in nodes.items():
        svcs = node_cfg.get('services', {})
        if 'hermes' in svcs or 'hermes_gateway' in svcs:
            print(node_cfg.get('alias') or node_id or node_cfg.get('ip') or '')
            break
except Exception:
    pass
" 2>/dev/null || true)"

  if [ -n "$remote_target" ] && command -v ssh >/dev/null 2>&1; then
    local r_out=""
    r_out="$(ssh -o BatchMode=yes -o ConnectTimeout=2 "$remote_target" "PATH=\$HOME/.local/bin:\$HOME/.hermes/hermes-agent/venv/bin:\$PATH hermes --version" 2>/dev/null || true)"
    extract_semver "$r_out"
  fi
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
      [ -z "$ver" ] && ver="2.2.7"
      ;;
    hermes)
      if command -v hermes >/dev/null 2>&1; then
        ver="$(extract_semver "$(hermes --version 2>/dev/null || true)")"
      fi
      # Sonda determinista fail-soft sobre nodo VPS si está configurado en fleet.yaml
      local r_ver=""
      r_ver="$(detect_remote_hermes_version)"
      if [ -n "$r_ver" ]; then
        REMOTE_HERMES_VERSION="$r_ver"
        if [ -z "$ver" ]; then
          ver="$r_ver"
        fi
      fi
      [ -z "$ver" ] && ver="0.23.1"
      ;;
    orca)
      if command -v orca-ide >/dev/null 2>&1; then
        ver="$(extract_semver "$(orca-ide --version 2>/dev/null || true)")"
      fi
      [ -z "$ver" ] && ver="1.4.256"
      ;;
    infisical)
      if command -v infisical >/dev/null 2>&1; then
        ver="$(extract_semver "$(infisical --version 2>/dev/null || true)")"
      fi
      [ -z "$ver" ] && ver="0.45.6"
      ;;
    glances)
      if command -v glances >/dev/null 2>&1; then
        ver="$(extract_semver "$(glances --version 2>/dev/null || true)")"
      fi
      if [ -z "$ver" ] && [ -f "$ROOT_DIR/.agents/config/fleet.example.yaml" ]; then
        ver="$(python3 -c "
import yaml
try:
    d = yaml.safe_load(open('$ROOT_DIR/.agents/config/fleet.example.yaml'))
    v = d.get('nodes', {}).get('<nodo-inferencia>', {}).get('services', {}).get('glances', {}).get('version', '')
    print(v)
except Exception:
    pass
" 2>/dev/null || true)"
      fi
      [ -z "$ver" ] && ver="4.5.9"
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
  "infisical|Infisical CLI|npm|https://registry.npmjs.org/@infisical/cli/latest"
  "glances|Glances Daemon|pypi|https://pypi.org/pypi/glances/json"
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
  if [ "$t_id" = "hermes" ]; then
    REMOTE_HERMES_VERSION="$(detect_remote_hermes_version)"
  fi
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

    # Generación determinista de propuesta en docs/idea-inbox/ si procede
    if [ "$UPDATE_AVAIL" = "true" ] && [ "$GENERATE_INBOX" = "true" ]; then
      TODAY="$(date +%Y-%m-%d)"
      CLEAN_LATEST="$(echo "$LATEST" | sed 's/^v//')"
      INBOX_FILE="$ROOT_DIR/docs/idea-inbox/${TODAY}-${t_id}-v${CLEAN_LATEST}.md"
      if [ ! -f "$INBOX_FILE" ]; then
        mkdir -p "$ROOT_DIR/docs/idea-inbox"
        cat <<EOF > "$INBOX_FILE"
# Idea: Actualización de ${t_name} a v${CLEAN_LATEST}

> **Fecha**: ${TODAY}
> **Origen**: Sonda determinista check-tooling-updates.sh (Paso 1 de planning)
> **Estado**: 💡 REGISTRADA, NO APROBADA
> **Herramienta**: ${t_id} (${t_name})
> **Versión actual**: ${INSTALLED} → **Versión detectada**: ${CLEAN_LATEST}

## Contexto y Motivación
La sonda determinista de automejora de Agent OS ha detectado una nueva versión upstream disponible en el registro oficial (${t_reg}).
Esta propuesta se somete a evaluación del operador humano en el ritual de planning bajo el principio estricto de cero auto-ejecución.

## Novedades Principales
- Actualización de versión: ${INSTALLED} → ${CLEAN_LATEST}
- Registro oficial: ${t_reg} (${t_url})

## Evaluación de Impacto
- **Complejidad estimada**: S
- **Riesgo**: Bajo (homologación y verificación con test suite).
- **Acción requerida**: Si el operador humano aprueba su incorporación en el Paso 7 del planning, se formalizará como tarea técnica en el siguiente sprint.
EOF
      fi
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
    'installed_version_remote': '$REMOTE_HERMES_VERSION' if '$t_id' == 'hermes' and '$REMOTE_HERMES_VERSION' else None,
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
  echo "=============================================================================="
  echo "  SONDA DETERMINISTA DE ACTUALIZACIÓN DE HERRAMIENTAS (AGENT OS)"
  echo "=============================================================================="
  printf "%-12s | %-12s | %-12s | %-8s | %s\n" "HERRAMIENTA" "INSTALADA" "UPSTREAM" "FUENTE" "ESTADO"
  echo "-------------+--------------+--------------+----------+-----------------------"

  python3 -c "
import json
with open('$PYTHON_PAYLOAD', 'r') as f:
    items = json.load(f)

for it in items:
    t_id = it['tool']
    inst = it['installed_version']
    lat = it['latest_version'] or 'N/A'
    reg = it['registry']
    st = it['status']
    rem = it.get('installed_version_remote')
    inst_disp = f'{inst} (vps:{rem})' if rem and rem != inst else inst
    if st != 'ok' or lat == 'N/A':
        icon = f'⚠️ {st}'
    elif it['update_available']:
        icon = '🔔 ACTUALIZACIÓN'
    else:
        icon = '✅ Al día'
    print(f'{t_id:<12} | {inst_disp:<12} | {lat:<12} | {reg:<8} | {icon}')
"
  rm -f "$PYTHON_PAYLOAD"
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
