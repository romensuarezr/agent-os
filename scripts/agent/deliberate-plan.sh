#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/deliberate-plan.sh — Motor determinista de arbitraje Coder-Reviewer
# ==============================================================================
# Ejecuta la deliberación cruzada entre el Coder local y el Revisor ($0)
# para auditar el plan contra la realidad del repositorio antes de la aprobación.
#
# Jerarquía determinista de 3 niveles:
#   1. Nivel 1 — Orca ADE: Revisor Ejecutor supervisado con spec declarativa (T-134)
#      bajo aislamiento estricto (env -i) y presupuesto acotado (60s).
#   2. Nivel 2 — Cascada HTTP: Fallback de 3 tiers (freellmapi -> omniroute -> ollama-local)
#      con presupuesto global estricto de 5s ante fallo de transporte/timeout de Orca.
#   3. Nivel 3 — Degradación Segura: Emisión de SIN_REVISOR ($0 tokens) si la cascada
#      HTTP falla o no hay conexión, sin bloquear el bucle de desarrollo.
#
# Principios y Guardarraíles:
#   1. Máximo 1 ronda de corrección automática (tope absoluto 2 rondas).
#      Sin consenso → ESCALADO_A_HUMANO. Nunca bucle infinito.
#   2. Timeout total en peor caso ~66s (<1s sonda + 60s Orca + 5s cascada HTTP).
#   3. Inventario acotado (<4KB): allowlist primero, ficheros de skills declaradas
#      y árbol estructural filtrado. Declara si hubo truncamiento.
#   4. Endpoints y agente configurables en routing-policy.yaml / fleet.yaml, nunca hardcodeados.
#   5. Verificación de Cláusula de Skills: detecta skills declaradas no aplicadas.
#   6. 5 estados canónicos: CONSENSO | REVISADO_CON_CAMBIOS | ESCALADO_A_HUMANO | RECHAZADO | SIN_REVISOR.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/cli-help.sh"
source "$SCRIPT_DIR/lib/orca-client.sh"

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
ORCA_TIMEOUT=15
NO_ORCA=false
MOCK_RESPONSE=""

for arg in "$@"; do
  if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
    show_help "deliberate-plan.sh" \
      "bash scripts/agent/deliberate-plan.sh --plan <PATH> [--task-id <ID>] [--output <PATH>] [--timeout <SEG>] [--orca-timeout <SEG>] [--no-orca] [--json]" \
      "Motor determinista de arbitraje Coder-Reviewer: audita el borrador del plan en 3 niveles (Orca ADE -> Cascada HTTP -> SIN_REVISOR)." \
      "--plan <PATH>        Ruta al archivo borrador del plan (ej: .agents/context/plan-draft.md)." \
      "--task-id <ID>       ID de la tarea activa (ej: T-135)." \
      "--output <PATH>      Ruta de destino del veredicto estructurado (defecto: .agents/context/plan-deliberation.json)." \
      "--timeout <SEG>      Timeout para la cascada HTTP en segundos (defecto: 5s)." \
      "--orca-timeout <SEG> Timeout máximo para el worker de Orca ADE en segundos. Precedencia: flag CLI > routing-policy.yaml (60s) > centinela en script (15s)." \
      "--no-orca            Omite la ejecución en Orca ADE (salta directamente a Nivel 2 / HTTP)." \
      "--mock <JSON/TEXT>   Payload simulado exclusivo para pruebas automatizadas (ignorado si no se indica)." \
      "--json               Emite el resultado final como JSON estructurado por stdout." \
      "ejemplo: bash scripts/agent/deliberate-plan.sh --plan .agents/context/plan-draft.md --task-id T-135 --json"
  fi
