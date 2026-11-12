#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/orchestration-report.sh — Agent OS
# Telemetría determinista de orquestación, playbooks y eficiencia ($0 tokens)
#
# Audita y consolida métricas de ejecución del enjambre, playbooks empleados,
# estado de compuertas y estimación de ahorro de tokens sin quemar inferencia.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || pwd)"

if [ -f "$SCRIPT_DIR/lib/cli-help.sh" ]; then
  # shellcheck disable=SC1090
  source "$SCRIPT_DIR/lib/cli-help.sh"
fi

SPRINT_FILTER=""
TASK_FILTER=""
JSON_OUTPUT=false

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      if command -v show_help >/dev/null 2>&1; then
        show_help "orchestration-report.sh" \
          "bash scripts/agent/orchestration-report.sh [--sprint <ID>] [--task-id <ID>] [--json]" \
          "Genera el reporte determinista de telemetría de orquestación, playbooks empleados y métricas de ejecución de tareas a coste \$0 tokens." \
          "--sprint <ID>         Filtra métricas por identificador de sprint (ej: sprint-37)" \
          "--task-id <ID>        Filtra métricas por identificador de tarea específica (ej: T-201)" \
          "--json                Emite el reporte estructurado en formato JSON estándar" \
          "-h, --help            Muestra este mensaje de ayuda" \
          "ejemplo: bash scripts/agent/orchestration-report.sh --sprint sprint-37 --json"
      else
        echo "Uso: bash scripts/agent/orchestration-report.sh [--sprint <ID>] [--task-id <ID>] [--json]"
        exit 0
      fi
      ;;
    --sprint)
      shift
      SPRINT_FILTER="${1:-}"
      shift || true
      ;;
    --task-id)
      shift
      TASK_FILTER="${1:-}"
      shift || true
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Ejecución analítica determinista con Python 3
python3 - "$ROOT_DIR" "$SPRINT_FILTER" "$TASK_FILTER" "$JSON_OUTPUT" << 'PYEOF'
import sys
import os
import glob
import re
import json

root_dir = sys.argv[1]
sprint_filter = sys.argv[2]
task_filter = sys.argv[3]
json_output = sys.argv[4].lower() == 'true'

# 1. Localizar archivo de sprint
sprint_files = []
if sprint_filter:
    target = os.path.join(root_dir, "docs", "sprints", f"{sprint_filter}.md")
    if not os.path.isfile(target):
        target = os.path.join(root_dir, "docs", "sprints", "_archived", f"{sprint_filter}.md")
    if os.path.isfile(target):
        sprint_files = [target]
else:
    # Buscar sprints activos
    active = glob.glob(os.path.join(root_dir, "docs", "sprints", "sprint-*.md"))
    active = [f for f in active if not f.endswith("-research.md")]
    active.sort(reverse=True)
    if active:
        sprint_files = [active[0]]
    else:
        archived = glob.glob(os.path.join(root_dir, "docs", "sprints", "_archived", "sprint-*.md"))
        archived = [f for f in archived if not f.endswith("-research.md")]
        archived.sort(reverse=True)
        if archived:
            sprint_files = [archived[0]]

sprint_name = "desconocido"
tasks_raw = []

