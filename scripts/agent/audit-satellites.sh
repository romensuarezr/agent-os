#!/usr/bin/env bash
# ==============================================================================
# audit-satellites.sh — Auditoría determinista de integridad de satélites (T-184)
# ==============================================================================
# Uso: bash scripts/agent/audit-satellites.sh [--satellites <yaml>] [--check] [--json] [rutas...]
#
# Audita la integridad, desvíos (drift), permisos (+x) y ausencia de scripts
# en repositorios satélite comparándolos con los scripts estándar del core.
#
# READ-ONLY: no escribe ficheros, no toca git y no realiza peticiones de red.
# Códigos de salida:
#   0: Éxito (o en modo --check si todos los satélites están limpios).
#   1: En modo --check si se detecta drift, ausencia o falta de permisos.
#   2: Error de argumentos o sintaxis de uso.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CORE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"

# shellcheck source=scripts/agent/lib/cli-help.sh
source "$SCRIPT_DIR/lib/cli-help.sh"

SATELLITES_FILE=""
CHECK_MODE=false
JSON_MODE=false
EXPLICIT_PATHS=()

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      show_help "audit-satellites.sh" \
        "bash scripts/agent/audit-satellites.sh [--satellites <yaml>] [--check] [--json] [rutas...]" \
        "Audita la integridad, permisos (+x), ausencia y desvios de scripts en satelites vs core. Solo lectura: cero escrituras, cero git y cero red." \
        "--satellites <yaml>      Declaracion con bloque 'satellites:' (alias y path)" \
        "--check                  Sale con codigo 1 si detecta desvios, ausencia o permisos invalidos" \
        "--json                   Emite el informe completo en formato JSON estructurado" \
        "<rutas...>               Rutas de repositorios satelite directos para auditar" \
        "-h, --help               Muestra este mensaje de ayuda" \
        "ejemplo: bash scripts/agent/audit-satellites.sh --check" \
        "ejemplo: bash scripts/agent/audit-satellites.sh --satellites .agents/config/satellites.yaml" \
        "ejemplo: bash scripts/agent/audit-satellites.sh --json ~/Proyectos/mi-satelite"
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
    --check)
      CHECK_MODE=true
      shift
      ;;
    --json)
      JSON_MODE=true
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

# ─── Utilidades deterministas ────────────────────────────────────────────────
calc_sha256() {
  local target="$1"
  if [ ! -f "$target" ]; then
    printf ''
    return 0
  fi
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$target" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$target" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$target" 2>/dev/null | sed 's/.*= //'
  else
    python3 -c "import hashlib, sys; print(hashlib.sha256(open(sys.argv[1], 'rb').read()).hexdigest())" "$target" 2>/dev/null || printf ''
  fi
}

as_resolve_dir() {
  (cd "$1" 2>/dev/null && pwd -P) || printf '%s\n' "$1"
}

as_json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

as_has_satellites_block() {
  [ -f "$1" ] && grep -qE '^satellites:[[:space:]]*$' "$1" 2>/dev/null
}

