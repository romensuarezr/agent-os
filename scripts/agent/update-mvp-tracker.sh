#!/usr/bin/env bash
# =============================================================================
# update-mvp-tracker.sh
# Recalcula el % global del MVP Tracker leyendo la tabla de capacidades
# en docs/MVP-TRACKER.md y actualiza la fila TOTAL y el historial.
#
# Uso (manual o desde sprint-planning):
#   bash scripts/agent/update-mvp-tracker.sh [--sprint sprint-16] [--dry-run]
#
# Qué hace:
#   1. Lee las filas | C? | ... | peso | ... | % | de MVP-TRACKER.md
#   2. Calcula: total = Σ(peso_i × %_i) / 100
#   3. Actualiza la fila | **TOTAL** | en la tabla
#   4. Añade una fila al Historial de actualizaciones
#   5. Hace git add del archivo (no commitea — el agente decide el mensaje)
#
# Qué NO hace:
#   - No modifica % individuales de capacidades (eso es decisin humana/agente)
#   - No commitea directamente
# =============================================================================

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
TRACKER="$ROOT/docs/MVP-TRACKER.md"
DRY_RUN=false
SPRINT_LABEL="—"

# --- Args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sprint) SPRINT_LABEL="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "❌ Argumento desconocido: $1"; exit 1 ;;
  esac
done

if [ ! -f "$TRACKER" ]; then
  echo "❌ No se encuentra $TRACKER"
  exit 1
fi

echo "🔍 Leyendo capacidades desde $TRACKER..."

# --- Parsear filas de capacidad (| C1 | ... | peso | estado | % | ... ) ---
# Formato esperado: | C? | Nombre | peso | estado | % | ... |
# Usamos python3 para la aritmtica de punto flotante
PYTHON_RESULT=$(python3 - "$TRACKER" <<'EOF'
import sys, re, pathlib

tracker = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "").read_text() if len(sys.argv) > 1 else open('/dev/stdin').read()
lines = tracker.splitlines()

total_weighted = 0.0
capacities_found = 0

for line in lines:
    # Busca filas tipo: | C1 | ... | 15 | 🟢 | 95 | ... |
    m = re.match(r'^\|\s*(C\d+)\s*\|.*?\|\s*(\d+)\s*\|[^|]+\|\s*(\d+)\s*\|', line)
    if m:
        peso = int(m.group(2))
        pct  = int(m.group(3))
        total_weighted += peso * pct
        capacities_found += 1

if capacities_found == 0:
    print("ERROR: no se encontraron filas de capacidad")
    sys.exit(1)

global_pct = total_weighted / 100
print(round(global_pct))
EOF
)

if [[ "$PYTHON_RESULT" == ERROR* ]]; then
  echo "❌ $PYTHON_RESULT"
  exit 1
fi

GLOBAL_PCT="$PYTHON_RESULT"
GLOBAL_PCT_ROUNDED="$GLOBAL_PCT"
TODAY=$(date +%Y-%m-%d)

echo "📊 Progreso MVP calculado: ${GLOBAL_PCT}% → ${GLOBAL_PCT_ROUNDED}%"

if [ "$DRY_RUN" = true ]; then
  echo "🟡 Dry-run activo. No se modifica el archivo."
  exit 0
fi

# --- Actualizar fila TOTAL en la tabla ---
# Busca la lnea que empieza con | **TOTAL** | y reemplaza el % (5 columna)
python3 - <<EOF
import re, pathlib

path = pathlib.Path("$TRACKER")
content = path.read_text()

# Actualizar fila TOTAL: | **TOTAL** | | **100** | | X% | | |
new_total_line = r'| **TOTAL** | | **100** | | **${GLOBAL_PCT_ROUNDED}%** | | |'
content = re.sub(
    r'^\| \*\*TOTAL\*\* \|.*$',
    new_total_line,
    content,
    flags=re.MULTILINE
)

# Actualizar nota de clculo debajo de la tabla
contents_split = content.split("\n")
new_lines = []
for line in contents_split:
    if line.startswith('> 🧮 Cálculo:'):
        # No tocamos esta lnea — la actualiza el agente manualmente en sprint-planning
        new_lines.append(line)
    else:
        new_lines.append(line)
content = "\n".join(new_lines)

path.write_text(content)
print("Tabla TOTAL actualizada.")
EOF

# --- Añadir fila al historial ---
python3 - <<EOF
import pathlib

path = pathlib.Path("$TRACKER")
content = path.read_text()

new_row = "| $TODAY | $SPRINT_LABEL | ${GLOBAL_PCT_ROUNDED}% | Actualizado automáticamente por update-mvp-tracker.sh |"

# Insertar justo antes de la última lnea vaca del archivo para mantener el historial al final
# Busca la lnea de cierre de tabla del historial
marker = "| Fecha | Sprint | % global | Cambios reseñables |"
if marker not in content:
    print("❌ No se encontró marcador de historial en el tracker.")
    exit(1)

lines = content.splitlines()
insert_at = None
for i, line in enumerate(lines):
    if line.startswith('| Fecha | Sprint'):
        # La siguiente lnea es el separador |---|..., luego vienen las filas existentes
        # Insertamos al final de las filas existentes del historial
        insert_at = len(lines)  # por defecto al final
        for j in range(i+2, len(lines)):
            if not lines[j].startswith('|'):
                insert_at = j
                break
        break

if insert_at is not None:
    lines.insert(insert_at, new_row)
    path.write_text("\n".join(lines) + "\n")
    print("Fila historial añadida.")
else:
    print("⚠️ No se pudo insertar en historial — revisa la estructura del archivo.")
EOF

# --- git add (sin commit) ---
git -C "$ROOT" add "$TRACKER"

echo "✅ MVP-TRACKER.md actualizado y staged."
echo "   Progreso global: ${GLOBAL_PCT_ROUNDED}%"
echo "   Revisa el diff antes de commitear: git diff --staged docs/MVP-TRACKER.md"
