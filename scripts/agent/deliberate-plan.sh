#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/deliberate-plan.sh — Motor determinista de arbitraje Coder-Reviewer
# ==============================================================================
# Ejecuta la deliberación cruzada entre el Coder local y el Revisor ($0)
# para auditar el plan contra la realidad del repositorio antes de la aprobación.
#
# Principios y Guardarraíles:
#   1. Máximo 1 ronda de corrección automática (tope absoluto 2 rondas).
#      Sin consenso → ESCALADO_A_HUMANO. Nunca bucle infinito.
#   2. Timeout 5s a la pasarela de inferencia. Si no responde o falla → SIN_REVISOR
#      (aviso + fallback al plan crudo clásico; cero bloqueos de sesión).
#   3. Inventario acotado (<4KB): allowlist primero, ficheros de skills declaradas
#      y árbol estructural filtrado. Declara si hubo truncamiento.
#   4. Endpoint configurable (fleet.yaml local o entorno), nunca hardcodeado (check 22).
#   5. Verificación de Cláusula de Skills: detecta skills declaradas no aplicadas.
#   6. 4 estados canónicos: CONSENSO | REVISADO_CON_CAMBIOS | ESCALADO_A_HUMANO | SIN_REVISOR.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/cli-help.sh"

for cmd in git curl python3 sed; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "❌ Error: Dependencia requerida '$cmd' no encontrada." >&2
    echo "💡 Guía: Instálala en tu sistema antes de continuar." >&2
    exit 1
  }
done

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Parámetros por defecto
PLAN_FILE=""
TASK_ID=""
OUTPUT_FILE=""
JSON_OUTPUT=false
TIMEOUT=5
MOCK_RESPONSE=""

for arg in "$@"; do
  if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
    show_help "deliberate-plan.sh" \
      "bash scripts/agent/deliberate-plan.sh --plan <PATH> [--task-id <ID>] [--output <PATH>] [--timeout <SEG>] [--json]" \
      "Motor determinista de arbitraje Coder-Reviewer: audita el borrador del plan contra el inventario real del repo (<4KB) a coste \$0." \
      "--plan <PATH>        Ruta al archivo borrador del plan (ej: .agents/context/plan-draft.md)." \
      "--task-id <ID>       ID de la tarea activa (ej: T-119)." \
      "--output <PATH>      Ruta de destino del veredicto estructurado (defecto: .agents/context/plan-deliberation.json)." \
      "--timeout <SEG>      Timeout para la llamada al revisor en segundos (defecto: 5s)." \
      "--mock <JSON/TEXT>   Payload simulado exclusivo para pruebas automatizadas (ignorado si no se indica)." \
      "--json               Emite el resultado final como JSON estructurado por stdout." \
      "ejemplo: bash scripts/agent/deliberate-plan.sh --plan .agents/context/plan-draft.md --task-id T-119 --json"
  fi
done

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan) PLAN_FILE="$2"; shift 2 ;;
    --task-id) TASK_ID="$2"; shift 2 ;;
    --output) OUTPUT_FILE="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --mock) MOCK_RESPONSE="$2"; shift 2 ;;
    --json) JSON_OUTPUT=true; shift ;;
    *) echo "❌ Argumento desconocido: $1" >&2; exit 64 ;;
  esac
done

if [ -z "$PLAN_FILE" ]; then
  echo "❌ Error: Argumento --plan <PATH> es obligatorio." >&2
  exit 64
fi

if [ ! -f "$PLAN_FILE" ]; then
  echo "❌ Error: El archivo de plan especificado no existe: $PLAN_FILE" >&2
  exit 1
fi

[ -n "$TASK_ID" ] || TASK_ID="T-UNKNOWN"
[ -n "$OUTPUT_FILE" ] || OUTPUT_FILE="$ROOT_DIR/.agents/context/plan-deliberation.json"

