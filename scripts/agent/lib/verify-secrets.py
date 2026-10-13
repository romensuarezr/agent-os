#!/usr/bin/env python3
"""
scripts/agent/lib/verify-secrets.py — Motor determinista de descubrimiento,
parseo, deduplicación y verificación liveness de secretos para Agent OS.
"""

import os
import sys
import re
import json
import argparse
import subprocess
import collections
import hashlib
import urllib.parse
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import urllib.request
import urllib.error

IGNORE_DIRS = {
    '.git', 'node_modules', '.next', 'venv', '.venv', 'dist', 'build',
    'target', '.cache', '__pycache__', '.pytest_cache', '.turbo',
    '.angular', 'coverage', '.antigravity', '.gemini', '.orca', '.orca-remote'
}

IGNORE_FILE_EXTENSIONS = (
    '.example', '.sample', '.template', '.backup', '.bak', '.orig', '.md', '.txt'
)

PLACEHOLDER_VALUES = {
    'your_api_key', 'your-api-key', 'your_api_key_here', 'your-api-key-here',
    'xxx', 'xxxx', 'xxxxx', 'change_me', 'changeme', 'todo', 'test',
    '123456', 'placeholder', 'dummy', 'none', 'null', 'undefined', 'your_token'
}

def is_env_file(filename: str) -> bool:
    if any(filename.endswith(ext) for ext in IGNORE_FILE_EXTENSIONS):
        return False
    if filename.startswith('.env') or filename.endswith('.env'):
        return True
    return False

def parse_dotenv_file(filepath: Path) -> dict:
    """Parsea un archivo dotenv extrayendo pares clave-valor seguros."""
    secrets = {}
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                # Soporte para 'export KEY=VAL'
                if line.startswith('export '):
                    line = line[7:].strip()
                if '=' not in line:
                    continue
                
                key, val = line.split('=', 1)
                key = key.strip()
                val = val.strip()
                
                # Quitar comillas envolventes si las tiene
                if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
                    val = val[1:-1]
                
                # Limpiar comentarios inline en valores no entrecomillados
                if '#' in val:
                    # Si no estaba entrecomillado, ignorar lo posterior a #
                    parts = val.split('#', 1)
                    val = parts[0].strip()

                if key:
                    secrets[key] = val
    except Exception as e:
        sys.stderr.write(f"Error leyendo {filepath}: {e}\n")
    return secrets

def is_placeholder(key: str, val: str) -> bool:
    if not val or len(val.strip()) < 3:
        return True
    val_clean = val.strip().lower()
    if val_clean in PLACEHOLDER_VALUES:
        return True
    if val.startswith('<') and val.endswith('>'):
        return True
    if val.startswith('YOUR_') or val.startswith('your_'):
        return True
    return False

