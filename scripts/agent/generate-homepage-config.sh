#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/generate-homepage-config.sh — Agent OS
# Generates declarative Homepage dashboard YAML configurations from config/fleet.yaml
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

FLEET_FILE="$REPO_ROOT/config/fleet.yaml"
if [[ ! -f "$FLEET_FILE" ]]; then
  FLEET_FILE="$REPO_ROOT/config/fleet.example.yaml"
fi

OUT_DIR="$REPO_ROOT/templates/homepage/config"
CHECK_ONLY=false
REMOTE_HOST=""

usage() {
  cat <<EOF
Uso: $(basename "$0") [OPCIONES]

Genera las configuraciones YAML para el dashboard Homepage a partir de config/fleet.yaml.

Opciones:
  --fleet <path>        Ruta al archivo fleet.yaml (defecto: config/fleet.yaml)
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
import yaml

fleet_file = os.environ.get("FLEET_FILE", "config/fleet.yaml")
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
    if "freellmapi" in services:
        s = services["freellmapi"]
        endpoint = s.get("endpoint", f"http://{host}:3001/v1")
        base_url = endpoint.replace("/v1", "")
        group_ai.append({
            "FreeLLMAPI": {
                "icon": "si-openai",
                "href": base_url,
                "description": s.get("description", "Unified AI inference proxy aggregator ($0)"),
                "ping": f"{endpoint}/models"
            }
        })
        
    if "omniroute" in services:
        s = services["omniroute"]
        endpoint = s.get("endpoint", f"http://{host}:20128/v1")
        base_url = endpoint.replace("/v1", "")
        group_ai.append({
            "OmniRoute AI Gateway": {
                "icon": "si-probot",
                "href": base_url,
                "description": s.get("description", "Multi-provider AI gateway with RTK compression"),
                "ping": f"{endpoint}/models"
            }
        })
        
    if "ollama" in services:
        s = services["ollama"]
        endpoint = s.get("endpoint", f"http://{host}:11434")
        models = ", ".join(s.get("models", []))
        group_ai.append({
            "Ollama (Local Models)": {
                "icon": "si-ollama",
                "href": endpoint,
                "description": f"Modelos locales: {models}" if models else "Local inference engine",
                "ping": endpoint
            }
        })
        
    if "searxng" in services:
        s = services["searxng"]
        endpoint = s.get("endpoint", f"http://{host}:8080")
        group_dev.append({
            "SearXNG Meta-Search": {
                "icon": "si-searxng",
                "href": endpoint,
                "description": s.get("description", "Private meta-search engine"),
                "ping": endpoint
            }
        })
        
    # 2. Control & Secrets
    if "infisical" in services:
        s = services["infisical"]
        url = s.get("admin_console") or s.get("endpoint", "")
        group_control.append({
            "Infisical Secrets Manager": {
                "icon": "si-vault",
                "href": url,
                "description": s.get("description", "Centralized secrets manager with Universal Auth"),
                "ping": f"{s.get('api_url', url)}/status" if "api_url" in s else url
            }
        })
        
    if "orca_gateway" in services:
        s = services["orca_gateway"]
        endpoint = s.get("endpoint", "http://localhost:8000")
        group_control.append({
            "Orca Desktop Engine": {
                "icon": "si-docker",
                "href": endpoint,
                "description": s.get("description", "Agent orchestrator & decision gate inspect engine"),
                "ping": endpoint
            }
        })
        
    # 3. Dev & Snippets
    if "bytebox" in services:
        s = services["bytebox"]
        url = s.get("url") or s.get("custom_domain", "")
        group_dev.append({
            "ByteBox Snippets & CLI": {
                "icon": "si-gnubash",
                "href": url,
                "description": s.get("description", "Developer CLI commands, snippets & notes"),
                "ping": f"{url}/api/cards"
            }
        })

    # 4. PaaS & Infrastructure
    if "coolify" in services:
        s = services["coolify"]
        url = s.get("url", "https://coolify.romensuarez.com")
        group_paas.append({
            "Coolify PaaS": {
                "icon": "si-docker",
                "href": url,
                "description": s.get("description", "PaaS manager for containerized applications"),
                "ping": f"{url}/api/v1/version"
            }
        })
        
    if "traefik" in services:
        s = services["traefik"]
        cool_url = services.get("coolify", {}).get("url", "https://coolify.example.com")
        group_paas.append({
            "Traefik SSL Proxy": {
                "icon": "si-traefikproxy",
                "href": cool_url,
                "description": s.get("description", "Edge reverse proxy with automatic Let's Encrypt SSL")
            }
        })

# Construir services.yaml
services_yaml = [
    {"AI Gateways & Inferencia ($0)": group_ai},
    {"Control Plane & Secretos": group_control},
    {"Productividad Dev & Snippets": group_dev},
    {"PaaS & Orquestación": group_paas}
]

# Obtener URL de Coolify si existe para bookmarks
coolify_portal_url = "https://coolify.example.com"
for nd in nodes.values():
    if "coolify" in nd.get("services", {}):
        coolify_portal_url = nd["services"]["coolify"].get("url", coolify_portal_url)
        break

# Construir bookmarks.yaml
bookmarks_yaml = [
    {
        "Control & Repos": [
            {
                "GitHub Agent OS": [
                    {"icon": "si-github", "href": "https://github.com/romensuarezr/agent-os"}
                ]
            },
            {
                "Coolify Console": [
                    {"icon": "si-docker", "href": coolify_portal_url}
                ]
            }
        ]
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

# Construir widgets.yaml
widgets_yaml = [
    {
        "resources": {
            "cpu": True,
            "memory": True,
            "disk": "/",
            "label": "Oracle VPS"
        }
    }
]

total_services = sum(len(g) for g in [group_ai, group_control, group_dev, group_paas])
print(f"✅ Parser completado: {total_services} servicios mapeados en 4 grupos de Homepage.")

if check_only:
    print("\n--- [DRY-RUN] services.yaml preview ---")
    print(yaml.dump(services_yaml, sort_keys=False))
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
