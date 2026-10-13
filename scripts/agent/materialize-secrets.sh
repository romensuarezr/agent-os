#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/materialize-secrets.sh — Agent OS
# Materializa los secretos de la bóveda al .env de un repositorio, usando el catálogo
# como contrato. Es el inverso de import-secrets.sh (que sube .env -> bóveda).
#
# Por qué existe: un proyecto no puede depender de conexión a la bóveda para arrancar.
# El .env es una COPIA para trabajar offline, nunca la fuente de verdad.
#
# Garantías:
#   - MODO DETECCIÓN POR DEFECTO (--dry-run). Nada se escribe sin --apply.
#   - NUNCA imprime valores, ni en modo --apply.
#   - NUNCA sobreescribe un valor existente salvo --force.
#   - RECHAZA escribir en un fichero que git versionaria (evita filtrar credenciales).
#   - Escribe con permisos 600.
#   - 0 tokens de inferencia.
# ==============================================================================
set -euo pipefail

SCRIPT_SRC="${BASH_SOURCE[0]}"
case "$SCRIPT_SRC" in /*) ;; *) SCRIPT_SRC="$PWD/$SCRIPT_SRC" ;; esac
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SRC")" && pwd)"
source "$SCRIPT_DIR/lib/cli-help.sh"

for cmd in python3; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "❌ Error: dependencia requerida '$cmd' no encontrada." >&2; exit 1;
    }
done

TARGET_DIR="."
APPLY_MODE=false
FORCE=false
JSON_OUTPUT=false
ENV_NAME="${INFISICAL_ENVIRONMENT:-dev}"

for arg in "$@"; do
    if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
        show_help "materialize-secrets.sh" \
            "bash scripts/agent/materialize-secrets.sh [--path <repo>] [--apply] [--force] [--env <entorno>] [--json]" \
            "Vuelca en el .env de un repositorio los valores que la bóveda tiene para las claves que ese repo declara. Modo detección por defecto: no escribe nada salvo --apply." \
            "--path <repo>   Repositorio destino (defecto: directorio actual)" \
            "--apply         Escribe realmente. Sin este flag solo informa (defecto)" \
            "--force         Sobrescribe valores que ya existen en el .env (por defecto NO los toca)" \
            "--env <entorno> Entorno de la bóveda (defecto: \$INFISICAL_ENVIRONMENT o dev)" \
            "--json          Emite el resultado estructurado" \
            "-h, --help      Muestra este mensaje de ayuda" \
            "ejemplo: bash scripts/agent/materialize-secrets.sh --path ." \
            "ejemplo: bash scripts/agent/materialize-secrets.sh --path . --apply"
    fi
done

while [[ $# -gt 0 ]]; do
    case "$1" in
        --path) TARGET_DIR="$2"; shift 2 ;;
        --apply) APPLY_MODE=true; shift ;;
        --force) FORCE=true; shift ;;
        --env) ENV_NAME="$2"; shift 2 ;;
        --json) JSON_OUTPUT=true; shift ;;
        *) echo "❌ Argumento desconocido: $1" >&2; exit 64 ;;
    esac
done

[ -d "$TARGET_DIR" ] || { echo "❌ Error: no existe el directorio: $TARGET_DIR" >&2; exit 1; }

export MAT_TARGET="$(cd "$TARGET_DIR" && pwd -P)" MAT_APPLY="$APPLY_MODE" MAT_FORCE="$FORCE"
export MAT_JSON="$JSON_OUTPUT" MAT_ENV="$ENV_NAME"
export MAT_API="${INFISICAL_API_URL:-}" MAT_PID="${INFISICAL_PROJECT_ID:-}"
export MAT_CID="${INFISICAL_CLIENT_ID:-}" MAT_CSECRET="${INFISICAL_CLIENT_SECRET:-}"

python3 - <<'PYEOF'
import json, os, re, subprocess, sys, hashlib, urllib.request, urllib.parse

target = os.environ["MAT_TARGET"]
apply_mode = os.environ["MAT_APPLY"] == "true"
force = os.environ["MAT_FORCE"] == "true"
as_json = os.environ["MAT_JSON"] == "true"
envn = os.environ["MAT_ENV"]
api, pid = os.environ["MAT_API"], os.environ["MAT_PID"]
cid, csecret = os.environ["MAT_CID"], os.environ["MAT_CSECRET"]

R, G, Y, B, NC = "\033[0;31m", "\033[0;32m", "\033[0;33m", "\033[0;34m", "\033[0m"
catalog_path = os.path.join(target, ".agents/config/secrets-catalog.yaml")

def die(msg, code=1):
    if as_json:
        print(json.dumps({"status": "ERROR", "error": msg}, indent=2))
    else:
        print(f"{R}❌ {msg}{NC}", file=sys.stderr)
    sys.exit(code)

# ------------------------------------------------------------------- catalogo
if not os.path.exists(catalog_path):
    die(f"No existe el catálogo: {os.path.relpath(catalog_path, target)}.\n"
        f"   Genera primero: bash scripts/agent/generate-secrets-catalog.sh --path .")
try:
    import yaml
    catalog = yaml.safe_load(open(catalog_path)) or {}
except ImportError:
    die("Falta PyYAML para leer el catálogo.")
except Exception as e:
    die(f"Catálogo ilegible: {e}")
entries = [s for s in (catalog.get("secrets") or []) if s.get("key")]
if not entries:
    die("El catálogo no declara ninguna clave.")

# ------------------------------------------------------- ¿git lo versionaría?
def would_be_tracked(rel_path):
    try:
        r = subprocess.run(["git", "check-ignore", "-q", rel_path],
                           cwd=target, capture_output=True)
        if r.returncode == 0:                     # ignorado -> seguro
            return False
        if r.returncode == 1:                     # no ignorado
            return True
        return None                               # no es repo git
    except Exception:
        return None

# -------------------------------------------------------------- boveda
token = ""
try:
    if not (api and pid and cid and csecret):
        die("Faltan credenciales de Infisical (API_URL, PROJECT_ID, CLIENT_ID, CLIENT_SECRET).")
    out = subprocess.run(["infisical", "login", "--method=universal-auth",
                          "--client-id", cid, "--client-secret", csecret],
                         capture_output=True, text=True, timeout=45).stdout
    m = re.search(r"eyJ[\w-]+\.[\w-]+\.[\w-]+", out)
    if not m:
        die("No se pudo autenticar contra Infisical.")
    token = m.group(0)
except Exception as e:
    die(f"Fallo de autenticación: {str(e)[:120]}")

vault = {}          # key -> (folder, value)
for folder in sorted({f for e in entries for f in (e.get("locations") or [])}):
    try:
        out = subprocess.run(["infisical", "export", "--path", f"/{folder}", "--env", envn,
                              "--projectId", pid, "--domain", api, "--format", "json", "--silent"],
                             capture_output=True, text=True, timeout=45,
                             env={**os.environ, "INFISICAL_TOKEN": token}).stdout
        for it in (json.loads(out) if out.strip().startswith("[") else []):
            k, v = it.get("key"), it.get("value")
            if k and v and k not in vault:
                vault[k] = (folder, v)
    except Exception:
        pass

# ------------------------------------------------------------- plan
plan, skipped = [], []
for e in entries:
    key = e["key"]
    # Las plantillas (.env.example) NUNCA son destino: están versionadas y contienen
    # marcadores, no credenciales. Solo los .env reales.
    targets = [f for f in (e.get("required_by") or [])
               if re.search(r"(^|/)\.env$", f)]
    if not targets:
        skipped.append({"key": key, "reason": "sin fichero .env destino en el catálogo"})
        continue
    if key not in vault:
        skipped.append({"key": key, "reason": "no está en la bóveda"})
        continue
    folder, value = vault[key]
    for rel in dict.fromkeys(targets):
        abs_t = os.path.join(target, rel)
        exists = os.path.exists(abs_t)
        current = None
        if exists:
            try:
                for line in open(abs_t, errors="ignore"):
                    s = line.strip()
                    if s.startswith(key + "="):
                        current = s.split("=", 1)[1].strip()
                        break
            except Exception:
                pass
        if current is not None and not force:
            same = current.strip('"\'') == value.strip('"\'')
            plan.append({"key": key, "file": rel, "action": "sin-cambios",
                         "same_value": same, "source_folder": folder})
        elif current is not None:
            plan.append({"key": key, "file": rel, "action": "sobreescribir",
                         "same_value": False, "source_folder": folder})
        else:
            plan.append({"key": key, "file": rel, "action": "anadir",
                         "same_value": None, "source_folder": folder})

# ------------------------------------------------------------- seguridad git
unsafe = sorted({p["file"] for p in plan
                 if p["action"] != "sin-cambios" and would_be_tracked(p["file"]) is True})

result = {
    "mode": "apply" if apply_mode else "dry-run",
    "target": os.path.basename(target),
    "environment": envn,
    "planned": plan,
    "skipped": skipped,
    "unsafe_targets": unsafe,
    "added": 0, "overwritten": 0, "unchanged": 0, "written": 0,
}

if unsafe:
    result["status"] = "ABORTADO_FICHERO_VERSIONABLE"
    if as_json:
        print(json.dumps(result, indent=2))
    else:
        print(f"{R}❌ ABORTADO: estos ficheros NO están ignorados por git y acabarían en un commit::{NC}")
        for f in unsafe:
            print(f"   {f}")
        print(f"\n   Añade el patrón a .gitignore antes de materializar.")
    sys.exit(1)

if not apply_mode:
    result["status"] = "DRY_RUN"
    if as_json:
        print(json.dumps(result, indent=2)); sys.exit(0)
    print(f"{B}=== MATERIALIZACIÓN DE SECRETOS (simulación) ==={NC}")
    for p in plan:
        icon = {"anadir": "+", "sobreescribir": "~", "sin-cambios": "="}[p["action"]]
        extra = ""
        if p["action"] == "sin-cambios":
            extra = " (mismo valor)" if p["same_value"] else f" {Y}(valor local DISTINTO){NC}"
        print(f"  {icon} {p['key']:<28} -> {p['file']}  [{p['source_folder']}]{extra}")
    for s in skipped:
        print(f"  · {s['key']:<28} omitida: {s['reason']}")
    adds = sum(1 for p in plan if p["action"] == "anadir")
    print(f"\n  {len(plan)} acciones | {adds} a añadir | simulación: nada escrito")
    print(f"  Aplica con: bash scripts/agent/materialize-secrets.sh --path {os.path.basename(target)} --apply")
    sys.exit(0)

# --------------------------------------------------------------- escritura
written_files = {}
for p in plan:
    if p["action"] == "sin-cambios":
        result["unchanged"] += 1; continue
    abs_t = os.path.join(target, p["file"])
    key, folder, _ = p["key"], p["source_folder"], None
    _, value = vault[key]
    if not os.path.exists(abs_t):
        os.makedirs(os.path.dirname(abs_t) or target, exist_ok=True)
        open(abs_t, "a").close()
    lines = open(abs_t, errors="ignore").read().splitlines()
    replaced = False
    for i, line in enumerate(lines):
        s = line.strip()
        if s.startswith(key + "="):
            lines[i] = f"{key}={value}"; replaced = True
    if not replaced:
        while lines and lines[-1].strip() == "":
            lines.pop()
        lines += ["", f"{key}={value}"]
    open(abs_t, "w").write("\n".join(lines) + "\n")
    os.chmod(abs_t, 0o600)
    written_files[p["file"]] = True
    result["added" if p["action"] == "anadir" else "overwritten"] += 1

result["status"] = "APLICADO"
result["written"] = sum(1 for p in plan if p["action"] != "sin-cambios")
result["files_written"] = sorted(written_files)
if as_json:
    print(json.dumps(result, indent=2)); sys.exit(0)
print(f"{G}✅ Materialización aplicada{NC}")
print(f"   {result['added']} añadidas · {result['overwritten']} sobrescritas · {result['unchanged']} sin cambios")
for f in result["files_written"]:
    print(f"   → {f} (permisos 600)")
PYEOF