def check_single_liveness(key: str, val: str) -> str:
    """Verifica la vigencia real de un token contra su API pública con timeout de 2.5s."""
    headers = {"User-Agent": "agent-os-secret-verifier/1.0"}
    timeout = 2.5
    
    url = None
    req_headers = dict(headers)
    method = "GET"
    
    # OpenAI
    if val.startswith("sk-proj-") or val.startswith("sk-") or key in {"OPENAI_API_KEY"}:
        url = "https://api.openai.com/v1/models"
        req_headers["Authorization"] = f"Bearer {val}"
    
    # GitHub
    elif val.startswith("ghp_") or val.startswith("github_pat_") or key in {"GITHUB_TOKEN", "GH_TOKEN", "GITHUB_PAT"}:
        url = "https://api.github.com/user"
        req_headers["Authorization"] = f"Bearer {val}"
    
    # Anthropic
    elif val.startswith("sk-ant-") or key in {"ANTHROPIC_API_KEY"}:
        url = "https://api.anthropic.com/v1/models"
        req_headers["x-api-key"] = val
        req_headers["anthropic-version"] = "2023-06-01"
        
    # Groq
    elif val.startswith("gsk_") or key in {"GROQ_API_KEY"}:
        url = "https://api.groq.com/openai/v1/models"
        req_headers["Authorization"] = f"Bearer {val}"
        
    # Google AI Studio / Gemini
    elif key in {"GEMINI_API_KEY", "GOOGLE_API_KEY"} or val.startswith("AIzaSy"):
        url = f"https://generativelanguage.googleapis.com/v1beta/models?key={val}"
        
    # Perplexity
    elif val.startswith("pplx-") or key in {"PERPLEXITY_API_KEY"}:
        url = "https://api.perplexity.ai/models"
        req_headers["Authorization"] = f"Bearer {val}"

    # Cloudflare (API Tokens). /user/tokens/verify responde success:false si el token
    # fue revocado, expirado o nunca existio. Distingue "invalido" de "sin red".
    elif val.startswith("eyJ") is False and key in {
            "CLOUDFLARE_API_TOKEN", "CLOUDFLARE_DNS_API_TOKEN",
            "CF_API_TOKEN", "CLOUDFLARE_ZONE_TOKEN"} or (
            "CLOUDFLARE" in key and "TOKEN" in key):
        url = "https://api.cloudflare.com/client/v4/user/tokens/verify"
        req_headers["Authorization"] = f"Bearer {val}"

    # Telegram (bot tokens). getMe es definitivo: 200 con el bot o 401 Unauthorized.
    elif key in {"TELEGRAM_BOT_TOKEN", "TELEGRAM_TOKEN"} or (
            "TELEGRAM" in key and "TOKEN" in key):
        url = f"https://api.telegram.org/bot{val}/getMe"

    # Sentry DSN: https<llave>@<org>.ingest.sentry.io/<project>
    # Verificarlo exigiria enviar un evento de prueba al proyecto, es decir ESCRIBIR en un
    # sistema de produccion. No se hace de forma automatica: se marca como no comprobable.
    elif val.startswith("https://") and "@" in val and "sentry.io" in val:
        return "UNTESTED_NO_WRITE"
    elif "SENTRY_DSN" in key:
        return "UNTESTED_NO_WRITE"

    if not url:
        return "UNTESTED_LOCAL"

    try:
        req = urllib.request.Request(url, headers=req_headers, method=method)
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            if resp.status in (200, 201):
                return "VALID"
            return "VALID"
    except urllib.error.HTTPError as e:
        # Cloudflare responde 400 con success:false para un token invalido
        if url and "cloudflare.com" in url and e.code == 400:
            try:
                body = json.loads(e.read().decode() or "{}")
                if body.get("success") is False:
                    return "REVOKED"
            except Exception:
                return "REVOKED"
        if url and "telegram.org" in url and e.code in (401, 404):
            return "REVOKED"
        if url and "sentry.io" in url:
            return "UNTESTED_NO_WRITE"
        if e.code in (401, 403):
            return "REVOKED"
        if e.code == 429: # Rate limit -> Token válido pero saturado
            return "VALID_RATELIMITED"
        if e.code == 400 and url and "googleapis.com" in url:
            # Gemini responde 400 "API key not valid" para una clave invalida
            return "REVOKED"
        return "UNTESTED_LOCAL"
    except Exception:
        # Timeout o fallo de red -> No asumir revocado, catalogar como local
        return "UNTESTED_LOCAL"