done

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan) PLAN_FILE="$2"; shift 2 ;;
    --task-id) TASK_ID="$2"; shift 2 ;;
    --output) OUTPUT_FILE="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --orca-timeout) ORCA_TIMEOUT="$2"; shift 2 ;;
    --no-orca) NO_ORCA=true; shift ;;
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
# TRAP DE LIBERACIÓN DE WORKER EN TODOS LOS CAMINOS
# ==============================================================================
ORCA_DISPATCH_ID=""
cleanup_worker() {
  if [ -n "${ORCA_DISPATCH_ID:-}" ]; then
    local disp="$ORCA_DISPATCH_ID"
    ORCA_DISPATCH_ID=""
    orca_cmd orchestration worker-stop --dispatch "$disp" --json >/dev/null 2>&1 || true
    orca_worker_release --dispatch "$disp" --json >/dev/null 2>&1 || true
  fi
}
trap cleanup_worker EXIT INT TERM

# ==============================================================================
# 1. RESOLUCIÓN DE POLÍTICA DE ROUTING Y CASCADA DE INFERENCIA
# ==============================================================================
resolve_deliberation_config() {
  python3 -c '
import os, sys, yaml, re, json

root = os.environ.get("AGENT_OS_ROOT", "'"$ROOT_DIR"'")
routing_file = os.environ.get("AGENT_OS_ROUTING_POLICY", os.path.join(root, ".agents", "config", "routing-policy.yaml"))
fleet_file = os.environ.get("AGENT_OS_FLEET_CONFIG", os.path.join(root, ".agents", "config", "fleet.yaml"))

cascade = []
endpoints_cfg = {}
http_timeout = int('"$TIMEOUT"')
orca_timeout = int('"$ORCA_TIMEOUT"')
orca_enabled = True
orca_agent = "opencode"
orca_role = "qa-judge"

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
                if val and val not in cascade and val != "primary-reliable":
                    cascade.append(val)
        if "timeout_seconds" in delib_cfg and http_timeout == 5:
            try:
                http_timeout = int(delib_cfg["timeout_seconds"])
            except Exception:
                pass

        # Configuración declarativa de orca_revisor
        orca_cfg = delib_cfg.get("orca_revisor", {})
        if isinstance(orca_cfg, dict):
            if "enabled" in orca_cfg:
                orca_enabled = bool(orca_cfg["enabled"])
            if "agent" in orca_cfg and orca_cfg["agent"]:
                orca_agent = str(orca_cfg["agent"])
            if "role" in orca_cfg and orca_cfg["role"]:
                orca_role = str(orca_cfg["role"])
            if "timeout_seconds" in orca_cfg and orca_timeout == 15:
                try:
                    orca_timeout = int(orca_cfg["timeout_seconds"])
                except Exception:
                    pass
    except Exception:
        pass

# Sobreescrituras de entorno para orca_revisor
if os.environ.get("ORCA_REVISOR_ENABLED") == "false" or os.environ.get("AGENT_OS_ORCA_REVIEWER") == "false":
    orca_enabled = False

# Si se indica explícitamente una pasarela HTTP vía INFERENCE_BASE_URL,
# se asume bypass de Orca para evaluar directamente el endpoint HTTP
if os.environ.get("INFERENCE_BASE_URL"):
    orca_enabled = False

if "'"$NO_ORCA"'" == "true":
    orca_enabled = False

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

out = {
    "http_timeout": http_timeout,
    "orca_timeout": orca_timeout,
    "orca_enabled": orca_enabled,
    "orca_agent": orca_agent,
    "orca_role": orca_role,
    "tiers": resolved_tiers
}
print(json.dumps(out))
'
}

