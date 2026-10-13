#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/secret-locate.sh — Agent OS
# Localizador determinista de secretos en Infisical: responde "¿dónde vive esta clave?"
#
# Por qué existe: un agente que busca un secreto en la carpeta de su proyecto, no lo
# encuentra, y pregunta al usuario. Eso quema turnos y tokens. Este script responde en una
# llamada, solo con nombres, sin mostrar jamas un valor.
#
# Garantías:
#   - SOLO LECTURA. No crea, no modifica y no borra nada en la bóveda.
#   - NUNCA imprime valores de secretos, ni siquiera parcialmente.
#   - No persiste tokens: el token efímero vive solo en el entorno de este proceso.
#   - 0 tokens de inferencia: no llama a ningún LLM.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/cli-help.sh"

for cmd in curl infisical; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "❌ Error: dependencia requerida '$cmd' no encontrada." >&2
        echo "💡 Guía: instalala con 'npm i -g @infisical/cli' o en tu gestor de paquetes." >&2
        exit 1
    }
done

NAME=""
LIST_MODE=false
AUDIT_MODE=false
HYGIENE_MODE=false
JSON_OUTPUT=false
ENV_NAME="${INFISICAL_ENVIRONMENT:-dev}"
TIMEOUT=15

for arg in "$@"; do
    if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
        show_help "secret-locate.sh" \
            "bash scripts/agent/secret-locate.sh [--name <CLAVE>] [--list] [--audit] [--hygiene] [--env <entorno>] [--json]" \
            "Localiza secretos en la bóveda de Infisical sin revelar valores. Herramienta de solo lectura para agentes que no deben adivinar la ubicación de una clave." \
            "--name <CLAVE>    Nombre del secreto a localizar. Devuelve las carpetas donde existe, ordenadas por última modificación." \
            "--list            Digest de todas las carpetas con su número de claves, ordenadas por última modificación." \
            "--audit           Auditoría de la bóveda: duplicados, shadowing y carpetas casi clonadas." \
            "--hygiene         Claves sin descripción ni etiquetas, que un agente puede proponer completar." \
            "--env <entorno>   Entorno a consultar (defecto: \$INFISICAL_ENVIRONMENT o dev)" \
            "--json            Emite el resultado estructurado para agentes y orquestadores" \
            "-h, --help        Muestra este mensaje de ayuda" \
            "ejemplo: bash scripts/agent/secret-locate.sh --name CLOUDFLARE_API_TOKEN" \
            "ejemplo: bash scripts/agent/secret-locate.sh --hygiene --json"
    fi
done

while [[ $# -gt 0 ]]; do
    case "$1" in
        --name) NAME="$2"; shift 2 ;;
        --list) LIST_MODE=true; shift ;;
        --audit) AUDIT_MODE=true; shift ;;
        --hygiene) HYGIENE_MODE=true; shift ;;
        --env) ENV_NAME="$2"; shift 2 ;;
        --json) JSON_OUTPUT=true; shift ;;
        *) echo "❌ Argumento desconocido: $1" >&2; exit 64 ;;
    esac
done

if [ -z "$NAME" ] && [ "$LIST_MODE" != true ] && [ "$AUDIT_MODE" != true ] && [ "$HYGIENE_MODE" != true ]; then
    echo "❌ Error: indica --name <CLAVE>, --list, --audit o --hygiene." >&2
    echo "💡 Guia: bash scripts/agent/secret-locate.sh --list" >&2
    exit 64
fi

[ -n "${INFISICAL_API_URL:-}" ] || { echo "❌ Error: INFISICAL_API_URL no definida." >&2; exit 1; }
[ -n "${INFISICAL_PROJECT_ID:-}" ] || { echo "❌ Error: INFISICAL_PROJECT_ID no definida." >&2; exit 1; }

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; NC='\033[0m'

# Token efímero via Universal Auth (Machine Identity). Solo vive en este proceso.
mint_token() {
    if [ -n "${INFISICAL_TOKEN:-}" ]; then
        echo "$INFISICAL_TOKEN"; return 0
    fi
    if [ -z "${INFISICAL_CLIENT_ID:-}" ] || [ -z "${INFISICAL_CLIENT_SECRET:-}" ]; then
        echo "❌ Error: faltan INFISICAL_CLIENT_ID o INFISICAL_CLIENT_SECRET." >&2
        return 1
    fi
    # La CLI emite el JWT en su propia linea; el resto es decorado de la interfaz.
    infisical login --method=universal-auth \
        --client-id="$INFISICAL_CLIENT_ID" \
        --client-secret="$INFISICAL_CLIENT_SECRET" 2>/dev/null | grep -E '^eyJ' | head -1
}