def scan_projects(root_dir: str, skip_liveness: bool = False):
    root_path = Path(root_dir).resolve()
    if not root_path.exists():
        sys.stderr.write(f"Error: El directorio {root_dir} no existe.\n")
        sys.exit(1)

    discovered_files = []
    
    # Recorrido recursivo seguro
    for dirpath, dirnames, filenames in os.walk(root_path):
        # Excluir directorios ignorados in-place
        dirnames[:] = [d for d in dirnames if d not in IGNORE_DIRS and not d.startswith('.')]
        for f in filenames:
            if is_env_file(f):
                discovered_files.append(Path(dirpath) / f)

    # Agrupar secretos por proyecto
    projects = {}
    total_parsed_raw = 0
    discarded_placeholders = 0

    for fpath in discovered_files:
        rel = fpath.relative_to(root_path)
        # Identificar nombre de proyecto
        parts = rel.parts
        if len(parts) > 1:
            project_name = parts[0]
        else:
            project_name = root_path.name

        if project_name not in projects:
            projects[project_name] = {
                "project_name": project_name,
                "secret_path": f"/{project_name}",
                "files": [],
                "secrets": {}
            }

        projects[project_name]["files"].append(str(fpath))
        file_secrets = parse_dotenv_file(fpath)
        total_parsed_raw += len(file_secrets)

        for k, v in file_secrets.items():
            if is_placeholder(k, v):
                discarded_placeholders += 1
                continue
            
            # Prioridad de sobrescritura dentro del mismo proyecto:
            # .env.local tiene más prioridad que .env
            current = projects[project_name]["secrets"].get(k)
            if not current or ".local" in fpath.name:
                projects[project_name]["secrets"][k] = {
                    "key": k,
                    "value": v,
                    "source_file": str(fpath),
                    "status": "PENDING"
                }

    # Recolectar claves únicas para testeo de liveness concurrente
    unique_tokens = {}
    for p_name, p_data in projects.items():
        for k, s_data in p_data["secrets"].items():
            val = s_data["value"]
            if val not in unique_tokens:
                unique_tokens[val] = (k, val)

    liveness_results = {}
    if not skip_liveness:
        with ThreadPoolExecutor(max_workers=10) as executor:
            future_to_val = {
                executor.submit(check_single_liveness, k, val): val
                for val, (k, val) in unique_tokens.items()
            }
            for future in as_completed(future_to_val):
                val = future_to_val[future]
                try:
                    status = future.result()
                except Exception:
                    status = "UNTESTED_LOCAL"
                liveness_results[val] = status
    else:
        for val in unique_tokens:
            liveness_results[val] = "UNTESTED_LOCAL"

    # Asignar estados finales a cada secreto de cada proyecto
    summary = {
        "root": str(root_path),
        "total_env_files": len(discovered_files),
        "total_projects": len(projects),
        "total_raw_secrets": total_parsed_raw,
        "placeholders_discarded": discarded_placeholders,
        "valid_secrets_count": 0,
        "revoked_secrets_count": 0,
        "untested_local_count": 0,
        "projects": {}
    }

    for p_name, p_data in projects.items():
        proj_summary = {
            "project_name": p_name,
            "secret_path": p_data["secret_path"],
            "files": p_data["files"],
            "secrets": []
        }
        for k, s_data in p_data["secrets"].items():
            val = s_data["value"]
            status = liveness_results.get(val, "UNTESTED_LOCAL")
            s_data["status"] = status
            
            if status in ("VALID", "VALID_RATELIMITED"):
                summary["valid_secrets_count"] += 1
            elif status == "REVOKED":
                summary["revoked_secrets_count"] += 1
            else:
                summary["untested_local_count"] += 1
                
            proj_summary["secrets"].append(s_data)

        summary["projects"][p_name] = proj_summary

    return summary

