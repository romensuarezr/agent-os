#!/usr/bin/env bash
# ==============================================================================
# fleet-version.sh — Desfase de versión entre el core y los satélites (T-115)
# ==============================================================================
# Uso: bash scripts/agent/fleet-version.sh [--satellites <yaml>] [--json] [rutas...]
#
# Lee el ledger `.agents/context/last-sync.md` que escriben install.sh y sync.sh
# (fecha, version, tag, commit) y lo compara con el VERSION del core.
#
# READ-ONLY: no escribe ficheros, no toca git y no hace llamadas de red.
# Exit 0 salvo error de uso (2) o core sin VERSION legible (1).
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CORE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
# shellcheck source=scripts/agent/lib/cli-help.sh
source "$SCRIPT_DIR/lib/cli-help.sh"

SATELLITES_FILE=""
JSON=false
EXPLICIT_PATHS=()

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      show_help "fleet-version.sh" \
        "bash scripts/agent/fleet-version.sh [--satellites <yaml>] [--json] [rutas...]" \
        "Compara la version del core con la que cada satelite registro en su ledger .agents/context/last-sync.md. Solo lectura: no escribe, no toca git y no usa la red." \
        "--satellites <yaml>      Declaracion con bloque 'satellites:' (alias y path)" \
        "--json                   Emite el digest en JSON estable" \
        "<rutas...>               Rutas de satelites anadidas a las de la declaracion" \
        "-h, --help               Muestra este mensaje de ayuda" \
        "ejemplo: bash scripts/agent/fleet-version.sh --satellites .agents/config/satellites.yaml" \
        "ejemplo: bash scripts/agent/fleet-version.sh --json ~/Proyectos/mi-sat"
      ;;
    --satellites)
      if [ $# -lt 2 ]; then
        echo "❌ ERROR: --satellites requiere una ruta." >&2
        exit 2
      fi
      SATELLITES_FILE="$2"
      shift 2
      ;;
    --satellites=*)
      SATELLITES_FILE="${1#*=}"
      shift
      ;;
    --json)
      JSON=true
      shift
      ;;
    --)
      shift
      while [ $# -gt 0 ]; do
        EXPLICIT_PATHS+=("$1")
        shift
      done
      ;;
    -*)
      echo "❌ ERROR: opción desconocida: $1" >&2
      echo "   Usa --help para ver las opciones disponibles." >&2
      exit 2
      ;;
    *)
      EXPLICIT_PATHS+=("$1")
      shift
      ;;
  esac
done

# ─── Semver por componentes (sin sort -V: BSD no lo soporta) ─────────────────
fv_semver_valid() {
  case "$1" in
    ''|*[!0-9.]*) return 1 ;;
  esac
  printf '%s\n' "$1" | grep -Eq '^[0-9]+\.[0-9]+(\.[0-9]+)?$'
}

