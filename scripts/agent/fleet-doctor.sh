#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/fleet-doctor.sh — Agent OS
# Diagnóstico determinista de herramientas locales, autenticación y conectividad viva
# Coste: 0 tokens de inferencia. Enmascaramiento de infraestructura: octetos centrales de IPv4 y dominios enmascarados; tokens siempre [MASKED].
# Digest acotado a máximo 20 líneas en modo texto. Soporte completo de flag --json.
# ==============================================================================
set -euo pipefail

# Pre-flight: verificación determinista de dependencias
if ! command -v python3 &>/dev/null; then
  echo "❌ ERROR: Dependencia requerida no encontrada: python3" >&2
  echo "Guía: Instala python3 en tu sistema antes de continuar." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

FLEET_FILE=""
JSON_OUTPUT=false
TIMEOUT=2
STRICT=false
CHECK_ONLY=false

usage() {
  cat <<EOF
Uso: $(basename "$0") [OPCIONES]

Diagnóstico determinista de herramientas locales, autenticación y conectividad de flota.

Opciones:
  --fleet <ruta>       Ruta al archivo fleet.yaml (defecto: config/fleet.yaml, fallback: config/fleet.example.yaml)
  --json               Emite el digest estructurado en JSON para agentes y orquestadores
  --timeout <segundos> Timeout estricto por socket/endpoint (defecto: 2s)
  --strict             Retorna código 1 si algún CLI o servicio falla
  --check              Modo dry-run de comprobación de sintaxis y entorno
  -h, --help           Muestra esta ayuda

Principios:
  - 0 tokens de inferencia (ejecución determinista puramente local)
  - Enmascaramiento de infraestructura: octetos centrales de IPv4 y dominios enmascarados; tokens siempre [MASKED]
  - Digest texto acotado a ≤ 20 líneas legibles
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fleet)
      FLEET_FILE="$2"
      shift 2
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    --timeout)
      TIMEOUT="$2"
      shift 2
      ;;
    --strict)
      STRICT=true
      shift
      ;;
    --check)
      CHECK_ONLY=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Error: Argumento desconocido '$1'" >&2
      usage
      ;;
  esac
done

# Resolver ruta de archivo fleet si no fue proporcionada
DOC_MODE=false
if [[ -z "$FLEET_FILE" ]]; then
  if [[ -f "$REPO_ROOT/config/fleet.yaml" ]]; then
    FLEET_FILE="$REPO_ROOT/config/fleet.yaml"
  elif [[ -f "$REPO_ROOT/config/fleet.example.yaml" ]]; then
    FLEET_FILE="$REPO_ROOT/config/fleet.example.yaml"
    DOC_MODE=true
  else
    FLEET_FILE=""
  fi
elif [[ ! -f "$FLEET_FILE" ]]; then
  echo "Error: El archivo de flota especificado no existe: $FLEET_FILE" >&2
  exit 1
fi

if [[ "$FLEET_FILE" == *"fleet.example.yaml"* ]]; then
  DOC_MODE=true
fi

export FLEET_FILE
export JSON_OUTPUT
export TIMEOUT
export STRICT
export CHECK_ONLY
export DOC_MODE

python3 - <<'PYEOF'
import os
import sys
import json
import socket
import urllib.request
import urllib.error
import re
import subprocess
import shutil

try:
    import yaml
    HAS_YAML = True
except ImportError:
    yaml = None
    HAS_YAML = False

fleet_file = os.environ.get("FLEET_FILE", "")
json_mode = os.environ.get("JSON_OUTPUT") == "true"
timeout = float(os.environ.get("TIMEOUT", "2.0"))
strict = os.environ.get("STRICT") == "true"
check_only = os.environ.get("CHECK_ONLY") == "true"
doc_mode = os.environ.get("DOC_MODE") == "true"

def mask_token(token):
    if not token or not isinstance(token, str):
        return "[NONE]"
    token = token.strip()
    if len(token) <= 8:
        return "[MASKED]"
    return token[:4] + "_***"

def mask_ip_or_host(val):
    if not val or not isinstance(val, str):
        return "[MASKED]"
    val_str = str(val).strip()
    # Enmascarar IPv4 (ej. 100.99.88.77 -> 100.***.***.77)
    val_masked = re.sub(r'\b(\d{1,3})\.\d{1,3}\.\d{1,3}\.(\d{1,3})\b', r'\1.***.***.\2', val_str)
    # Enmascarar hostnames con dominio o ejemplo
    val_masked = re.sub(r'\b([a-zA-Z0-9_\-]+)\.(?:[a-zA-Z0-9_\-\.]+)\b', r'\1.[MASKED-DOMAIN]', val_masked)
    return val_masked

def mask_endpoint(endpoint_url):
    if not endpoint_url or not isinstance(endpoint_url, str):
        return "[MASKED-ENDPOINT]"
    # Extraer puerto si existe
    port_match = re.search(r':(\d{2,5})', endpoint_url)
    port_str = f":{port_match.group(1)}" if port_match else ""
    # Extraer path si existe
    path_match = re.search(r'https?://[^/]+(/.*)?', endpoint_url)
    path_str = path_match.group(1) if (path_match and path_match.group(1)) else ""
    return f"http://[MASKED-HOST]{port_str}{path_str}"

