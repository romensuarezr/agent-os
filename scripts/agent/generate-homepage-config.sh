#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/generate-homepage-config.sh — Agent OS
# Generates declarative Homepage dashboard YAML configurations from .agents/config/fleet.yaml
# Fully agnostic & modular: reads telemetry, monitoring & service endpoints dynamically
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

FLEET_FILE="$REPO_ROOT/.agents/config/fleet.yaml"
if [[ ! -f "$FLEET_FILE" ]] && [[ -f "$REPO_ROOT/config/fleet.yaml" ]]; then
  # Fallback retrocompatible para proyectos hijos desactualizados
  echo "⚠️  DEPRECATED: $REPO_ROOT/config/fleet.yaml es una ruta obsoleta. Migrar a .agents/config/fleet.yaml" >&2
  FLEET_FILE="$REPO_ROOT/config/fleet.yaml"
fi
if [[ ! -f "$FLEET_FILE" ]]; then
  if [[ -f "$REPO_ROOT/.agents/config/fleet.example.yaml" ]]; then
    FLEET_FILE="$REPO_ROOT/.agents/config/fleet.example.yaml"
  elif [[ -f "$REPO_ROOT/config/fleet.example.yaml" ]]; then
    # Fallback retrocompatible para proyectos hijos desactualizados
    echo "⚠️  DEPRECATED: $REPO_ROOT/config/fleet.example.yaml es una ruta obsoleta. Migrar a .agents/config/fleet.example.yaml" >&2
    FLEET_FILE="$REPO_ROOT/config/fleet.example.yaml"
  fi
fi

OUT_DIR="$REPO_ROOT/templates/homepage/config"
CHECK_ONLY=false
REMOTE_HOST=""

usage() {
  cat <<EOF
Uso: $(basename "$0") [OPCIONES]

Genera las configuraciones YAML para el dashboard Homepage a partir de .agents/config/fleet.yaml.

Opciones:
  --fleet <path>        Ruta al archivo fleet.yaml (defecto: .agents/config/fleet.yaml)
  --out-dir <path>      Directorio de salida para los YAMLs (defecto: templates/homepage/config)
  --remote-push <host>  Sincroniza los archivos generados con el VPS remoto vía SSH/docker
  --check               Modo comprobación (dry-run): parsea y valida sin escribir en disco
  -h, --help            Muestra esta ayuda
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fleet)
      FLEET_FILE="$2"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="$2"
      shift 2
      ;;
    --remote-push)
      REMOTE_HOST="$2"
      shift 2
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
      exit 1
      ;;
  esac
done

if [[ ! -f "$FLEET_FILE" ]]; then
  echo "Error: Archivo de flota '$FLEET_FILE' no encontrado." >&2
  exit 1
fi

FLEET_FILE="$FLEET_FILE" OUT_DIR="$OUT_DIR" CHECK_ONLY="$CHECK_ONLY" python3 - <<'PYEOF'
import os
import sys
import re
import socket
import yaml

fleet_file = os.environ.get("FLEET_FILE", ".agents/config/fleet.yaml")
out_dir = os.environ.get("OUT_DIR", "templates/homepage/config")
check_only = os.environ.get("CHECK_ONLY") == "true"

try:
    with open(fleet_file, "r", encoding="utf-8") as f:
        fleet = yaml.safe_load(f) or {}
except Exception as e:
    print(f"Error parseando {fleet_file}: {e}", file=sys.stderr)
    sys.exit(1)

nodes = fleet.get("nodes", {})
local_env = fleet.get("local_environment", {})
mcp_servers = fleet.get("mcpServers", {})
monitoring = fleet.get("monitoring", {})

def is_placeholder_url(url):
    if not url or not isinstance(url, str):
        return True
    u = url.lower().strip()
    return "example.com" in u or "example.org" in u or "example.net" in u

def is_service_enabled(s_conf):
    if not s_conf:
        return False
    if isinstance(s_conf, dict):
        if s_conf.get("enabled") is False:
            return False
        if s_conf.get("status") in ("inactive", "disabled", "stopped", "down"):
            return False
        if s_conf.get("active") is False:
            return False
    return True