CONFIG_DATA=$(resolve_deliberation_config)
ORCA_ENABLED=$(python3 -c 'import json, sys; print("true" if json.loads(sys.argv[1]).get("orca_enabled", False) else "false")' "$CONFIG_DATA" 2>/dev/null || echo "false")
ORCA_AGENT=$(python3 -c 'import json, sys; print(json.loads(sys.argv[1]).get("orca_agent", "opencode"))' "$CONFIG_DATA" 2>/dev/null || echo "opencode")
ORCA_ROLE=$(python3 -c 'import json, sys; print(json.loads(sys.argv[1]).get("orca_role", "qa-judge"))' "$CONFIG_DATA" 2>/dev/null || echo "qa-judge")
ORCA_TIMEOUT=$(python3 -c 'import json, sys; print(json.loads(sys.argv[1]).get("orca_timeout", 15))' "$CONFIG_DATA" 2>/dev/null || echo 15)
HTTP_TIMEOUT=$(python3 -c 'import json, sys; print(json.loads(sys.argv[1]).get("http_timeout", 5))' "$CONFIG_DATA" 2>/dev/null || echo 5)
NUM_TIERS=$(python3 -c 'import json, sys; print(len(json.loads(sys.argv[1]).get("tiers", [])))' "$CONFIG_DATA" 2>/dev/null || echo 0)

# ==============================================================================
# 2. RECOPILACIÓN Y ACOTE DE INVENTARIO (<4KB)
# ==============================================================================
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

try:
    skill_dirs = [d for d in os.listdir(os.path.join(root, ".agents/skills")) if os.path.isdir(os.path.join(root, ".agents/skills", d))]
    inv["declared_skills"] = skill_dirs
except Exception:
    pass