as_parse_satellites() {
  local file="$1"
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

# ─── Catálogo de scripts del Core ─────────────────────────────────────────────
CORE_SCRIPTS=()
if [ -d "$CORE_ROOT/scripts/agent" ]; then
  for sc in "$CORE_ROOT/scripts/agent"/*.sh; do
    [ -f "$sc" ] && CORE_SCRIPTS+=("scripts/agent/$(basename "$sc")")
  done
  if [ -d "$CORE_ROOT/scripts/agent/lib" ]; then
    for sc in "$CORE_ROOT/scripts/agent/lib"/*.sh; do
      [ -f "$sc" ] && CORE_SCRIPTS+=("scripts/agent/lib/$(basename "$sc")")
    done
  fi
fi

CORE_VER="unknown"
if [ -f "$CORE_ROOT/VERSION" ]; then
  CORE_VER="$(tr -d '[:space:]' < "$CORE_ROOT/VERSION" 2>/dev/null || echo "unknown")"
fi

# ─── Descubrimiento de satélites ─────────────────────────────────────────────
ENTRIES=()
if [ -n "$SATELLITES_FILE" ]; then
  if [ ! -f "$SATELLITES_FILE" ]; then
    echo "❌ ERROR: declaración de satélites no encontrada: $SATELLITES_FILE" >&2
    exit 2
  fi
  while IFS=$'\t' read -r a p; do
    [ -n "${a:-}" ] && [ -n "${p:-}" ] && ENTRIES+=("$a"$'\t'"$p")
  done < <(as_parse_satellites "$SATELLITES_FILE")
elif [ ${#EXPLICIT_PATHS[@]} -eq 0 ]; then
  for candidate in "$CORE_ROOT/.agents/config/fleet.yaml" "$CORE_ROOT/.agents/config/satellites.yaml"; do
    if as_has_satellites_block "$candidate"; then
      while IFS=$'\t' read -r a p; do
        [ -n "${a:-}" ] && [ -n "${p:-}" ] && ENTRIES+=("$a"$'\t'"$p")
      done < <(as_parse_satellites "$candidate")
      if [ ${#ENTRIES[@]} -gt 0 ]; then
        break
      fi
    fi
  done
fi

for p in ${EXPLICIT_PATHS[@]+"${EXPLICIT_PATHS[@]}"}; do
  clean_p="${p%/}"
  ENTRIES+=("$(basename "$clean_p")"$'\t'"$p")
done

# ─── Casos sin satélites ─────────────────────────────────────────────────────
if [ ${#ENTRIES[@]} -eq 0 ]; then
  if [ "$JSON_MODE" = true ]; then
    cat <<EOF
{
  "core": {
    "root": "$(as_json_escape "$CORE_ROOT")",
    "version": "$(as_json_escape "$CORE_VER")",
    "total_scripts": ${#CORE_SCRIPTS[@]}
  },
  "satellites": [],
  "summary": { "total": 0, "clean": 0, "drift": 0, "missing": 0, "no_exec": 0, "errors": 0 }
}
EOF
  else
    echo "📦 Core: $CORE_VER ($CORE_ROOT)"
    echo "ℹ️  No hay satélites configurados (usa --satellites <yaml> o pasa rutas)."
  fi
  exit 0
fi

# ─── Procesamiento y Auditoría ───────────────────────────────────────────────
SEEN_LIST=()
TOTAL=0
CLEAN=0
DRIFT_COUNT=0
MISSING_COUNT=0
NO_EXEC_COUNT=0
ERRORS_COUNT=0

SATELLITE_RESULTS=()

for entry in ${ENTRIES[@]+"${ENTRIES[@]}"}; do
  alias="${entry%%$'\t'*}"
  raw_path="${entry#*$'\t'}"
  case "$raw_path" in
    "~/"*) raw_path="${HOME:-}/${raw_path#\~/}" ;;
  esac
  real_path="$(as_resolve_dir "$raw_path")"

  dup=false
  for seen in ${SEEN_LIST[@]+"${SEEN_LIST[@]}"}; do
    if [ "$seen" = "$real_path" ]; then dup=true; break; fi
  done
  [ "$dup" = true ] && continue
  SEEN_LIST+=("$real_path")
  TOTAL=$((TOTAL + 1))

  sat_status="LIMPIO"
  sat_total=${#CORE_SCRIPTS[@]}
  sat_ok=0
  sat_drift=0
  sat_missing=0
  sat_no_exec=0
  ISSUES=()

  if [ "$real_path" = "$CORE_ROOT" ]; then
    sat_status="SELF"
    sat_ok=$sat_total
    SATELLITE_RESULTS+=("$alias"$'\t'"$real_path"$'\t'"$sat_status"$'\t'"$sat_total"$'\t'"$sat_ok"$'\t'"0"$'\t'"0"$'\t'"0")
    continue
  fi

  if [ ! -d "$real_path" ]; then
    sat_status="AUSENTE"
    sat_missing=$sat_total
    ERRORS_COUNT=$((ERRORS_COUNT + 1))
    SATELLITE_RESULTS+=("$alias"$'\t'"$real_path"$'\t'"$sat_status"$'\t'"$sat_total"$'\t'"0"$'\t'"0"$'\t'"$sat_total"$'\t'"0")
    continue
  fi

  for rel in "${CORE_SCRIPTS[@]}"; do
    core_f="$CORE_ROOT/$rel"
    sat_f="$real_path/$rel"

    if [ ! -f "$sat_f" ]; then
      sat_missing=$((sat_missing + 1))
      sat_status="DESFASADO"
      core_hash="$(calc_sha256 "$core_f")"
      ISSUES+=("$rel|MISSING|$core_hash||archivo ausente")
      continue
    fi

    drift=false
    no_exec=false

    if ! cmp -s "$core_f" "$sat_f"; then
      drift=true
      sat_drift=$((sat_drift + 1))
    fi

    if [ -x "$core_f" ] && [ ! -x "$sat_f" ]; then
      no_exec=true
      sat_no_exec=$((sat_no_exec + 1))
    fi

    if [ "$drift" = true ] && [ "$no_exec" = true ]; then
      sat_status="DESFASADO"
      core_hash="$(calc_sha256 "$core_f")"
      sat_hash="$(calc_sha256 "$sat_f")"
      ISSUES+=("$rel|DRIFT|$core_hash|$sat_hash|desvío de contenido y sin permiso +x")
    elif [ "$drift" = true ]; then
      sat_status="DESFASADO"
      core_hash="$(calc_sha256 "$core_f")"
      sat_hash="$(calc_sha256 "$sat_f")"
      ISSUES+=("$rel|DRIFT|$core_hash|$sat_hash|suma sha256 difiere")
    elif [ "$no_exec" = true ]; then
      sat_status="DESFASADO"
      core_hash="$(calc_sha256 "$core_f")"
      sat_hash="$(calc_sha256 "$sat_f")"
      ISSUES+=("$rel|NO-EXEC|$core_hash|$sat_hash|falta permiso de ejecución +x")
    else
      sat_ok=$((sat_ok + 1))
    fi
  done

  if [ "$sat_status" = "LIMPIO" ]; then
    CLEAN=$((CLEAN + 1))
  else
    DRIFT_COUNT=$((DRIFT_COUNT + sat_drift))
    MISSING_COUNT=$((MISSING_COUNT + sat_missing))
    NO_EXEC_COUNT=$((NO_EXEC_COUNT + sat_no_exec))
    ERRORS_COUNT=$((ERRORS_COUNT + 1))
  fi

  # Codificar issues concatenadas con pipes si existen
  encoded_issues=""
  for iss in ${ISSUES[@]+"${ISSUES[@]}"}; do
    if [ -n "$encoded_issues" ]; then
      encoded_issues="${encoded_issues}@@@${iss}"
    else
      encoded_issues="${iss}"
    fi
  done

  SATELLITE_RESULTS+=("$alias"$'\t'"$real_path"$'\t'"$sat_status"$'\t'"$sat_total"$'\t'"$sat_ok"$'\t'"$sat_drift"$'\t'"$sat_missing"$'\t'"$sat_no_exec"$'\t'"$encoded_issues")
done

# ─── Salida JSON ─────────────────────────────────────────────────────────────
if [ "$JSON_MODE" = true ]; then
  cat <<EOF
{
  "core": {
    "root": "$(as_json_escape "$CORE_ROOT")",
    "version": "$(as_json_escape "$CORE_VER")",
    "total_scripts": ${#CORE_SCRIPTS[@]}
  },
  "satellites": [
EOF
  first_sat=true
  for res in "${SATELLITE_RESULTS[@]}"; do
    IFS=$'\t' read -r r_alias r_path r_status r_total r_ok r_drift r_missing r_no_exec r_issues <<< "$res"
    if [ "$first_sat" = true ]; then
      first_sat=false
    else
      printf ',\n'
    fi

    cat <<EOF
    {
      "alias": "$(as_json_escape "$r_alias")",
      "path": "$(as_json_escape "$r_path")",
      "status": "$r_status",
      "stats": {
        "total": $r_total,
        "ok": $r_ok,
        "drift": $r_drift,
        "missing": $r_missing,
        "no_exec": $r_no_exec
      },
      "issues": [
EOF
    if [ -n "${r_issues:-}" ]; then
      first_issue=true
      IFS='@@@' read -ra iss_array <<< "$r_issues"
      for single_iss in "${iss_array[@]}"; do
        [ -z "$single_iss" ] && continue
        IFS='|' read -r i_script i_st i_chash i_shash i_det <<< "$single_iss"
        if [ "$first_issue" = true ]; then
          first_issue=false
        else
          printf ',\n'
        fi
        printf '        { "script": "%s", "status": "%s", "core_sha256": "%s", "sat_sha256": "%s", "detail": "%s" }' \
          "$(as_json_escape "$i_script")" "$i_st" "$i_chash" "$i_shash" "$(as_json_escape "$i_det")"
      done
    fi
    printf '\n      ]\n    }'
  done
  cat <<EOF

  ],
  "summary": {
    "total": $TOTAL,
    "clean": $CLEAN,
    "drift": $DRIFT_COUNT,
    "missing": $MISSING_COUNT,
    "no_exec": $NO_EXEC_COUNT,
    "errors": $ERRORS_COUNT
  }
}
EOF
else
  # ─── Salida Humana ───────────────────────────────────────────────────────────
  echo "📦 Core: $CORE_VER ($CORE_ROOT) · Total scripts auditables: ${#CORE_SCRIPTS[@]}"
  echo ""
  printf '%-20s %-10s %-8s %-8s %-8s %-8s\n' "ALIAS" "ESTADO" "OK" "DRIFT" "MISSING" "NO-EXEC"
  printf '%-20s %-10s %-8s %-8s %-8s %-8s\n' "--------------------" "----------" "--------" "--------" "--------" "--------"

  for res in "${SATELLITE_RESULTS[@]}"; do
    IFS=$'\t' read -r r_alias r_path r_status r_total r_ok r_drift r_missing r_no_exec r_issues <<< "$res"
    printf '%-20s %-10s %-8s %-8s %-8s %-8s\n' "$r_alias" "$r_status" "$r_ok" "$r_drift" "$r_missing" "$r_no_exec"

    if [ -n "${r_issues:-}" ]; then
      IFS='@@@' read -ra iss_array <<< "$r_issues"
      for single_iss in "${iss_array[@]}"; do
        [ -z "$single_iss" ] && continue
        IFS='|' read -r i_script i_st i_chash i_shash i_det <<< "$single_iss"
        echo "   ↳ [$i_st] $i_script ($i_det)"
      done
    fi
  done

  echo ""
  echo "📊 Satélites: $TOTAL · Limpios: $CLEAN · Drift: $DRIFT_COUNT · Missing: $MISSING_COUNT · No-exec: $NO_EXEC_COUNT · Con incidencias: $ERRORS_COUNT"
fi

# ─── Código de salida determinista ───────────────────────────────────────────
if [ "$CHECK_MODE" = true ]; then
  if [ "$ERRORS_COUNT" -gt 0 ]; then
    exit 1
  fi
fi

exit 0
