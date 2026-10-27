#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/secrets.sh — Único punto del core que manipula VALORES (T-117)
# ==============================================================================
# Uso:
#   bash scripts/agent/secrets.sh set    <CLAVE> [--path /<carpeta>] [--env <e>] (--stdin | --generate[=N]) [--tags a,b] [--json]
#   bash scripts/agent/secrets.sh rotate <CLAVE> [--path /<carpeta>] [--env <e>] [--stdin] [--generate[=N]] [--json]
#
# Contrato de seguridad:
#   - El valor SOLO entra por stdin (--stdin, sin eco) o se genera (--generate).
#   - Cualquier valor en argv se rechaza con exit 2: no aparece en `ps` ni en el
#     historial de shell.
#   - El valor viaja al CLI por stdin (`infisical secrets set --file /dev/stdin`):
#     no se escribe en disco ni se imprime.
#   - La confirmación muestra clave, carpeta, entorno y sha256 truncado. Nunca el
#     valor, ni un fragmento, ni su longitud.
#
# Código de salida: 0 ok | 1 entorno/verificación | 2 uso o valor por argv | 6 clave inexistente
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/lib/cli-help.sh"

INFISICAL_BIN="${AGENT_OS_INFISICAL_BIN:-infisical}"
LOCATE="${AGENT_OS_SECRET_LOCATE:-$SCRIPT_DIR/secret-locate.sh}"
ENV_NAME="${INFISICAL_ENVIRONMENT:-dev}"
FOLDER=""
USE_STDIN=false
GEN_LEN=""
JSON_OUT=false
TAGS_CSV=""

show_usage() {
    show_help "secrets.sh" \
        "bash scripts/agent/secrets.sh set|rotate <CLAVE> [--path /<carpeta>] [--env <e>] (--stdin | --generate[=N]) [--tags a,b] [--json]" \
        "Escribe o rota un secreto sin exponer el valor: entra por stdin o se genera, viaja al CLI por stdin y la confirmación solo muestra metadatos y un sha256 truncado." \
        "set <CLAVE>          Crea o actualiza el secreto (requiere --stdin o --generate)" \
        "rotate <CLAVE>       Genera un valor nuevo, lo escribe y verifica que updatedAt cambió" \
        "--path /<carpeta>    Carpeta destino. Obligatoria para crear una clave que no existe" \
        "--env <entorno>      Entorno de Infisical (defecto: \$INFISICAL_ENVIRONMENT o dev)" \
        "--stdin              Lee el valor de stdin sin eco (TTY) o de la tubería" \
        "--generate[=N]       Genera un valor alfanumérico de N caracteres (defecto 32; 16-128)" \
        "--tags a,b           Etiquetas a asociar (se pasan como --tag repetido)" \
        "--json               Confirma en JSON (clave, carpeta, entorno, sha256 truncado)" \
        "-h, --help           Muestra este mensaje de ayuda" \
        "ejemplo: printf 'valor' | bash scripts/agent/secrets.sh set MI_CLAVE --stdin --path /proyectos-x" \
        "ejemplo: bash scripts/agent/secrets.sh rotate MI_CLAVE --path /proyectos-x --generate=48" \
        "ejemplo: bash scripts/agent/secrets.sh set NUEVA --stdin --path /proyectos-x --tags scope-shared,env-dev"
}

die_usage() { echo "❌ ERROR: $*" >&2; exit 2; }

ACTION="${1:-}"
case "$ACTION" in
    -h|--help) show_usage ;;
    set|rotate) ;;
    "") die_usage "indica 'set' o 'rotate'." ;;
    *) die_usage "acción desconocida: '$ACTION' (usa set o rotate)." ;;
esac
shift

[ $# -ge 1 ] || die_usage "falta <CLAVE>."
KEY="$1"
shift
case "$KEY" in
    *'='*) die_usage "no se acepta 'CLAVE=valor': el valor nunca va por argumentos (usa --stdin o --generate)." ;;
