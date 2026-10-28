#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/design-digest.sh — Generador de registro histórico de diseño
# ==============================================================================
# Genera docs/sprints/design-decisions/T-XXX-digest.md para documentar las decisiones
# arquitectónicas, objeciones de arbitraje y patrones aplicados al cerrar cada tarea.
#
# Principios y Guardarraíles:
#   1. Lee .agents/context/plan-deliberation.json si existe.
#   2. Fallback determinista en frío: extrae objetivo y skills del task file,
#      ficheros tocados de `git diff HEAD~1` y mensaje de `git log -1`.
#   3. Canalización obligatoria por scripts/agent/lib/redact.sh (0 fugas de secretos).
#   4. Falla con exit code >0 si no puede redactar o generar el digest (fail-closed).
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/cli-help.sh"

for cmd in git python3 sed cat mkdir; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "❌ Error: Dependencia requerida '$cmd' no encontrada." >&2
    echo "💡 Guía: Instálala en tu sistema antes de continuar." >&2
    exit 1
  }
done

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

TASK_ID=""
OUTPUT_FILE=""
JSON_OUTPUT=false
EXPLICIT_KEYS=""

for arg in "$@"; do
  if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
    show_help "design-digest.sh" \
      "bash scripts/agent/design-digest.sh --task-id <ID> [--output <PATH>] [--keys <K1,K2>] [--json]" \
      "Genera el registro histórico de diseño y deliberación de una tarea, redactando secretos con lib/redact.sh." \
      "--task-id <ID>       ID de la tarea que se cierra (ej: T-121)." \
      "--output <PATH>      Ruta de destino del digest (defecto: docs/sprints/design-decisions/T-XXX-digest.md)." \
      "--keys <K1,K2>       Nombres de claves explícitas a redactar (separadas por comas)." \
      "--json               Emite la información generada como JSON a stdout." \
      "-h, --help           Muestra este mensaje de ayuda." \
      "ejemplo: bash scripts/agent/design-digest.sh --task-id T-121"
  fi
done

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task-id) TASK_ID="$2"; shift 2 ;;
    --output) OUTPUT_FILE="$2"; shift 2 ;;
    --keys) EXPLICIT_KEYS="$2"; shift 2 ;;
    --json) JSON_OUTPUT=true; shift ;;
    T-[0-9]*|[0-9]*)
      if [ -z "$TASK_ID" ]; then
        TASK_ID="$1"
        shift
      else
        echo "❌ Argumento desconocido: $1" >&2; exit 64
      fi
      ;;
    *) echo "❌ Argumento desconocido: $1" >&2; exit 64 ;;
  esac
done

if [ -z "$TASK_ID" ]; then
  # Intentar deducir de la rama activa
  BRANCH=$(git -C "$ROOT_DIR" branch --show-current 2>/dev/null || true)
  TASK_NUM=$(echo "$BRANCH" | sed -n 's/.*T-\([0-9][0-9]*\).*/\1/p')
  if [ -n "$TASK_NUM" ]; then
    TASK_ID="T-${TASK_NUM}"
  else
    echo "❌ Error: Argumento --task-id <ID> es obligatorio si no se puede deducir de la rama." >&2
    exit 64
  fi
fi

# Formato normalizado T-XXX
if [[ ! "$TASK_ID" =~ ^T- ]]; then
  TASK_ID="T-${TASK_ID}"
fi

TASK_NUM=$(echo "$TASK_ID" | sed 's/^T-//')
[ -n "$OUTPUT_FILE" ] || OUTPUT_FILE="$ROOT_DIR/docs/sprints/design-decisions/${TASK_ID}-digest.md"

REDACT_SCRIPT="$SCRIPT_DIR/lib/redact.sh"
if [ ! -f "$REDACT_SCRIPT" ]; then
  echo "❌ Error: Filtro obligatorio de secretos no encontrado: $REDACT_SCRIPT" >&2
  exit 1
fi

DELIBERATION_JSON="$ROOT_DIR/.agents/context/plan-deliberation.json"
PLAN_DRAFT="$ROOT_DIR/.agents/context/plan-draft.md"
TASK_FILE="$ROOT_DIR/.agents/tasks/task-${TASK_NUM}.md"
if [ ! -f "$TASK_FILE" ]; then
  TASK_FILE="$ROOT_DIR/.agents/tasks/_archived/task-${TASK_NUM}.md"
fi