export INFI_TOKEN="$(mint_token)"
[ -n "$INFI_TOKEN" ] || { echo "❌ Error: no se pudo autenticar contra Infisical." >&2; exit 1; }

export GW_API="$INFISICAL_API_URL" GW_PID="$INFISICAL_PROJECT_ID" GW_TOKEN="$INFI_TOKEN"
export GW_ENV="$ENV_NAME" GW_TIMEOUT="$TIMEOUT" GW_JSON="$JSON_OUTPUT"
export GW_NAME="$NAME" GW_LIST="$LIST_MODE" GW_AUDIT="$AUDIT_MODE" GW_HYGIENE="$HYGIENE_MODE"
# El token tambien debe llegar por entorno al subproceso `infisical secrets`.
export INFISICAL_TOKEN="$INFI_TOKEN"
python3 - <<'PYEOF'
import json, os, subprocess, sys, urllib.request, urllib.parse, collections

api   = os.environ["GW_API"]
pid   = os.environ["GW_PID"]
token = os.environ["GW_TOKEN"]
envn  = os.environ["GW_ENV"]
timeout = float(os.environ["GW_TIMEOUT"])
name  = os.environ["GW_NAME"]
do_list = os.environ["GW_LIST"] == "true"
do_audit = os.environ["GW_AUDIT"] == "true"
do_hygiene = os.environ["GW_HYGIENE"] == "true"
as_json = os.environ["GW_JSON"] == "true"

G, R, Y, NC = "\033[0;32m", "\033[0;31m", "\033[0;33m", "\033[0m"

def http_json(path, **params):
    url = f"{api}{path}?" + urllib.parse.urlencode(
        {"workspaceId": pid, "environment": envn, **params})
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.load(r)

def _parse_iso(txt):
    from datetime import datetime
    try:
        return datetime.fromisoformat(txt.replace("Z", "+00:00")).timestamp()
    except Exception:
        return 0.0

def _fmt(ts):
    from datetime import datetime, timezone
    return datetime.fromtimestamp(ts, tz=timezone.utc).strftime("%Y-%m-%d") if ts else "nunca"

def folder_meta():
    """Nombre -> metadata de carpeta. lastSecretModified ordena por antiguedad real."""
    try:
        data = http_json("/v1/folders")
    except Exception as e:
        print(f"❌ No se pudieron listar las carpetas: {e}", file=sys.stderr)
        sys.exit(1)
    return {f.get("name", ""): f for f in data.get("folders", [])}

def modified(meta):
    """Ultima modificacion de un secreto en la carpeta; 0 si nunca se toco."""
    return _parse_iso(meta.get("lastSecretModified") or meta.get("updatedAt") or "")

def keys_with_meta(folder):
    """(claves, etiquetas, descripcion). Los VALORES se descartan sin imprimirse."""
    tags, comments = {}, {}
    try:
        out = subprocess.run(
            ["infisical", "export", "--path", f"/{folder}", "--env", envn,
             "--projectId", pid, "--domain", api, "--format", "json", "--silent"],
            capture_output=True, text=True, timeout=timeout + 25).stdout
        for item in json.loads(out) if isinstance(json.loads(out), list) else []:
            k = item.get("key") or item.get("secretKey")
            if not k:
                continue
            tags[k] = item.get("tags") or []
            comments[k] = (item.get("comment") or "").strip()
    except Exception:
        return [], tags, comments
    return list(tags), tags, comments

def keys_in(folder):
    return keys_with_meta(folder)[0]

meta = folder_meta()
folders = sorted(meta)
inventory = {f: keys_in(f) for f in folders}
index = collections.defaultdict(list)
for folder, keys in inventory.items():
    for k in keys:
        index[k].append(folder)

by_recency = sorted(folders, key=lambda f: -modified(meta[f]))

result = {"environment": envn, "folders_scanned": len(folders)}

if do_list:
    result["inventory"] = {f: len(k) for f, k in inventory.items()}
    result["unique_keys"] = len(index)
    result["total_entries"] = sum(len(k) for k in inventory.values())
    result["folders_by_recency"] = [
        {"folder": f, "last_modified": _fmt(modified(meta[f])),
         "description": (meta[f].get("description") or "").strip()} for f in by_recency]
    if as_json:
        print(json.dumps(result, indent=2)); sys.exit(0)
    print(f"=== SECRETOS EN INFISICAL (entorno {envn}) - por ultima modificacion ===")
    for f in by_recency:
        d = (meta[f].get("description") or "").strip()
        print(f"  /{f:<24} {len(inventory[f]):>4} claves   {_fmt(modified(meta[f]))}"
              + (f"   | {d[:44]}" if d else "   | (sin descripcion)"))
    print(f"  {'TOTAL':<24} {result['unique_keys']:>4} claves unicas en {len(folders)} carpetas")
    sys.exit(0)

