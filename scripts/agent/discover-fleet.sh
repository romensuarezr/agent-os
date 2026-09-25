#!/usr/bin/env bash
# ==============================================================================
# Agent OS — Deterministic Fleet & Local Environment Discovery
# ==============================================================================
# Usage:
#   bash scripts/agent/discover-fleet.sh [OPTIONS]
#
# Options:
#   --apply     Write/merge discovered tools into config/fleet.yaml
#   --docs      Generate human-readable docs in docs/architecture/tools/local-environment.local.md
#   --json      Output discovery digest in JSON format instead of YAML
#   --help, -h  Show this help message
#
# Principles:
#   - 0 inference token cost (deterministic execution).
#   - Non-destructive by default (outputs digest to stdout without touching files).
#   - Safe merge on --apply (preserves existing nodes, mcpServers, and custom keys).
#   - Dynamic profile discovery (auto-detects agy, agy2, agy3, etc. without hardcoding).
# ==============================================================================

set -eo pipefail

APPLY=false
GEN_DOCS=false
OUTPUT_JSON=false

for arg in "$@"; do
    case "$arg" in
        --apply)
            APPLY=true
            ;;
        --docs)
            GEN_DOCS=true
            ;;
        --json)
            OUTPUT_JSON=true
            ;;
        --help|-h)
            echo "Uso: bash scripts/agent/discover-fleet.sh [--apply] [--docs] [--json]"
            echo ""
            echo "Opciones:"
            echo "  --apply    Actualiza config/fleet.yaml preservando nodos y servidores MCP"
            echo "  --docs     Genera docs/architecture/tools/local-environment.local.md"
            echo "  --json     Emite la salida en formato JSON en vez de YAML"
            echo "  --help     Muestra este mensaje de ayuda"
            exit 0
            ;;
        *)
            echo "Opción desconocida: $arg" >&2
            echo "Usa --help para ver las opciones disponibles." >&2
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Ejecutar motor de descubrimiento determinista en Python
python3 - "$REPO_ROOT" "$APPLY" "$GEN_DOCS" "$OUTPUT_JSON" << 'EOF'
import sys, os, json, glob, re, subprocess, platform

repo_root = sys.argv[1]
apply_flag = sys.argv[2] == "true"
docs_flag = sys.argv[3] == "true"
json_output = sys.argv[4] == "true"

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

def run_cmd(cmd, timeout=3):
    try:
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        if res.returncode == 0:
            return res.stdout.strip()
    except Exception:
        pass
    return None