def check_socket_open(host, port, timeout=1.0):
    if not host or "100.x.y.z" in host or "example.com" in host or "203.0.113." in host:
        return False
    try:
        s = socket.create_connection((host, int(port)), timeout=timeout)
        s.close()
        return True
    except Exception:
        return False

# Mapear servicios a grupos de Homepage
group_ai = []
group_control = []
group_dev = []
group_paas = []

# Procesar nodos
for node_name, node_data in nodes.items():
    services = node_data.get("services", {})
    host = node_data.get("host", "")
    
    # 1. AI Services
    if "freellmapi" in services and is_service_enabled(services["freellmapi"]):
        s = services["freellmapi"]
        endpoint = s.get("endpoint", f"http://{host}:3001/v1")
        base_url = endpoint.replace("/v1", "").rstrip("/")
        fl_card = {
            "icon": "si-openai",
            "href": base_url,
            "description": s.get("description", "Unified AI inference proxy aggregator ($0)"),
            "ping": f"{base_url}/health"
        }
        # Solo incluir widget customapi si se activa explícitamente y con Bearer auth para evitar 401
        if s.get("enable_widget") or s.get("include_models_widget"):
            fl_card["widget"] = {
                "type": "customapi",
                "url": f"{endpoint}/models",
                "refreshInterval": 30000,
                "headers": {
                    "Authorization": "Bearer {{HOMEPAGE_VAR_FREELLMAPI_KEY}}"
                },
                "mappings": [
                    {"field": "data", "label": "Modelos activos", "format": "count"}
                ]
            }
        group_ai.append({"FreeLLMAPI ($0 AI Aggregator)": fl_card})
        
    if "omniroute" in services and is_service_enabled(services["omniroute"]):
        s = services["omniroute"]
        endpoint = s.get("endpoint", f"http://{host}:20128/v1")
        base_url = endpoint.replace("/v1", "").rstrip("/")
        group_ai.append({
            "OmniRoute AI Gateway": {
                "icon": "si-probot",
                "href": base_url,
                "description": s.get("description", "Multi-provider AI gateway with RTK compression"),
                "ping": f"{base_url}/health" if s.get("ping_health", True) else f"{endpoint}/models"
            }
        })
        
    if "ollama" in services and is_service_enabled(services["ollama"]):
        s = services["ollama"]
        endpoint = s.get("endpoint", f"http://{host}:11434")
        models = ", ".join(s.get("models", [])) if s.get("models") else ""
        
        port = 11434
        pm = re.search(r':(\d{2,5})', endpoint)
        if pm:
            port = int(pm.group(1))
            
        is_doc = "100.x.y.z" in host or "example.com" in host or "203.0.113." in host
        is_live = check_socket_open(host, port)
        
        # En hosts reales, si el puerto está cerrado no inventar estado ni forzar tarjeta DOWN
        if not is_doc and not is_live:
            # Servicio caído en host real: se omite condicionalmente (ausente) para no ensuciar la Homepage
            pass
        else:
            ol_card = {
                "icon": "si-ollama",
                "href": endpoint,
                "description": f"Modelos locales: {models}" if models else "Local inference engine ($0)"
            }
            if is_live:
                ol_card["ping"] = endpoint
                ol_card["widget"] = {
                    "type": "customapi",
                    "url": f"{endpoint}/api/tags",
                    "refreshInterval": 15000,
                    "mappings": [
                        {"field": "models", "label": "Modelos instalados", "format": "count"}
                    ]
                }
            elif is_doc:
                # En modo doc / plantilla: bajo demanda sin ping para evitar DOWN
                ol_card["description"] = f"Modelos locales (bajo demanda): {models}" if models else "Local inference engine ($0 bajo demanda)"
            group_ai.append({"Ollama (Local Models)": ol_card})
        
    if "searxng" in services and is_service_enabled(services["searxng"]):
        s = services["searxng"]
        endpoint = s.get("endpoint", f"http://{host}:8080")
        if not is_placeholder_url(endpoint):
            group_dev.append({
                "SearXNG Meta-Search": {
                    "icon": "si-searxng",
                    "href": endpoint,
                    "description": s.get("description", "Private meta-search engine"),
                    "ping": endpoint
                }
            })
        
    # 2. Control & Secrets
    if "infisical" in services and is_service_enabled(services["infisical"]):
        s = services["infisical"]
        url = s.get("admin_console") or s.get("endpoint", "")
        # Omitir si es un placeholder ficticio *.example.com no configurado
        if not is_placeholder_url(url):
            ping_url = f"{s.get('api_url', url)}/status" if "api_url" in s else url
            group_control.append({
                "Infisical Secrets Manager": {
                    "icon": "si-vault",
                    "href": url,
                    "description": s.get("description", "Centralized secrets manager with Universal Auth"),
                    "ping": ping_url
                }
            })
        
    if "orca_gateway" in services and is_service_enabled(services["orca_gateway"]):
        s = services["orca_gateway"]
        endpoint = s.get("endpoint", "http://localhost:8000")
        if not is_placeholder_url(endpoint):
            group_control.append({
                "Orca Desktop Engine": {
                    "icon": "si-docker",
                    "href": endpoint,
                    "description": s.get("description", "Agent orchestrator & decision gate inspect engine"),
                    "ping": endpoint
                }
            })
        
    # 3. Dev & Snippets
    if "bytebox" in services and is_service_enabled(services["bytebox"]):
        s = services["bytebox"]
        url = s.get("url") or s.get("custom_domain", "")
        # Omitir si es un placeholder ficticio *.example.com no configurado
        if not is_placeholder_url(url):
            group_dev.append({
                "ByteBox Snippets & CLI": {
                    "icon": "si-gnubash",
                    "href": url,
                    "description": s.get("description", "Developer CLI commands, code snippets and notes organizer"),
                    "ping": f"{url}/api/cards"
                }
            })

    # 4. PaaS & Infrastructure
    if "coolify" in services and is_service_enabled(services["coolify"]):
        s = services["coolify"]
        url = s.get("url", "")
        # Omitir si es un placeholder ficticio *.example.com no configurado
        if not is_placeholder_url(url):
            group_paas.append({
                "Coolify PaaS": {
                    "icon": "si-docker",
                    "href": url,
                    "description": s.get("description", "PaaS manager for containerized applications"),
                    "ping": f"{url}/api/v1/version"
                }
            })
        
    if "traefik" in services and is_service_enabled(services["traefik"]):
        s = services["traefik"]
        cool_url = services.get("coolify", {}).get("url", "")
        if not is_placeholder_url(cool_url):
            group_paas.append({
                "Traefik SSL Proxy": {
                    "icon": "si-traefikproxy",
                    "href": cool_url,
                    "description": s.get("description", "Edge reverse proxy with automatic SSL")
                }
            })

