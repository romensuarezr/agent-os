#!/usr/bin/env bash
# scripts/agent/lib/redact.sh — Agent OS
#
# Filtro stdin → stdout que sustituye el VALOR de cada clave conocida por
# <redacted:CLAVE>. Pensado para diagnósticos que pueden volcar secretos:
# `docker compose config`, `docker inspect`, `env`/`printenv`, logs...
#
# Uso:
#   <comando> 2>&1 | bash scripts/agent/lib/redact.sh [--keys A,B] [--catalog FICHERO]
#
# Fuentes de claves (en orden de prioridad):
#   1. --keys A,B
#   2. --catalog FICHERO  (o AGENT_OS_SECRETS_CATALOG)
#   3. $REPO/.agents/config/secrets-catalog.yaml (artefacto generado, no versionado)
#
# Garantías:
#   - Trabaja línea a línea: el número de líneas no cambia y el JSON sigue siendo
#     JSON válido (los escalares se convierten en string entrecomillado).
#   - Determinista, sin red, sin escrituras. Solo cat y sed.
#   - Sin claves conocidas: pasa el texto intacto y avisa por stderr.
#
# Límites: sobre-redacta por diseño (fail-safe); los valores anidados en objetos
# o arrays JSON no se redactan. Un diagnóstico opaco es preferible a uno con token.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

KEYS_ARG=""
CATALOG=""

show_help() {
    cat <<HELP
redact.sh — redacta valores de secretos en un stream (stdin → stdout)

USO
  <comando> 2>&1 | bash scripts/agent/lib/redact.sh [opciones]

OPCIONES
  --keys A,B         claves a redactar (coma-separadas); tiene prioridad
  --catalog FICHERO  catálogo YAML con las claves (formato de
                     generate-secrets-catalog.sh)
  -h, --help         esta ayuda

SIN CLAVES
  Pasa el texto intacto (exit 0) y avisa por stderr.

FORMAS REDACTADAS
  KEY=valor   KEY="valor"   "KEY": "valor"   "KEY": 123   KEY: valor

EJEMPLOS
  docker compose config 2>&1 | bash scripts/agent/lib/redact.sh
  printf 'API_TOKEN=abc123\n' | bash scripts/agent/lib/redact.sh --keys API_TOKEN
  docker inspect app 2>&1 | bash scripts/agent/lib/redact.sh --catalog /tmp/cat.yaml

CÓDIGOS
  0  filtro aplicado (o sin claves: passthrough)
  64 uso incorrecto
HELP
}

while [ $# -gt 0 ]; do
    case "$1" in
        --keys)
            KEYS_ARG="${2:-}"; shift 2 ;;
        --keys=*)
            KEYS_ARG="${1#*=}"; shift ;;
        --catalog)
            CATALOG="${2:-}"; shift 2 ;;
        --catalog=*)
            CATALOG="${1#*=}"; shift ;;
        -h|--help)
            show_help; exit 0 ;;
        *)
            echo "redact.sh: argumento no reconocido: '$1' (usa --help)" >&2
            exit 64 ;;
    esac
done

if [ -z "$CATALOG" ]; then
    CATALOG="${AGENT_OS_SECRETS_CATALOG:-$ROOT/.agents/config/secrets-catalog.yaml}"
fi

VALID_KEY_RE='^[A-Za-z_][A-Za-z0-9_]*$'

collect_catalog_keys() {
    local f="$1"
    [ -f "$f" ] || return 0
    sed -n 's/^[[:space:]]*- key:[[:space:]]*\([A-Za-z_][A-Za-z0-9_]*\).*/\1/p' "$f"
    sed -n 's/^needs_declaration:[[:space:]]*\[\(.*\)\][[:space:]]*$/\1/p' "$f" \
        | tr ',' '\n' \
        | tr -d "[]\"' " \
        | grep -E "$VALID_KEY_RE" || true
}

KEYS=()
if [ -n "$KEYS_ARG" ]; then
    IFS=',' read -r -a _raw <<< "$KEYS_ARG"
    for k in "${_raw[@]}"; do
        k="${k#"${k%%[![:space:]]*}"}"
        k="${k%"${k##*[![:space:]]}"}"
        [ -n "$k" ] || continue
        if ! printf '%s' "$k" | grep -qE "$VALID_KEY_RE"; then
            echo "redact.sh: clave inválida: '$k'" >&2
            exit 64
        fi
        KEYS+=("$k")
    done
else
    while IFS= read -r k; do
        [ -n "$k" ] || continue
        printf '%s' "$k" | grep -qE "$VALID_KEY_RE" || continue
        KEYS+=("$k")
    done < <(collect_catalog_keys "$CATALOG")
fi

if [ "${#KEYS[@]}" -gt 0 ]; then
    mapfile -t KEYS < <(printf '%s\n' "${KEYS[@]}" | awk '!seen[$0]++')
else
    echo "redact.sh: sin claves conocidas (catálogo: $CATALOG); passthrough sin redactar" >&2
    cat
    exit 0
fi

SED_ARGS=()
for k in "${KEYS[@]}"; do
    SED_ARGS+=(-e "s/\"${k}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"${k}\": \"<redacted:${k}>\"/g")
    SED_ARGS+=(-e "s/\"${k}\"[[:space:]]*:[[:space:]]*[^,}\"[:space:]][^,}]*/\"${k}\": \"<redacted:${k}>\"/g")
    SED_ARGS+=(-e "s/(^|[^A-Za-z0-9_])${k}=\"[^\"]*\"/\\1${k}=\"<redacted:${k}>\"/g")
    SED_ARGS+=(-e "s/(^|[^A-Za-z0-9_])${k}=[^[:space:]\"'][^[:space:]\"']*/\\1${k}=<redacted:${k}>/g")
    SED_ARGS+=(-e "s/(^|[^A-Za-z0-9_])${k}:[[:space:]]+.*$/\\1${k}: <redacted:${k}>/")
done

sed -E "${SED_ARGS[@]}"