encoded = json.dumps(inv, indent=2)
if len(encoded.encode("utf-8")) > max_bytes:
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
# 3. LLAMADA HTTP (NIVEL 2 — FALLBACK DE CASCADA)
# ==============================================================================
call_http_cascade() {
  local prompt_content="$1"

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
        {"role": "system", "content": "Eres el Revisor de Arquitectura de agent-os (rol reviewer). Auditas planes contra el inventario git provisto y las reglas de skills. Responde estricta y únicamente un JSON con las claves: verdict (CONSENSO | REVISADO_CON_CAMBIOS | ESCALADO_A_HUMANO | RECHAZADO), objections (lista de strings), proposed_corrections (lista de strings o vacia), skills_evaluation (objeto con skills aplicadas y objecion si una skill declarada no se justifico), design_summary (string corto explicativo de buenas practicas)."},
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
    local remaining=$(( HTTP_TIMEOUT - elapsed ))

    if [ "$remaining" -le 0 ]; then
      break
    fi

    local tier_timeout=$(( remaining < HTTP_TIMEOUT ? remaining : HTTP_TIMEOUT ))
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
' "$CONFIG_DATA" "$idx" 2>/dev/null || true)

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
    data = json.loads(sys.stdin.read(), strict=False)
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
# 4. EJECUCIÓN JERÁRQUICA: NIVEL 1 (ORCA) -> NIVEL 2 (HTTP) -> NIVEL 3 (SIN_REVISOR)
# ==============================================================================
RAW_REVIEW=""
EVALUATOR_ROLE=""
EVALUATION_TIER=""
ROUND=1

# Si hay MOCK_RESPONSE, se usa directamente
if [ -n "$MOCK_RESPONSE" ]; then
  RAW_REVIEW="$MOCK_RESPONSE"
  EVALUATOR_ROLE="mock-judge"
  EVALUATION_TIER="mock"
fi

# NIVEL 1: ORCA ADE (Prioritario)
if [ -z "$RAW_REVIEW" ] && [ "$ORCA_ENABLED" = "true" ]; then
  # Sonda determinista fail-fast (<1s). Si está inactivo o sordo, salta sin demora
  if orca_is_ready; then
    SPEC_GEN="$SCRIPT_DIR/lib/generate-reviewer-spec.sh"
    if [ -f "$SPEC_GEN" ] && [ -x "$SPEC_GEN" ]; then
      SPEC_DATA="$("$SPEC_GEN" --task-id "$TASK_ID" --plan "$PLAN_FILE" --json 2>/dev/null || true)"
      SPEC_TEXT="$(python3 -c 'import json, sys; d=json.loads(sys.argv[1]); print(d.get("spec", ""))' "$SPEC_DATA" 2>/dev/null || true)"
      SPEC_ROLE="$(python3 -c 'import json, sys; d=json.loads(sys.argv[1]); print(d.get("role", "qa-judge"))' "$SPEC_DATA" 2>/dev/null || echo "$ORCA_ROLE")"

      if [ -n "$SPEC_TEXT" ]; then
        RUN_ID="$(orca_cmd orchestration run-current --json 2>/dev/null | python3 -c 'import json, sys; print(json.load(sys.stdin).get("result", {}).get("run", {}).get("id") or "")' 2>/dev/null || true)"
        if [ -z "$RUN_ID" ]; then
          RUN_OUT="$(orca_cmd orchestration run-create --objective "Deliberate $TASK_ID" --json 2>/dev/null || true)"
          RUN_ID="$(python3 -c 'import json, sys; print(json.loads(sys.argv[1]).get("result", {}).get("run", {}).get("id") or "")' "$RUN_OUT" 2>/dev/null || true)"
        fi

        # Inyectar instrucción de evaluación estática directa para ceñirse al presupuesto
        SPEC_DIRECT="$SPEC_TEXT"$'\n\n'"INSTRUCCIÓN DE EJECUCIÓN DIRECTA (PRESUPUESTO 60s): Evalúa el plan provisto estáticamente contra el inventario y reglas indicadas. Sé conciso (design_summary en 1-2 párrafos). No ejecutes herramientas bash de mutación ni tests de control plane. Emite directamente tu veredicto según el contrato y delimitadores indicados en la directiva."

        START_ARGS=()
        [ -n "$RUN_ID" ] && START_ARGS+=(--run "$RUN_ID")
        START_ARGS+=(
          --task-title "deliberate-plan $TASK_ID"
          --spec "$SPEC_DIRECT"
          --agent "$ORCA_AGENT"
          --worktree current
          --json
        )

        ORCA_START_TS=$(date +%s)
        START_OUT="$(orca_worker_start "${START_ARGS[@]}" 2>/dev/null || true)"
        ORCA_DISPATCH_ID="$(python3 -c 'import json, sys; print(json.loads(sys.argv[1]).get("result", {}).get("dispatchId") or "")' "$START_OUT" 2>/dev/null || true)"

        if [ -n "$ORCA_DISPATCH_ID" ]; then
          while true; do
            NOW_TS=$(date +%s)
            ELAPSED=$(( NOW_TS - ORCA_START_TS ))
            if [ "$ELAPSED" -ge "$ORCA_TIMEOUT" ]; then
              break
            fi

            READ_OUT="$(orca_worker_read --dispatch "$ORCA_DISPATCH_ID" --limit 100 --json 2>/dev/null || true)"
            PARSED_VERDICT="$(python3 -c '
import json, sys, re

start_delim = "<!-- VERDICT_JSON_START -->"
end_delim = "<!-- VERDICT_JSON_END -->"

try:
    data = json.loads(sys.argv[1], strict=False)
    res = data.get("result", {})
    lines = []
    if "transcript" in res and res["transcript"]:
        t = res["transcript"]
        if isinstance(t, list):
            lines = [str(x) for x in t]
        else:
            lines = [str(t)]
    if not lines and "terminal" in res:
        lines = res.get("terminal", {}).get("tail", [])
    
    full_text = "\n".join(lines)
    matches = []
    pos = 0
    while True:
        s = full_text.find(start_delim, pos)
        if s == -1:
            break
        e = full_text.find(end_delim, s + len(start_delim))
        if e == -1:
            break
        matches.append((s, e))
        pos = e + len(end_delim)

    for s_idx, e_idx in reversed(matches):
        raw_chunk = full_text[s_idx + len(start_delim):e_idx]
        cleaned_lines = []
        for line in raw_chunk.splitlines():
            l = re.sub(r"^[│┃╹╻|\s]+", "", line)
            l = re.sub(r"\s{6,}\S.*$", "", l)
            l = re.sub(r"[│┃╹╻|\s]+$", "", l)
            cleaned_lines.append(l)
        cleaned = "\n".join(cleaned_lines)
        s_brace = cleaned.find("{")
        e_brace = cleaned.rfind("}")
        if s_brace != -1 and e_brace > s_brace:
            json_str = cleaned[s_brace:e_brace + 1]
            try:
                parsed = json.loads(json_str, strict=False)
                v = parsed.get("verdict", "").strip().upper()
                if v in ["CONSENSO", "REVISADO_CON_CAMBIOS", "ESCALADO_A_HUMANO", "RECHAZADO"]:
                    print(json.dumps(parsed))
                    break
            except Exception:
                continue
except Exception:
    pass
' "$READ_OUT" 2>/dev/null || true)"

            if [ -n "$PARSED_VERDICT" ]; then
              RAW_REVIEW="$PARSED_VERDICT"
              EVALUATOR_ROLE="$SPEC_ROLE"
              EVALUATION_TIER="orca"
              break
            fi

            sleep 1.5
          done

          # Liberar terminal garantizado
          cleanup_worker
        fi
      fi
    fi
  fi
fi

# NIVEL 2: CASCADA HTTP (Solo ante fallo transporte/timeout/no-parseable de Orca o si Orca está deshabilitado)
if [ -z "$RAW_REVIEW" ]; then
  HTTP_PROMPT=$(cat << EOF
Audita el siguiente PLAN DE TAREA ($TASK_ID) contra el INVENTARIO REAL DEL REPOSITORIO (<4KB).
INVENTARIO:
$INVENTORY_PAYLOAD

PLAN A EVALUAR:
$PLAN_CONTENT

CLÁUSULA DE SKILLS OBLIGATORIA:
Si el plan cita skills o el task file las tiene declaradas, verifica que el Coder justifique explícitamente qué regla aplicó de cada skill o si declaró "no aplica" con motivo. Si una skill declarada no está justificada, añade una objeción de clase "skill declarada no aplicada".
EOF
)

  if HTTP_OUT=$(call_http_cascade "$HTTP_PROMPT"); then
    if [ -n "$HTTP_OUT" ]; then
      RAW_REVIEW="$HTTP_OUT"
      EVALUATOR_ROLE="reviewer"
      EVALUATION_TIER="http_cascade"
    fi
  fi
fi

# NIVEL 3: DEGRADACIÓN SEGURA (SIN_REVISOR)
STATUS=""
if [ -z "$RAW_REVIEW" ]; then
  STATUS="SIN_REVISOR"
  EVALUATOR_ROLE="none"
  EVALUATION_TIER="fallback_safe"
else
  STATUS=$(python3 -c '
import json, sys

raw = sys.stdin.read().strip()
start_delim = "<!-- VERDICT_JSON_START -->"
end_delim = "<!-- VERDICT_JSON_END -->"
s_idx = raw.rfind(start_delim)
e_idx = raw.rfind(end_delim)
if s_idx != -1 and e_idx > s_idx:
    raw = raw[s_idx + len(start_delim):e_idx].strip()
if "```json" in raw:
    raw = raw.split("```json")[1].split("```")[0].strip()
elif "```" in raw:
    raw = raw.split("```")[1].split("```")[0].strip()

try:
    d = json.loads(raw, strict=False)
    v = d.get("verdict", "").strip().upper()
    if v in ["CONSENSO", "REVISADO_CON_CAMBIOS", "ESCALADO_A_HUMANO", "RECHAZADO"]:
        print(v)
    else:
        print("REVISADO_CON_CAMBIOS")
except Exception:
    print("REVISADO_CON_CAMBIOS")
' <<< "$RAW_REVIEW" 2>/dev/null || echo "REVISADO_CON_CAMBIOS")
fi

# ==============================================================================
# 5. CONSOLIDACIÓN DE RESULTADOS Y MAPEADO CANÓNICO
# ==============================================================================
if [ "$STATUS" = "SIN_REVISOR" ]; then
  FINAL_VERDICT="SIN_REVISOR"
  DESIGN_SUMMARY="Revisor no disponible (timeout o conexión rehusada). Se activa fallback seguro a aprobación manual clásica."
  OBJECTIONS="[]"
  CORRECTIONS="[]"
  SKILLS_EVAL='{"status": "skipped", "reason": "sin_revisor"}'
elif [ "$STATUS" = "CONSENSO" ]; then
  FINAL_VERDICT="CONSENSO"
  DESIGN_SUMMARY=$(python3 -c '
import json, sys
raw = sys.stdin.read()
s_delim = "<!-- VERDICT_JSON_START -->"
e_delim = "<!-- VERDICT_JSON_END -->"
s_idx = raw.rfind(s_delim)
e_idx = raw.rfind(e_delim)
if s_idx != -1 and e_idx > s_idx:
    raw = raw[s_idx + len(s_delim):e_idx].strip()
if "```json" in raw:
    raw = raw.split("```json")[1].split("```")[0].strip()
elif "```" in raw:
    raw = raw.split("```")[1].split("```")[0].strip()
d = json.loads(raw[raw.find("{"):raw.rfind("}")+1], strict=False) if "{" in raw else {}
print(d.get("design_summary", "Plan auditado sin objeciones de inventario."))
' <<< "$RAW_REVIEW" 2>/dev/null || echo "Plan auditado sin objeciones.")
  OBJECTIONS="[]"
  CORRECTIONS="[]"
  SKILLS_EVAL=$(python3 -c '
import json, sys
raw = sys.stdin.read()
s_delim = "<!-- VERDICT_JSON_START -->"
e_delim = "<!-- VERDICT_JSON_END -->"
s_idx = raw.rfind(s_delim)
e_idx = raw.rfind(e_delim)
if s_idx != -1 and e_idx > s_idx:
    raw = raw[s_idx + len(s_delim):e_idx].strip()
if "```json" in raw:
    raw = raw.split("```json")[1].split("```")[0].strip()
elif "```" in raw:
    raw = raw.split("```")[1].split("```")[0].strip()
d = json.loads(raw[raw.find("{"):raw.rfind("}")+1], strict=False) if "{" in raw else {}
print(json.dumps(d.get("skills_evaluation", {"status": "ok"})))
' <<< "$RAW_REVIEW" 2>/dev/null || echo '{"status": "ok"}')
else
  # REVISADO_CON_CAMBIOS, RECHAZADO o ESCALADO_A_HUMANO
  ROUND=2
  FINAL_VERDICT="$STATUS"
  DESIGN_SUMMARY=$(python3 -c '
import json, sys
raw = sys.stdin.read()
s_delim = "<!-- VERDICT_JSON_START -->"
e_delim = "<!-- VERDICT_JSON_END -->"
s_idx = raw.rfind(s_delim)
e_idx = raw.rfind(e_delim)
if s_idx != -1 and e_idx > s_idx:
    raw = raw[s_idx + len(s_delim):e_idx].strip()
if "```json" in raw:
    raw = raw.split("```json")[1].split("```")[0].strip()
elif "```" in raw:
    raw = raw.split("```")[1].split("```")[0].strip()
d = json.loads(raw[raw.find("{"):raw.rfind("}")+1], strict=False) if "{" in raw else {}
print(d.get("design_summary", "Ajustes de inventario y guardarraíles aplicados."))
' <<< "$RAW_REVIEW" 2>/dev/null || echo "Ajustes de inventario aplicados.")
  OBJECTIONS=$(python3 -c '
import json, sys
raw = sys.stdin.read()
s_delim = "<!-- VERDICT_JSON_START -->"
e_delim = "<!-- VERDICT_JSON_END -->"
s_idx = raw.rfind(s_delim)
e_idx = raw.rfind(e_delim)
if s_idx != -1 and e_idx > s_idx:
    raw = raw[s_idx + len(s_delim):e_idx].strip()
if "```json" in raw:
    raw = raw.split("```json")[1].split("```")[0].strip()
elif "```" in raw:
    raw = raw.split("```")[1].split("```")[0].strip()
d = json.loads(raw[raw.find("{"):raw.rfind("}")+1], strict=False) if "{" in raw else {}
print(json.dumps(d.get("objections", [])))
' <<< "$RAW_REVIEW" 2>/dev/null || echo '[]')
  CORRECTIONS=$(python3 -c '
import json, sys
raw = sys.stdin.read()
s_delim = "<!-- VERDICT_JSON_START -->"
e_delim = "<!-- VERDICT_JSON_END -->"
s_idx = raw.rfind(s_delim)
e_idx = raw.rfind(e_delim)
if s_idx != -1 and e_idx > s_idx:
    raw = raw[s_idx + len(s_delim):e_idx].strip()
if "```json" in raw:
    raw = raw.split("```json")[1].split("```")[0].strip()
elif "```" in raw:
    raw = raw.split("```")[1].split("```")[0].strip()
d = json.loads(raw[raw.find("{"):raw.rfind("}")+1], strict=False) if "{" in raw else {}
corrs = d.get("proposed_corrections") or d.get("corrections") or []
print(json.dumps(corrs))
' <<< "$RAW_REVIEW" 2>/dev/null || echo '[]')
  SKILLS_EVAL=$(python3 -c '
import json, sys
raw = sys.stdin.read()
s_delim = "<!-- VERDICT_JSON_START -->"
e_delim = "<!-- VERDICT_JSON_END -->"
s_idx = raw.rfind(s_delim)
e_idx = raw.rfind(e_delim)
if s_idx != -1 and e_idx > s_idx:
    raw = raw[s_idx + len(s_delim):e_idx].strip()
if "```json" in raw:
    raw = raw.split("```json")[1].split("```")[0].strip()
elif "```" in raw:
    raw = raw.split("```")[1].split("```")[0].strip()
d = json.loads(raw[raw.find("{"):raw.rfind("}")+1], strict=False) if "{" in raw else {}
print(json.dumps(d.get("skills_evaluation", {})))
' <<< "$RAW_REVIEW" 2>/dev/null || echo '{}')
fi

# ==============================================================================
# 6. EMISIÓN DE ARTEFACTO Y SALIDA ESTRUCTURADA
# ==============================================================================
mkdir -p "$(dirname "$OUTPUT_FILE")"

DELIBERATION_JSON=$(python3 -c '
import json, sys

data = {
    "task_id": "'"$TASK_ID"'",
    "verdict": "'"$FINAL_VERDICT"'",
    "role": "'"$EVALUATOR_ROLE"'",
    "evaluator_tier": "'"$EVALUATION_TIER"'",
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
  echo "🏛️ AGENT-OS DELIBERATION ENGINE — $TASK_ID ($EVALUATION_TIER: $EVALUATOR_ROLE)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Estado: $FINAL_VERDICT (Rondas: $ROUND/2, Timeout: ${TIMEOUT}s)"
  echo "  Síntesis: $DESIGN_SUMMARY"
  if [ "$FINAL_VERDICT" = "SIN_REVISOR" ]; then
    echo "  ⚠️ AVISO: Revisor offline o no configurado. Se mantiene fallback a Fase 3.5 clásica."
  elif [ "$FINAL_VERDICT" = "REVISADO_CON_CAMBIOS" ]; then
    echo "  🛠️ Correcciones consensuadas registradas en $OUTPUT_FILE"
  elif [ "$FINAL_VERDICT" = "RECHAZADO" ]; then
    echo "  ⛔ PLAN RECHAZADO: Objeciones críticas registradas en $OUTPUT_FILE"
  elif [ "$FINAL_VERDICT" = "ESCALADO_A_HUMANO" ]; then
    echo "  🚨 ESCALADO A HUMANO: Intervención manual requerida."
  fi
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi
