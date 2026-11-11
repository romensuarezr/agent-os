#!/usr/bin/env bash
# ==============================================================================
# rotate-freellmapi-token.sh — Rotación y sincronización determinista de FreeLLMAPI en Hermes
# ==============================================================================
# Uso:
#   bash scripts/agent/lib/rotate-freellmapi-token.sh --check
#   bash scripts/agent/lib/rotate-freellmapi-token.sh --sync [--apply]
#   bash scripts/agent/lib/rotate-freellmapi-token.sh --rotate [--apply]
#
# Principios:
#   1. Secreto Cero: NUNCA imprime valores en stdout, stderr ni logs.
#   2. Determinista y seguro: Respaldo previo de ~/.hermes/config.yaml con timestamp.
#   3. Permisos estrictos: Preserva modo 0600 en config.yaml.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/agent/lib/cli-help.sh
source "$SCRIPT_DIR/cli-help.sh"

TARGET_HOST="${SSH_TARGET:-${INFERENCE_HOST:-}}"
MODE="check"
APPLY=false
SWITCH_MODEL=false
SYNC_OPENCODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help "rotate-freellmapi-token.sh" \
        "bash scripts/agent/lib/rotate-freellmapi-token.sh [OPCIONES]" \
        "Rotación y sincronización determinista de la clave unified_api_key de FreeLLMAPI en Hermes y OpenCode. Cero exposición de secretos en pantalla ni logs." \
        "--check                  Verifica la coherencia entre freeapi.db y ~/.hermes/config.yaml (solo lectura)" \
        "--sync                   Sincroniza la unified_api_key actual de FreeLLMAPI hacia Hermes" \
        "--rotate                 Regenera una nueva unified_api_key en FreeLLMAPI y la sincroniza a Hermes" \
        "--switch-model           Conmuta el bloque raiz model: de Hermes hacia custom:freellmapi" \
        "--sync-opencode          Sincroniza también la clave en la configuración local de OpenCode" \
        "--apply                  Aplica las modificaciones en disco (requerido para --sync y --rotate)" \
        "--target <host>          Host SSH de destino (por defecto: \$SSH_TARGET o \$INFERENCE_HOST)" \
        "-h, --help               Muestra este mensaje de ayuda" \
        "ejemplo: bash scripts/agent/lib/rotate-freellmapi-token.sh --check --target <nodo-inferencia>" \
        "ejemplo: bash scripts/agent/lib/rotate-freellmapi-token.sh --target <nodo-inferencia> --rotate --apply"
      ;;
    --check) MODE="check"; shift ;;
    --sync) MODE="sync"; shift ;;
    --rotate) MODE="rotate"; shift ;;
    --switch-model) SWITCH_MODEL=true; shift ;;
    --sync-opencode) SYNC_OPENCODE=true; shift ;;
    --apply) APPLY=true; shift ;;
    --target)
      if [ $# -lt 2 ]; then
        echo "❌ ERROR: --target requiere un argumento." >&2
        exit 2
      fi
      TARGET_HOST="$2"
      shift 2
      ;;
    --target=*)
      TARGET_HOST="${1#*=}"
      shift
      ;;
    --)
      shift
      if [ $# -gt 0 ] && [ -z "$TARGET_HOST" ]; then
        TARGET_HOST="$1"
        shift
      fi
      ;;
    -*)
      echo "❌ ERROR: Opción no reconocida: $1" >&2
      echo "   Usa --help para ver las opciones disponibles." >&2
      exit 2
      ;;
    *)
      if [ -z "$TARGET_HOST" ]; then
        TARGET_HOST="$1"
      fi
      shift
      ;;
  esac
done

if [ -z "$TARGET_HOST" ]; then
  echo "❌ ERROR: Host destino no especificado. Usa --target <host> o exporta SSH_TARGET / INFERENCE_HOST." >&2
  exit 1
fi

# Pre-flight de conectividad SSH
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$TARGET_HOST" "echo ping" >/dev/null 2>&1; then
  echo "❌ ERROR: No se puede conectar vía SSH a $TARGET_HOST." >&2
  exit 1
fi

case "$MODE" in
  check)
    echo "🔍 Verificando estado de claves de FreeLLMAPI en $TARGET_HOST..."
    ssh "$TARGET_HOST" "sudo python3 - <<'PYEOF'
import sqlite3, yaml, sys

