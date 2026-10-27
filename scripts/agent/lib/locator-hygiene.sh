#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/lib/locator-hygiene.sh — Agent OS
# Escáner de higiene de localizadores: detecta literales de infraestructura,
# rutas personales y patrones de credencial en ficheros del repositorio.
#
# Por qué existe: el core TIENE la política escrita (docs/critical-flows.md abre
# con un [IMPORTANT] que prohíbe literales de infraestructura) y tiene scripts de
# secretos. Lo que nunca tuvo fue aplicación: la regla existía y nadie la ejecutaba,
# así que la historia del repo la incumplía 451 veces.
#
# Esto es la versión ejecutable de la política. El mismo escáner lo usan:
#   - el check N de tests/validate-control-plane.sh (repo entero, en la suite)
#   - el hook pre-commit opcional (solo ficheros staged, en el momento de escribir)
#
# No reemplaza a secret-locate.sh: aquel busca secretos con VALOR en la bóveda y el
# entorno; este busca FUGAS de literales en ficheros. Son cosas distintas y se
# complementan.
#
# Uso:
#   bash scripts/agent/lib/locator-hygiene.sh [--staged] [--path <dir>] [--quiet]
#
#   --staged   Revisa solo los ficheros con cambios en el índice (uso del hook).
#   --path     Raíz a revisar. Por defecto, la del repo.
#   --quiet    Solo emite código de salida, sin detalle.
#
# Código de salida: 0 limpio | 1 hallazgo
# ==============================================================================
set -uo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$LIB_DIR/../../.." && pwd)"
STAGED=false
QUIET=false

while [ $# -gt 0 ]; do
    case "$1" in
        --staged) STAGED=true; shift ;;
        --path)   ROOT="$2"; shift 2 ;;
        --quiet)  QUIET=true; shift ;;
        -h|--help) sed -n '2,28p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Argumento no reconocido: $1" >&2; exit 2 ;;
    esac
done

EXCEPTIONS="$ROOT/.agents/config/infra-literals.exceptions"

say() { [ "$QUIET" = true ] || echo "$@"; }

# Igual que say(), pero para printf: los printf de formato NO pasan por say(), así que
# en --quiet se colaban por stdout y el check de la suite emitía ruido en el primer caso.
sayf() { [ "$QUIET" = true ] || printf "$@"; }

# ── Patrones prohibidos ──────────────────────────────────────────────────────
# Cada entrada: <etiqueta>|<regex extended>. Se stably desempareja así, y así se
# documenta en el fichero de excepciones.
PATTERNS=(
    "ruta-personal|/(home|Users)/[a-z0-9_-]+"
    "ip-tailscale|100\.(6[4-9]|[7-9][0-9]|1[0-2][0-7])\.[0-9]{1,3}\.[0-9]{1,3}"
    "ip-publica|4\.158\.179\.213|158\.179\.213\.240|141\.253\.197\.108"
    # "oracle" en minúscula es el nombre de un nodo de la flota; "Oracle" con mayúscula
    # es la base de datos y NO se toca (el patrón distingue por caja a propósito).
    "hostname-nodo|datamanager|vnic-rsr|vnic-susana|inteligencia-colectiva|\boracle\b"
    "credencial|freellmapi-[a-f0-9]{32,}|sk-[A-Za-z0-9]{32,}|ghp_[A-Za-z0-9]{30,}|AIza[0-9A-Za-z_-]{30,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----"
)

