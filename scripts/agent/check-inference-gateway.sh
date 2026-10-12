#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/check-inference-gateway.sh — Agent OS
# Pre-flight determinista de una pasarela de inferencia OpenAI-compatible
# (FreeLLMAPI, OmniRoute, LiteLLM, vLLM, Ollama, cualquier /v1) desde el cliente local.
#
# Coste: 0 tokens de inferencia salvo el probe mínimo opcional (1 mensaje, max_tokens acotado).
# No destructivo: solo GET /v1/models y, con --probe, un POST mínimo de chat.
# La clave nunca se imprime: se lee del entorno y se enmascara en toda la salida.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/cli-help.sh"

for cmd in curl python3; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "❌ Error: dependencia requerida '$cmd' no encontrada." >&2
    echo "💡 Guía: instálala con apt-get install -y $cmd (Linux) o brew install $cmd (macOS)." >&2
    exit 1
  }
done

BASE_URL=""
MODEL=""
KEY_ENV=""
TIMEOUT=8
PROBE=false
JSON_OUTPUT=false

for arg in "$@"; do
  if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
    show_help "check-inference-gateway.sh" \
      "bash scripts/agent/check-inference-gateway.sh --url <BASE_URL> [--model <MODEL>] [--key-env <VAR>] [--probe] [--json]" \
      "Verifica de forma determinista que una pasarela de inferencia OpenAI-compatible es alcanzable, autenticada y responde inferencia. Usar antes de lanzar cualquier agente para evitar 401/503/502 en local." \
      "--url <BASE_URL>      Base URL del gateway (defecto: \$INFERENCE_BASE_URL). Debe incluir /v1." \
      "--model <MODEL>       Modelo a sondear con --probe (defecto: \$INFERENCE_MODEL o 'auto')" \
      "--key-env <VAR>       Variable de entorno con la API key (defecto: \$INFERENCE_API_KEY). Si está vacía, el sondeo se hace sin auth (útil para pasarelas locales)." \
      "--probe               Ejecuta un chat completion mínimo para confirmar inferencia real y leer el modelo servido" \
      "--timeout <seg>       Timeout por petición (defecto: 8s)" \
      "--json                Emite el digest estructurado para agentes y orquestadores" \
      "ejemplo: bash scripts/agent/check-inference-gateway.sh --url http://<GATEWAY_HOST>:3001/v1 --key-env FREELLMAPI_KEY --probe --json" \
      "ejemplo: INFERENCE_BASE_URL=http://localhost:11434/v1 bash scripts/agent/check-inference-gateway.sh"
  fi
done

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url) BASE_URL="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --key-env) KEY_ENV="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --probe) PROBE=true; shift ;;
    --json) JSON_OUTPUT=true; shift ;;
    *) echo "❌ Argumento desconocido: $1" >&2; exit 64 ;;
  esac
done

[ -n "$BASE_URL" ] || BASE_URL="${INFERENCE_BASE_URL:-}"
[ -n "$MODEL" ] || MODEL="${INFERENCE_MODEL:-auto}"
[ -n "$KEY_ENV" ] || KEY_ENV="${INFERENCE_API_KEY_VAR:-INFERENCE_API_KEY}"

if [ -z "$BASE_URL" ]; then
  echo "❌ Error: falta --url o INFERENCE_BASE_URL." >&2
  echo "💡 Ejemplo: --url http://<GATEWAY_HOST>:3001/v1" >&2
  exit 64
fi

BASE_URL="${BASE_URL%/}"
API_KEY="${!KEY_ENV:-}"

export GW_BASE_URL="$BASE_URL" GW_TIMEOUT="$TIMEOUT" GW_JSON="$JSON_OUTPUT" \
       GW_PROBE="$PROBE" GW_MODEL="$MODEL" GW_KEY="$API_KEY" GW_KEY_ENV="$KEY_ENV" GW_HAS_KEY="$([ -n "$API_KEY" ] && echo 1 || echo 0)"

python3 - <<'PYEOF'
import json, os, re, subprocess, sys, urllib.parse

base = os.environ["GW_BASE_URL"]
timeout = float(os.environ["GW_TIMEOUT"])
as_json = os.environ["GW_JSON"] == "true"
do_probe = os.environ["GW_PROBE"] == "true"
model = os.environ["GW_MODEL"]
api_key = os.environ["GW_KEY"]
has_key = os.environ["GW_HAS_KEY"] == "1"

GREEN, RED, YELLOW, BLUE, NC = "\033[0;32m", "\033[0;31m", "\033[0;33m", "\033[0;34m", "\033[0m"