# 1. Leer metadata de freeapi.db
db_path = '/var/lib/docker/volumes/freellmapi_freellmapi-data/_data/freeapi.db'
try:
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    row = c.execute(\"SELECT length(value), substr(value, 1, 11) FROM settings WHERE key = 'unified_api_key'\").fetchone()
    if not row:
        print('  ❌ freeapi.db: unified_api_key no encontrada en tabla settings.')
        sys.exit(1)
    db_len, db_prefix = row
    print(f'  ✅ freeapi.db: unified_api_key presente (prefijo: {db_prefix}***, len: {db_len})')
except Exception as e:
    print(f'  ⚠️ Error al acceder a freeapi.db: {e}')
    sys.exit(1)

# 2. Leer ~/.hermes/config.yaml
cfg_path = '/home/ubuntu/.hermes/config.yaml'
try:
    with open(cfg_path, 'r', encoding='utf-8') as f:
        cfg = yaml.safe_load(f) or {}
    
    # Buscar freellmapi en custom_providers
    cp_list = cfg.get('custom_providers', [])
    fl_entry = next((p for p in cp_list if isinstance(p, dict) and p.get('name') == 'freellmapi'), None)
    
    if not fl_entry:
        print('  ❌ ~/.hermes/config.yaml: proveedor freellmapi no configurado en custom_providers.')
    else:
        key_val = fl_entry.get('api_key', '')
        key_len = len(key_val) if key_val else 0
        key_prefix = key_val[:11] if key_len >= 11 else (key_val[:4] if key_len >= 4 else '***')
        print(f'  ℹ️  hermes custom_providers: freellmapi key (prefijo: {key_prefix}***, len: {key_len})')
        if key_len == db_len and key_prefix == db_prefix:
            print('  ✅ Coherencia: la clave configurada en Hermes coincide en longitud y prefijo con FreeLLMAPI.')
        else:
            print('  ⚠️  Desfase: la clave en Hermes NO coincide con la unified_api_key de FreeLLMAPI.')

    # Modelo raíz actual
    root_model = cfg.get('model', {})
    provider = root_model.get('provider', '')
    default_m = root_model.get('default', '')
    print(f'  ℹ️  Hermes root model activo: provider={provider}, default={default_m}')
except Exception as e:
    print(f'  ⚠️ Error al leer {cfg_path}: {e}')
    sys.exit(1)
PYEOF"
    ;;

  sync)
    if [ "$APPLY" != "true" ]; then
      echo "ℹ️  Modo --sync en simulación (dry-run). Para aplicar los cambios usa --sync --apply."
      exit 0
    fi
    echo "⚙️  Sincronizando unified_api_key de FreeLLMAPI hacia ~/.hermes/config.yaml..."
    ssh "$TARGET_HOST" "sudo SWITCH_MODEL='$SWITCH_MODEL' python3 - <<'PYEOF'
import sqlite3, yaml, os, time, shutil

db_path = '/var/lib/docker/volumes/freellmapi_freellmapi-data/_data/freeapi.db'
cfg_path = '/home/ubuntu/.hermes/config.yaml'

# Obtener clave activa
conn = sqlite3.connect(db_path)
c = conn.cursor()
row = c.execute(\"SELECT value FROM settings WHERE key = 'unified_api_key'\").fetchone()
if not row or not row[0]:
    print('ERROR: unified_api_key vacia o no encontrada.')
    exit(1)
unified_key = row[0]

# Respaldo de config.yaml
timestamp = time.strftime('%Y%m%d_%H%M%S')
bak_path = f'{cfg_path}.bak.{timestamp}'
shutil.copy2(cfg_path, bak_path)
os.chmod(bak_path, 0o600)

with open(cfg_path, 'r', encoding='utf-8') as f:
    cfg = yaml.safe_load(f) or {}

cp_list = cfg.get('custom_providers', [])
found = False
existing_url = None
for p in cp_list:
    if isinstance(p, dict) and p.get('name') == 'freellmapi':
        existing_url = p.get('base_url')
        p['api_key'] = unified_key
        found = True
        break

target_url = existing_url or 'http://127.0.0.1:3001/v1'

if not found:
    cp_list.append({
        'name': 'freellmapi',
        'base_url': target_url,
        'api_key': unified_key
    })
cfg['custom_providers'] = cp_list

if os.environ.get('SWITCH_MODEL') == 'true':
    cfg['model'] = {
        'default': 'auto',
        'provider': 'custom:freellmapi',
        'base_url': target_url,
        'api_key': unified_key
    }
    print('ℹ️  Bloque raíz model: actualizado a custom:freellmapi.')

with open(cfg_path, 'w', encoding='utf-8') as f:
    yaml.dump(cfg, f, default_flow_style=False, sort_keys=False)
os.chmod(cfg_path, 0o600)
shutil.chown(cfg_path, user='ubuntu', group='ubuntu')

print(f'✅ ~/.hermes/config.yaml sincronizado exitosamente (respaldo en {bak_path}).')
PYEOF"
    if [ "$SYNC_OPENCODE" = "true" ]; then
      OPENCODE_CFG="${OPENCODE_CONFIG_PATH:-$HOME/.config/opencode/opencode.json}"
      [ -f "$OPENCODE_CFG" ] || OPENCODE_CFG="$HOME/.antigravity_pro2/.config/opencode/opencode.json"
      if [ -f "$OPENCODE_CFG" ]; then
        echo "⚙️  Sincronizando clave hacia OpenCode..."
        ssh "$TARGET_HOST" "sudo python3 -c 'import sqlite3; c=sqlite3.connect(\"/var/lib/docker/volumes/freellmapi_freellmapi-data/_data/freeapi.db\").cursor(); print(c.execute(\"SELECT value FROM settings WHERE key=\\\"unified_api_key\\\"\").fetchone()[0])'" | python3 -c "
import json, sys
key = sys.stdin.read().strip()
cfg_file = '$OPENCODE_CFG'
with open(cfg_file, 'r', encoding='utf-8') as f:
    d = json.load(f)
if 'provider' in d and 'freellmapi' in d['provider']:
    if 'options' not in d['provider']['freellmapi']:
        d['provider']['freellmapi']['options'] = {}
    d['provider']['freellmapi']['options']['apiKey'] = key
    with open(cfg_file, 'w', encoding='utf-8') as f:
        json.dump(d, f, indent=2)
    print('  ✅ OpenCode sincronizado con la clave de FreeLLMAPI.')
"
      fi
    fi
    ;;

  rotate)
    if [ "$APPLY" != "true" ]; then
      echo "ℹ️  Modo --rotate en simulación (dry-run). Para aplicar los cambios usa --rotate --apply."
      exit 0
    fi
    echo "🔄 Regenerando unified_api_key en FreeLLMAPI y sincronizando a Hermes..."
    ssh "$TARGET_HOST" "sudo SWITCH_MODEL='$SWITCH_MODEL' python3 - <<'PYEOF'
import sqlite3, yaml, os, time, shutil, secrets

db_path = '/var/lib/docker/volumes/freellmapi_freellmapi-data/_data/freeapi.db'
cfg_path = '/home/ubuntu/.hermes/config.yaml'

# Generar nueva clave unificada conforme a la especificación de FreeLLMAPI: freellmapi-<hex48>
new_key = f'freellmapi-{secrets.token_hex(24)}'

# Actualizar base de datos
conn = sqlite3.connect(db_path)
c = conn.cursor()
c.execute(\"UPDATE settings SET value = ? WHERE key = 'unified_api_key'\", (new_key,))
conn.commit()

# Respaldo de config.yaml
timestamp = time.strftime('%Y%m%d_%H%M%S')
bak_path = f'{cfg_path}.bak.{timestamp}'
shutil.copy2(cfg_path, bak_path)
os.chmod(bak_path, 0o600)

with open(cfg_path, 'r', encoding='utf-8') as f:
    cfg = yaml.safe_load(f) or {}

cp_list = cfg.get('custom_providers', [])
found = False
existing_url = None
for p in cp_list:
    if isinstance(p, dict) and p.get('name') == 'freellmapi':
        existing_url = p.get('base_url')
        p['api_key'] = new_key
        found = True
        break

target_url = existing_url or 'http://127.0.0.1:3001/v1'

if not found:
    cp_list.append({
        'name': 'freellmapi',
        'base_url': target_url,
        'api_key': new_key
    })
cfg['custom_providers'] = cp_list

if os.environ.get('SWITCH_MODEL') == 'true':
    cfg['model'] = {
        'default': 'auto',
        'provider': 'custom:freellmapi',
        'base_url': target_url,
        'api_key': new_key
    }
    print('ℹ️  Bloque raíz model: actualizado a custom:freellmapi.')

with open(cfg_path, 'w', encoding='utf-8') as f:
    yaml.dump(cfg, f, default_flow_style=False, sort_keys=False)
os.chmod(cfg_path, 0o600)
shutil.chown(cfg_path, user='ubuntu', group='ubuntu')

print(f'✅ Clave unificada rotada en FreeLLMAPI y sincronizada en Hermes (respaldo en {bak_path}).')
PYEOF"
    if [ "$SYNC_OPENCODE" = "true" ]; then
      OPENCODE_CFG="${OPENCODE_CONFIG_PATH:-$HOME/.config/opencode/opencode.json}"
      [ -f "$OPENCODE_CFG" ] || OPENCODE_CFG="$HOME/.antigravity_pro2/.config/opencode/opencode.json"
      if [ -f "$OPENCODE_CFG" ]; then
        echo "⚙️  Sincronizando nueva clave hacia OpenCode..."
        ssh "$TARGET_HOST" "sudo python3 -c 'import sqlite3; c=sqlite3.connect(\"/var/lib/docker/volumes/freellmapi_freellmapi-data/_data/freeapi.db\").cursor(); print(c.execute(\"SELECT value FROM settings WHERE key=\\\"unified_api_key\\\"\").fetchone()[0])'" | python3 -c "
import json, sys
key = sys.stdin.read().strip()
cfg_file = '$OPENCODE_CFG'
with open(cfg_file, 'r', encoding='utf-8') as f:
    d = json.load(f)
if 'provider' in d and 'freellmapi' in d['provider']:
    if 'options' not in d['provider']['freellmapi']:
        d['provider']['freellmapi']['options'] = {}
    d['provider']['freellmapi']['options']['apiKey'] = key
    with open(cfg_file, 'w', encoding='utf-8') as f:
        json.dump(d, f, indent=2)
    print('  ✅ OpenCode sincronizado con la nueva clave rotada de FreeLLMAPI.')
"
      fi
    fi
    ;;
esac