esac
[[ "$KEY" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || die_usage "nombre de clave inválido: '$KEY'."

while [ $# -gt 0 ]; do
    case "$1" in
        --path)
            [ $# -ge 2 ] || die_usage "--path requiere una carpeta."
            FOLDER="$2"; shift 2 ;;
        --path=*) FOLDER="${1#*=}"; shift ;;
        --env)
            [ $# -ge 2 ] || die_usage "--env requiere un entorno."
            ENV_NAME="$2"; shift 2 ;;
        --env=*) ENV_NAME="${1#*=}"; shift ;;
        --stdin) USE_STDIN=true; shift ;;
        --generate) GEN_LEN=32; shift ;;
        --generate=*)
            GEN_LEN="${1#*=}"
            case "$GEN_LEN" in
                ''|*[!0-9]*) die_usage "--generate=N requiere un entero." ;;
            esac
            shift ;;
        --tags)
            [ $# -ge 2 ] || die_usage "--tags requiere una lista."
            TAGS_CSV="$2"; shift 2 ;;
        --tags=*) TAGS_CSV="${1#*=}"; shift ;;
        --json) JSON_OUT=true; shift ;;
        --value|--value=*)
            die_usage "no se acepta --value: el valor nunca va por argumentos (usa --stdin o --generate)." ;;
        -*)
            die_usage "opción desconocida: '$1'." ;;
        *)
            die_usage "argumento inesperado: '$1'. El valor nunca va por argumentos (usa --stdin o --generate)." ;;
    esac
done

if [ "$USE_STDIN" = true ] && [ -n "$GEN_LEN" ]; then
    die_usage "usa --stdin o --generate, no ambos."
fi
if [ -z "$GEN_LEN" ] && [ "$USE_STDIN" = false ]; then
    if [ "$ACTION" = "set" ]; then
        die_usage "indica el origen del valor: --stdin o --generate[=N]."
    fi
    GEN_LEN=32
fi
if [ -n "$GEN_LEN" ]; then
    if [ "$GEN_LEN" -lt 16 ] || [ "$GEN_LEN" -gt 128 ]; then
        die_usage "--generate=N fuera de rango (16-128)."
    fi
fi

# Carpeta: normalizada sin barras redundantes.
FOLDER="${FOLDER#/}"
FOLDER="${FOLDER%/}"

for cmd in python3 grep head tr sed cut; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "❌ Error: dependencia requerida '$cmd' no encontrada." >&2; exit 1; }
done
command -v "$INFISICAL_BIN" >/dev/null 2>&1 || {
    echo "❌ Error: dependencia requerida '$INFISICAL_BIN' no encontrada." >&2
    echo "💡 Guía: npm i -g @infisical/cli" >&2; exit 1; }
[ -x "$LOCATE" ] || { echo "❌ Error: no se encontró secret-locate.sh ($LOCATE)." >&2; exit 1; }
[ -n "${INFISICAL_API_URL:-}" ] || { echo "❌ Error: INFISICAL_API_URL no definida." >&2; exit 1; }
[ -n "${INFISICAL_PROJECT_ID:-}" ] || { echo "❌ Error: INFISICAL_PROJECT_ID no definida." >&2; exit 1; }

VALUE=""
trap 'unset VALUE' EXIT

mint_token() {
    if [ -n "${INFISICAL_TOKEN:-}" ]; then printf '%s' "$INFISICAL_TOKEN"; return 0; fi
    if [ -z "${INFISICAL_CLIENT_ID:-}" ] || [ -z "${INFISICAL_CLIENT_SECRET:-}" ]; then
        return 1
    fi
    "$INFISICAL_BIN" login --method=universal-auth \
        --client-id="$INFISICAL_CLIENT_ID" \
        --client-secret="$INFISICAL_CLIENT_SECRET" 2>/dev/null | grep -E '^eyJ' | head -1
}

read_value() {
    local extra
    if [ -t 0 ]; then
        printf 'Valor para %s (no se mostrará): ' "$KEY" >&2
        if ! IFS= read -rs VALUE; then
            printf '\n' >&2
            echo "❌ ERROR: no se pudo leer el valor de stdin." >&2
            exit 2
        fi
        printf '\n' >&2
    else
        IFS= read -r VALUE || true
    fi
    VALUE="${VALUE%$'\r'}"
    [ -n "$VALUE" ] || { echo "❌ ERROR: el valor está vacío." >&2; exit 2; }
    if IFS= read -r extra; then
        echo "❌ ERROR: el valor no puede contener saltos de línea." >&2
        exit 2
    fi
}

gen_value() {
    local n="$1"
    VALUE="$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c "$n" || true)"
    if [ "${#VALUE}" -ne "$n" ]; then
        echo "❌ ERROR: no se pudo generar el valor." >&2
        exit 1
    fi
}

hash_prefix() {
    if command -v sha256sum >/dev/null 2>&1; then
        printf '%s' "$1" | sha256sum | cut -c1-12
    elif command -v shasum >/dev/null 2>&1; then
        printf '%s' "$1" | shasum -a 256 | cut -c1-12
    else
        printf '%s' "$1" | openssl dgst -sha256 2>/dev/null | sed 's/.*= //' | cut -c1-12
    fi
}

json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

locate_json() { "$LOCATE" --name "$KEY" --json 2>/dev/null || true; }