def scan_infisical(api: str, pid: str, env_name: str, token: str,
                   skip_liveness: bool = False) -> dict:
    """Audita la boveda de Infisical reutilizando el verificador de vigencia existente.

    Los valores se traen a memoria para comprobarlos y se descartan acto seguido:
    ni el informe JSON ni la salida legible los contienen jamas.
    """
    result = {
        "source": "infisical",
        "environment": env_name,
        "folders_scanned": 0,
        "total_entries": 0,
        "valid_secrets_count": 0,
        "revoked_secrets_count": 0,
        "untested_count": 0,
        "revoked": [],
        "duplicated_same_value": [],
        "shadowing_conflicts": [],
        "legitimate_per_project": [],
        "errors": [],
    }

    def _get(path, **params):
        url = f"{api}{path}?" + urllib.parse.urlencode(
            {"workspaceId": pid, "environment": env_name, **params})
        req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
        with urllib.request.urlopen(req, timeout=15) as r:
            return json.load(r)

    try:
        folders = sorted(f.get("name", "") for f in _get("/v1/folders").get("folders", []))
    except Exception as e:
        result["errors"].append(f"No se pudieron listar carpetas: {e}")
        return result

    result["folders_scanned"] = len(folders)
    seen = collections.defaultdict(list)  # clave -> [(carpeta, valor)]
    scopes = collections.defaultdict(set)  # clave -> {"project"|"shared", ...}

    for folder in folders:
        try:
            out = subprocess.run(
                ["infisical", "export", "--path", f"/{folder}", "--env", env_name,
                 "--projectId", pid, "--domain", api, "--format", "json", "--silent"],
                capture_output=True, text=True, timeout=45).stdout
            data = json.loads(out)
            items = data if isinstance(data, list) else data.get("secrets", [])
        except Exception as e:
            result["errors"].append(f"/{folder}: {e}")
            continue

        for item in items:
            key = item.get("key") or item.get("secretKey", "") if isinstance(item, dict) else item
            val = "" if isinstance(item, str) else (item.get("value") or item.get("secretValue") or "")
            tg = (item.get("tags") or []) if isinstance(item, dict) else []
            for t in tg:
                if str(t).startswith("scope="):
                    scopes[key].add(str(t).split("=", 1)[1])
            if not key:
                continue
            result["total_entries"] += 1
            seen[key].append((folder, val))

            if skip_liveness or not val:
                result["untested_count"] += 1
                continue
            status = check_single_liveness(key, val)
            if status == "VALID":
                result["valid_secrets_count"] += 1
            elif status == "REVOKED":
                result["revoked_secrets_count"] += 1
                result["revoked"].append({"key": key, "folder": folder})
            else:
                result["untested_count"] += 1

    # Evidencia de uso: hash de cada valor frente a los .env reales de la flota.
    # IMPORTANTE: mismo nombre con valores distintos NO es por si solo un conflicto.
    # DATABASE_URL o TELEGRAM_CHAT_ID son configuracion POR PROYECTO que comparten
    # nombre a proposito; forzar un unico valor romperia servicios en marcha.
    usage = collections.defaultdict(set)
    for root in ("$HOME/orca/workspaces", "$LOCAL_PROJECTS"):
        rp = Path(root)
        if not rp.exists():
            continue
        for dotenv in rp.rglob(".env*"):
            try:
                txt = dotenv.read_text(errors="ignore")
            except Exception:
                continue
            for line in txt.splitlines():
                line = line.strip()
                if "=" in line and not line.startswith("#"):
                    k, _, val = line.partition("=")
                    usage[k.strip()].add(
                        hashlib.sha256(val.strip().strip("\"'").encode()).hexdigest()[:8])

    for key, places in seen.items():
        if len(places) < 2:
            continue
        values = {v for _, v in places}
        folders = sorted(f for f, _ in places)
        if len(values) == 1:
            result["duplicated_same_value"].append({"key": key, "folders": folders})
            continue
        hashed = {f: hashlib.sha256(v.encode()).hexdigest()[:8] for f, v in places}
        in_use = [f for f, h in hashed.items() if h in usage.get(key, set())]
        without = [f for f, h in hashed.items() if h not in usage.get(key, set())]
        if "project" in scopes.get(key, set()):
            verdict = "INTENCIONAL_SCOPE_PROJECT"
        elif len(in_use) == len(hashed):
            verdict = "LEGITIMO_CONFIG_POR_PROYECTO"
        elif not in_use:
            verdict = "SIN_EVIDENCIA_DE_USO"
        else:
            verdict = "REVISAR"
        entry = {"key": key, "folders": folders, "distinct_values": len(values),
                 "verdict": verdict, "in_use": in_use, "without_usage_evidence": without}
        if verdict in ("LEGITIMO_CONFIG_POR_PROYECTO", "INTENCIONAL_SCOPE_PROJECT"):
            result["legitimate_per_project"].append(entry)
        else:
            result["shadowing_conflicts"].append(entry)

    return result