# ==============================================================================
# EXTRACCIÓN DE INFORMACIÓN (EN CALIENTE O FALLBACK EN FRÍO)
# ==============================================================================
UNREDACTED_CONTENT=$(python3 -c '
import os, sys, json, subprocess

root = "'"$ROOT_DIR"'"
task_id = "'"$TASK_ID"'"
delib_json_path = "'"$DELIBERATION_JSON"'"
task_file_path = "'"$TASK_FILE"'"

objective = "Objetivo no especificado."
verdict = "N/A"
rounds = "1"
summary = "Cierre de tarea sin deliberacion interactiva."
objections = []
corrections = []
skills = []
files_touched = []
recent_commit_msg = ""

# 1. Intentar leer deliberacion en caliente si existe
if os.path.isfile(delib_json_path):
    try:
        with open(delib_json_path, "r", encoding="utf-8") as f:
            d = json.load(f)
        verdict = d.get("verdict", "N/A")
        rounds = str(d.get("rounds_executed", 1))
        summary = d.get("design_summary", summary)
        objections = d.get("objections", [])
        corrections = d.get("corrections", [])
        se = d.get("skills_evaluation", {})
        if isinstance(se, dict) and "applied" in se:
            skills = se["applied"]
    except Exception:
        pass

# 2. Leer task file (activo o archivado)
if os.path.isfile(task_file_path):
    try:
        with open(task_file_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
        in_obj = False
        in_skills = False
        obj_lines = []
        for line in lines:
            if line.startswith("## Objetivo"):
                in_obj = True
                in_skills = False
                continue
            elif line.startswith("## Skills relevantes") or line.startswith("## Skills"):
                in_skills = True
                in_obj = False
                continue
            elif line.startswith("## "):
                in_obj = False
                in_skills = False

            if in_obj and line.strip():
                obj_lines.append(line.strip())
            elif in_skills and line.strip().startswith("- "):
                s_name = line.strip()[2:].split(":")[0].strip(" `*")
                if s_name and s_name not in skills:
                    skills.append(s_name)

        if obj_lines:
            objective = " ".join(obj_lines)
    except Exception:
        pass

# 3. Fallback en frío para ficheros tocados (git diff HEAD~1) y mensaje (git log -1)
try:
    cmd_diff = ["git", "diff", "--name-only", "HEAD~1"]
    out_diff = subprocess.check_output(cmd_diff, cwd=root, text=True, stderr=subprocess.DEVNULL)
    files_touched = [f.strip() for f in out_diff.splitlines() if f.strip()]
except Exception:
    files_touched = []

try:
    cmd_log = ["git", "log", "-1", "--pretty=%s"]
    recent_commit_msg = subprocess.check_output(cmd_log, cwd=root, text=True, stderr=subprocess.DEVNULL).strip()
except Exception:
    recent_commit_msg = ""

# Construir Markdown
md = []
md.append(f"# Executive Design Digest — {task_id}")
md.append("")
md.append("## 🎯 Objetivo")
md.append(objective)
md.append("")
md.append("## 🏛️ Decisiones de Arquitectura y Buenas Prácticas")
md.append(f"- **Veredicto de Deliberación**: `{verdict}` (Rondas: {rounds})")
md.append(f"- **Síntesis de Diseño**: {summary}")
if recent_commit_msg:
    md.append(f"- **Mensaje de Cierre**: `{recent_commit_msg}`")
md.append("")
md.append("## 🛠️ Ajustes y Arbitraje de Deliberación")
if objections:
    md.append("### Objeciones planteadas:")
    for obj in objections:
        md.append(f"- ⚠️ {obj}")
else:
    md.append("- Consenso inicial sin objeciones o cerrado en modo directo.")

if corrections:
    md.append("### Correcciones acordadas:")
    for corr in corrections:
        md.append(f"- ✅ {corr}")

md.append("")
md.append("## 📁 Ficheros Modificados y Criterio de Alcance")
if files_touched:
    for f in files_touched:
        md.append(f"- `{f}`")
else:
    md.append("- Sin cambios detectados en diff reciente.")

md.append("")
md.append("## 🧠 Skills Declaradas y Aplicadas")
if skills:
    for s in skills:
        md.append(f"- `{s}`")
else:
    md.append("- Ninguna skill adicional registrada.")

md.append("")
print("\n".join(md))
')

# ==============================================================================
# DERIVACIÓN DETERMINISTA DE NOMBRES DE CLAVES (NUNCA VALORES)
# ==============================================================================
# Prohibido source o eval de archivos .env (solo parseo estático de nombres)
VALID_KEY_RE='^[A-Za-z_][A-Za-z0-9_]*$'
COLLECTED_KEYS=()

# 1. Claves explícitas recibidas por argumento --keys
if [ -n "$EXPLICIT_KEYS" ]; then
  IFS=',' read -r -a _exp_raw <<< "$EXPLICIT_KEYS"
  for k in "${_exp_raw[@]}"; do
    k="$(echo "$k" | tr -d '[:space:]')"
    [[ "$k" =~ $VALID_KEY_RE ]] && COLLECTED_KEYS+=("$k")
  done
fi

# 2. Claves de archivos .env* en el root (parseo estático con grep/sed)
while IFS= read -r k; do
  [[ "$k" =~ $VALID_KEY_RE ]] && COLLECTED_KEYS+=("$k")
done < <(find "$ROOT_DIR" -maxdepth 1 -name ".env*" -type f 2>/dev/null -exec grep -hE '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*=' {} + 2>/dev/null | sed -E 's/^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=.*/\1/' || true)

# 3. Claves declaradas en el contenido de la tarea o plan (asignaciones KEY=valor en texto)
while IFS= read -r k; do
  [[ "$k" =~ $VALID_KEY_RE ]] && COLLECTED_KEYS+=("$k")
done < <(echo "$UNREDACTED_CONTENT" | grep -oE '\b[A-Za-z_][A-Za-z0-9_]*=' 2>/dev/null | tr -d '=' || true)

if [ -f "$TASK_FILE" ]; then
  while IFS= read -r k; do
    [[ "$k" =~ $VALID_KEY_RE ]] && COLLECTED_KEYS+=("$k")
  done < <(grep -oE '\b[A-Za-z_][A-Za-z0-9_]*=' "$TASK_FILE" 2>/dev/null | tr -d '=' || true)
fi

# 4. Claves del catálogo si existe (local o variable AGENT_OS_SECRETS_CATALOG)
CATALOG_PATH="${AGENT_OS_SECRETS_CATALOG:-$ROOT_DIR/.agents/config/secrets-catalog.yaml}"
if [ -f "$CATALOG_PATH" ]; then
  while IFS= read -r k; do
    [[ "$k" =~ $VALID_KEY_RE ]] && COLLECTED_KEYS+=("$k")
  done < <(
    sed -n 's/^[[:space:]]*- key:[[:space:]]*\([A-Za-z_][A-Za-z0-9_]*\).*/\1/p' "$CATALOG_PATH" 2>/dev/null
    sed -n 's/^needs_declaration:[[:space:]]*\[\(.*\)\][[:space:]]*$/\1/p' "$CATALOG_PATH" 2>/dev/null \
      | tr ',' '\n' | tr -d "[]\"' " | grep -E "$VALID_KEY_RE" || true
  )
fi

# Unificar y filtrar sin duplicados
UNIQUE_KEYS=()
if [ "${#COLLECTED_KEYS[@]}" -gt 0 ]; then
  mapfile -t UNIQUE_KEYS < <(printf '%s\n' "${COLLECTED_KEYS[@]}" | awk '!seen[$0]++' | grep -v '^$')
fi

REDACT_CMD=(bash "$REDACT_SCRIPT")
if [ "${#UNIQUE_KEYS[@]}" -gt 0 ]; then
  KEYS_CSV="$(IFS=','; echo "${UNIQUE_KEYS[*]}")"
  REDACT_CMD+=(--keys "$KEYS_CSV")
fi

# ==============================================================================
# CANALIZACIÓN OBLIGATORIA POR LIB/REDACT.SH (FAIL-CLOSED)
# ==============================================================================
mkdir -p "$(dirname "$OUTPUT_FILE")"

TMP_OUTPUT="${OUTPUT_FILE}.tmp.$$"
if ! echo "$UNREDACTED_CONTENT" | "${REDACT_CMD[@]}" > "$TMP_OUTPUT"; then
  echo "❌ Error: Fallo crítico al canalizar el digest por $REDACT_SCRIPT. Abortando sin persistir." >&2
  rm -f "$TMP_OUTPUT"
  exit 1
fi

if [ ! -s "$TMP_OUTPUT" ]; then
  echo "❌ Error: El digest redactado resultó vacío. Abortando sin persistir." >&2
  rm -f "$TMP_OUTPUT"
  exit 1
fi

mv "$TMP_OUTPUT" "$OUTPUT_FILE"
chmod 644 "$OUTPUT_FILE"

# Archivado opcional de JSON crudo redactado si existe deliberación de la tarea
if [ -f "$DELIBERATION_JSON" ]; then
  RAW_OUTPUT="$ROOT_DIR/docs/sprints/design-decisions/${TASK_ID}-raw.json"
  TMP_RAW="${RAW_OUTPUT}.tmp.$$"
  if cat "$DELIBERATION_JSON" | "${REDACT_CMD[@]}" > "$TMP_RAW"; then
    mv "$TMP_RAW" "$RAW_OUTPUT"
    chmod 644 "$RAW_OUTPUT"
  else
    rm -f "$TMP_RAW"
  fi
fi

if [ "$JSON_OUTPUT" = true ]; then
  python3 -c '
import json, sys
data = {
    "task_id": "'"$TASK_ID"'",
    "output_file": "'"$OUTPUT_FILE"'",
    "status": "GENERATED_AND_REDACTED"
}
print(json.dumps(data, indent=2))
'
else
  echo "✅ Digest de diseño generado y redactado exitosamente:"
  echo "   ↳ $OUTPUT_FILE"
fi
