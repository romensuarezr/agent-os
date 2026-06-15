#!/bin/bash
# inventory-check.sh — Verifica código existente antes de crear task file o planificar sprint
# Uso: bash scripts/agent/inventory-check.sh "palabras clave separadas por espacio"
# Ejemplo: bash scripts/agent/inventory-check.sh "timeline propuesta respuesta modal"
#
# Propósito: Evitar que se describan tareas como "no implementadas" cuando ya existen.
# Ejecutar ANTES de redactar el scope en .agents/tasks/task-XXX.md
# y ANTES de añadir una tarea al sprint (paso 2c de sprint-planning).
#
# Al final del check, evalúa la señal de complejidad (0–3).
# Si SIGNAL >= 2, genera automáticamente un digest de la zona caliente
# via generate-digest.sh para que el agente tenga contexto panorámico.
# El test -f en session-start sigue siendo el firewall determinista final.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
KEYWORDS="$*"

if [ -z "$KEYWORDS" ]; then
  echo "❌ Uso: bash scripts/agent/inventory-check.sh \"keywords de la tarea\""
  echo "   Ejemplo: bash scripts/agent/inventory-check.sh \"timeline propuesta respuesta\""
  exit 1
fi

# Cargar biblioteca de detección de stack
source "$(dirname "$0")/lib/detect-stack.sh"
detect_stack "$ROOT"

# Salvaguarda: si el directorio de código no existe, salir limpio con 0
if [ ! -d "$SRC_DIR" ]; then
  echo "=== INVENTORY CHECK ==="
  echo "Palabras clave: $KEYWORDS"
  echo "⚠️  El directorio de código '$SRC_DIR' no existe en este proyecto."
  echo "✅ Sin coincidencias. Puedes describir la tarea desde cero."
  echo "=== FIN INVENTORY CHECK ==="
  exit 0
fi

echo "=== INVENTORY CHECK ==="
echo "Palabras clave: $KEYWORDS"
echo "Directorio: $SRC_DIR"
echo ""

FOUND_COUNT=0
ALL_MATCHES=""

# 1. Buscar archivos cuyo NOMBRE contiene alguna keyword
echo "📁 Archivos cuyo nombre coincide:"
for keyword in $KEYWORDS; do
  MATCHES=$(find "$SRC_DIR" -type f \( "${CODE_EXTS_FIND[@]}" \) \
    -iname "*${keyword}*" 2>/dev/null | head -5 || true)
  if [ -n "$MATCHES" ]; then
    while IFS= read -r f; do
      KB=$(wc -c < "$f" 2>/dev/null | awk '{printf "%.1f", $1/1024}')
      FLAG="new"
      [ "$(wc -c < "$f" 2>/dev/null)" -gt 3072 ] && FLAG="⚠️  EXISTE (${KB}KB)"
      echo "    ↳ ${f#$ROOT/}  [$FLAG]"
      FOUND_COUNT=$((FOUND_COUNT + 1))
      ALL_MATCHES="$ALL_MATCHES\n$f"
    done <<< "$MATCHES"
  fi
done
[ $FOUND_COUNT -eq 0 ] && echo "    (sin coincidencias por nombre)"

# 2. Buscar archivos cuyo CONTENIDO menciona las keywords (grep, limitado a 5 por keyword)
echo ""
echo "🔍 Archivos que contienen las keywords en su código:"
for keyword in $KEYWORDS; do
  MATCHES=$(grep -rl -i "$keyword" "$SRC_DIR" "${CODE_EXTS_GREP[@]}" \
    2>/dev/null | head -5 || true)
  if [ -n "$MATCHES" ]; then
    echo "  '$keyword':"
    while IFS= read -r f; do
      KB=$(wc -c < "$f" 2>/dev/null | awk '{printf "%.1f", $1/1024}')
      FLAG=""
      [ "$(wc -c < "$f" 2>/dev/null)" -gt 3072 ] && FLAG="  ⚠️  ${KB}KB — no recrear"
      echo "    ↳ ${f#$ROOT/}${FLAG}"
      FOUND_COUNT=$((FOUND_COUNT + 1))
      ALL_MATCHES="$ALL_MATCHES\n$f"
    done <<< "$MATCHES"
  fi
done

# 3. Buscar interfaces/tipos en archivos de definición/datos
echo ""
echo "📄 Tipos/modelos relacionados:"
found_types_files=0
for pat in "${TYPES_PATTERNS[@]}"; do
  TYPES_FILES=$(find "$SRC_DIR" -name "$pat" 2>/dev/null || true)
  if [ -n "$TYPES_FILES" ]; then
    found_types_files=1
    for TYPES_FILE in $TYPES_FILES; do
      for keyword in $KEYWORDS; do
        MATCHES=$(grep -i "$keyword" "$TYPES_FILE" 2>/dev/null | head -3 || true)
        if [ -n "$MATCHES" ]; then
          echo "  '$keyword' en $(basename "$TYPES_FILE"):"
          echo "$MATCHES" | sed 's|^|    ↳ |'
          FOUND_COUNT=$((FOUND_COUNT + 1))
          ALL_MATCHES="$ALL_MATCHES\n$TYPES_FILE"
        fi
      done
    done
  fi
