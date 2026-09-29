#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/lib/cli-help.sh — Formateador estándar de ayuda CLI para Agent OS
# ==============================================================================
# Uso:
#   source "$(dirname "$0")/lib/cli-help.sh"
#   show_help <nombre> <sinopsis> <descripcion> [parametros/ejemplos...]
#
# Formato estandarizado emitido:
#   - Sinopsis de invocación
#   - Descripción del comando
#   - Parámetros y opciones aceptadas
#   - Ejemplos prácticos de ejecución
#   - exit 0
# ==============================================================================

show_help() {
  local name="${1:-}"
  local synopsis="${2:-}"
  local description="${3:-}"
  shift 3 2>/dev/null || true

  echo "Uso: $synopsis"
  echo ""
  echo "Descripción:"
  echo "  $description"
  echo ""

  local -a params=()
  local -a examples=()
  local has_help_param=false

  while [ $# -gt 0 ]; do
    local item="$1"
    shift
    if [[ "$item" =~ ^([eE][jJ][eE][mM][pP][lL][oO]|[eE][xX][aA][mM][pP][lL][eE]):[[:space:]]*(.*)$ ]]; then
      examples+=("${BASH_REMATCH[2]}")
    else
      if [[ "$item" =~ (-h|--help) ]]; then
        has_help_param=true
      fi
      params+=("$item")
    fi
  done

  if [ "$has_help_param" = false ]; then
    params+=("-h, --help               Muestra este mensaje de ayuda")
  fi

  echo "Opciones / Parámetros:"
  for p in "${params[@]}"; do
    echo "  $p"
  done
  echo ""

  if [ ${#examples[@]} -gt 0 ]; then
    echo "Ejemplos:"
    for ex in "${examples[@]}"; do
      echo "  $ex"
    done
    echo ""
  fi

  exit 0
}