# 1. Detección de Sistema Operativo y Distribución
os_name = platform.system().lower()
arch = platform.machine()
distro = "unknown"
if os.path.exists("/etc/os-release"):
    try:
        with open("/etc/os-release", "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("PRETTY_NAME="):
                    distro = line.split("=", 1)[1].strip().strip('"')
                    break
    except Exception:
        pass

# 2. Detección de Gestores de Paquetes
pkg_managers = []
for pm in ["apt", "pacman", "dnf", "brew", "npm", "pnpm", "yarn", "pip", "pip3", "cargo", "snap", "flatpak"]:
    if run_cmd(f"which {pm}"):
        pkg_managers.append(pm)

# 3. Construcción de PATH expandido (incluye binarios locales y perfiles de usuario)
custom_paths = ["~/.local/bin", "~/bin", "~/.opencode/bin", "/opt/Orca/resources/bin", "~/.bun/bin"]
user_homes = [os.path.expanduser("~")]
parent_home = os.path.dirname(os.path.expanduser("~"))
if os.path.isdir(parent_home) and parent_home not in ["/", "/home"]:
    user_homes.append(parent_home)
real_user = os.environ.get("USER")
if real_user and os.path.isdir(f"/home/{real_user}") and f"/home/{real_user}" not in user_homes:
    user_homes.append(f"/home/{real_user}")

# Añadir carpetas bin de posibles perfiles ~/.antigravity*
for uh in user_homes:
    for agy_dir in glob.glob(f"{uh}/.antigravity*"):
        bin_dir = os.path.join(agy_dir, "bin")
        if os.path.isdir(bin_dir) and bin_dir not in custom_paths:
            custom_paths.append(bin_dir)

expanded_path = os.environ.get("PATH", "")
for cp in custom_paths:
    exp = os.path.expanduser(cp)
    if os.path.isdir(exp) and exp not in expanded_path:
        expanded_path += f":{exp}"

installed_clis = {}
antigravity_accounts = {}

# 4. Descubrimiento Dinámico de Cuentas y Wrappers Antigravity (agy, agy2, agy3...)
agy_binaries = set()
for p in expanded_path.split(":"):
    p_exp = os.path.expanduser(p)
    if os.path.isdir(p_exp):
        for f in glob.glob(os.path.join(p_exp, "agy*")):
            if os.path.isfile(f) and os.access(f, os.X_OK):
                agy_binaries.add(os.path.basename(f))

for agy_name in sorted(agy_binaries):
    raw_path = run_cmd(f"PATH=\"{expanded_path}\" which {agy_name} 2>/dev/null")
    if not raw_path:
        continue
    
    # Versión
    raw_ver = run_cmd(f"PATH=\"{expanded_path}\" {agy_name} --version 2>/dev/null")
    ver = "installed"
    if raw_ver:
        vmatch = re.search(r'([0-9]+\.[0-9]+(\.[0-9]+)?)', raw_ver)
        ver = vmatch.group(1) if vmatch else raw_ver.splitlines()[0][:30]

    # Analizar si es wrapper o script que apunta a un HOME o perfil alternativo
    profile_info = "default (~/.antigravity)"
    desc = "Antigravity CLI (cuenta principal)"
    try:
        real_target = os.path.realpath(raw_path)
        script_content = ""
        if os.path.isfile(raw_path):
            with open(raw_path, "r", errors="ignore") as sf:
                script_content += sf.read(600)
        if real_target != raw_path and os.path.isfile(real_target):
            with open(real_target, "r", errors="ignore") as sf:
                script_content += sf.read(600)
        
        home_match = re.search(r'HOME=([^\s"]+)', script_content)
        if home_match:
            custom_home = home_match.group(1)
            prof_name = os.path.basename(custom_home)
            profile_info = f"{prof_name} ({custom_home})"
            desc = f"Antigravity CLI (cuenta/perfil: {prof_name})"
        elif agy_name != "agy":
            desc = f"Antigravity CLI (perfil adicional {agy_name})"
            profile_info = agy_name
    except Exception:
        pass

    installed_clis[agy_name] = {
        "status": "available",
        "version": ver,
        "description": desc
    }
    antigravity_accounts[agy_name] = {
        "executable": raw_path,
        "version": ver,
        "profile": profile_info,
        "description": desc
    }

# 5. Detección de Otras Herramientas CLI Estándar y Runtimes
standard_clis = [
    {"name": "git", "cmd": "git", "ver_cmd": "git --version", "desc": "Distributed version control system"},
    {"name": "gh", "cmd": "gh", "ver_cmd": "gh --version", "desc": "GitHub CLI"},
    {"name": "docker", "cmd": "docker", "ver_cmd": "docker --version", "desc": "Container virtualization runtime"},
    {"name": "curl", "cmd": "curl", "ver_cmd": "curl --version", "desc": "Data transfer CLI"},
    {"name": "jq", "cmd": "jq", "ver_cmd": "jq --version", "desc": "Command-line JSON processor"},
    {"name": "tailscale", "cmd": "tailscale", "ver_cmd": "tailscale --version", "desc": "Mesh VPN client"},
    {"name": "opencode", "cmd": "opencode", "ver_cmd": "opencode --version", "desc": "Autonomous terminal AI coding agent"},
    {"name": "antigravity", "cmd": "antigravity", "ver_cmd": "antigravity --version", "desc": "Antigravity AI Agent IDE"},
    {"name": "orca-ide", "cmd": "orca-ide", "ver_cmd": "orca-ide --version", "desc": "Orca Desktop agent orchestrator"},
    {"name": "hermes", "cmd": "hermes", "ver_cmd": "hermes --version", "desc": "Hermes persistent agent CLI"},
    {"name": "uv", "cmd": "uv", "ver_cmd": "uv --version", "desc": "Fast Python package manager (Rust)"},
    {"name": "uvx", "cmd": "uvx", "ver_cmd": "uvx --version", "desc": "Ephemeral Python tool runner"},
    {"name": "gitingest", "cmd": "gitingest", "ver_cmd": "gitingest --version", "desc": "Repository content extractor for LLMs"},
    {"name": "scout.sh", "cmd": f"test -f {os.path.join(repo_root, 'scripts/agent/scout.sh')} && echo ok", "ver_cmd": None, "desc": "Deterministic OSS pre-code scout"},
    {"name": "infisical", "cmd": "infisical", "ver_cmd": "infisical --version", "desc": "Secrets management CLI"},
    {"name": "python3", "cmd": "python3", "ver_cmd": "python3 --version", "desc": "Python runtime"},
    {"name": "node", "cmd": "node", "ver_cmd": "node --version", "desc": "Node.js JavaScript runtime"},
    {"name": "bun", "cmd": "bun", "ver_cmd": "bun --version", "desc": "Bun JavaScript runtime"}
]

for item in standard_clis:
    name = item["name"]
    check = run_cmd(f"PATH=\"{expanded_path}\" which {item['cmd']} 2>/dev/null" if not item['cmd'].startswith("test") else item['cmd'])
    if check:
        ver = None
        if item.get("ver_cmd"):
            raw_ver = run_cmd(f"PATH=\"{expanded_path}\" {item['ver_cmd']} 2>/dev/null")
            if raw_ver:
                ver_match = re.search(r'([0-9]+\.[0-9]+(\.[0-9]+)?)', raw_ver)
                ver = ver_match.group(1) if ver_match else raw_ver.splitlines()[0][:30]
        installed_clis[name] = {
            "status": "available",
            "version": ver if ver else "installed",
            "description": item["desc"]
        }

# 6. Detección Inteligente de Navegadores y Herramientas Web AI
known_signatures = {}
known_yaml_path = os.path.join(repo_root, "config/known-web-tools.yaml")
if HAS_YAML and os.path.exists(known_yaml_path):
    try:
        with open(known_yaml_path, "r", encoding="utf-8") as f:
            ydata = yaml.safe_load(f)
            if ydata and "domains" in ydata:
                known_signatures = ydata["domains"]
    except Exception:
        pass

bookmark_files = []
for uh in user_homes:
    bookmark_files.extend(glob.glob(f"{uh}/.config/google-chrome/*/Bookmarks"))
    bookmark_files.extend(glob.glob(f"{uh}/.config/BraveSoftware/Brave-Browser/*/Bookmarks"))
    bookmark_files.extend(glob.glob(f"{uh}/.config/chromium/*/Bookmarks"))

ai_folder_regex = re.compile(r'\b(ias?|ai|llms?|prompts?|gpt|agentes?|devtools?|herramientas?)\b', re.IGNORECASE)
discovered_web_tools = {}

def scan_bookmark_tree(node, current_folder=""):
    if isinstance(node, dict):
        folder_name = node.get("name", "") if node.get("type") == "folder" else current_folder
        if node.get("type") == "url":
            url = node.get("url", "")
            title = node.get("name", "")
            domain_match = re.search(r'https?://([^/:]+)', url)
            if domain_match:
                domain = domain_match.group(1).lower()
                matched_meta = None
                for kd, meta in known_signatures.items():
                    if kd in domain:
                        matched_meta = meta
                        break
                is_ai_folder = bool(ai_folder_regex.search(folder_name))
                
                if matched_meta or is_ai_folder:
                    key = matched_meta.get("name", domain.replace(".", "_")) if matched_meta else domain.replace(".", "_")
                    if key not in discovered_web_tools:
                        discovered_web_tools[key] = {
                            "domain": domain,
                            "title": title[:60],
                            "category": matched_meta.get("category", "web_tool") if matched_meta else "heuristic_bookmark",
                            "provider": matched_meta.get("provider", "Custom/Web") if matched_meta else "Discovered",
                            "folder_context": folder_name if is_ai_folder else None
                        }
        for val in node.values():
            scan_bookmark_tree(val, folder_name)
    elif isinstance(node, list):
        for item in node:
            scan_bookmark_tree(item, current_folder)

for bf in bookmark_files:
    try:
        with open(bf, "r", encoding="utf-8", errors="ignore") as f:
            bdata = json.load(f)
            scan_bookmark_tree(bdata)
    except Exception:
        pass

# 7. Detección de Nodos Tailscale Activos
tailscale_peers = {}
if "tailscale" in installed_clis:
    ts_json = run_cmd("tailscale status --json 2>/dev/null")
    if ts_json:
        try:
            ts_data = json.loads(ts_json)
            peers = ts_data.get("Peer", {})
            for pid, peer in peers.items():
                pname = peer.get("HostName", "unknown")
                pips = peer.get("TailscaleIPs", [])
                pos = peer.get("OS", "unknown")
                online = peer.get("Online", False)
                tailscale_peers[pname] = {
                    "ip": pips[0] if pips else "unknown",
                    "os": pos,
                    "online": online
                }
        except Exception:
            pass

# 8. Carga de Configuración Existente de Flota y Enrutamiento (fleet.yaml)
fleet_file = os.path.join(repo_root, "config/fleet.yaml")
fleet_example = os.path.join(repo_root, "config/fleet.example.yaml")
target_fleet_path = fleet_file if os.path.exists(fleet_file) else fleet_example

configured_nodes = {}
configured_routing = {}
if os.path.exists(target_fleet_path) and HAS_YAML:
    try:
        with open(target_fleet_path, "r", encoding="utf-8") as f:
            existing_fleet = yaml.safe_load(f) or {}
            configured_nodes = existing_fleet.get("nodes", {})
            configured_routing = existing_fleet.get("routing", {})
    except Exception:
        pass

# 9. Estructurar Digest de Descubrimiento
discovery_data = {
    "version": "1.0",
    "discovery_timestamp": run_cmd("date -Iseconds") or "",
    "local_environment": {
        "os": os_name,
        "distro": distro,
        "arch": arch,
        "package_managers": pkg_managers,
        "installed_clis": installed_clis,
        "antigravity_accounts": antigravity_accounts
    },
    "configured_nodes": configured_nodes,
    "routing_policy": configured_routing,
    "discovered_web_tools_count": len(discovered_web_tools),
    "discovered_web_tools": discovered_web_tools,
    "tailscale_mesh": {
        "active": "tailscale" in installed_clis,
        "peers_found": len(tailscale_peers),
        "peers": tailscale_peers
    }
}

# 10. Modo Aplicar (--apply): Fusión segura en config/fleet.yaml
if apply_flag:
    target_data = {}
    if os.path.exists(fleet_file) and HAS_YAML:
        try:
            with open(fleet_file, "r", encoding="utf-8") as f:
                target_data = yaml.safe_load(f) or {}
        except Exception as e:
            print(f"⚠️ Error leyendo config/fleet.yaml existente: {e}", file=sys.stderr)
    elif os.path.exists(fleet_example) and HAS_YAML:
        try:
            with open(fleet_example, "r", encoding="utf-8") as f:
                target_data = yaml.safe_load(f) or {}
        except Exception:
            pass

    # Fusionar local_environment
    if "local_environment" not in target_data:
        target_data["local_environment"] = {}
    target_data["local_environment"]["os"] = os_name
    target_data["local_environment"]["distro"] = distro
    target_data["local_environment"]["package_managers"] = pkg_managers
    target_data["local_environment"]["antigravity_accounts"] = antigravity_accounts
    
    if "installed_clis" not in target_data["local_environment"]:
        target_data["local_environment"]["installed_clis"] = {}
    for k, v in installed_clis.items():
        target_data["local_environment"]["installed_clis"][k] = v

    # Añadir fallback de cuentas si existe agy2 y no está definido
    if "routing" in target_data and isinstance(target_data["routing"], dict):
        if "agy2" in antigravity_accounts and "fallback_agent_account" not in target_data["routing"]:
            target_data["routing"]["fallback_agent_account"] = "agy2"

    # Fusionar herramientas web descubiertas en cloud_and_web_ai
    if "cloud_and_web_ai" not in target_data:
        target_data["cloud_and_web_ai"] = {}
    for k, v in discovered_web_tools.items():
        if k not in target_data["cloud_and_web_ai"]:
            target_data["cloud_and_web_ai"][k] = {
                "provider": v["provider"],
                "category": v["category"],
                "domain": v["domain"],
                "source": "browser_discovery"
            }

    # Guardar de forma segura sin sobreescribir nodes ni mcpServers
    if HAS_YAML:
        try:
            with open(fleet_file, "w", encoding="utf-8") as f:
                yaml.dump(target_data, f, sort_keys=False, allow_unicode=True, default_flow_style=False)
            print(f"✅ config/fleet.yaml actualizado con éxito (CLIs: {len(installed_clis)}, Cuentas agy: {len(antigravity_accounts)}, Web tools: {len(discovered_web_tools)}).")
        except Exception as e:
            print(f"❌ Error al escribir config/fleet.yaml: {e}", file=sys.stderr)

# 11. Modo Documentación (--docs): Generar vista humana unificada
if docs_flag:
    docs_path = os.path.join(repo_root, "docs/architecture/tools/local-environment.local.md")
    os.makedirs(os.path.dirname(docs_path), exist_ok=True)
    md_lines = [
        "# 💻 Estado Real de la Flota y Entorno Local (Auto-descubierto)",
        "",
        f"> **Fecha**: {discovery_data['discovery_timestamp']}  ",
        f"> **Sistema Operativo**: {distro} ({os_name} {arch})  ",
        f"> **Gestores de paquetes**: {', '.join(pkg_managers)}  ",
        "",
        "---",
        "",
        "## 1. Herramientas CLI y Agentes Detectados en PATH",
        "",
        "| Herramienta | Versión | Estado | Descripción |",
        "| :--- | :--- | :---: | :--- |"
    ]
    for name, info in sorted(installed_clis.items()):
        md_lines.append(f"| **`{name}`** | `{info['version']}` | ✅ Disponible | {info['description']} |")

    # Sección 2: Cuentas y Perfiles de Antigravity
    if antigravity_accounts:
        md_lines.extend([
            "",
            "---",
            "",
            "## 2. Cuentas y Perfiles Antigravity Detectados (Multi-Account Failover)",
            "",
            "Permite conmutar perfiles de ejecución CLI para prevenir rate limits o agotamiento de cuota.",
            "",
            "| Comando CLI | Versión | Directorio / Perfil HOME | Rol Operativo |",
            "| :--- | :--- | :--- | :--- |"
        ])
        for agy_k, agy_v in sorted(antigravity_accounts.items()):
            role_hint = "Cuenta principal (Default)" if agy_k == "agy" else f"Cuenta de respaldo / failover ({agy_k})"
            md_lines.append(f"| **`{agy_k}`** | `{agy_v['version']}` | `{agy_v['profile']}` | {role_hint} |")

    # Sección 3: Gateways de Inferencia y Servicios Remotos Configurados
    if configured_nodes:
        md_lines.extend([
            "",
            "---",
            "",
            "## 3. Pasarelas de Inferencia y Servicios Remotos Configurados (Fleet)",
            "",
            "Servicios activos en la red privada de nodos (Tailscale / VPS).",
            "",
            "| Nodo | Servicio | Endpoint / URL | Coste / Token | Rol / Descripción |",
            "| :--- | :--- | :--- | :---: | :--- |"
        ])
        for node_name, node_info in configured_nodes.items():
            services = node_info.get("services", {})
            for sname, sdata in services.items():
                endpoint = sdata.get("endpoint") or sdata.get("url") or f"host: {node_info.get('host', 'n/a')}"
                cost = f"${sdata.get('cost_per_token'):.2f}" if "cost_per_token" in sdata else ("$0.00 (Local)" if sname == "ollama" else "-")
                desc = sdata.get("description", "-")
                if "models" in sdata:
                    desc += f" (Modelos: {', '.join(sdata['models'][:3])})"
                md_lines.append(f"| **`{node_name}`** | **`{sname}`** | `{endpoint}` | {cost} | {desc} |")

    # Sección 4: Política de Enrutamiento de Modelos
    if configured_routing:
        md_lines.extend([
            "",
            "---",
            "",
            "## 4. Políticas de Enrutamiento Activas (`routing`)",
            "",
            f"- **Prioridad Coste Cero**: `{'Activada (local/free first)' if configured_routing.get('local_zero_cost_first') else 'Desactivada'}`",
            f"- **Runtime Principal**: `{configured_routing.get('primary_agent_runtime', 'antigravity')}`",
            f"- **Cuenta de Respaldo Antigravity**: `{configured_routing.get('fallback_agent_account', 'agy2 si está disponible')}`",
            f"- **Runtime de Fallback**: `{configured_routing.get('fallback_agent_runtime', 'opencode')}`",
            f"- **Endpoint LLM Local por Defecto**: `{configured_routing.get('default_local_llm_endpoint', 'n/a')}` (`{configured_routing.get('default_local_model', 'n/a')}`)"
        ])

    # Sección 5: Herramientas Web AI y Consolas
    md_lines.extend([
        "",
        "---",
        "",
        "## 5. Herramientas Web AI y Consolas (Navegador)",
        "",
        "| Herramienta | Proveedor | Dominio | Categoría | Origen |",
        "| :--- | :--- | :--- | :--- | :--- |"
    ])
    for key, item in sorted(discovered_web_tools.items()):
        folder_ctx = f" (📁 {item['folder_context']})" if item.get('folder_context') else ""
        md_lines.append(f"| **{key}** | {item['provider']} | `{item['domain']}` | {item['category']} | Marcadores{folder_ctx} |")
    
    # Sección 6: Nodos Tailscale
    if tailscale_peers:
        md_lines.extend([
            "",
            "---",
            "",
            "## 6. Nodos Remotos en Red Mesh (Tailscale)",
            "",
            "| Hostname | IP | SO | Estado |",
            "| :--- | :--- | :--- | :---: |"
        ])
        for host, pinfo in tailscale_peers.items():
            status_ico = "🟢 Conectado" if pinfo["online"] else "⚪ Desconectado"
            md_lines.append(f"| **`{host}`** | `{pinfo['ip']}` | {pinfo['os']} | {status_ico} |")

    md_lines.append("")
    try:
        with open(docs_path, "w", encoding="utf-8") as f:
            f.write("\n".join(md_lines))
        print(f"📄 Documento humano generado: docs/architecture/tools/local-environment.local.md")
    except Exception as e:
        print(f"❌ Error al escribir docs: {e}", file=sys.stderr)

# 12. Emisión de Digest a stdout
if json_output:
    print(json.dumps(discovery_data, indent=2, ensure_ascii=False))
elif not apply_flag and not docs_flag:
    if HAS_YAML:
        print(yaml.dump(discovery_data, sort_keys=False, allow_unicode=True, default_flow_style=False))
    else:
        print(json.dumps(discovery_data, indent=2, ensure_ascii=False))
EOF