# ── Excepciones ──────────────────────────────────────────────────────────────
# Formato por línea: <etiqueta>|<regex>   # <motivo>
# Sin motivo, la excepción se descarta: una excepción sin justificación es un
# silencio accidental, que es justo lo que este escáner existe para evitar.
# Patrón acumulado como ARRAY, nunca como cadena con "|" delante: un separador
# inicial produciría una alternativa VACÍA que casa con cualquier línea y convertiría
# este escáner en "siempre limpio". Ese fallo existió y solo lo cazó la prueba negativa.
EXC_PAT=()
EXC_LAB=()
EXC_FILES=()
load_exceptions() {
    [ -f "$EXCEPTIONS" ] || return 0
    local line label pat motivo
    while IFS= read -r line; do
        case "$line" in ''|'#'*) continue ;; esac
        # Exención de FICHERO completo: "archivo:<glob>   # <motivo>".
        # Existe para el propio escáner, que contiene los literales que busca: sin esto
        # el control se detecta a sí mismo y sería imposible de dejar en verde.
        case "$line" in
            archivo:*)
                fglob="${line#archivo:}"; fglob="${fglob%%#*}"
                fglob="$(printf '%s' "$fglob" | sed 's/[[:space:]]*$//')"
                freason="${line#*#}"; freason="$(printf '%s' "$freason" | sed 's/^[[:space:]]*//')"
                if [ -z "$fglob" ] || [ -z "$freason" ]; then
                    say "  ⚠️  Exención de fichero sin motivo, se ignora: $line"
                    continue
                fi
                EXC_FILES+=("$fglob")
                continue
                ;;
        esac
        label="${line%%|*}"
        pat="${line#*|}"
        pat="${pat%%#*}"
        pat="$(printf '%s' "$pat" | sed 's/[[:space:]]*$//')"
        motivo="${line#*#}"
        motivo="$(printf '%s' "$motivo" | sed 's/^[[:space:]]*//')"
        if [ -z "$pat" ] || [ -z "$motivo" ]; then
            say "  ⚠️  Excepción sin motivo en $EXCEPTIONS, se ignora: $line"
            continue
        fi
        EXC_PAT+=("$pat")
        EXC_LAB+=("$label")
    done < "$EXCEPTIONS"
}
load_exceptions

# ── Ficheros a revisar ───────────────────────────────────────────────────────
FILES=""
if [ "$STAGED" = true ]; then
    FILES="$(git -C "$ROOT" diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)"
    if [ -z "$FILES" ]; then
        say "  (nada en staging)"
        exit 0
    fi
else
    FILES="$(git -C "$ROOT" ls-files 2>/dev/null || true)"
fi

FOUND=0

is_excepted() {
    local text="$1" i
    for i in "${!EXC_PAT[@]}"; do
        if printf '%s' "$text" | grep -qE "${EXC_PAT[$i]}"; then
            return 0
        fi
    done
    return 1
}

is_file_exempt() {
    local path="$1" g
    for g in "${EXC_FILES[@]}"; do
        # shellcheck disable=SC2254 # el glob viene del fichero de excepciones revisado
        case "$path" in $g) return 0 ;; esac
    done
    return 1
}

while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ -f "$ROOT/$f" ] || continue
    case "$f" in *.pyc|*.png|*.jpg|*.gif|*.ico|*.pdf|*.woff*|*.zip) continue ;; esac
    is_file_exempt "$f" && continue

    for entry in "${PATTERNS[@]}"; do
        label="${entry%%|*}"
        pat="${entry#*|}"
        while IFS= read -r hit; do
            [ -n "$hit" ] || continue
            lnum="${hit%%:*}"
            ltext="${hit#*:}"
            is_excepted "$ltext" && continue
            say "  ❌ [$label] $f:$lnum"
            sayf '       %s\n' "$(printf '%s' "$ltext" | cut -c1-130)"
            FOUND=$((FOUND + 1))
            break
        done < <(grep -nE "$pat" "$ROOT/$f" 2>/dev/null | head -3)
    done
done <<EOF
$FILES
EOF

if [ "$FOUND" -eq 0 ]; then
    say "  ✅ Sin literales de infraestructura, rutas personales ni credenciales."
    exit 0
fi

say ""
sayf "  ╔%s╗\n" "$(printf '═%.0s' $(seq 1 60))"
sayf "  ║ %-60s ║\n" "$FOUND hallazgo(s) que violan la frontera portable."
sayf "  ║ %-60s ║\n" "Política: docs/critical-flows.md (bloque [IMPORTANT])."
sayf "  ║ %-60s ║\n" "Excepción con motivo: .agents/config/infra-literals.exceptions"
sayf "  ╚%s╝\n" "$(printf '═%.0s' $(seq 1 60))"
exit 1