# Agregar GitHub widget en group_dev si está habilitado en monitoring
github_cfg = monitoring.get("github", {})
if github_cfg.get("enabled", True):
    repo = github_cfg.get("repo", "romensuarezr/agent-os")
    desc = github_cfg.get("description", "Core Architecture, Workflows, Skills & Multi-Agent Engine")
    group_dev.insert(0, {
        "GitHub Core (Agent OS)": {
            "icon": "si-github",
            "href": f"https://github.com/{repo}",
            "description": desc,
            "widget": {
                "type": "github",
                "repo": repo
            }
        }
    })

# Construir services.yaml solo con grupos que contengan servicios
services_yaml = []
if group_ai:
    services_yaml.append({"AI Gateways & Inferencia ($0)": group_ai})
if group_control:
    services_yaml.append({"Control Plane & Secretos": group_control})
if group_dev:
    services_yaml.append({"Productividad Dev & Snippets": group_dev})
if group_paas:
    services_yaml.append({"PaaS & Orquestación": group_paas})

# Obtener URL de Coolify si existe y no es placeholder para bookmarks
coolify_portal_url = None
for nd in nodes.values():
    if "coolify" in nd.get("services", {}):
        c_url = nd["services"]["coolify"].get("url", "")
        if not is_placeholder_url(c_url):
            coolify_portal_url = c_url
            break

# Construir bookmarks.yaml
control_bookmarks = [
    {
        "GitHub Agent OS": [
            {"icon": "si-github", "href": f"https://github.com/{github_cfg.get('repo', 'romensuarezr/agent-os')}"}
        ]
    }
]
if coolify_portal_url:
    control_bookmarks.append({
        "Coolify Console": [
            {"icon": "si-docker", "href": coolify_portal_url}
        ]
    })