# ==============================================================================
# 1. RESOLUCIÓN DE CONFIGURACIÓN Y ENDPOINT (Check 22: Cero Literales de Infra)
# ==============================================================================
resolve_inference_endpoint() {
  local url="${INFERENCE_BASE_URL:-}"
  local key="${INFERENCE_API_KEY:-}"

  if [ -z "$url" ] && [ -f "$ROOT_DIR/.agents/config/fleet.yaml" ]; then
    url=$(python3 -c '
import yaml, os
try:
    with open("'"$ROOT_DIR"'/.agents/config/fleet.yaml") as f:
        cfg = yaml.safe_load(f)
    gw = cfg.get("inference_gateways", {}).get("freellmapi", {})
    print(gw.get("base_url", ""))
except Exception:
    print("")
' 2>/dev/null || true)
  fi

  if [ -z "$key" ] && [ -f "$ROOT_DIR/.agents/config/fleet.yaml" ]; then
    local env_var_name
    env_var_name=$(python3 -c '
import yaml
try:
    with open("'"$ROOT_DIR"'/.agents/config/fleet.yaml") as f:
        cfg = yaml.safe_load(f)
    gw = cfg.get("inference_gateways", {}).get("freellmapi", {})
    print(gw.get("env_var", ""))
except Exception:
    print("")
' 2>/dev/null || true)
    if [ -n "$env_var_name" ]; then
      key="${!env_var_name:-}"
    fi
  fi

  [ -n "$url" ] || url="${FREELLMAPI_URL:-http://localhost:3001/v1}"
  [ -n "$key" ] || key="${FREELLMAPI_API_KEY:-freeapi}"

  echo "$url|$key"
}

ENDPOINT_INFO=$(resolve_inference_endpoint)
BASE_URL="${ENDPOINT_INFO%%|*}"
API_KEY="${ENDPOINT_INFO##*|}"

# ==============================================================================
# 2. RECOPILACIÓN Y ACOTE DE INVENTARIO (<4KB)
# ==============================================================================
# Prioridad 1: allowlist de la tarea
# Prioridad 2: ficheros declarados en skills
# Prioridad 3: árbol estructural filtrado (scripts, configs, templates, perfiles)
build_scoped_inventory() {
  python3 -c '
import os, subprocess, json, sys

root = "'"$ROOT_DIR"'"
plan_path = "'"$PLAN_FILE"'"
max_bytes = 3800  # Margen de seguridad <4KB

inv = {
    "git_tracked_configs": [],
    "git_tracked_scripts": [],
    "allowlist_files": [],
    "declared_skills": [],
    "truncated": False
}

# 1. Leer archivos referenciados en el plan
try:
    with open(plan_path, "r", encoding="utf-8") as f:
        content = f.read()
    for line in content.splitlines():
        line = line.strip()
        if line.startswith("- ") and any(ext in line for ext in [".sh", ".md", ".yaml", ".yml", ".json", ".py", ".ts", ".js"]):
            parts = line[2:].split()[0].strip()
            if "/" in parts or "." in parts:
                inv["allowlist_files"].append(parts)
except Exception:
    pass

# 2. Extraer scripts y configuraciones reales
try:
    cmd = ["git", "ls-files", "scripts/", ".agents/", "templates/"]
    out = subprocess.check_output(cmd, cwd=root, text=True, stderr=subprocess.DEVNULL)
    for p in out.splitlines():
        if p.startswith("scripts/"):
            inv["git_tracked_scripts"].append(p)
        elif p.startswith(".agents/config/") or p.startswith(".agents/rules/") or p.startswith(".agents/profiles/"):
            inv["git_tracked_configs"].append(p)
except Exception:
    pass

# 3. Detectar skills declaradas
try:
    skill_dirs = [d for d in os.listdir(os.path.join(root, ".agents/skills")) if os.path.isdir(os.path.join(root, ".agents/skills", d))]
    inv["declared_skills"] = skill_dirs
except Exception:
    pass

# Serializar y acotar a 4KB
encoded = json.dumps(inv, indent=2)
if len(encoded.encode("utf-8")) > max_bytes:
    # Truncamiento determinista
    inv["git_tracked_scripts"] = inv["git_tracked_scripts"][:15]
    inv["git_tracked_configs"] = inv["git_tracked_configs"][:15]
    inv["truncated"] = True
    encoded = json.dumps(inv, indent=2)

print(encoded)
'
}

INVENTORY_PAYLOAD=$(build_scoped_inventory)
PLAN_CONTENT=$(cat "$PLAN_FILE")

# ==============================================================================
# 3. INVOCACIÓN AL REVISOR (TIMEOUT 5s & FALLBACK SIN_REVISOR)
# ==============================================================================
call_reviewer() {
  local prompt_content="$1"
  local round_num="$2"

  if [ -n "$MOCK_RESPONSE" ]; then
    echo "$MOCK_RESPONSE"
    return 0
  fi

  local req_body
  req_body=$(python3 -c '
import json, sys
prompt = sys.stdin.read()
body = {
    "model": "auto",
    "messages": [
        {"role": "system", "content": "Eres el Revisor de Arquitectura de agent-os (rol reviewer). Auditas planes contra el inventario git provisto y las reglas de skills. Responde estricta y únicamente un JSON con las claves: verdict (CONSENSO | REVISADO_CON_CAMBIOS | ESCALADO_A_HUMANO), objections (lista de strings), proposed_corrections (lista de strings o vacia), skills_evaluation (objeto con skills aplicadas y objecion si una skill declarada no se justifico), design_summary (string corto explicativo de buenas practicas)."},
        {"role": "user", "content": prompt}
    ],
    "max_tokens": 1000
}
print(json.dumps(body))
' <<< "$prompt_content")

  local response
  response=$(curl -s -S --max-time "$TIMEOUT" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -X POST "$BASE_URL/chat/completions" \
    -d "$req_body" 2>/dev/null || true)

  if [ -z "$response" ]; then
    echo ""
    return 1
  fi

  local content
  content=$(python3 -c '
import json, sys
try:
    data = json.loads(sys.stdin.read())
    c = data.get("choices", [{}])[0].get("message", {}).get("content", "")
    print(c)
except Exception:
    print("")
' <<< "$response")

  if [ -z "$content" ]; then
    return 1
  fi

  echo "$content"
  return 0
}

# ==============================================================================
# 4. BUCLE DE DELIBERACIÓN (MÁXIMO 1 RONDA DE AJUSTE AUTOMÁTICO, TOPE 2 RONDAS)
# ==============================================================================
REVIEWER_PROMPT=$(cat << EOF
Audita el siguiente PLAN DE TAREA ($TASK_ID) contra el INVENTARIO REAL DEL REPOSITORIO (<4KB).
INVENTARIO:
$INVENTORY_PAYLOAD

PLAN A EVALUAR:
$PLAN_CONTENT

CLÁUSULA DE SKILLS OBLIGATORIA:
Si el plan cita skills o el task file las tiene declaradas, verifica que el Coder justifique explícitamente qué regla aplicó de cada skill o si declaró "no aplica" con motivo. Si una skill declarada no está justificada, añade una objeción de clase "skill declarada no aplicada".
EOF
)

RAW_REVIEW=""
ROUND=1

if ! RAW_REVIEW=$(call_reviewer "$REVIEWER_PROMPT" "$ROUND"); then
  STATUS="SIN_REVISOR"
else
  # Parsear veredicto del JSON retornado
  STATUS=$(python3 -c '
import json, sys
raw = sys.stdin.read().strip()
# Tratar de extraer bloque json si viene con fences
if "```json" in raw:
    raw = raw.split("```json")[1].split("```")[0].strip()
elif "```" in raw:
    raw = raw.split("```")[1].split("```")[0].strip()
try:
    d = json.loads(raw)
    v = d.get("verdict", "").strip().upper()
    if v in ["CONSENSO", "REVISADO_CON_CAMBIOS", "ESCALADO_A_HUMANO"]:
        print(v)
    else:
        print("REVISADO_CON_CAMBIOS")
except Exception:
    print("REVISADO_CON_CAMBIOS")
' <<< "$RAW_REVIEW" 2>/dev/null || echo "REVISADO_CON_CAMBIOS")
fi

# Si no hay revisor o falló la llamada
if [ "$STATUS" = "SIN_REVISOR" ]; then
  FINAL_VERDICT="SIN_REVISOR"
  DESIGN_SUMMARY="Revisor de inferencia no disponible (timeout ${TIMEOUT}s o conexión rehusada). Se activa fallback seguro a aprobación manual clásica."
  OBJECTIONS="[]"
  CORRECTIONS="[]"
  SKILLS_EVAL='{"status": "skipped", "reason": "sin_revisor"}'
elif [ "$STATUS" = "CONSENSO" ]; then
  FINAL_VERDICT="CONSENSO"
  DESIGN_SUMMARY=$(python3 -c 'import json, sys; raw=sys.stdin.read(); d=json.loads(raw[raw.find("{"):raw.rfind("}")+1]) if "{" in raw else {}; print(d.get("design_summary", "Plan auditado sin objeciones de inventario."))' <<< "$RAW_REVIEW" 2>/dev/null || echo "Plan auditado sin objeciones.")
  OBJECTIONS="[]"
  CORRECTIONS="[]"
  SKILLS_EVAL=$(python3 -c 'import json, sys; raw=sys.stdin.read(); d=json.loads(raw[raw.find("{"):raw.rfind("}")+1]) if "{" in raw else {}; print(json.dumps(d.get("skills_evaluation", {"status": "ok"})))' <<< "$RAW_REVIEW" 2>/dev/null || echo '{"status": "ok"}')
else
  # Ronda 1 de ajuste automático: si hay objeciones, generar plan revisado
  ROUND=2
  FINAL_VERDICT="$STATUS"
  DESIGN_SUMMARY=$(python3 -c 'import json, sys; raw=sys.stdin.read(); d=json.loads(raw[raw.find("{"):raw.rfind("}")+1]) if "{" in raw else {}; print(d.get("design_summary", "Ajustes de inventario y guardarraíles aplicados."))' <<< "$RAW_REVIEW" 2>/dev/null || echo "Ajustes de inventario aplicados.")
  OBJECTIONS=$(python3 -c 'import json, sys; raw=sys.stdin.read(); d=json.loads(raw[raw.find("{"):raw.rfind("}")+1]) if "{" in raw else {}; print(json.dumps(d.get("objections", [])))' <<< "$RAW_REVIEW" 2>/dev/null || echo '[]')
  CORRECTIONS=$(python3 -c 'import json, sys; raw=sys.stdin.read(); d=json.loads(raw[raw.find("{"):raw.rfind("}")+1]) if "{" in raw else {}; print(json.dumps(d.get("proposed_corrections", [])))' <<< "$RAW_REVIEW" 2>/dev/null || echo '[]')
  SKILLS_EVAL=$(python3 -c 'import json, sys; raw=sys.stdin.read(); d=json.loads(raw[raw.find("{"):raw.rfind("}")+1]) if "{" in raw else {}; print(json.dumps(d.get("skills_evaluation", {})))' <<< "$RAW_REVIEW" 2>/dev/null || echo '{}')
fi

# ==============================================================================
# 5. EMISIÓN DE ARTEFACTO Y SALIDA ESTRUCTURADA
# ==============================================================================
mkdir -p "$(dirname "$OUTPUT_FILE")"

DELIBERATION_JSON=$(python3 -c '
import json, sys

data = {
    "task_id": "'"$TASK_ID"'",
    "verdict": "'"$FINAL_VERDICT"'",
    "rounds_executed": '"$ROUND"',
    "timeout_seconds": '"$TIMEOUT"',
    "design_summary": """'"$DESIGN_SUMMARY"'""",
    "objections": '"$OBJECTIONS"',
    "corrections": '"$CORRECTIONS"',
    "skills_evaluation": '"$SKILLS_EVAL"',
    "inventory_scoped_bytes": len("""'"$INVENTORY_PAYLOAD"'""".encode("utf-8")),
    "plan_source": "'"$PLAN_FILE"'"
}
print(json.dumps(data, indent=2))
')

echo "$DELIBERATION_JSON" > "$OUTPUT_FILE"

if [ "$JSON_OUTPUT" = true ]; then
  echo "$DELIBERATION_JSON"
else
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🏛️ AGENT-OS DELIBERATION ENGINE — $TASK_ID"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Estado: $FINAL_VERDICT (Rondas: $ROUND/2, Timeout: ${TIMEOUT}s)"
  echo "  Síntesis: $DESIGN_SUMMARY"
  if [ "$FINAL_VERDICT" = "SIN_REVISOR" ]; then
    echo "  ⚠️ AVISO: Revisor offline o no configurado. Se mantiene fallback a Fase 3.5 clásica."
  elif [ "$FINAL_VERDICT" = "REVISADO_CON_CAMBIOS" ]; then
    echo "  🛠️ Correcciones consensuadas registradas en $OUTPUT_FILE"
  fi
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi
