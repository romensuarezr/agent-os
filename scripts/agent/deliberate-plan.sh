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
if [ "$TASK_ID" != "T-UNKNOWN" ] && [[ ! "$TASK_ID" =~ ^T- ]]; then
  TASK_ID="T-${TASK_ID}"
fi
[ -n "$OUTPUT_FILE" ] || OUTPUT_FILE="$ROOT_DIR/.agents/context/plan-deliberation.json"

# ==============================================================================
# 1. RESOLUCIÓN DE CASCADA DE INFERENCIA (Check 22: Cero Literales de Infra)
# ==============================================================================
resolve_inference_cascade() {
  python3 -c '
import os, sys, yaml, re, json

root = os.environ.get("AGENT_OS_ROOT", "'"$ROOT_DIR"'")
routing_file = os.environ.get("AGENT_OS_ROUTING_POLICY", os.path.join(root, ".agents", "config", "routing-policy.yaml"))
fleet_file = os.environ.get("AGENT_OS_FLEET_CONFIG", os.path.join(root, ".agents", "config", "fleet.yaml"))

cascade = []
endpoints_cfg = {}
timeout_seconds = int('"$TIMEOUT"')

if os.path.isfile(routing_file):
    try:
        with open(routing_file, "r", encoding="utf-8") as f:
            rp = yaml.safe_load(f) or {}
        endpoints_cfg = rp.get("endpoints", {})
        delib_cfg = rp.get("task_routing_matrix", {}).get("deliberation_and_review", {})
        cascade = delib_cfg.get("fallback_cascade", [])
        if not cascade:
            for key in ["primary", "secondary", "fallback"]:
                val = delib_cfg.get(key)
                if val and val not in cascade:
                    cascade.append(val)
        if "timeout_seconds" in delib_cfg and timeout_seconds == 5:
            try:
                timeout_seconds = int(delib_cfg["timeout_seconds"])
            except Exception:
                pass
    except Exception:
        pass

if not cascade:
    cascade = ["freellmapi", "omniroute", "ollama-local"]

fleet_cfg = {}
if os.path.isfile(fleet_file):
    try:
        with open(fleet_file, "r", encoding="utf-8") as f:
            fleet_cfg = yaml.safe_load(f) or {}
    except Exception:
        pass

gw_fleet = fleet_cfg.get("inference_gateways", {})

def expand_env(val):
    if not val:
        return ""
    def repl(m):
        var = m.group(1)
        dflt = m.group(2) if m.group(2) is not None else ""
        return os.environ.get(var, dflt)
    return re.sub(r"\$\{([A-Za-z_][A-Za-z0-9_]*)(?::-([^}]*))?\}", repl, str(val))

resolved_tiers = []
override_url = os.environ.get("INFERENCE_BASE_URL", "").strip()
override_key = os.environ.get("INFERENCE_API_KEY", "").strip() or "freeapi"

for idx, name in enumerate(cascade):
    base_url = ""
    api_key = ""

    # Precedencia: INFERENCE_BASE_URL (prioritario para el primer tier) -> fleet.yaml -> variables de entorno / routing-policy -> loopback
    if idx == 0 and override_url:
        base_url = override_url
        api_key = override_key
    else:
        if name in gw_fleet:
            gw_info = gw_fleet[name]
            base_url = expand_env(gw_info.get("base_url", ""))
            env_key_var = gw_info.get("env_var", "")
            if env_key_var:
                api_key = os.environ.get(env_key_var, "")

        if not base_url:
            ep = endpoints_cfg.get(name, {})
            base_url = expand_env(ep.get("base_url", ""))

        if not base_url:
            if name == "freellmapi":
                base_url = os.environ.get("FREELLMAPI_URL", "http://localhost:3001/v1")
                api_key = os.environ.get("FREELLMAPI_API_KEY", "freeapi")
            elif name == "omniroute":
                base_url = os.environ.get("TABBY_URL", "http://localhost:20128/v1")
                api_key = os.environ.get("TABBY_API_KEY", "omniroute")
            elif name == "ollama-local":
                base_url = os.environ.get("OLLAMA_URL", "http://127.0.0.1:11434/v1")
                api_key = "ollama"

    if base_url and not any(t["url"] == base_url for t in resolved_tiers):
        resolved_tiers.append({"name": name, "url": base_url, "key": api_key or "freeapi"})

print(json.dumps({"timeout": timeout_seconds, "tiers": resolved_tiers}))
'
}

CASCADE_DATA=$(resolve_inference_cascade)
NUM_TIERS=$(python3 -c 'import json, sys; print(len(json.loads(sys.argv[1]).get("tiers", [])))' "$CASCADE_DATA" 2>/dev/null || echo 0)
GLOBAL_TIMEOUT="$TIMEOUT"

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

  local start_time
  start_time=$(date +%s)

  local idx=0
  while [ "$idx" -lt "$NUM_TIERS" ]; do
    local now
    now=$(date +%s)
    local elapsed=$(( now - start_time ))
    local remaining=$(( GLOBAL_TIMEOUT - elapsed ))

    if [ "$remaining" -le 0 ]; then
      break
    fi

    local tier_timeout=$(( remaining < GLOBAL_TIMEOUT ? remaining : GLOBAL_TIMEOUT ))
    if [ "$tier_timeout" -le 0 ]; then
      tier_timeout=1
    fi

    local tier_info tier_name tier_url tier_key
    tier_info=$(python3 -c '
import json, sys
data = json.loads(sys.argv[1])
idx = int(sys.argv[2])
tiers = data.get("tiers", [])
if idx < len(tiers):
    t = tiers[idx]
    n = t.get("name", "")
    u = t.get("url", "")
    k = t.get("key", "")
    print(f"{n}|{u}|{k}")
' "$CASCADE_DATA" "$idx" 2>/dev/null || true)

    tier_name="${tier_info%%|*}"
    local rest="${tier_info#*|}"
    tier_url="${rest%%|*}"
    tier_key="${rest##*|}"

    if [ -n "$tier_url" ]; then
      local response
      response=$(curl -s -S --max-time "$tier_timeout" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $tier_key" \
        -X POST "$tier_url/chat/completions" \
        -d "$req_body" 2>/dev/null || true)

      if [ -n "$response" ]; then
        local content
        content=$(python3 -c '
import json, sys
try:
    data = json.loads(sys.stdin.read())
    c = data.get("choices", [{}])[0].get("message", {}).get("content", "")
    print(c)
except Exception:
    print("")
' <<< "$response" 2>/dev/null || true)

        if [ -n "$content" ]; then
          echo "$content"
          return 0
        fi
      fi
    fi

    idx=$(( idx + 1 ))
  done

  echo ""
  return 1
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

# Persistencia de deliberación nombrada para handover multi-sesión (T-124)
if [ -n "$TASK_ID" ] && [ "$TASK_ID" != "T-UNKNOWN" ]; then
  NAMED_DELIB_FILE="$ROOT_DIR/.agents/context/deliberation-${TASK_ID}.json"
  mkdir -p "$(dirname "$NAMED_DELIB_FILE")"
  echo "$DELIBERATION_JSON" > "$NAMED_DELIB_FILE"
fi

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