def mask_host(url):
    try:
        p = urllib.parse.urlsplit(url)
        host = p.hostname or ""
        if re.fullmatch(r"\d+\.\d+\.\d+\.\d+", host):
            a = host.split(".")
            host = f"{a[0]}.x.x.{a[3]}"
        else:
            parts = host.split(".")
            host = ".".join(parts[:-1] + ["*"]) if len(parts) > 2 else host
        port = f":{p.port}" if p.port else ""
        return f"{p.scheme}://{host}{port}{p.path}"
    except Exception:
        return "[unparseable]"

def http(method, url, payload=None):
    cmd = ["curl", "-sS", "--max-time", str(timeout), "-X", method,
           "-w", "\n%{http_code}", url]
    if payload is not None:
        cmd += ["-H", "Content-Type: application/json", "-d", json.dumps(payload)]
    if has_key:
        cmd += ["-H", f"Authorization: Bearer {api_key}"]
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout + 5)
    except subprocess.TimeoutExpired:
        return None, "timeout"
    if r.returncode != 0:
        return None, (r.stderr.strip().splitlines() or ["connection failed"])[-1]
    out = r.stdout.rsplit("\n", 1)
    body, code = out[0], out[1].strip()
    try:
        return int(code), body
    except ValueError:
        return None, "sin codigo http"

def classify(code):
    if code is None:
        return "UNREACHABLE", RED
    if code in (200, 201):
        return "OK", GREEN
    if code in (401, 403):
        return "AUTH_FAIL", RED
    if code in (502, 503, 504):
        return "UPSTREAM_DOWN", RED
    if code == 404:
        return "NOT_FOUND", YELLOW
    return f"HTTP_{code}", YELLOW

report = {
    "gateway": mask_host(base),
    "auth": f"bearer:{'present' if has_key else 'absent'} (${os.environ['GW_KEY_ENV']})",
    "models_endpoint": {"status": None, "models": 0, "detail": None},
    "probe": None,
    "verdict": "UNKNOWN",
}

code, body = http("GET", base + "/models")
status, color = classify(code)
if status == "OK":
    try:
        report["models_endpoint"]["models"] = len(json.loads(body).get("data", []))
    except Exception:
        report["models_endpoint"]["detail"] = "respuesta no parseable"
elif code == 401 or code == 403:
    report["models_endpoint"]["detail"] = "credencial ausente o invalida"
elif status == "UNREACHABLE":
    report["models_endpoint"]["detail"] = str(body)[:120]
report["models_endpoint"]["status"] = status

verdict = status
if do_probe and status == "OK":
    code, body = http("POST", base + "/chat/completions",
                      {"model": model, "max_tokens": 64,
                       "messages": [{"role": "user", "content": "reply with the single word: pong"}]})
    pstatus, pcolor = classify(code)
    served, routed, content = None, None, None
    if code in (200, 201):
        try:
            d = json.loads(body)
            served = d.get("model")
            routed = (d.get("_routed_via") or {}).get("platform") or (d.get("_routed_via") or {}).get("provider")
            content = ((d.get("choices") or [{}])[0].get("message") or {}).get("content")
            content = (content or "").strip()
        except Exception:
            pstatus, detail = "BAD_BODY", "json invalido"
    report["probe"] = {"status": pstatus, "requested_model": model, "served_model": served,
                       "routed_via": routed, "answered": bool(content)}
    verdict = "OK" if pstatus == "OK" else pstatus

order = {"OK": 0, "NOT_FOUND": 1, "AUTH_FAIL": 2, "UPSTREAM_DOWN": 3, "UNREACHABLE": 4, "BAD_BODY": 5}
report["verdict"] = verdict

if as_json:
    print(json.dumps(report, indent=2))
    sys.exit(0 if verdict == "OK" else min(order.get(verdict, 5) + 1, 5))

if not has_key:
    print(f"{YELLOW}⚠ Sin credencial (--key-env ${os.environ['GW_KEY_ENV']}): un 401 aquí es esperable{NC}")
print(f"Gateway: {report['gateway']}")
print(f"Auth:    {report['auth']}")
print(f"Models:  {report['models_endpoint']['status']} ({report['models_endpoint']['models']} modelos)"
      + (f" — {report['models_endpoint']['detail']}" if report["models_endpoint"]["detail"] else ""))
if do_probe:
    p = report["probe"] or {"status": "SKIPPED"}
    print(f"Probe:   {p['status']}"
          + (f" | pedido={p.get('requested_model')} servido={p.get('served_model')}"
             f" via={p.get('routed_via')} responde={'sí' if p.get('answered') else 'no'}"
             if p.get("served_model") is not None else ""))
print(f"Veredicto: {color}{verdict}{NC}")
sys.exit(0 if verdict == "OK" else min(order.get(verdict, 5) + 1, 5))
PYEOF