def write_mark(path: str, results: dict, skip_liveness: bool = False) -> None:
    """Escribe la marca de salud. Sin valores, solo nombres y contadores."""
    from datetime import datetime, timezone
    checked = results["valid_secrets_count"] + results["revoked_secrets_count"]
    total = results["total_entries"]
    coverage = f"{checked}/{total}" if total else "0/0"
    pct = round(100 * checked / total) if total else 0
    lines = [
        "# secrets-health.md — Salud de los secretos",
        "",
        "> Marca generada. NO editar a mano. NO contiene valores.",
        "> NO se comprueba en cada sesión a propósito: solo se lee cuando un agente",
        "> trabaja con secretos. Verifica antigüedad antes de fiarte de estos datos.",
        "",
        "## Estado",
        "",
        f"- **Auditado**: {datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}",
        f"- **Entorno**: {results['environment']}",
        f"- **Carpetas**: {results['folders_scanned']} | **Entradas**: {total}",
        f"- **Revocadas**: {results['revoked_secrets_count']}",
        f"- **Conflictos de shadowing**: {len(results['shadowing_conflicts'])}",
        f"- **Duplicados con mismo valor**: {len(results['duplicated_same_value'])}",
        f"- **Config por proyecto (no es conflicto)**: {len(results['legitimate_per_project'])}",
        f"- **Cobertura de verificacion**: {coverage} ({pct}%)"
        + (" — omitida por --skip-liveness" if skip_liveness else ""),
        "",
    ]
    if results["revoked_secrets_count"]:
        lines += ["## Claves revocadas (rotar)", ""]
        lines += [f"- `{r['key']}` en `/{r['folder']}`" for r in results["revoked"]]
        lines += [""]
    if results["shadowing_conflicts"]:
        lines += ["## Shadowing a revisar", ""]
        lines += [f"- `{c['key']}` ({c['distinct_values']} valores en {len(c['folders'])} carpetas), "
                  f"sin evidencia de uso: {', '.join('/' + f for f in c['without_usage_evidence'])}"
                  for c in results["shadowing_conflicts"]]
        lines += [""]
    lines += ["## Regenerar", "",
              "```bash",
              "python3 scripts/agent/lib/verify-secrets.py --source=infisical --mark",
              "```", ""]
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text("\n".join(lines))
    os.chmod(path, 0o644)