if do_hygiene:
    undocumented = []
    for f in by_recency:
        _, tg, cm = keys_with_meta(f)
        for k in inventory[f]:
            missing = ([("descripcion")] if not cm.get(k) else []) + ([("etiquetas")] if not tg.get(k) else [])
            if missing:
                undocumented.append({"key": k, "folder": f, "missing": missing,
                                     "last_modified": _fmt(modified(meta[f]))})
    result["undocumented"] = undocumented
    result["undocumented_count"] = len(undocumented)
    result["total_keys"] = sum(len(k) for k in inventory.values())
    if as_json:
        print(json.dumps(result, indent=2)); sys.exit(0)
    print(f"=== HIGIENE DE METADATOS (entorno {envn}) ===")
    print(f"Entradas: {result['total_keys']} | sin descripcion o etiquetas: {len(undocumented)}")
    print("\nClaves completables por un agente. La CLI soporta etiquetas:")
    print("  infisical secrets set <CLAVE>='<valor>' --path=/<carpeta> --tag scope-shared --tag env-dev")
    by_folder = collections.defaultdict(list)
    for u in undocumented:
        by_folder[u["folder"]].append(u["key"])
    print("\nPor carpeta (ordenadas por ultima modificacion):")
    for f in by_recency:
        if f in by_folder:
            print(f"  /{f} ({len(by_folder[f])}): {', '.join(sorted(by_folder[f])[:5])}"
                  + (" ..." if len(by_folder[f]) > 5 else ""))
    sys.exit(0)

if do_audit:
    dup = {k: sorted(v) for k, v in index.items() if len(v) > 1}
    shared_candidates = {k: sorted(v) for k, v in index.items() if len(v) >= 2}
    clones = []
    names = sorted(inventory)
    for i, a in enumerate(names):
        A = set(inventory[a])
        if not A:
            continue
        for b in names[i + 1:]:
            B = set(inventory[b])
            if not B:
                continue
            j = len(A & B) / len(A | B)
            if j >= 0.5:
                clones.append({"a": a, "b": b, "similarity": round(j, 2),
                               "shared": len(A & B), "only_in_a": sorted(A - B)})
    result["duplicated"] = dup
    result["duplicated_count"] = len(dup)
    result["shared_candidates"] = sorted(shared_candidates)
    result["near_clone_folders"] = clones
    if as_json:
        print(json.dumps(result, indent=2)); sys.exit(0)
    print(f"=== AUDITORIA DE BOVEDA (entorno {envn}) ===")
    print(f"Carpetas: {len(folders)} | claves unicas: {len(index)} | entradas: {result['total_entries'] if 'total_entries' in result else sum(len(k) for k in inventory.values())}")
    print(f"\nClaves duplicadas en 2+ carpetas: {len(dup)}")
    for k, v in sorted(dup.items()):
        print(f"  {k}  ->  {', '.join(v)}")
    print(f"\nCarpetas casi clonadas (similitud >= 50%): {len(clones)}")
    for c in clones:
        print(f"  {c['similarity']:.0%}  /{c['a']}  ~  /{c['b']}  ({c['shared']} comunes)")
        if c["only_in_a"]:
            print(f"        exclusivas de /{c['a']}: {', '.join(c['only_in_a'])}")
    sys.exit(0)

# Modo --name
hits = sorted(index.get(name, []))
result["name"] = name
result["found_in"] = hits
result["found_count"] = len(hits)
result["shadowing"] = len(hits) > 1
if as_json:
    print(json.dumps(result, indent=2))
    sys.exit(0 if hits else 6)

if name not in index:
    print(f"{R}❌ '{name}' no existe en ninguna carpeta (entorno {envn}).{NC}")
    print(f"   Carpetas disponibles: {', '.join('/' + f for f in folders)}")
    print("   Siguiente paso: 'secret-locate.sh --list' para ver el inventario completo.")
    sys.exit(6)

for f in hits:
    print(f"  {G}✔{NC} {name}  ->  /{f}  (entorno {envn})")
if len(hits) > 1:
    print(f"\n  {Y}⚠ La misma clave existe en {len(hits)} carpetas.{NC}")
    print("    Puede ser una clave transversal duplicada o una copia obsoleta.")
    print("    Decide con 'secret-locate.sh --audit' antes de darla por buena.")
print("")
print("  Para consumirla sin llevarla a disco:")
print(r"    infisical run --path=/<carpeta> -- bash -c 'echo $<CLAVE>'")
PYEOF