folders_from_json() {
    printf '%s' "$1" | python3 -c 'import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for folder in data.get("found_in") or []:
    print(folder)'
}

updated_at_from_json() {
    printf '%s' "$1" | python3 -c 'import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
wanted = sys.argv[1] if len(sys.argv) > 1 else ""
for hit in data.get("hits_detail") or []:
    if hit.get("folder") == wanted:
        print(hit.get("updated_at") or "")
        break' "$2"
}

resolve_folder() {
    [ -n "$FOLDER" ] && return 0
    local json found n
    json="$(locate_json)"
    found="$(folders_from_json "$json")"
    n=0
    [ -n "$found" ] && n="$(printf '%s\n' "$found" | grep -c . || true)"
    if [ "$n" -eq 0 ]; then
        echo "❌ ERROR: '$KEY' no existe en la bóveda (entorno $ENV_NAME)." >&2
        echo "   Para crearla indica la carpeta: --path /<carpeta>" >&2
        exit 6
    fi
    if [ "$n" -gt 1 ]; then
        echo "❌ ERROR: '$KEY' existe en $n carpetas; indica --path:" >&2
        printf '%s\n' "$found" | while IFS= read -r f; do printf '   /%s\n' "$f" >&2; done
        exit 2
    fi
    FOLDER="$found"
}

current_updated_at() {
    local json
    json="$(locate_json)"
    updated_at_from_json "$json" "$1"
}

write_secret() {
    local token tag_args=() tag
    token="$(mint_token)" || {
        echo "❌ Error: faltan credenciales de Infisical (INFISICAL_TOKEN o CLIENT_ID/SECRET)." >&2
        exit 1
    }
    [ -n "$token" ] || { echo "❌ Error: no se pudo autenticar contra Infisical." >&2; exit 1; }
    if [ -n "$TAGS_CSV" ]; then
        IFS=',' read -r -a _tags <<< "$TAGS_CSV"
        for tag in "${_tags[@]}"; do
            tag="$(printf '%s' "$tag" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
            [ -n "$tag" ] && tag_args+=(--tag "$tag")
        done
    fi
    # El valor viaja por stdin: ni argv ni fichero temporal.
    if ! printf '%s=%s\n' "$KEY" "$VALUE" | \
        "$INFISICAL_BIN" secrets set --file /dev/stdin --path "/$FOLDER" \
            --env "$ENV_NAME" --projectId "$INFISICAL_PROJECT_ID" --domain "$INFISICAL_API_URL" \
            --token "$token" --silent ${tag_args[@]+"${tag_args[@]}"} >/dev/null; then
        echo "❌ ERROR: Infisical rechazó la escritura de '$KEY' en /$FOLDER." >&2
        exit 1
    fi
}

# ─── Ejecución ───────────────────────────────────────────────────────────────
resolve_folder

BEFORE=""
if [ "$ACTION" = "rotate" ]; then
    BEFORE="$(current_updated_at "$FOLDER")"
fi

if [ -n "$GEN_LEN" ]; then
    gen_value "$GEN_LEN"
else
    read_value
fi

HASH="$(hash_prefix "$VALUE")"
write_secret

VERIFIED=""
if [ "$ACTION" = "rotate" ]; then
    AFTER="$(current_updated_at "$FOLDER")"
    if [ -z "$AFTER" ]; then
        echo "❌ ERROR: '$KEY' no aparece tras la rotación en /$FOLDER." >&2
        exit 1
    fi
    if [ -n "$BEFORE" ] && [ "$AFTER" = "$BEFORE" ]; then
        echo "❌ ERROR: updatedAt no cambió; no se puede verificar la rotación." >&2
        exit 1
    fi
    VERIFIED="true"
fi

if [ "$JSON_OUT" = true ]; then
    printf '{"action": "%s", "key": "%s", "folder": "%s", "environment": "%s", "sha256_prefix": "%s", "generated": %s, "verified": %s}\n' \
        "$ACTION" "$(json_escape "$KEY")" "$(json_escape "$FOLDER")" "$(json_escape "$ENV_NAME")" \
        "$HASH" "$([ -n "$GEN_LEN" ] && echo true || echo false)" \
        "$([ -n "$VERIFIED" ] && echo true || echo null)"
    exit 0
fi

echo "🔐 $KEY escrita en /$FOLDER (entorno $ENV_NAME)"
echo "   sha256: $HASH"
if [ -n "$VERIFIED" ]; then
    echo "   ✅ Verificado: updatedAt cambió tras la rotación."
fi
echo "   Consumo sin imprimir: infisical run --path=/$FOLDER -- <comando>"
exit 0
