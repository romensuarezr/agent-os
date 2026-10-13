#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/generate-secrets-catalog.sh — Agent OS
# Genera el catálogo de secretos de un repositorio: el CONTRATO de qué claves necesita
# ese proyecto, de dónde vienen y si siguen vivas. Nunca contiene valores.
#
# El catálogo se VERSIONA en git a propósito: un PR muestra "esta clave pasó a
# scope-shared" o "esta está revocada", que es visibilidad que un .env no da.
#
# Garantías:
#   - NUNCA escribe ni imprime valores de secretos, ni siquiera parciales.
#   - Es un artefacto GENERADO: se regenera, no se edita a mano.
#   - Degrada sin red: si la bóveda no responde, genera la parte local y lo marca.
#   - 0 tokens de inferencia.
#
# Uso:
#   bash scripts/agent/generate-secrets-catalog.sh [--path <repo>] [--check] [--json]
# ==============================================================================
set -euo pipefail

SCRIPT_SRC="${BASH_SOURCE[0]}"
case "$SCRIPT_SRC" in /*) ;; *) SCRIPT_SRC="$PWD/$SCRIPT_SRC" ;; esac
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SRC")" && pwd)"
source "$SCRIPT_DIR/lib/cli-help.sh"

for cmd in python3; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "❌ Error: dependencia requerida '$cmd' no encontrada." >&2
        exit 1
    }
done

TARGET_DIR="."
CHECK_MODE=false
JSON_OUTPUT=false

for arg in "$@"; do
    if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
        show_help "generate-secrets-catalog.sh" \
            "bash scripts/agent/generate-secrets-catalog.sh [--path <repo>] [--check] [--json]" \
            "Genera el catálogo de secretos de un repositorio: qué claves necesita, de qué carpeta de la bóveda vienen y si están revocadas. Es un artefacto generado que se versiona en git; nunca incluye valores." \
            "--path <repo>   Repositorio a analizar (defecto: directorio actual)" \
            "--check         No escribe: devuelve 1 si el catálogo está desfasado. Para pre-flight y CI." \
            "--json          Emite el catálogo en JSON en lugar de escribir el fichero" \
            "-h, --help      Muestra este mensaje de ayuda" \
            "ejemplo: bash scripts/agent/generate-secrets-catalog.sh --path . --check" \
            "ejemplo: bash scripts/agent/generate-secrets-catalog.sh --path /ruta/al/satelite"
    fi
done

while [[ $# -gt 0 ]]; do
    case "$1" in
        --path) TARGET_DIR="$2"; shift 2 ;;
        --check) CHECK_MODE=true; shift ;;
        --json) JSON_OUTPUT=true; shift ;;
        *) echo "❌ Argumento desconocido: $1" >&2; exit 64 ;;
    esac
done

[ -d "$TARGET_DIR" ] || { echo "❌ Error: no existe el directorio: $TARGET_DIR" >&2; exit 1; }
TARGET_ABS="$(cd "$TARGET_DIR" && pwd -P)"
OUT_FILE="$TARGET_ABS/.agents/config/secrets-catalog.yaml"

# El stack lo resuelve el detector del core: el core es agnóstico y no debe
# hardcodear extensiones. Si no está disponible, se usa un conjunto mínimo.
CAT_STACK="unknown"
if [ -f "$SCRIPT_DIR/lib/detect-stack.sh" ]; then
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/lib/detect-stack.sh" || true
    if command -v detect_stack >/dev/null 2>&1; then
        detect_stack "$TARGET_ABS" >/dev/null 2>&1 || true
        CAT_STACK="${AGENT_OS_STACK:-unknown}"
    fi
fi

export CAT_TARGET="$TARGET_ABS" CAT_CHECK="$CHECK_MODE" CAT_JSON="$JSON_OUTPUT" CAT_STACK="$CAT_STACK"
export CAT_API="${INFISICAL_API_URL:-}" CAT_PID="${INFISICAL_PROJECT_ID:-}"
export CAT_CID="${INFISICAL_CLIENT_ID:-}" CAT_CSECRET="${INFISICAL_CLIENT_SECRET:-}"

python3 - <<'PYEOF'
import json, os, re, subprocess, sys, datetime, collections, urllib.request, urllib.parse

target = os.environ["CAT_TARGET"]
check_mode = os.environ["CAT_CHECK"] == "true"
as_json = os.environ["CAT_JSON"] == "true"
api, pid = os.environ["CAT_API"], os.environ["CAT_PID"]
cid, csecret = os.environ["CAT_CID"], os.environ["CAT_CSECRET"]
out_file = os.path.join(target, ".agents/config", "secrets-catalog.yaml")

# ---------------------------------------------------------------- referencias
# Solo NOMBRES de clave. Los valores se descartan al leer la linea.
ENV_FILES, COMPOSE_FILES = [], []
for root, dirs, files in os.walk(target):
    dirs[:] = [d for d in dirs if d not in {".git", "node_modules", ".venv", "venv", "__pycache__", "dist", "build"}]
    for f in files:
        p = os.path.join(root, f)
        rel = os.path.relpath(p, target)
        if f == ".env.example" or f == ".env.sample" or f == ".env.template":
            ENV_FILES.append(rel)
        elif f == ".env" or (f.startswith(".env.") and f not in (".env.example",)):
            ENV_FILES.append(rel)
        elif re.match(r"(docker-)?compose(\.\w+)?\.ya?ml$", f):
            COMPOSE_FILES.append(rel)

declared = set()
for rel in ENV_FILES:
    try:
        txt = open(os.path.join(target, rel), errors="ignore").read()
    except Exception:
        continue
    for line in txt.splitlines():
        s = line.strip()
        if not s or s.startswith("#") or "=" not in s:
            continue
        k, _, v = s.partition("=")
        k = k.strip()
        if not re.fullmatch(r"[A-Z][A-Z0-9_]{1,}", k):
            continue
        if not v.strip() or v.strip() in ('""', "''") or v.strip().startswith("changeme"):
            continue          # marcador de plantilla: lo declara, no lo consume
        declared.add(k)

compose_keys = set()
for rel in COMPOSE_FILES:
    try:
        txt = open(os.path.join(target, rel), errors="ignore").read()
    except Exception:
        continue
    for k in re.findall(r"^\s{2,6}([A-Z][A-Z0-9_]{1,})\s*:", txt, re.M):
        compose_keys.add(k)

# ------------------------------------------------- referencias en el codigo
# Segundo origen de descubrimiento: una variable usada en el codigo que no esta
# en ningun .env es un contrato incompleto. En un clon nuevo, eso rompe.
STACK = os.environ.get("CAT_STACK", "unknown")
CODE_EXTS = {
    "python": {".py"},
    "typescript": {".ts", ".tsx", ".mts"},
    "javascript": {".js", ".jsx", ".mjs", ".cjs"},
    "bun": {".ts", ".tsx", ".js", ".jsx"},
    "go": {".go"},
    "rust": {".rs"},
    "java": {".java"},
    "php": {".php"},
    "ruby": {".rb"},
    "dotnet": {".cs"},
}.get(STACK, {".py", ".js", ".jsx", ".ts", ".tsx", ".mjs", ".go", ".rs", ".rb", ".php", ".java", ".cs"})

PATTERNS = [
    (r"process\.env\.([A-Z][A-Z0-9_]{1,})", "process.env"),
    (r"os\.environ\.get\([\"']?([A-Z][A-Z0-9_]{1,})", "os.environ.get"),
    (r"os\.environ\[[\"']?([A-Z][A-Z0-9_]{1,})", "os.environ"),
    (r"os\.getenv\([\"']?([A-Z][A-Z0-9_]{1,})", "os.getenv"),
    (r"Deno\.env\.get\([\"']?([A-Z][A-Z0-9_]{1,})", "Deno.env"),
    (r"import\.meta\.env\.([A-Z][A-Z0-9_]{1,})", "import.meta.env"),
]
# Ruido known de runtime que no son contrato del proyecto.
NOISE = re.compile(r"^(NODE_|NPM_|YARN_|PNPM_|BUN_|PATH$|HOME$|USER$|SHELL$|TERM$|PWD$|LANG$|LC_|TZ$|CI$|DEBUG$|TEST$|TEMP$|TMP$)")

code_refs = {}
scanned = 0
if STACK != "static":
    for root, dirs, files in os.walk(target):
        dirs[:] = [d for d in dirs if d not in {".git", "node_modules", ".venv", "venv", "__pycache__", "dist", "build", ".next"}]
        for f in files:
            if os.path.splitext(f)[1] not in CODE_EXTS:
                continue
            try:
                txt = open(os.path.join(root, f), errors="ignore").read()
            except Exception:
                continue
            scanned += 1
            for pat, origin in PATTERNS:
                for k in re.findall(pat, txt):
                    if NOISE.match(k):
                        continue
                    code_refs.setdefault(k, set()).add(origin)

# ------------------------------------------------------- boveda
def http_json(path, **params):
    url = f"{api}{path}?" + urllib.parse.urlencode(
        {"workspaceId": pid, "environment": "dev", **params})
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {vault_token}"})
    with urllib.request.urlopen(req, timeout=12) as r:
        return json.load(r)

vault_token = ""
vault_ok = False
vault_error = ""
try:
    if not (api and pid and cid and csecret):
        vault_error = "credenciales de Infisical ausentes"
    else:
        out = subprocess.run(
            ["infisical", "login", "--method=universal-auth",
             "--client-id", cid, "--client-secret", csecret],
            capture_output=True, text=True, timeout=45).stdout
        m = re.search(r"eyJ[\w-]+\.[\w-]+\.[\w-]+", out)
        if not m:
            vault_error = "no se pudo autenticar"
        else:
            vault_token = m.group(0)
            # El subproceso `infisical export` necesita el token por entorno.
            os.environ["INFISICAL_TOKEN"] = vault_token
            http_json("/v1/folders")
            vault_ok = True
except Exception as e:
    vault_error = str(e)[:80]

folders, index = {}, collections.defaultdict(dict)
if vault_ok:
    try:
        meta = {f.get("name", ""): f for f in http_json("/v1/folders").get("folders", [])}
        for name in sorted(meta):
            fdesc = (meta[name].get("description") or "").strip()
            out = subprocess.run(
                ["infisical", "export", "--path", f"/{name}", "--env", "dev",
                 "--projectId", pid, "--domain", api, "--format", "json", "--silent"],
                capture_output=True, text=True, timeout=45).stdout
            try:
                items = json.loads(out)
            except Exception:
                items = []
            tags_map = {}
            for it in (items if isinstance(items, list) else []):
                k = it.get("key")
                if not k:
                    continue
                slugs = [(t.get("slug") if isinstance(t, dict) else t) for t in (it.get("tags") or [])]
                tags_map[k] = slugs
                index[k][name] = slugs
            folders[name] = {"description": fdesc, "tags": tags_map}
    except Exception as e:
        vault_ok = False
        vault_error = str(e)[:80]

def tags_of(key):
    """Etiquetas de una clave en la carpeta canonica (shared si existe, si no la primera)."""
    per_folder = index.get(key, {})
    if not per_folder:
        return []
    order = (["shared"] if "shared" in per_folder else []) + \
            sorted(f for f in per_folder if f != "shared")
    for f in order:
        if per_folder[f]:
            return per_folder[f]
    return []

# ------------------------------------------------------------------ catalogo
# Heuristica, NO un veredicto: solo una pista para el agente. Se incluyen URL/URI
# porque las de base de datos y colas llevan credenciales embebidas
# (postgres://user:pass@host, mongodb://user:pass@host, redis://:pass@host).
SECRETISH = re.compile(r"(KEY|TOKEN|SECRET|PASSWORD|PASSWD|PRIVATE|DSN|CREDENTIAL|API|URL|URI)$")

needed = sorted(declared | compose_keys | set(code_refs))
entries = []
for key in needed:
    locations = sorted(index.get(key, {}))
    in_env = key in declared
    in_code = key in code_refs
    origins = []
    if in_env:
        origins.append("env")
    if key in compose_keys:
        origins.append("compose")
    if in_code:
        origins.append("code")

    # Contrato incompleto: el codigo la usa y no hay donde obtenerla.
    if in_code and not in_env and not locations:
        status = "FALTA-DECLARAR"
    elif not locations and not vault_ok:
        status = "sin-verificar"
    elif not locations:
        status = "NO-EN-BOVEDA"
    elif any(t == "unverified-consumer" for t in tags_of(key)):
        status = "sin-verificar-consumo"
    else:
        status = "ok"

    entry = {
        "key": key,
        "kind": "secreto" if SECRETISH.search(key) else "config",
        "discovered_from": origins,
        "status": status,
        "scope": "shared" if "shared" in locations else ("project" if locations else "unknown"),
        "locations": locations,
        "tags": tags_of(key),
        "code_refs": sorted(code_refs.get(key, [])),
        "required_by": sorted(
            {f for f in ENV_FILES if key in open(os.path.join(target, f), errors="ignore").read()} |
            {f for f in COMPOSE_FILES if key in compose_keys}),
    }
    entries.append(entry)

catalog = {
    "generated_at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "source": "infisical+local" if vault_ok else "local-only",
    "complete": vault_ok,
    "target_repo": os.path.basename(target),
    "secrets_declared": len(entries),
    "detected_stack": STACK,
    "code_files_scanned": scanned,
    "needs_declaration": sorted(e["key"] for e in entries if e["status"] == "FALTA-DECLARAR"),
    "not_in_vault": sorted(e["key"] for e in entries if e["status"] == "NO-EN-BOVEDA"),
    "vault_note": vault_error,
    "secrets": entries,
}

def to_yaml(c):
    L = ["# Catálogo de secretos — ARTEFACTO GENERADO, no editar a mano.",
         "# Regenerar: bash scripts/agent/generate-secrets-catalog.sh --path .",
         "# Este fichero NO contiene valores. Solo metadatos.",
         f"generated_at: {c['generated_at']}",
         f"source: {c['source']}",
         f"complete: {str(c['complete']).lower()}",
         f"secrets_declared: {c['secrets_declared']}",
         f"detected_stack: {c['detected_stack']}",
         f"needs_declaration: {c['needs_declaration']}"]
    if c["vault_note"]:
        L.append(f"vault_note: \"{c['vault_note']}\"")
    L.append("secrets:")
    if not entries:
        L[-1] = "secrets: []"
        return "\n".join(L) + "\n"
    for e in entries:
        L.append(f"  - key: {e['key']}")
        L.append(f"    kind: {e['kind']}")
        L.append(f"    status: {e['status']}")
        L.append(f"    discovered_from: [{', '.join(e['discovered_from'])}]")
        L.append(f"    scope: {e['scope']}")
        L.append(f"    locations: [{', '.join(e['locations'])}]")
        L.append(f"    tags: [{', '.join(e['tags'])}]")
        L.append(f"    code_refs: [{', '.join(e['code_refs'])}]")
        L.append(f"    required_by: [{', '.join(e['required_by'])}]")
    return "\n".join(L) + "\n"

rendered = to_yaml(catalog)

if as_json:
    print(json.dumps(catalog, indent=2)); sys.exit(0)

if check_mode:
    existing = ""
    if os.path.exists(out_file):
        existing = open(out_file).read()
    # generated_at cambia siempre: se compara ignorándolo
    def norm(t):
        return "\n".join(l for l in t.splitlines() if not l.startswith("generated_at:"))
    if norm(existing) != norm(rendered):
        print(f"⚠️  Catálogo desfasado o inexistente: {os.path.relpath(out_file, target)}")
        print("    Regenera con: bash scripts/agent/generate-secrets-catalog.sh --path .")
        sys.exit(1)
    print(f"✅ Catálogo al día: {os.path.relpath(out_file, target)}")
    sys.exit(0)

os.makedirs(os.path.dirname(out_file), exist_ok=True)
open(out_file, "w").write(rendered)
print(f"✅ Catálogo generado: {os.path.relpath(out_file, target)}")
print(f"   {catalog['secrets_declared']} claves | stack: {STACK} | {scanned} ficheros de código leídos | fuente: {catalog['source']}")
if catalog["needs_declaration"]:
    print(f"   ⚠️  {len(catalog['needs_declaration'])} referenciadas en código y ausentes de .env y de la bóveda:")
    print("      " + ", ".join(catalog["needs_declaration"][:12]))
if not vault_ok:
    print(f"   ℹ️  Sin bóveda ({catalog['vault_note']}): generado solo con referencias locales.")
PYEOF