fv_semver_parts() {
  local v="${1#v}"
  FV_MAJ="${v%%.*}"
  FV_MIN=0
  FV_PAT=0
  case "$v" in
    *.*)
      local rest="${v#*.}"
      case "$rest" in
        *.*) FV_MIN="${rest%%.*}"; FV_PAT="${rest#*.}" ;;
        *)   FV_MIN="$rest" ;;
      esac
      ;;
  esac
  FV_MAJ=$((10#$FV_MAJ))
  FV_MIN=$((10#$FV_MIN))
  FV_PAT=$((10#$FV_PAT))
}

fv_semver_cmp() {
  local am ai ap bm bi bp
  fv_semver_parts "$1"
  am=$FV_MAJ; ai=$FV_MIN; ap=$FV_PAT
  fv_semver_parts "$2"
  bm=$FV_MAJ; bi=$FV_MIN; bp=$FV_PAT
  if [ "$am" -ne "$bm" ]; then
    if [ "$am" -gt "$bm" ]; then echo 1; else echo -1; fi
  elif [ "$ai" -ne "$bi" ]; then
    if [ "$ai" -gt "$bi" ]; then echo 1; else echo -1; fi
  elif [ "$ap" -ne "$bp" ]; then
    if [ "$ap" -gt "$bp" ]; then echo 1; else echo -1; fi
  else
    echo 0
  fi
}

# ─── Versión del core ────────────────────────────────────────────────────────
if [ ! -f "$CORE_ROOT/VERSION" ]; then
  echo "❌ ERROR: no se encontró VERSION en el core ($CORE_ROOT)." >&2
  exit 1
fi
CORE_VER="$(tr -d '[:space:]' < "$CORE_ROOT/VERSION" 2>/dev/null || true)"
if ! fv_semver_valid "$CORE_VER"; then
  echo "❌ ERROR: VERSION del core no es semver válida: '${CORE_VER}'." >&2
  exit 1
fi

# ─── Descubrimiento de satélites ─────────────────────────────────────────────
fv_has_satellites_block() {
  [ -f "$1" ] && grep -qE '^satellites:[[:space:]]*$' "$1" 2>/dev/null
}

fv_parse_satellites() {
  local file="$1" alias path
  awk '
    /^satellites:[[:space:]]*$/ { inside=1; next }
    inside && /^[^[:space:]#]/ { inside=0 }
    inside && /^[[:space:]]*#/ { next }
    inside && /^  [A-Za-z0-9._-]+:[[:space:]]*$/ {
      alias=$0
      sub(/^[[:space:]]*/, "", alias)
      sub(/:.*$/, "", alias)
      next
    }
    inside && /^    path:/ {
      path=$0
      sub(/^    path:[[:space:]]*/, "", path)
      sub(/[[:space:]]+#.*$/, "", path)
      if (alias != "") { printf "%s\t%s\n", alias, path; alias="" }
    }
  ' "$file" 2>/dev/null || true
}

ENTRIES=()
if [ -n "$SATELLITES_FILE" ]; then
  if [ ! -f "$SATELLITES_FILE" ]; then
    echo "❌ ERROR: declaración de satélites no encontrada: $SATELLITES_FILE" >&2
    exit 2
  fi
  while IFS=$'\t' read -r a p; do
    [ -n "${a:-}" ] && [ -n "${p:-}" ] && ENTRIES+=("$a"$'\t'"$p")
  done < <(fv_parse_satellites "$SATELLITES_FILE")
elif [ ${#EXPLICIT_PATHS[@]} -eq 0 ]; then
  for candidate in "$CORE_ROOT/.agents/config/fleet.yaml" "$CORE_ROOT/.agents/config/satellites.yaml"; do
    if fv_has_satellites_block "$candidate"; then
      while IFS=$'\t' read -r a p; do
        [ -n "${a:-}" ] && [ -n "${p:-}" ] && ENTRIES+=("$a"$'\t'"$p")
      done < <(fv_parse_satellites "$candidate")
      if [ ${#ENTRIES[@]} -gt 0 ]; then
        break
      fi
    fi
  done
fi

for p in ${EXPLICIT_PATHS[@]+"${EXPLICIT_PATHS[@]}"}; do
  ENTRIES+=("$(basename "${p%/}")"$'\t'"$p")
done

# ─── Lectura del ledger ──────────────────────────────────────────────────────
fv_resolve_dir() {
  (cd "$1" 2>/dev/null && pwd -P) || printf '%s\n' "$1"
}

fv_json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

ROWS=()
SEEN_LIST=()
TOTAL=0
ALIGNED=0
DRIFT=0
LEGACY=0
ABSENT=0
SELF=0

for entry in ${ENTRIES[@]+"${ENTRIES[@]}"}; do
  alias="${entry%%$'\t'*}"
  raw_path="${entry#*$'\t'}"
  case "$raw_path" in
    "~/"*) raw_path="$HOME/${raw_path#\~/}" ;;
  esac
  real_path="$(fv_resolve_dir "$raw_path")"

  dup=false
  for seen in ${SEEN_LIST[@]+"${SEEN_LIST[@]}"}; do
    if [ "$seen" = "$real_path" ]; then dup=true; break; fi
  done
  [ "$dup" = true ] && continue
  SEEN_LIST+=("$real_path")
  TOTAL=$((TOTAL + 1))

  ledger="$real_path/.agents/context/last-sync.md"
  ver=""
  tag=""
  commit=""
  date=""

  if [ "$real_path" = "$CORE_ROOT" ]; then
    status="SELF"
    SELF=$((SELF + 1))
  elif [ -f "$ledger" ] && head -n 1 "$ledger" 2>/dev/null | grep -q "Estado operativo del core"; then
    status="SELF"
    SELF=$((SELF + 1))
  elif [ ! -f "$ledger" ]; then
    status="AUSENTE"
    ABSENT=$((ABSENT + 1))
  else
    date="$(head -n 1 "$ledger" 2>/dev/null | awk '{print $1}' || true)"
    ver="$(grep -E '^version:' "$ledger" 2>/dev/null | head -1 | awk '{print $2}' || true)"
    ver="${ver#v}"
    tag="$(grep -E '^tag:' "$ledger" 2>/dev/null | head -1 | awk '{print $2}' || true)"
    commit="$(grep -E '^commit:' "$ledger" 2>/dev/null | head -1 | awk '{print $2}' || true)"
    if ! fv_semver_valid "$ver"; then
      status="LEGACY"
      LEGACY=$((LEGACY + 1))
    elif [ "$(fv_semver_cmp "$ver" "$CORE_VER")" = "0" ]; then
      status="ALINEADO"
      ALIGNED=$((ALIGNED + 1))
    else
      status="DESFASE"
      DRIFT=$((DRIFT + 1))
    fi
  fi

  ROWS+=("$alias"$'\t'"$real_path"$'\t'"$status"$'\t'"${ver:-}"$'\t'"${date:-}"$'\t'"${tag:-}")
done

# ─── Salida JSON ─────────────────────────────────────────────────────────────
if [ "$JSON" = true ]; then
  configured=false
  [ "$TOTAL" -gt 0 ] && configured=true
  printf '{\n'
  printf '  "core": { "version": "%s" },\n' "$(fv_json_escape "$CORE_VER")"
  printf '  "configured": %s,\n' "$configured"
  printf '  "satellites": ['
  first=true
  while IFS=$'\t' read -r alias real_path status ver date tag; do
    [ -z "${alias:-}" ] && continue
    if [ "$first" = true ]; then
      printf '\n'
      first=false
    else
      printf ',\n'
    fi
    direction=""
    delta="null"
    if [ "$status" = "DESFASE" ]; then
      if [ "$(fv_semver_cmp "$ver" "$CORE_VER")" = "-1" ]; then
        direction="atras"
      else
        direction="adelante"
      fi
      fv_semver_parts "$ver"; sm=$FV_MAJ; si=$FV_MIN; sp=$FV_PAT
      fv_semver_parts "$CORE_VER"; cm=$FV_MAJ; ci=$FV_MIN; cp=$FV_PAT
      dm=0; di=0; dp=0
      if [ "$sm" -ne "$cm" ]; then
        if [ "$sm" -gt "$cm" ]; then dm=$((sm - cm)); else dm=$((cm - sm)); fi
      elif [ "$si" -ne "$ci" ]; then
        if [ "$si" -gt "$ci" ]; then di=$((si - ci)); else di=$((ci - si)); fi
      elif [ "$sp" -ne "$cp" ]; then
        if [ "$sp" -gt "$cp" ]; then dp=$((sp - cp)); else dp=$((cp - sp)); fi
      fi
      delta="{\"major\": $dm, \"minor\": $di, \"patch\": $dp}"
    fi
    printf '    { "alias": "%s", "path": "%s", "status": "%s", "version": "%s", "date": "%s", "tag": "%s", "direction": "%s", "delta": %s }' \
      "$(fv_json_escape "$alias")" "$(fv_json_escape "$real_path")" "$status" \
      "$(fv_json_escape "$ver")" "$(fv_json_escape "$date")" "$(fv_json_escape "$tag")" \
      "$direction" "$delta"
  done < <(printf '%s\n' ${ROWS[@]+"${ROWS[@]}"} | sort)
  printf '\n  ],\n'
  printf '  "summary": { "total": %d, "aligned": %d, "drift": %d, "legacy": %d, "absent": %d, "self": %d }\n' \
    "$TOTAL" "$ALIGNED" "$DRIFT" "$LEGACY" "$ABSENT" "$SELF"
  printf '}\n'
  exit 0
fi

# ─── Salida humana ───────────────────────────────────────────────────────────
echo "📦 Versión del core: $CORE_VER ($CORE_ROOT)"
if [ "$TOTAL" -eq 0 ]; then
  echo "ℹ️  No hay satélites configurados (usa --satellites <yaml> o pasa rutas)."
  exit 0
fi

echo ""
printf '%-20s %-10s %-14s %s\n' "ALIAS" "ESTADO" "SATÉLITE" "DETALLE"
printf '%-20s %-10s %-14s %s\n' "--------------------" "----------" "--------------" "-------"
while IFS=$'\t' read -r alias real_path status ver date tag; do
  [ -z "${alias:-}" ] && continue
  detail=""
  case "$status" in
    ALINEADO) detail="core $CORE_VER" ;;
    DESFASE)
      if [ "$(fv_semver_cmp "$ver" "$CORE_VER")" = "-1" ]; then
        detail="atrás (core $CORE_VER)"
      else
        detail="adelante (core $CORE_VER)"
      fi
      ;;
    LEGACY) detail="version no declarada o no semver" ;;
    AUSENTE) detail="sin .agents/context/last-sync.md" ;;
    SELF) detail="el propio core (no es ledger)" ;;
  esac
  printf '%-20s %-10s %-14s %s\n' "$alias" "$status" "${ver:--}" "$detail"
done < <(printf '%s\n' ${ROWS[@]+"${ROWS[@]}"} | sort)

echo ""
echo "📊 Total: $TOTAL · alineados: $ALIGNED · desfase: $DRIFT · legacy: $LEGACY · ausentes: $ABSENT · self: $SELF"
exit 0
