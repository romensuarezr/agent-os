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

    if not url:
        return "UNTESTED_LOCAL"

    try:
        req = urllib.request.Request(url, headers=req_headers, method=method)
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            if resp.status in (200, 201):
                return "VALID"
            return "VALID"
    except urllib.error.HTTPError as e:
        if e.code in (401, 403):
            return "REVOKED"
        if e.code == 429: # Rate limit -> Token válido pero saturado
            return "VALID_RATELIMITED"
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

def main():
    parser = argparse.ArgumentParser(description="Auditor y verificador de secretos para Agent OS")
    parser.add_argument("root", nargs="?", default=".", help="Directorio raíz para escanear")
    parser.add_argument("--json", action="store_true", help="Salida en formato JSON compacto")
    parser.add_argument("--skip-liveness", action="store_true", help="Omitir validación de APIs externas")
    args = parser.parse_args()

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