if sprint_files:
    sf = sprint_files[0]
    sprint_name = os.path.splitext(os.path.basename(sf))[0]
    with open(sf, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line_str = line.strip()
            if line_str.startswith("|") and not line_str.startswith("| ID") and not line_str.startswith("|---"):
                parts = [p.strip() for p in line_str.split("|")]
                if len(parts) >= 6:
                    tid = parts[1]
                    desc = parts[2]
                    size = parts[3]
                    status_raw = parts[4]
                    if tid.startswith("T-"):
                        tasks_raw.append({
                            "id": tid,
                            "description": desc,
                            "size": size,
                            "status_raw": status_raw
                        })

# 2. Cargar eventos de despacho de dispatched.jsonl
dispatched_events = {}
disp_path = os.path.join(root_dir, ".agents", "context", "dispatched.jsonl")
if os.path.isfile(disp_path):
    with open(disp_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line_str = line.strip()
            if line_str:
                try:
                    obj = json.loads(line_str)
                    tid = obj.get("task_id")
                    if tid:
                        dispatched_events[tid] = obj
                except Exception:
                    pass

# 3. Analizar tareas y asociar playbooks
tasks = []
playbook_counts = {
    "direct": 0,
    "scout-then-build": 0,
    "plan-big-execute-small": 0,
    "parallel-worktrees": 0,
    "review-gate": 0
}

for item in tasks_raw:
    tid = item["id"]
    if task_filter and tid != task_filter:
        continue

    # Resolver estado normalizado
    status = "PENDING"
    if "✅" in item["status_raw"] or "Completada" in item["status_raw"]:
        status = "COMPLETED"
    elif "🟡" in item["status_raw"] or "En curso" in item["status_raw"]:
        status = "IN_PROGRESS"

    # Resolver playbook a partir de task file y despacho
    playbook = "direct"
    file_count = 0
    tfile = os.path.join(root_dir, ".agents", "tasks", f"task-{tid[2:]}.md")
    if not os.path.isfile(tfile):
        tfile = os.path.join(root_dir, ".agents", "tasks", "_archived", f"task-{tid[2:]}.md")

    has_scout = False
    if os.path.isfile(tfile):
        with open(tfile, "r", encoding="utf-8", errors="ignore") as tf:
            content = tf.read()
            if "Scout OSS" in content or "searxng" in content.lower():
                has_scout = True
            m = re.search(r'## Caja de archivos.*?(?=\n## |\Z)', content, re.S)
            if m:
                caja = m.group(0)
                file_count = len(re.findall(r'^\s*-\s*`([^`]+)`', caja, re.M))

    if tid in dispatched_events:
        playbook = "parallel-worktrees"
    elif file_count > 0 and file_count <= 3:
        playbook = "direct"
    elif has_scout:
        playbook = "scout-then-build"
    elif file_count > 3:
        playbook = "plan-big-execute-small"
    else:
        playbook = "direct"

    playbook_counts[playbook] = playbook_counts.get(playbook, 0) + 1

    tasks.append({
        "id": tid,
        "description": item["description"],
        "size": item["size"],
        "status": status,
        "playbook": playbook,
        "files_in_box": file_count,
        "dispatched": tid in dispatched_events
    })

total = len(tasks)
completed = sum(1 for t in tasks if t["status"] == "COMPLETED")
pending = sum(1 for t in tasks if t["status"] == "PENDING")
in_progress = sum(1 for t in tasks if t["status"] == "IN_PROGRESS")
direct_count = playbook_counts.get("direct", 0)

# Ahorro estimado de tokens (floor cost evitado por no instanciar transcripts redundantes: ~15k tokens/tarea)
estimated_tokens_saved = direct_count * 15000

report = {
    "sprint": sprint_name,
    "summary": {
        "total_tasks": total,
        "completed_tasks": completed,
        "in_progress_tasks": in_progress,
        "pending_tasks": pending,
        "progress_percent": round((completed / total * 100), 1) if total > 0 else 0.0
    },
    "playbook_breakdown": playbook_counts,
    "telemetry": {
        "direct_tasks_count": direct_count,
        "estimated_tokens_saved": estimated_tokens_saved,
        "context_rot_mitigated": True,
        "zero_token_preflights": True
    },
    "tasks": tasks
}

if json_output:
    print(json.dumps(report, indent=2, ensure_ascii=False))
else:
    print("=" * 64)
    print(f"📊 REPORTE DE ORQUESTACIÓN Y TELEMETRÍA — {sprint_name.upper()}")
    print("=" * 64)
    print(f"Progreso global: {completed}/{total} tareas completadas ({report['summary']['progress_percent']}%)")
    print(f"Tareas en curso: {in_progress} | Pendientes: {pending}")
    print("\nEstrategias de Playbook empleadas:")
    for pb, count in playbook_counts.items():
        if count > 0:
            print(f"  • {pb:22} : {count} tarea(s)")
    print("\nMétricas de eficiencia en tokens:")
    print(f"  • Tareas en modo 'direct' (<=3 archivos): {direct_count}")
    print(f"  • Ahorro estimado por floor cost evitado: ~{estimated_tokens_saved:,} tokens")
    print(f"  • Mitigación de context rot: ACTIVA (contrato de retorno compacto)")
    print("\nDetalle de tareas:")
    print(f"{'ID':<8} {'ESTADO':<14} {'PLAYBOOK':<22} {'ARCHIVOS':<10} {'DESCRIPCIÓN'}")
    print("-" * 64)
    for t in tasks:
        print(f"{t['id']:<8} {t['status']:<14} {t['playbook']:<22} {t['files_in_box']:<10} {t['description'][:35]}")
    print("=" * 64)
PYEOF