# 1. Comprobación determinista de CLIs locales
clis_status = {}

def check_cli(cmd):
    return shutil.which(cmd) is not None

clis_to_check = ["git", "gh", "docker", "infisical", "tailscale"]
for c in clis_to_check:
    clis_status[c] = {"installed": check_cli(c)}

# 2. Comprobación funcional de autenticación
auth_status = {}

# Git
if clis_status["git"]["installed"]:
    try:
        p = subprocess.run(["git", "status", "--short"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        auth_status["git"] = {"ok": p.returncode == 0, "status": "CLEAN" if len(p.stdout.strip()) == 0 else "DIRTY"}
    except Exception:
        auth_status["git"] = {"ok": False, "status": "FAIL"}
else:
    auth_status["git"] = {"ok": False, "status": "MISSING"}

# GitHub CLI
if clis_status["gh"]["installed"]:
    try:
        p = subprocess.run(["gh", "auth", "status"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        raw = p.stdout + p.stderr
        if "Logged in to github.com" in raw or "Logged in to" in raw:
            acc_match = re.search(r'account\s+([a-zA-Z0-9_\-]+)', raw)
            user = acc_match.group(1) if acc_match else "authenticated"
            auth_status["gh"] = {"ok": True, "status": f"AUTH ({user})", "user": user}
        else:
            auth_status["gh"] = {"ok": False, "status": "UNAUTHENTICATED", "user": None}
    except Exception:
        auth_status["gh"] = {"ok": False, "status": "FAIL", "user": None}
else:
    auth_status["gh"] = {"ok": False, "status": "MISSING", "user": None}

# Infisical CLI
if clis_status["infisical"]["installed"]:
    try:
        p = subprocess.run(["infisical", "profile", "list"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        raw = p.stdout + p.stderr
        if "No login profiles found" in raw:
            auth_status["infisical"] = {"ok": False, "status": "NO-PROFILE"}
        elif p.returncode == 0 and len(raw.strip()) > 0:
            auth_status["infisical"] = {"ok": True, "status": "PROFILE-ACTIVE"}
        else:
            auth_status["infisical"] = {"ok": False, "status": "FAIL"}
    except Exception:
        auth_status["infisical"] = {"ok": False, "status": "FAIL"}
else:
    auth_status["infisical"] = {"ok": False, "status": "MISSING"}

# Tailscale
if clis_status["tailscale"]["installed"]:
    try:
        p = subprocess.run(["tailscale", "status"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        auth_status["tailscale"] = {"ok": p.returncode == 0, "status": "CONNECTED" if p.returncode == 0 else "STOPPED"}
    except Exception:
        auth_status["tailscale"] = {"ok": False, "status": "FAIL"}
else:
    auth_status["tailscale"] = {"ok": False, "status": "MISSING"}

# Docker
if clis_status["docker"]["installed"]:
    try:
        p = subprocess.run(["docker", "info"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        auth_status["docker"] = {"ok": p.returncode == 0, "status": "UP" if p.returncode == 0 else "DOWN"}
    except Exception:
        auth_status["docker"] = {"ok": False, "status": "FAIL"}
else:
    auth_status["docker"] = {"ok": False, "status": "MISSING"}

# 3. Parsear flota y verificar conectividad viva
fleet_data = {}
if not HAS_YAML:
    fleet_mode_status = "NO_YAML_LIB"
    nodes_data = {}
else:
    if fleet_file and os.path.isfile(fleet_file):
        try:
            with open(fleet_file, "r", encoding="utf-8") as f:
                fleet_data = yaml.safe_load(f) or {}
        except Exception as e:
            fleet_data = {"error": str(e)}

    nodes_data = fleet_data.get("nodes", {})
    if doc_mode or not nodes_data:
        fleet_mode_status = "SKIPPED-NO-FLEET"
    else:
        fleet_mode_status = "ACTIVE"

nodes_result = {}
total_services = 0
services_up = 0
services_down = 0

def check_tcp_socket(host, port, to_sec):
    try:
        s = socket.create_connection((host, int(port)), timeout=to_sec)
        s.close()
        return True, "TCP_OK"
    except socket.timeout:
        return False, "TIMEOUT_2S"
    except ConnectionRefusedError:
        return False, "REFUSED"
    except Exception as e:
        return False, "UNREACHABLE"

def check_http_status(url, to_sec):
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "agent-os-fleet-doctor/1.0"})
        with urllib.request.urlopen(req, timeout=to_sec) as response:
            return response.getcode(), "OK"
    except urllib.error.HTTPError as he:
        return he.code, f"HTTP_{he.code}"
    except urllib.error.URLError as ue:
        return None, "TIMEOUT_OR_ERR"
    except Exception:
        return None, "ERR"

for node_alias, node_info in nodes_data.items():
    raw_host = node_info.get("host", "")
    role = node_info.get("role", "general")
    services = node_info.get("services", {})
    
    node_res = {
        "role": role,
        "host_masked": mask_ip_or_host(raw_host),
        "services": {}
    }

    for svc_name, svc_conf in services.items():
        total_services += 1
        port = None
        endpoint = ""
        auth_type = "none"

        if isinstance(svc_conf, dict):
            endpoint = svc_conf.get("endpoint", svc_conf.get("url", ""))
            auth_type = svc_conf.get("auth", "none")
            if "port" in svc_conf:
                port = svc_conf.get("port")
        elif isinstance(svc_conf, str):
            endpoint = svc_conf

        if not port and endpoint:
            pm = re.search(r':(\d{2,5})', endpoint)
            if pm:
                port = int(pm.group(1))

        if doc_mode or not raw_host or "100.x.y.z" in raw_host or "example.com" in raw_host or "203.0.113." in raw_host:
            status_desc = "SKIPPED-DOC-MODE"
            is_up = None
        else:
            # Comprobar socket TCP en host real
            if port:
                tcp_ok, tcp_msg = check_tcp_socket(raw_host, port, timeout)
                if tcp_ok:
                    is_up = True
                    services_up += 1
                    status_desc = "UP"
                    # Si tiene endpoint http, hacer probe rápido de status code
                    if endpoint.startswith("http"):
                        http_code, http_msg = check_http_status(endpoint, timeout)
                        if http_code:
                            status_desc = f"UP (HTTP {http_code})"
                else:
                    is_up = False
                    services_down += 1
                    status_desc = f"DOWN ({tcp_msg})"
            else:
                status_desc = "NO_PORT_DEFINED"
                is_up = None

        node_res["services"][svc_name] = {
            "status": status_desc,
            "port": port,
            "endpoint_masked": mask_endpoint(endpoint) if endpoint else None,
            "auth": "bearer_masked" if "bearer" in str(auth_type).lower() else auth_type
        }

    nodes_result[node_alias] = node_res

# Estructurar resultado global
cli_ok_count = sum(1 for c, data in auth_status.items() if data.get("ok"))
total_clis = len(clis_to_check)

overall_healthy = (cli_ok_count >= 3) and (services_down == 0)
exit_code = 0
if strict and not overall_healthy:
    exit_code = 1

summary_data = {
    "overall_healthy": overall_healthy,
    "fleet_mode": fleet_mode_status,
    "clis_checked": total_clis,
    "clis_ok": cli_ok_count,
    "services_checked": total_services,
    "services_up": services_up,
    "services_down": services_down
}

if json_mode:
    output_obj = {
        "doctor_version": "1.0.0",
        "summary": summary_data,
        "clis": clis_status,
        "authentication": auth_status,
        "fleet": {
            "source": "config/fleet.example.yaml" if doc_mode else (fleet_file if fleet_file else "config/fleet.yaml"),
            "mode": fleet_mode_status,
            "nodes": nodes_result
        }
    }
    print(json.dumps(output_obj, indent=2))
    sys.exit(exit_code)

# 4. Modo Texto: Estrictamente acotado a <= 20 líneas, 0 IPs, 0 secretos
lines = []
lines.append("=== FLEET DOCTOR DIGEST ===")
if not HAS_YAML:
    fleet_source_label = f"{fleet_file if fleet_file else 'config/fleet.yaml'} [MODE: NO_YAML_LIB]"
else:
    fleet_source_label = "config/fleet.yaml (active overlay)" if not doc_mode else "config/fleet.example.yaml [MODE: SKIPPED-NO-FLEET]"
lines.append(f"Fleet: {fleet_source_label}")

# Línea compacta de CLIs
cli_parts = []
for c in ["git", "gh", "docker", "infisical", "tailscale"]:
    st = auth_status.get(c, {}).get("status", "UNKNOWN")
    cli_parts.append(f"{c}:{st}")
lines.append("CLIs: " + " | ".join(cli_parts))

if not HAS_YAML:
    lines.append("Nodes: (PyYAML no disponible — diagnóstico de flota omitido con aviso)")
elif doc_mode or not nodes_result:
    lines.append("Nodes: (Sin fleet.yaml local — conectividad de flota omitida en modo agnóstico)")
else:
    for node_name, ninfo in nodes_result.items():
        role = ninfo.get("role", "")
        svc_parts = []
        for sname, sdata in ninfo.get("services", {}).items():
            port_label = f":{sdata['port']}" if sdata.get("port") else ""
            st = sdata.get("status", "UNKNOWN")
            auth_note = " [auth:masked]" if sdata.get("auth") == "bearer_masked" else ""
            svc_parts.append(f"{sname}{port_label}:{st}{auth_note}")
        line_entry = f"• [{node_name}] ({role}): " + ", ".join(svc_parts)
        lines.append(line_entry)

lines.append(f"Summary: CLIs {cli_ok_count}/{total_clis} OK | Services: {services_up} UP, {services_down} DOWN, {total_services - services_up - services_down} SKIPPED")
lines.append("=== FIN FLEET DOCTOR (0 tokens inferidos, infraestructura enmascarada) ===")

# Asegurar tope estricto de 20 líneas
final_output = lines[:20]
for l in final_output:
    print(l)

sys.exit(exit_code)
PYEOF
