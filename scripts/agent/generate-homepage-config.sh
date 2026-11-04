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

OUT_DIR=""
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

TEMP_OUT_DIR=""
if [[ -z "$OUT_DIR" ]]; then
  if [[ -n "$REMOTE_HOST" ]]; then
    TEMP_OUT_DIR=$(mktemp -d)
    OUT_DIR="$TEMP_OUT_DIR"
  else
    OUT_DIR="$REPO_ROOT/templates/homepage/config"
  fi
fi

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

# Normalizar nodos y servicios al inicio (soporte transparente para ip como host y servicios como int/str)
normalized_nodes = {}
for n_name, n_data in nodes.items():
    if not isinstance(n_data, dict):
        continue
    h = n_data.get("host") or n_data.get("ip", "")
    s_raw = n_data.get("services", {})
    s_norm = {}
    if isinstance(s_raw, dict):
        for sk, sv in s_raw.items():
            if isinstance(sv, (int, str)):
                p = str(sv).strip()
                ep = p if "://" in p else (f"http://{h}:{p}" if h else f"http://localhost:{p}")
                s_norm[sk] = {"endpoint": ep, "url": ep, "port": p}
            elif isinstance(sv, dict):
                s_norm[sk] = dict(sv)
            elif sv is True:
                s_norm[sk] = {}
    n_copy = dict(n_data)
    n_copy["host"] = h
    n_copy["services"] = s_norm
    normalized_nodes[n_name] = n_copy
nodes = normalized_nodes

def is_placeholder_url(url):
    if not url or not isinstance(url, str):
        return True
    u = url.lower().strip()
    return "example.com" in u or "example.org" in u or "example.net" in u or "localhost:8000" in u or "127.0.0.1:8000" in u

def is_service_enabled(s_conf):
    if s_conf is None or s_conf is False:
        return False
    if isinstance(s_conf, (int, str)):
        return True
    if isinstance(s_conf, dict):
        if s_conf.get("enabled") is False:
            return False
        if s_conf.get("status") in ("inactive", "disabled", "stopped", "down"):
            return False
        if s_conf.get("active") is False:
            return False
    return True