bookmarks_yaml = [
    {
        "Control & Repos": control_bookmarks
    }
]

# Construir settings.yaml
settings_yaml = {
    "title": "Agent OS — Fleet Control Dashboard",
    "theme": "dark",
    "color": "slate",
    "headerStyle": "boxed",
    "cardBlur": "sm",
    "layout": {
        "AI Gateways & Inferencia ($0)": {"style": "row", "columns": 3},
        "Control Plane & Secretos": {"style": "row", "columns": 2},
        "Productividad Dev & Snippets": {"style": "row", "columns": 2},
        "PaaS & Orquestación": {"style": "row", "columns": 2}
    }
}

# Construir widgets.yaml de forma modular y agnóstica
widgets_yaml = []

# A. Bloque Search
search_cfg = monitoring.get("search", {})
if search_cfg.get("enabled", True):
    widgets_yaml.append({
        "search": {
            "provider": search_cfg.get("provider", "duckduckgo"),
            "target": search_cfg.get("target", "_blank")
        }
    })

# B. Bloque Local Resources (Host PaaS / Oracle VPS)
paas_label = "Oracle VPS"
for n_name, n_data in nodes.items():
    if "coolify" in n_data.get("services", {}):
        paas_label = n_data.get("label", "Oracle VPS")
        break

widgets_yaml.append({
    "resources": {
        "cpu": True,
        "memory": True,
        "disk": "/",
        "label": paas_label
    }
})

# C. Bloque Glances Multi-Host detectado dinámicamente en nodes
for node_name, node_data in nodes.items():
    services = node_data.get("services", {})
    host = node_data.get("host", "")
    if "glances" in services:
        g = services["glances"]
        endpoint = g.get("endpoint", f"http://{host}:61208")
        label = g.get("label", f"{node_name.title()} (Glances)")
        version = g.get("version", 4)
        widgets_yaml.append({
            "glances": {
                "label": label,
                "url": endpoint,
                "version": version,
                "cpu": True,
                "mem": True,
                "expanded": True,
                "disk": ["/"]
            }
        })

total_services = sum(len(g) for g in [group_ai, group_control, group_dev, group_paas])
print(f"✅ Parser completado: {total_services} servicios mapeados en 4 grupos de Homepage.")

if check_only:
    print("\n--- [DRY-RUN] services.yaml preview ---")
    print(yaml.dump(services_yaml, sort_keys=False))
    print("\n--- [DRY-RUN] widgets.yaml preview ---")
    print(yaml.dump(widgets_yaml, sort_keys=False))
    sys.exit(0)

os.makedirs(out_dir, exist_ok=True)

with open(os.path.join(out_dir, "services.yaml"), "w", encoding="utf-8") as f:
    yaml.dump(services_yaml, f, sort_keys=False)

with open(os.path.join(out_dir, "bookmarks.yaml"), "w", encoding="utf-8") as f:
    yaml.dump(bookmarks_yaml, f, sort_keys=False)

with open(os.path.join(out_dir, "settings.yaml"), "w", encoding="utf-8") as f:
    yaml.dump(settings_yaml, f, sort_keys=False)

with open(os.path.join(out_dir, "widgets.yaml"), "w", encoding="utf-8") as f:
    yaml.dump(widgets_yaml, f, sort_keys=False)

print(f"✅ Archivos generados exitosamente en: {out_dir}/")
PYEOF

chmod +x "$REPO_ROOT/scripts/agent/generate-homepage-config.sh"

if [[ -n "$REMOTE_HOST" ]]; then
  echo "--> Sincronizando configuración generada con nodo remoto $REMOTE_HOST..."
  ssh "$REMOTE_HOST" "sudo mkdir -p /var/lib/docker/volumes/homepage-config/_data"
  scp -r "$OUT_DIR"/* "$REMOTE_HOST:/tmp/homepage-config/"
  ssh "$REMOTE_HOST" "sudo cp -r /tmp/homepage-config/* /var/lib/docker/volumes/homepage-config/_data/ && rm -rf /tmp/homepage-config"
  echo "✅ Sincronización remota completada."
fi