def main():
    parser = argparse.ArgumentParser(description="Auditor y verificador de secretos para Agent OS")
    parser.add_argument("root", nargs="?", default=".", help="Directorio raíz para escanear")
    parser.add_argument("--json", action="store_true", help="Salida en formato JSON compacto")
    parser.add_argument("--skip-liveness", action="store_true", help="Omitir validación de APIs externas")
    parser.add_argument("--source", choices=["local", "infisical"], default="local",
                        help="Origen a auditar: archivos .env locales (defecto) o la bóveda de Infisical")
    parser.add_argument("--infisical-env", default=os.environ.get("INFISICAL_ENVIRONMENT", "dev"),
                        help="Entorno de Infisical a auditar")
    parser.add_argument("--mark", metavar="RUTA", nargs="?",
                        const=".agents/context/secrets-health.md",
                        help="Escribe el digest de salud en esa marca (por defecto .agents/context/secrets-health.md)")
    args = parser.parse_args()

    if args.source == "infisical":
        api = os.environ.get("INFISICAL_API_URL", "")
        pid = os.environ.get("INFISICAL_PROJECT_ID", "")
        token = os.environ.get("INFISICAL_TOKEN", "")
        missing = [n for n, v in (("INFISICAL_API_URL", api), ("INFISICAL_PROJECT_ID", pid),
                                  ("INFISICAL_TOKEN", token)) if not v]
        if missing:
            print(f"❌ Faltan variables para auditar Infisical: {', '.join(missing)}", file=sys.stderr)
            print("   Genera el token con 'infisical login --method=universal-auth ...' "
                  "y expórtalo como INFISICAL_TOKEN.", file=sys.stderr)
            sys.exit(1)
        results = scan_infisical(api, pid, args.infisical_env, token,
                                 skip_liveness=args.skip_liveness)
        if args.mark:
            write_mark(args.mark, results, skip_liveness=args.skip_liveness)
            if not args.json:
                print(f"   Marca escrita en {args.mark}")
        if args.json:
            print(json.dumps(results, indent=2))
            return
        print("\n" + "=" * 65)
        print("  🔐 AGENT OS: AUDITORÍA DE LA BÓVEDA DE INFISICAL")
        print("=" * 65)
        print(f"🌐 Entorno: {results['environment']}")
        print(f"📂 Carpetas: {results['folders_scanned']} | entradas: {results['total_entries']}")
        print("-" * 65)
        print(f"✅ Válidas verificadas: {results['valid_secrets_count']}")
        print(f"❌ Revocadas / caducadas: {results['revoked_secrets_count']}")
        print(f"➖ Sin comprobable: {results['untested_count']}")
        print(f"🔁 Duplicadas con idéntico valor: {len(results['duplicated_same_value'])}")
        print(f"✅ No es conflicto (config por proyecto, incl. etiqueta scope=project): "
              f"{len(results['legitimate_per_project'])}")
        print(f"⚠️  Conflictos reales a revisar: {len(results['shadowing_conflicts'])}")
        for c in results["shadowing_conflicts"]:
            print(f"    {c['key']}  ({c['distinct_values']} valores en {len(c['folders'])} carpetas)"
                  f"  sin evidencia de uso: {', '.join('/' + f for f in c['without_usage_evidence'])}")
        if results["revoked"]:
            print("-" * 65)
            print("   Claves revocadas que hay que rotar:")
            for r in results["revoked"]:
                print(f"    ❌ {r['key']}  (carpeta /{r['folder']})")
        if results["errors"]:
            print("-" * 65)
            for e in results["errors"]:
                print(f"    ⚠️  {e}")
        print("=" * 65)
        return

    results = scan_projects(args.root, skip_liveness=args.skip_liveness)

    if args.json:
        print(json.dumps(results, indent=2))
        return

    # Salida formateada legible en consola
    print("\n" + "=" * 65)
    print("  🔐 AGENT OS: REPORTE DE AUDITORÍA Y VIGENCIA DE SECRETOS")
    print("=" * 65)
    print(f"📁 Directorio analizado: {results['root']}")
    print(f"📄 Archivos .env detectados: {results['total_env_files']}")
    print(f"📦 Proyectos descubiertos: {results['total_projects']}")
    print(f"🧹 Placeholders y dummies ignorados: {results['placeholders_discarded']}")
    print("-" * 65)
    print(f"✅ Claves activas verificadas en APIs: {results['valid_secrets_count']}")
    print(f"❌ Claves revocadas / caducadas (omitir): {results['revoked_secrets_count']}")
    print(f"🏠 Secretos locales / BD / opacos: {results['untested_local_count']}")
    print("=" * 65 + "\n")

    for p_name, p_data in results["projects"].items():
        sec_list = p_data["secrets"]
        if not sec_list:
            continue
        print(f"📁 Proyecto: \033[1;34m{p_name}\033[0m (Ruta Infisical: \033[1;32m{p_data['secret_path']}\033[0m) [{len(sec_list)} secretos]")
        for s in sec_list:
            st = s["status"]
            if st in ("VALID", "VALID_RATELIMITED"):
                st_badge = "\033[0;32m[VÁLIDA ✅]\033[0m"
            elif st == "REVOKED":
                st_badge = "\033[0;31m[REVOCADA ❌]\033[0m"
            else:
                st_badge = "\033[0;33m[LOCAL 🏠]\033[0m"
            
            masked_val = s['value'][:4] + "..." + s['value'][-3:] if len(s['value']) > 8 else "***"
            print(f"   ↳ {s['key']} = {masked_val} {st_badge}")
        print()

if __name__ == "__main__":
    main()