def check_socket_open(host, port, timeout=1.0):
    if not host or "100.x.y.z" in host or "example.com" in host or "192.0.2." in host or "198.51.100." in host or "203.0.113." in host:
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
    if not isinstance(node_data, dict):
        continue
    host = node_data.get("host") or node_data.get("ip", "")
    services_raw = node_data.get("services", {})
    services = {}
    if isinstance(services_raw, dict):
        for sk, sv in services_raw.items():
            if isinstance(sv, (int, str)):
                p = str(sv).strip()
                ep = p if "://" in p else (f"http://{host}:{p}" if host else f"http://localhost:{p}")
                services[sk] = {"endpoint": ep, "url": ep, "port": p}
            elif isinstance(sv, dict):
                services[sk] = sv
            elif sv is True:
                services[sk] = {}
    
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
        # T-168: Soportar ping granular (OmniRoute no expone /health, devuelve 404; su raíz / devuelve 200)
        ping_url = s.get("ping")
        if not ping_url:
            ping_path = s.get("ping_path")
            if ping_path is not None:
                ping_url = f"{base_url}{ping_path}" if ping_path.startswith("/") else f"{base_url}/{ping_path}"
            elif s.get("ping_health") is True:
                ping_url = f"{base_url}/health"
            else:
                ping_url = f"{base_url}/"
        group_ai.append({
            "OmniRoute AI Gateway": {
                "icon": "si-probot",
                "href": base_url,
                "description": s.get("description", "Multi-provider AI gateway with RTK compression"),
                "ping": ping_url
            }
        })

    ow_svc = services.get("open-webui") or services.get("open_webui")
    if ow_svc and is_service_enabled(ow_svc):
        endpoint = ow_svc.get("endpoint") or ow_svc.get("url", f"http://{host}:3005")
        if not is_placeholder_url(endpoint):
            ping_url = ow_svc.get("ping") or ow_svc.get("ping_url")
            if not ping_url:
                ping_path = ow_svc.get("ping_path")
                ping_url = f"{endpoint.rstrip('/')}{ping_path}" if ping_path else endpoint
            group_ai.append({
                "Open-WebUI (AI Chat Interface)": {
                    "icon": "si-openai",
                    "href": endpoint,
                    "description": ow_svc.get("description", "Web UI chat interface for local & gateway models"),
                    "ping": ping_url
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

    if "nango" in services and is_service_enabled(services["nango"]):
        s = services["nango"]
        endpoint = s.get("endpoint") or s.get("url", f"http://{host}:3003")
        connect_ui = s.get("connect_ui_url", f"http://{host}:3009")
        if not is_placeholder_url(endpoint):
            group_paas.append({
                "Nango Unified OAuth": {
                    "icon": "si-auth0",
                    "href": connect_ui if not is_placeholder_url(connect_ui) else endpoint,
                    "description": s.get("description", "Unified OAuth & API integration platform"),
                    "ping": f"{endpoint}/health"
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
    if not isinstance(node_data, dict):
        continue
    services = node_data.get("services", {})
    host = node_data.get("host") or node_data.get("ip", "")
    if "glances" in services and is_service_enabled(services["glances"]):
        g = services["glances"]
        if isinstance(g, (int, str)):
            endpoint = f"http://{host}:{g}"
            label = f"{node_name.title()} (Glances)"
            version = 4
        elif isinstance(g, dict):
            endpoint = g.get("endpoint", f"http://{host}:61208")
            label = g.get("label", f"{node_name.title()} (Glances)")
            version = g.get("version", 4)
        else:
            endpoint = f"http://{host}:61208"
            label = f"{node_name.title()} (Glances)"
            version = 4

        if not is_placeholder_url(endpoint):
            # T-168: Glances solo se reactiva si el servicio responde; en hosts reales comprobamos socket
            port = 61208
            pm = re.search(r':(\d{2,5})', endpoint)
            if pm:
                port = int(pm.group(1))
            is_doc = "100.x.y.z" in host or "example.com" in host or "192.0.2." in host or "198.51.100." in host or "203.0.113." in host
            is_live = check_socket_open(host, port)
            if is_live or is_doc:
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
  # Localizar el montaje activo de Homepage si el contenedor está en ejecución, o fallback a volumen Coolify
  REMOTE_DATA_DIR=$(ssh "$REMOTE_HOST" "docker inspect \$(docker ps -q --filter 'name=homepage' 2>/dev/null | head -n 1) --format '{{range .Mounts}}{{if eq .Destination \"/app/config\"}}{{.Source}}{{end}}{{end}}' 2>/dev/null || true")
  if [[ -z "$REMOTE_DATA_DIR" ]]; then
    REMOTE_VOL_DIR=$(ssh "$REMOTE_HOST" "sudo find /var/lib/docker/volumes/ -maxdepth 1 -name '*homepage-config' -type d 2>/dev/null | grep -E '_homepage-config' | head -n 1 || true")
    if [[ -n "$REMOTE_VOL_DIR" ]]; then
      REMOTE_DATA_DIR="$REMOTE_VOL_DIR/_data"
    else
      REMOTE_DATA_DIR="/var/lib/docker/volumes/homepage-config/_data"
    fi
  fi

  # T-168: Backup fechado mandatorio antes de sobrescribir volumen en vivo
  BACKUP_TIMESTAMP=$(date +%Y%m%d%H%M%S)
  echo "--> Creando backup previo fechado de $REMOTE_DATA_DIR en $REMOTE_HOST..."
  ssh "$REMOTE_HOST" "sudo bash -c 'if [ -d \"$REMOTE_DATA_DIR\" ]; then cp -a \"$REMOTE_DATA_DIR\" \"${REMOTE_DATA_DIR}.bak.${BACKUP_TIMESTAMP}\"; echo \"✅ Backup creado en: ${REMOTE_DATA_DIR}.bak.${BACKUP_TIMESTAMP}\"; fi'"

  # T-168: Eliminar integración Swarm residual (docker.yaml) para evitar 403 / ECONNREFUSED
  echo "--> Eliminando integración Swarm (docker.yaml) en $REMOTE_HOST..."
  ssh "$REMOTE_HOST" "sudo rm -f '$REMOTE_DATA_DIR/docker.yaml'"

  ssh "$REMOTE_HOST" "sudo mkdir -p '$REMOTE_DATA_DIR' && mkdir -p /tmp/homepage-config"
  scp -r "$OUT_DIR"/* "$REMOTE_HOST:/tmp/homepage-config/"
  ssh "$REMOTE_HOST" "rm -f /tmp/homepage-config/docker.yaml && sudo cp -r /tmp/homepage-config/* '$REMOTE_DATA_DIR/' && sudo rm -f '$REMOTE_DATA_DIR/docker.yaml' && rm -rf /tmp/homepage-config"
  echo "✅ Sincronización remota completada en $REMOTE_DATA_DIR."

  echo "--> Reiniciando contenedor de Homepage para aplicar la nueva configuración..."
  ssh "$REMOTE_HOST" "HP_ID=\$(docker ps -q --filter 'name=homepage' | head -n 1); if [ -n \"\$HP_ID\" ]; then docker restart \"\$HP_ID\" >/dev/null; echo \"✅ Contenedor Homepage (\$HP_ID) reiniciado exitosamente.\"; fi"
fi

if [[ -n "$TEMP_OUT_DIR" && -d "$TEMP_OUT_DIR" ]]; then
  rm -rf "$TEMP_OUT_DIR"
fi