done
[ $found_types_files -eq 0 ] && echo "    (sin archivos de definición de datos/tipos)"

# 4. Servicios/Hooks relacionados
echo ""
echo "🪝 $SERVICES_LABEL:"
if [ -d "$SERVICES_DIR" ]; then
  KEYWORD_PATTERN=$(echo "$KEYWORDS" | tr ' ' '\|')
  MATCHES=$(grep -rl -i "$KEYWORD_PATTERN" "$SERVICES_DIR" "${CODE_EXTS_GREP[@]}" \
    2>/dev/null | head -5 || true)
  if [ -n "$MATCHES" ]; then
    echo "$MATCHES" | sed "s|$ROOT/||" | sed 's|^|    ↳ |'
    FOUND_COUNT=$((FOUND_COUNT + 1))
    ALL_MATCHES="$ALL_MATCHES\n$MATCHES"
  else
    echo "    (ninguno)"
  fi
else
  echo "    ($SERVICES_DIR no existe)"
fi

echo ""
echo "=== FIN INVENTORY CHECK ==="
echo ""

# ── Evaluación de complejidad para digest condicional ────────────────────────

# 1. Archivos únicos detectados
UNIQUE_FILES=$(printf "%b" "$ALL_MATCHES" | grep -v '^$' | sort -u | grep -c . 2>/dev/null || echo 0)

# 2. Capas distintas afectadas
LAYERS=0
for layer_pat in "${COMPLEXITY_LAYERS[@]}"; do
  printf "%b" "$ALL_MATCHES" | grep -qi "$layer_pat" && LAYERS=$((LAYERS + 1)) || true
done

# 3. Subcarpeta caliente (>=2 archivos en la misma ruta de 2 niveles)
HOT_FOLDER=$(printf "%b" "$ALL_MATCHES" | grep -v '^$' \
  | grep -oE "$HOT_FOLDER_REGEX" 2>/dev/null \
  | sort | uniq -c | sort -rn \
  | awk '$1 >= 2 {print $2; exit}' || echo "")

# 4. Evaluar umbral: >=2 condiciones activas
SIGNAL=0
[ "$UNIQUE_FILES" -ge 3 ] && SIGNAL=$((SIGNAL + 1)) || true
[ "$LAYERS" -ge 2 ]       && SIGNAL=$((SIGNAL + 1)) || true
[ -n "$HOT_FOLDER" ]      && SIGNAL=$((SIGNAL + 1)) || true

echo "=== EVALUACIÓN DE COMPLEJIDAD ==="
echo "  Archivos únicos:  $UNIQUE_FILES"
echo "  Capas afectadas:  $LAYERS / ${#COMPLEXITY_LAYERS[@]} ($COMPLEXITY_LABELS)"
echo "  Carpeta caliente: ${HOT_FOLDER:-(ninguna)}"
echo "  Señal total:      $SIGNAL / 3"
echo ""

if [ "$SIGNAL" -ge 2 ]; then
  echo "⚠️  Señal de complejidad alta. Generando digest de contexto compacto..."
  DIGEST_FILTER="${HOT_FOLDER:-$SRC_DIR}"
  EXCLUDE_OPTS=""
  if [ "$DIGEST_FILTER" = "$SRC_DIR" ]; then
    echo "   (sin subcarpeta clara → digest de $SRC_DIR excluyendo ficheros del stack)"
    # Expandir los patrones de exclusión de digest
    EXCLUDE_OPTS="--exclude-pattern $(echo "${DIGEST_EXCLUDE[@]}")"
  fi
  echo ""
  bash "$(dirname "$0")/generate-digest.sh" --filter "${DIGEST_FILTER#$ROOT/}" $EXCLUDE_OPTS
  echo ""
  echo "💡 Usa el digest para redactar '## Código existente detectado' en el task file."
  echo "   El test -f en session-start sigue siendo el firewall determinista final."

elif [ $FOUND_COUNT -gt 0 ]; then
  echo "⚠️  Coincidencias encontradas pero señal de complejidad baja."
  echo "   1. Lee los archivos marcados con ⚠️  antes de escribir el task file."
  echo "   2. Describe SOLO lo que FALTA, no lo que ya está implementado."
  echo "   3. Si el scope ya está >50% cubierto → consulta con el usuario antes de planificar."

else
  echo "✅ Sin coincidencias. Puedes describir la tarea desde cero."
fi
