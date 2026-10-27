#!/usr/bin/env bash
# ==============================================================================
# Agent OS — Orca ADE Multi-Agent Orchestration CLI (orca-orchestrate.sh)
# ==============================================================================
# Usage:
#   bash scripts/agent/orca-orchestrate.sh <command> [options]
#
# Commands:
#   status                  Check Orca ADE readiness, active runs and worktrees
#   report                   Read-only consolidated report of one Run (no mutations)
#   create-run              Create a new orchestration Run with an objective
#   list-runs               List all active and historical Runs
#   create-task             Create a task bound to a Run
#   list-tasks              List tasks for a specific Run
#   dispatch-worker         Dispatch a supervised worker in a dedicated worktree
#   create-gate             Create a human-in-the-loop Decision Gate (L3)
#   list-gates              List pending and resolved Decision Gates
#   check-events            Wait or poll for worker completion, questions, gates
#   batch                   Decompose and dispatch multiple parallel workers
#
# Principles:
#   - 0 inference token cost (deterministic CLI execution).
#   - $0 Inference Mandate: workers default to opencode / freellmapi / local.
#   - agy / agy2 reserved strictly for Coordinator or critical architecture.
# ==============================================================================

set -eo pipefail

# Pre-flight: python3 es dependencia real (status, batch y la sonda lo usan).
for cmd in python3; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ ERROR: Dependencia requerida no encontrada: $cmd" >&2
    exit 1
  fi
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Resolver ejecutable de Orca
ORCA_BIN=""
if command -v orca >/dev/null 2>&1; then
    ORCA_BIN="orca"
elif [ -x "$HOME/.config/orca/linux-orca-cli-shim/orca" ]; then
    ORCA_BIN="$HOME/.config/orca/linux-orca-cli-shim/orca"
elif [ -x "/opt/Orca/resources/bin/orca-ide" ]; then
    ORCA_BIN="/opt/Orca/resources/bin/orca-ide"
fi

# Contrato T-105 para los 10 subcomandos existentes + run-flow:
#
#   sonda_runtime()  clasifica SIN abortar (siempre return 0) en RUNTIME_STATE:
#                      RUNTIME_OK | CLI_AUSENTE | RUNTIME_SIN_RESPUESTA.
#                    La sonda va acotada a 15 s: un homónimo (`/usr/bin/orca`
#                    v46.1, ajeno al ADE) cuelga `status` para siempre (T-104).
#   check_orca()     mantiene fail-hard para los subcomandos directos, con
#                    mensaje accionable. SOLO run-flow usa el clasificador
#                    para el fail-soft; el resto aborta como siempre.
RUNTIME_STATE=""
sonda_runtime() {
    if [ -z "$ORCA_BIN" ]; then
        RUNTIME_STATE="CLI_AUSENTE"
        return 0
    fi
    if python3 -c "import subprocess,sys; sys.exit(subprocess.run(['$ORCA_BIN','status','--json'],capture_output=True,timeout=15).returncode)" >/dev/null 2>&1; then
        RUNTIME_STATE="RUNTIME_OK"
    else
        RUNTIME_STATE="RUNTIME_SIN_RESPUESTA"
    fi
    return 0
}

check_orca() {
    sonda_runtime
    case "$RUNTIME_STATE" in
        RUNTIME_OK)
            return 0
            ;;
        CLI_AUSENTE)
            echo "❌ Error: CLI de Orca no encontrado en PATH ni en rutas conocidas." >&2
            echo "   Instala la distribución de Orca, o usa 'run-flow' (falla al fallback Git-nativo de T-104 en vez de abortar)." >&2
            exit 1
            ;;
        RUNTIME_SIN_RESPUESTA)
            echo "⚠️ Advertencia: Orca no responde (CLI presente, runtime sordo)." >&2
            echo "Ejecuta 'orca open' para iniciar el runtime, o usa 'run-flow' para el fallback Git-nativo." >&2
            exit 1
            ;;
    esac
}

usage() {
    echo "=== 🐳 Agent OS — Orca ADE Multi-Agent Orchestrator ==="
    echo "Uso: bash scripts/agent/orca-orchestrate.sh <comando> [opciones]"
    echo ""
    echo "Comandos disponibles:"
    echo "  status                            Diagnóstico del runtime, runs activos y worktrees"
    echo "  report <run-id> [--json]          Informe consolidado read-only del lote (una pantalla)"
    echo "  create-run --objective <texto>    Crea un nuevo Run de orquestación"
    echo "  list-runs                         Lista todos los Runs registrados"
  echo "  create-task --run <id> --title <t> --spec <s> [--deps <json_array>] [--parent <id>]"
  echo "                                    Crea una tarea asociada a un Run"
    echo "  list-tasks --run <id>             Lista las tareas de un Run"
    echo "  dispatch-worker --run <id> --spec <s> [--agent <opencode|antigravity|codex|claude>]"
    echo "                  [--role <developer|reviewer|ops-auditor>] [--name <worktree_name>]"
    echo "                  [--worktree <current|new-top-level>] [--repo <path>]"
    echo "                                    Despacha un trabajador supervisado en paralelo"
    echo "  create-gate --task <id> --question <q> [--options <json_array>]"
    echo "                                    Crea una compuerta de decisión bloqueante (L3)"
    echo "  list-gates [--run <id>]           Lista compuertas de decisión pendientes/resueltas"
    echo "  check-events [--run <id>] [--wait] [--timeout-ms <n>]"
    echo "                                    Consulta o espera eventos de workers (worker_done, ask)"
  echo "  batch --objective <o> --spec-file <file.json> [--repo <path>]"
  echo "                                    Trocea y despacha workers en paralelo automáticamente"
  echo "                                    (legado: no para en gates ni cae al fallback; usa run-flow)"
  echo "  run-flow --objective <o> --spec-file <file.json> [--repo <path>]"
  echo "           [--satellite <alias>] [--satellites <file>] [--agent <id>] [--wait] [--timeout-ms <n>]"
  echo "                                    Secuencia supervisada: run → tareas → workers →"
  echo "                                    seguimiento → gate. PARA en el gate; sin runtime"
  echo "                                    cae al fallback Git-nativo (T-104)"
    echo ""
    echo "Opciones globales:"
    echo "  --json                            Salida directa en formato JSON"
    echo "  --dry-run                         Simula la acción sin invocar mutaciones en Orca"
    echo "  --help, -h                        Muestra este mensaje de ayuda"
    exit 0
}

COMMAND="${1:-}"
if [ -z "$COMMAND" ] || [ "$COMMAND" = "--help" ] || [ "$COMMAND" = "-h" ]; then
    usage
fi
shift

OUTPUT_JSON=false
DRY_RUN=false
RUN_ID=""
POSITIONAL_RUN=""
OBJECTIVE=""
TASK_ID=""
TASK_TITLE=""
SPEC=""
SPEC_FILE=""
TASK_DEPS=""
TASK_PARENT=""
AGENT="opencode"
ROLE="developer"
WORKTREE="new-top-level"
WORKTREE_NAME=""
REPO_PATH="$REPO_ROOT"
SATELLITE=""
SATELLITES_FILE=""
DISPATCH_REGISTRY=""
QUESTION=""
OPTIONS=""
GATE_ID=""
RESOLUTION=""
WAIT_FLAG=false
TIMEOUT_MS=60000

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            OUTPUT_JSON=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --run)
            RUN_ID="$2"
            shift 2
            ;;
        --objective)
            OBJECTIVE="$2"
            shift 2
            ;;
        --task)
            TASK_ID="$2"
            shift 2
            ;;
        --id)
            GATE_ID="$2"
            shift 2
            ;;
        --resolution)
            RESOLUTION="$2"
            shift 2
            ;;
        --title)
            TASK_TITLE="$2"
            shift 2
            ;;
        --spec)
            SPEC="$2"
            shift 2
            ;;
        --spec-file)
            SPEC_FILE="$2"
            shift 2
            ;;
        --deps)
            TASK_DEPS="$2"
            shift 2
            ;;
        --parent)
            TASK_PARENT="$2"
            shift 2
            ;;
        --agent)
            AGENT="$2"
            shift 2
            ;;
        --role)
            ROLE="$2"
            shift 2
            ;;
        --worktree)
            WORKTREE="$2"
            shift 2
            ;;
        --name)
            WORKTREE_NAME="$2"
            shift 2
            ;;
        --repo)
            REPO_PATH="$2"
            shift 2
            ;;
        --satellite)
            SATELLITE="$2"
            shift 2
            ;;
        --satellites)
            SATELLITES_FILE="$2"
            shift 2
            ;;
        --registry)
            DISPATCH_REGISTRY="$2"
            shift 2
            ;;
        --question)
            QUESTION="$2"
            shift 2
            ;;
        --options)
            OPTIONS="$2"
            shift 2
            ;;
        --wait)
            WAIT_FLAG=true
            shift
            ;;
        --timeout-ms)
            TIMEOUT_MS="$2"
            shift 2
            ;;
        *)
            if [ "$COMMAND" = "report" ] && [ -z "$POSITIONAL_RUN" ]; then
                POSITIONAL_RUN="$1"
                shift
            else
                echo "Opción desconocida: $1" >&2
                exit 1
            fi
            ;;
    esac
done

# Ejecución según comando
case "$COMMAND" in
    status)
        # Sonda silenciosa (no check_orca): status se degrada con gracia a
        # '{"ok": false}' en vez de abortar, como siempre ha hecho.
        sonda_runtime
        STATUS_OUT=$($ORCA_BIN status --json 2>/dev/null || echo '{"ok": false}')
        RUNS_OUT=$($ORCA_BIN orchestration run-list --json 2>/dev/null || echo '{"ok": false}')
        WORKTREES_OUT=$($ORCA_BIN worktree ps --json 2>/dev/null || echo '{"ok": false}')

        if [ "$OUTPUT_JSON" = true ]; then
            python3 - "$STATUS_OUT" "$RUNS_OUT" "$WORKTREES_OUT" << 'PYEOF'
import json, sys
try:
    s_raw = sys.argv[1] if len(sys.argv) > 1 else "{}"
    r_raw = sys.argv[2] if len(sys.argv) > 2 else "{}"
    w_raw = sys.argv[3] if len(sys.argv) > 3 else "{}"
    data = {
        'status': json.loads(s_raw) if s_raw else {},
        'runs': json.loads(r_raw) if r_raw else {},
        'worktrees': json.loads(w_raw) if w_raw else {}
    }
    print(json.dumps(data, indent=2))
except Exception as e:
    print(json.dumps({"error": str(e)}))
PYEOF
        else
            echo "=== 🐳 ESTADO DE ORCA ADE ==="
            python3 - "$STATUS_OUT" "$RUNS_OUT" "$WORKTREES_OUT" << 'PYEOF'
import json, sys
try:
    st = json.loads(sys.argv[1]) if len(sys.argv) > 1 and sys.argv[1] else {}
    app = st.get('result', {}).get('app', {})
    rt = st.get('result', {}).get('runtime', {})
    print(f'🖥️  App PID: {app.get("pid", "n/a")} | Versión: {rt.get("appVersion", "n/a")} | Estado: {rt.get("state", "desconectado")}')
except Exception:
    print('  Estado de runtime no disponible.')

try:
    r_data = json.loads(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2] else {}
    runs = r_data.get('result', {}).get('runs', [])
    print(f'🏃 Runs registrados: {len(runs)}')
    for r in runs[:3]:
        print(f'   - [{r.get("id")}] {r.get("objective")} ({r.get("created_at")})')
except Exception:
    pass

try:
    w_data = json.loads(sys.argv[3]) if len(sys.argv) > 3 and sys.argv[3] else {}
    wts = w_data.get('result', {}).get('worktrees', [])
    print(f'📂 Worktrees activos: {len(wts)}')
    for w in wts[:4]:
        print(f'   - {w.get("displayName")} ({w.get("path")}) | Repo: {w.get("repo")}')
except Exception:
    pass
PYEOF
        fi
        ;;

    # >>> T-112 report
    report)
        # Read-only estricto: solo primitivas de lectura (run-list, task-list,
        # gate-list, worker-list, worktree ps). No aborta si falta el runtime.
        sonda_runtime
        REPORT_RUN_ID="${RUN_ID:-$POSITIONAL_RUN}"
        REPORT_RUNS='{"ok":false}'
        REPORT_TASKS='{"ok":false}'
        REPORT_GATES='{"ok":false}'
        REPORT_WORKERS='{"ok":false}'
        REPORT_WTS='{"ok":false}'
        if [ "$RUNTIME_STATE" = "RUNTIME_OK" ]; then
            REPORT_RUNS=$($ORCA_BIN orchestration run-list --json 2>/dev/null || echo '{"ok":false}')
            if [ -n "$REPORT_RUN_ID" ]; then
                REPORT_TASKS=$($ORCA_BIN orchestration task-list --run "$REPORT_RUN_ID" --json 2>/dev/null || echo '{"ok":false}')
                REPORT_GATES=$($ORCA_BIN orchestration gate-list --run "$REPORT_RUN_ID" --json 2>/dev/null || echo '{"ok":false}')
                REPORT_WORKERS=$($ORCA_BIN orchestration worker-list --run "$REPORT_RUN_ID" --json 2>/dev/null || echo '{"ok":false}')
            fi
            REPORT_WTS=$($ORCA_BIN worktree ps --json 2>/dev/null || echo '{"ok":false}')
        fi
        REPORT_RC=0
        python3 - "$REPORT_RUN_ID" "$RUNTIME_STATE" "$OUTPUT_JSON" \
            "$REPORT_RUNS" "$REPORT_TASKS" "$REPORT_GATES" "$REPORT_WORKERS" "$REPORT_WTS" << 'PYEOF' || REPORT_RC=$?
import json, subprocess, sys

run_id, runtime, as_json = sys.argv[1], sys.argv[2], sys.argv[3] == "true"

def load(s):
    try:
        d = json.loads(s) if s and s.strip() else {}
        return d if isinstance(d, dict) else {}
    except Exception:
        return {}

def rows(d, key):
    r = d.get("result") or {}
    v = r.get(key) if isinstance(r, dict) else None
    return v if isinstance(v, list) else []

runs_d, tasks_d, gates_d, workers_d, wts_d = (load(x) for x in sys.argv[4:9])
runs = rows(runs_d, "runs")
tasks = rows(tasks_d, "tasks")
gates = rows(gates_d, "gates")
workers = rows(workers_d, "workers")
wts = rows(wts_d, "worktrees")

sources_ok = {
    "runs": bool(runs_d.get("ok")),
    "tasks": bool(tasks_d.get("ok")),
    "gates": bool(gates_d.get("ok")),
    "workers": bool(workers_d.get("ok")),
    "worktrees": bool(wts_d.get("ok")),
}

def glyph(s):
    s = (s or "").lower()
    if s in ("done", "completed", "success", "succeeded", "ok"):
        return "✅"
    if s in ("failed", "error", "cancelled", "canceled"):
        return "❌"
    if s in ("running", "in_progress", "working", "dispatched", "pending", "ready", "queued", "blocked"):
        return "⏳"
    return "⚪"

def available_runs():
    return [{"id": r.get("id"), "objective": r.get("objective")} for r in runs[:20]]

def human(o):
    print("=== 📋 INFORME DE LOTE (read-only) ===")
    if o.get("verdict") == "SIN_RUNTIME":
        print("Runtime  : " + str(o.get("runtime_state")))
        print("⚠️  " + str(o.get("hint")))
        return
    if o.get("run") is None:
        print("⚠️  " + str(o.get("hint")))
        for r in o.get("available_runs", [])[:10]:
            obj = str(r.get("objective") or "")[:60]
            print("  - " + str(r.get("id")) + "  " + obj)
        return
    r = o["run"]
    print("Run      : " + str(r.get("id")))
    print("Objetivo : " + str(r.get("objective") or "")[:80])
    print("Creado   : " + str(r.get("created_at") or "n/d"))
    print("Runtime  : " + str(o.get("runtime_state")))
    print("Base diff: " + str(o.get("diff_base") or "n/d"))
    c = o["counts"]
    print("")
    print("TAREAS (" + str(c["tasks"]) + "): ✅ " + str(c["done"]) +
          " · ⏳ " + str(c["running"]) + " · ❌ " + str(c["failed"]))
    for t in o["tasks"]:
        g = (t.get("gate") or {}).get("status") or "-"
        w = (t.get("worker") or {}).get("state") or "-"
        print("  [" + t["status_glyph"] + "] " + str(t["id"]).ljust(18) +
              str(t["title"])[:30].ljust(30) +
              " gate:" + str(g)[:10].ljust(10) +
              " worker:" + str(w)[:10].ljust(10) +
              " diff:" + str(t.get("diffstat") or "n/d"))
    print("")
    print("GATES (" + str(c["gates_pending"] + c["gates_resolved"]) + "): " +
          str(c["gates_pending"]) + " pendiente(s) · " +
          str(c["gates_resolved"]) + " resuelta(s)")
    for g in o["gates"][:8]:
        print("  - " + str(g.get("status") or "?") + " " + str(g.get("id")) +
              " task:" + str(g.get("task_id")) + " " +
              str(g.get("question") or "")[:50])
    if not o["sources_ok"].get("tasks", True):
        print("")
        print("⚠️  Datos incompletos: el runtime no devolvió las tareas.")
    print("")
    print("VEREDICTO: " + str(o.get("verdict")))

def emit(obj, code):
    if as_json:
        print(json.dumps(obj, ensure_ascii=False, indent=2))
    else:
        human(obj)
    sys.exit(code)

empty_counts = {"tasks": 0, "done": 0, "failed": 0, "running": 0,
                "gates_pending": 0, "gates_resolved": 0}

if runtime != "RUNTIME_OK":
    hint = {
        "CLI_AUSENTE": "CLI de Orca no encontrado: instala la distribución o revisa PATH.",
        "RUNTIME_SIN_RESPUESTA": "Orca no responde: ejecuta 'orca open' para iniciar el runtime.",
    }.get(runtime, "Runtime de Orca no disponible.")
    emit({"run": None, "runtime_state": runtime, "diff_base": None,
          "tasks": [], "gates": [], "counts": empty_counts,
          "sources_ok": sources_ok, "verdict": "SIN_RUNTIME",
          "hint": hint, "exit_code": 0}, 0)

if not run_id:
    emit({"run": None, "runtime_state": runtime, "diff_base": None,
          "tasks": [], "gates": [], "counts": empty_counts,
          "sources_ok": sources_ok, "verdict": "RUN_NO_ESPECIFICADO",
          "available_runs": available_runs(),
          "hint": "Indica el run: report <run-id> [--json]",
          "exit_code": 1}, 1)

run = next((r for r in runs if r.get("id") == run_id), None)
if run is None:
    emit({"run": None, "runtime_state": runtime, "diff_base": None,
          "tasks": [], "gates": [], "counts": empty_counts,
          "sources_ok": sources_ok, "verdict": "RUN_NO_ENCONTRADO",
          "available_runs": available_runs(),
          "hint": "Run '" + run_id + "' no registrado. Lista de runs disponibles:",
          "exit_code": 1}, 1)

base = run.get("base_ref") or run.get("baseRef") or run.get("base") or None
gate_by_task, worker_by_task, wt_by_path = {}, {}, {}
for g in gates:
    gate_by_task.setdefault(g.get("task_id"), g)
for w in workers:
    worker_by_task.setdefault(w.get("taskId"), w)
for w in wts:
    p = w.get("path")
    if p:
        wt_by_path[p] = w

def worktree_path(worker):
    r = (worker or {}).get("resource") or {}
    wid = r.get("worktreeId") or ""
    return wid.split("::", 1)[1] if "::" in wid else None

def diffstat(path):
    if not base or not path:
        return "n/d"
    try:
        out = subprocess.run(["git", "-C", path, "diff", "--stat", base + "..HEAD"],
                             capture_output=True, text=True, timeout=10)
        hit = [l for l in out.stdout.strip().splitlines() if "changed" in l]
        return hit[-1].strip() if hit else "n/d"
    except Exception:
        return "n/d"

task_rows = []
for t in tasks:
    g = gate_by_task.get(t.get("id"))
    w = worker_by_task.get(t.get("id"))
    path = worktree_path(w)
    wt = wt_by_path.get(path) if path else None
    task_rows.append({
        "id": t.get("id"),
        "title": t.get("display_name") or t.get("task_title") or t.get("id"),
        "status": t.get("status") or "unknown",
        "status_glyph": glyph(t.get("status")),
        "deps": t.get("deps") or [],
        "gate": {"id": g.get("id"), "status": g.get("status")} if g else None,
        "worker": {
            "state": w.get("workerState") if w else None,
            "dispatch_status": w.get("dispatchStatus") if w else None,
            "worktree": (wt or {}).get("displayName") if wt else None,
            "branch": ((wt or {}).get("branch") or "").replace("refs/heads/", "") if wt else None,
            "path": path,
        },
        "diffstat": diffstat(path),
    })

pending = [g for g in gates if (g.get("status") or "").lower() in ("pending", "open", "waiting")]
done = [t for t in task_rows if t["status"].lower() in ("done", "completed", "success", "succeeded", "ok")]
failed = [t for t in task_rows if t["status"].lower() in ("failed", "error", "cancelled", "canceled")]
running = [t for t in task_rows if t["status"].lower() in ("running", "in_progress", "working", "dispatched", "pending", "ready", "queued", "blocked")]

if not task_rows:
    verdict = "SIN_TAREAS"
elif pending:
    verdict = "GATE_PENDIENTE"
elif failed:
    verdict = "CON_FALLOS"
elif len(done) == len(task_rows):
    verdict = "COMPLETADO"
else:
    verdict = "EN_CURSO"
if not sources_ok.get("tasks"):
    verdict = "DATOS_INCOMPLETOS"

counts = {
    "tasks": len(task_rows),
    "done": len(done),
    "failed": len(failed),
    "running": len(running),
    "gates_pending": len(pending),
    "gates_resolved": len(gates) - len(pending),
}

emit({"run": {"id": run.get("id"), "objective": run.get("objective"),
              "created_at": run.get("created_at")},
      "runtime_state": runtime, "diff_base": base,
      "tasks": task_rows,
      "gates": [{"id": g.get("id"), "task_id": g.get("task_id"),
                 "status": g.get("status"), "question": g.get("question")} for g in gates],
      "counts": counts, "sources_ok": sources_ok,
      "verdict": verdict, "exit_code": 0}, 0)
PYEOF
        exit "$REPORT_RC"
        ;;
    # <<< T-112 report

    create-run)
        if [ -z "$OBJECTIVE" ]; then
            echo "❌ Error: Se requiere --objective '<descripción del objetivo>'" >&2
            exit 1
        fi
        check_orca
        if [ "$DRY_RUN" = true ]; then
            echo "🔎 [DRY-RUN] Simulación de creación de Run: '$OBJECTIVE'"
            exit 0
        fi
        $ORCA_BIN orchestration run-create --objective "$OBJECTIVE" --json
        ;;

    list-runs)
        check_orca
        $ORCA_BIN orchestration run-list --json
        ;;

    create-task)
        if [ -z "$RUN_ID" ] || [ -z "$SPEC" ]; then
            echo "❌ Error: Se requieren --run <id> y --spec '<especificación>'" >&2
            exit 1
        fi
        check_orca
        TASK_TITLE_ARG=()
        if [ -n "$TASK_TITLE" ]; then
            TASK_TITLE_ARG=(--task-title "$TASK_TITLE")
        fi
        TASK_DEPS_ARG=()
        if [ -n "$TASK_DEPS" ]; then
            TASK_DEPS_ARG=(--deps "$TASK_DEPS")
        fi
        TASK_PARENT_ARG=()
        if [ -n "$TASK_PARENT" ]; then
            TASK_PARENT_ARG=(--parent "$TASK_PARENT")
        fi
        if [ "$DRY_RUN" = true ]; then
            echo "🔎 [DRY-RUN] Creando tarea en Run $RUN_ID: ${TASK_TITLE:-'Sin título'}"
            exit 0
        fi
        $ORCA_BIN orchestration task-create --run "$RUN_ID" --spec "$SPEC" "${TASK_TITLE_ARG[@]}" "${TASK_DEPS_ARG[@]}" "${TASK_PARENT_ARG[@]}" --json
        ;;

    list-tasks)
        if [ -z "$RUN_ID" ]; then
            echo "❌ Error: Se requiere --run <id>" >&2
            exit 1
        fi
        check_orca
        $ORCA_BIN orchestration task-list --run "$RUN_ID" --json
        ;;

    dispatch-worker)
        if [ -z "$SPEC" ]; then
            echo "❌ Error: Se requiere --spec '<especificación de la tarea>'" >&2
            exit 1
        fi
        check_orca
        
        # Enriquecer spec con directiva de perfil Agent OS si existe
        ROLE_PROFILE="$REPO_ROOT/.agents/profiles/${ROLE}.yaml"
        FULL_SPEC="$SPEC"
        if [ -f "$ROLE_PROFILE" ]; then
            FULL_SPEC="[Rol: $ROLE]\n$SPEC\n(Respeta invariantes de .agents/profiles/${ROLE}.yaml y \$0 cost mandate)."
        fi

        DISPATCH_ARGS=(--spec "$FULL_SPEC" --agent "$AGENT")
        if [ -n "$RUN_ID" ]; then
            DISPATCH_ARGS+=(--run "$RUN_ID")
        fi
        if [ -n "$TASK_TITLE" ]; then
            DISPATCH_ARGS+=(--task-title "$TASK_TITLE")
        fi
        if [ -n "$WORKTREE_NAME" ]; then
            DISPATCH_ARGS+=(--name "$WORKTREE_NAME")
        fi
        if [ -n "$REPO_PATH" ]; then
            DISPATCH_ARGS+=(--repo "path:$REPO_PATH")
        fi
        DISPATCH_ARGS+=(--worktree "$WORKTREE")

        if [ "$DRY_RUN" = true ]; then
            echo "🔎 [DRY-RUN] Despachando worker:"
            echo "  Agente: $AGENT | Rol: $ROLE"
            echo "  Worktree: $WORKTREE (${WORKTREE_NAME:-auto})"
            echo "  Spec: $FULL_SPEC"
            exit 0
        fi

        $ORCA_BIN orchestration worker-start "${DISPATCH_ARGS[@]}" --json
        ;;

    create-gate)
        if [ -z "$TASK_ID" ] || [ -z "$QUESTION" ]; then
            echo "❌ Error: Se requieren --task <id> y --question '<pregunta>'" >&2
            exit 1
        fi
        check_orca
        GATE_ARGS=(--task "$TASK_ID" --question "$QUESTION")
        if [ -n "$OPTIONS" ]; then
            GATE_ARGS+=(--options "$OPTIONS")
        fi
        if [ "$DRY_RUN" = true ]; then
            echo "🔎 [DRY-RUN] Creando Decision Gate en Task $TASK_ID: $QUESTION"
            exit 0
        fi
        $ORCA_BIN orchestration gate-create "${GATE_ARGS[@]}" --json
        ;;

    list-gates)
        check_orca
        GATE_LIST_ARGS=()
        if [ -n "$RUN_ID" ]; then
            GATE_LIST_ARGS+=(--run "$RUN_ID")
        fi
        $ORCA_BIN orchestration gate-list "${GATE_LIST_ARGS[@]}" --json
        ;;

    resolve-gate)
        if [ -z "$GATE_ID" ] || [ -z "$RESOLUTION" ]; then
            echo "❌ Error: Se requieren --id <gate_id> y --resolution '<texto de resolución>'" >&2
            exit 1
        fi
        check_orca
        if [ "$DRY_RUN" = true ]; then
            echo "🔎 [DRY-RUN] Resolviendo Decision Gate $GATE_ID: $RESOLUTION"
            exit 0
        fi
        $ORCA_BIN orchestration gate-resolve --id "$GATE_ID" --resolution "$RESOLUTION" --json
        ;;

    check-events)
        check_orca
        CHECK_ARGS=(--types "worker_done,escalation,question")
        if [ -n "$RUN_ID" ]; then
            CHECK_ARGS+=(--run "$RUN_ID")
        fi
        if [ "$WAIT_FLAG" = true ]; then
            CHECK_ARGS+=(--wait --timeout-ms "$TIMEOUT_MS")
        fi
        $ORCA_BIN orchestration check "${CHECK_ARGS[@]}" --json
        ;;

    batch)
        if [ -z "$OBJECTIVE" ]; then
            echo "❌ Error: Se requiere --objective '<objetivo global>'" >&2
            exit 1
        fi
        check_orca
        echo "🚀 Inicializando Run de Orquestación: '$OBJECTIVE'..."
        
        RUN_RESP=$($ORCA_BIN orchestration run-create --objective "$OBJECTIVE" --json)
        ACTIVE_RUN_ID=$(echo "$RUN_RESP" | python3 -c "import json, sys; print(json.load(sys.stdin).get('result', {}).get('run', {}).get('id', ''))")
        
        if [ -z "$ACTIVE_RUN_ID" ]; then
            echo "❌ Fallo al inicializar Run en Orca." >&2
            echo "$RUN_RESP" >&2
            exit 1
        fi
        echo "✅ Run Creado Exitosamente: $ACTIVE_RUN_ID"

        # Si se suministró un archivo de subtareas JSON
        if [ -n "$SPEC_FILE" ] && [ -f "$SPEC_FILE" ]; then
            echo "📋 Despachando subtareas desde $SPEC_FILE en paralelo..."
            python3 -c "
import json, sys, subprocess

with open('$SPEC_FILE') as f:
    plan = json.load(f)

run_id = '$ACTIVE_RUN_ID'
tasks = plan.get('tasks', [])
print(f'Total de subtareas a despachar: {len(tasks)}')

for idx, t in enumerate(tasks):
    title = t.get('title', f'subtask-{idx+1}')
    spec = t.get('spec', '')
    agent = t.get('agent', 'opencode')
    role = t.get('role', 'developer')
    wt_name = t.get('worktree_name', f'wt-{title.lower().replace(\" \", \"-\")[:20]}')
    
    cmd = [
        'bash', '$SCRIPT_DIR/orca-orchestrate.sh', 'dispatch-worker',
        '--run', run_id,
        '--title', title,
        '--spec', spec,
        '--agent', agent,
        '--role', role,
        '--name', wt_name,
        '--worktree', 'new-top-level'
    ]
    print(f'  ▶ Despachando worker [{idx+1}/{len(tasks)}]: {title} (Agente: {agent}, Rol: {role})...')
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode == 0:
        print(f'    ✅ Despachado.')
    else:
        print(f'    ⚠️ Advertencia en despacho: {res.stderr.strip()[:100]}')
"
        else
            echo "ℹ️  Run creado listo para despachos manuales: --run $ACTIVE_RUN_ID"
        fi
        ;;

    run-flow)
        # Punto de entrada supervisado (T-105): run → tareas → workers →
        # seguimiento → gate. PARA en el gate: nunca invoca resolve-gate.
        # Sin runtime usable cae al fallback Git-nativo (T-104) con ruta
        # explícita; nunca finge éxito.
        if [ -z "$OBJECTIVE" ]; then
            echo "❌ Error: Se requiere --objective '<objetivo del lote>'" >&2
            exit 1
        fi
        if [ -z "$SPEC_FILE" ] || [ ! -f "$SPEC_FILE" ]; then
            echo "❌ Error: Se requiere --spec-file <file.json> existente." >&2
            exit 1
        fi
        SELF="bash $SCRIPT_DIR/orca-orchestrate.sh"
        DISPATCHER="bash $SCRIPT_DIR/dispatch-satellite.sh"
        FLOW_TASKS="$(python3 -c "
import json, re, sys
plan = json.load(open(sys.argv[1]))
sep = chr(31)
out = []
for idx, t in enumerate(plan.get('tasks', [])):
    title = t.get('title', 'subtask-%d' % (idx + 1)).replace(chr(31), ' ').replace('\n', ' ')
    slug = re.sub(r'[^a-z0-9]+', '-', title.lower()).strip('-')[:24] or 'task-%d' % (idx + 1)
    deps = json.dumps(t.get('deps', []), separators=(',', ':'))
    spec = t.get('spec', '').replace(chr(31), ' ').replace('\n', ' ')
    out.append(sep.join([str(idx), title, spec, t.get('agent', 'opencode'), t.get('role', 'developer'), 'flow-' + slug, deps]))
print('\n'.join(out))
" "$SPEC_FILE")" || {
            echo "❌ Error: spec-file inválido (se esperaba JSON con array 'tasks')." >&2
            exit 1
        }
        if [ -z "$FLOW_TASKS" ]; then
            echo "❌ Error: spec-file sin tareas." >&2
            exit 1
        fi
        NTASKS="$(printf '%s' "$FLOW_TASKS" | grep -c .)"
        if [ "$DRY_RUN" = true ]; then
            sonda_runtime
            echo "🔎 [DRY-RUN] run-flow: '$OBJECTIVE' ($NTASKS tareas, runtime: $RUNTIME_STATE). Sin mutaciones."
            exit 0
        fi
        rflog() {
            if [ "$OUTPUT_JSON" = true ]; then echo -e "$@" >&2; else echo -e "$@"; fi
        }
        SEP=$'\x1f'
        sonda_runtime
        if [ "$RUNTIME_STATE" = "RUNTIME_OK" ]; then
            rflog "🚀 [run-flow] Runtime Orca disponible. Secuencia supervisada: '$OBJECTIVE'."
            if RUN_OUT=$($SELF create-run --objective "$OBJECTIVE" --json 2>/dev/null); then
                ACTIVE_FLOW_RUN="$(printf '%s' "$RUN_OUT" | python3 -c "
import json, sys
try: obj = json.loads(sys.stdin.read())
except ValueError: obj = {}
def pick(o):
    if isinstance(o, dict):
        for k in ('id', 'run_id'):
            if o.get(k): return o[k]
        for k in ('result', 'data'):
            v = o.get(k)
            if isinstance(v, str) and v: return v
            if isinstance(v, dict):
                for kk in ('id', 'run_id'):
                    if v.get(kk): return v[kk]
    return ''
print(pick(obj))
")"
            else
                ACTIVE_FLOW_RUN=""
            fi
            if [ -z "$ACTIVE_FLOW_RUN" ]; then
                echo "❌ Error: create-run no devolvió un run id parseable." >&2
                exit 1
            fi
            rflog "  ✅ Run: $ACTIVE_FLOW_RUN"
            FLOW_PAIRS=""
            FLOW_GATEPAIRS=""
            while IFS= read -r tline; do
                [ -z "$tline" ] && continue
                TTITLE="$(printf '%s' "$tline" | cut -d"$SEP" -f2)"
                TSPEC="$(printf '%s' "$tline" | cut -d"$SEP" -f3)"
                TAGENT="$(printf '%s' "$tline" | cut -d"$SEP" -f4)"
                TROLE="$(printf '%s' "$tline" | cut -d"$SEP" -f5)"
                TDEPS_WANT="$(printf '%s' "$tline" | cut -d"$SEP" -f7)"
                if ! TDEPS_IDS="$(DEPS="$TDEPS_WANT" MAP="$FLOW_PAIRS" python3 -c "
import json, os
want = json.loads(os.environ.get('DEPS') or '[]')
have = {}
for line in os.environ.get('MAP', '').splitlines():
    if not line.strip(): continue
    t, i = line.split(chr(31), 1)
    have[t] = i
missing = [w for w in want if w not in have]
if missing: raise SystemExit('forward-ref:' + ','.join(missing))
print(json.dumps([have[w] for w in want]))")"; then
                    echo "❌ Error: deps de '$TTITLE' referencia tareas no creadas aún (solo hacia atrás)." >&2
                    exit 1
                fi
                DEPARGS=()
                [ "$TDEPS_IDS" != "[]" ] && DEPARGS=(--deps "$TDEPS_IDS")
                rflog "  ▶ [$TTITLE] creando tarea y despachando worker..."
                OTASK_OUT=""
                if OTASK_OUT=$($SELF create-task --run "$ACTIVE_FLOW_RUN" --title "$TTITLE" --spec "$TSPEC" "${DEPARGS[@]}" --json 2>/dev/null); then
                    OTASK_ID="$(printf '%s' "$OTASK_OUT" | python3 -c "
import json, sys
try: obj = json.loads(sys.stdin.read())
except ValueError: obj = {}
def pick(o):
    if isinstance(o, dict):
        for k in ('id', 'task_id'):
            if o.get(k): return o[k]
        for k in ('result', 'data'):
            v = o.get(k)
            if isinstance(v, str) and v: return v
            if isinstance(v, dict):
                for kk in ('id', 'task_id'):
                    if v.get(kk): return v[kk]
    return ''
print(pick(obj))
")"
                else
                    OTASK_ID=""
                fi
                if [ -z "$OTASK_ID" ]; then
                    echo "❌ Error: create-task no devolvió task id para '$TTITLE'." >&2
                    exit 1
                fi
                if ! $SELF dispatch-worker --run "$ACTIVE_FLOW_RUN" --title "$TTITLE" --spec "$TSPEC" --agent "$TAGENT" --role "$TROLE" --repo "path:$REPO_PATH" --worktree new-top-level --json >/dev/null 2>&1; then
                    echo "❌ Error: dispatch-worker falló para '$TTITLE'." >&2
                    exit 1
                fi
                rflog "    ✅ despachado (task $OTASK_ID)."
                FLOW_PAIRS+="${TTITLE}${SEP}${OTASK_ID}
"
            done <<< "$FLOW_TASKS"
            if [ "$WAIT_FLAG" = true ]; then
                rflog "  ⏳ esperando eventos (check-events --wait)..."
                $SELF check-events --run "$ACTIVE_FLOW_RUN" --wait --timeout-ms "$TIMEOUT_MS" --json >/dev/null 2>&1 || true
            else
                $SELF check-events --run "$ACTIVE_FLOW_RUN" --json >/dev/null 2>&1 || true
            fi
            while IFS= read -r pair; do
                [ -z "$pair" ] && continue
                TTITLE="${pair%%${SEP}*}"
                OTASK_ID="${pair#*${SEP}}"
                OGATE_OUT=""
                if OGATE_OUT=$($SELF create-gate --task "$OTASK_ID" --question "Aprobar '$TTITLE' para integración" --json 2>/dev/null); then
                    OGATE_ID="$(printf '%s' "$OGATE_OUT" | python3 -c "
import json, sys
try: obj = json.loads(sys.stdin.read())
except ValueError: obj = {}
def pick(o):
    if isinstance(o, dict):
        for k in ('id', 'gate_id'):
            if o.get(k): return o[k]
        for k in ('result', 'data'):
            v = o.get(k)
            if isinstance(v, str) and v: return v
            if isinstance(v, dict):
                for kk in ('id', 'gate_id'):
                    if v.get(kk): return v[kk]
    return ''
print(pick(obj))
")"
                else
                    OGATE_ID=""
                fi
                if [ -z "$OGATE_ID" ]; then
                    echo "❌ Error: create-gate no devolvió gate id para '$TTITLE'." >&2
                    exit 1
                fi
                RESOLVE_CMD="bash scripts/agent/orca-orchestrate.sh resolve-gate --id $OGATE_ID --resolution '<tu decisión>'"
                rflog "  🛑 GATE $OGATE_ID: aprueba con: $RESOLVE_CMD"
                FLOW_GATEPAIRS+="${TTITLE}${SEP}${OTASK_ID}${SEP}${OGATE_ID}${SEP}${RESOLVE_CMD}
"
            done <<< "$FLOW_PAIRS"
            rflog "✅ [run-flow] detenido en ${NTASKS} gate(s). El humano decide; el flujo no continúa solo."
            if [ "$OUTPUT_JSON" = true ]; then
                PAIRS="$FLOW_PAIRS" GATEPAIRS="$FLOW_GATEPAIRS" python3 -c "
import json, os, sys
def rows(s, n):
    out = []
    for line in s.splitlines():
        if not line.strip(): continue
        parts = line.split(chr(31))
        out.append(parts[:n])
    return out
tasks = [{'title': r[0], 'task_id': r[1]} for r in rows(os.environ.get('PAIRS', ''), 2)]
gates = [{'task_id': r[1], 'gate_id': r[2], 'resolve_cmd': r[3]} for r in rows(os.environ.get('GATEPAIRS', ''), 4)]
print(json.dumps({'objective': sys.argv[1], 'route': 'orca', 'runtime_state': 'RUNTIME_OK', 'run_id': sys.argv[2], 'tasks': tasks, 'gates': gates, 'status': 'GATE_PENDING', 'exit_code': 0}))
" "$OBJECTIVE" "$ACTIVE_FLOW_RUN"
            fi
            exit 0
        else
            rflog "⚠️  [run-flow] Sin runtime usable ($RUNTIME_STATE). Fallback Git-nativo (T-104)."
            if [ -z "$SATELLITE" ]; then
                if [ "$OUTPUT_JSON" = true ]; then
                    python3 -c "import json,sys; print(json.dumps({'objective':sys.argv[1],'route':'git-fallback','status':'ERROR','error':'Sin runtime y sin --satellite: declara un satélite en satellites.yaml o ejecuta con runtime','exit_code':1}))" "$OBJECTIVE"
                else
                    echo "❌ Error: sin runtime Orca y sin --satellite." >&2
                    echo "   Declara un satélite en .agents/config/satellites.yaml y repite con --satellite <alias>." >&2
                fi
                exit 1
            fi
            FALLBACK_PAIRS=""
            FALLBACK_OK=true
            while IFS= read -r tline; do
                [ -z "$tline" ] && continue
                TTITLE="$(printf '%s' "$tline" | cut -d"$SEP" -f2)"
                FSLUG="$(printf '%s' "$tline" | cut -d"$SEP" -f6)"
                if FOUT=$($DISPATCHER ${SATELLITES_FILE:+--satellites "$SATELLITES_FILE"} ${DISPATCH_REGISTRY:+--registry "$DISPATCH_REGISTRY"} --satellite "$SATELLITE" --task-id "$FSLUG" --json 2>/dev/null); then
                    rflog "  ✅ '$TTITLE' despachado por ruta Git (satélite $SATELLITE)."
                    FALLBACK_PAIRS+="${TTITLE}${SEP}${FSLUG}${SEP}true
"
                else
                    rflog "  ❌ '$TTITLE' no se pudo despachar: $FOUT"
                    FALLBACK_PAIRS+="${TTITLE}${SEP}${FSLUG}${SEP}false
"
                    FALLBACK_OK=false
                fi
            done <<< "$FLOW_TASKS"
            if [ "$FALLBACK_OK" = true ]; then
                FSTATUS="DISPATCHED_FALLBACK"; FEXIT=0
            else
                FSTATUS="ERROR"; FEXIT=1
            fi
            if [ "$OUTPUT_JSON" = true ]; then
                PAIRS="$FALLBACK_PAIRS" python3 -c "
import json, os, sys
tasks = []
for line in os.environ.get('PAIRS', '').splitlines():
    if not line.strip(): continue
    t, i, ok = line.split(chr(31))
    tasks.append({'title': t, 'task_id': i, 'dispatched': ok == 'true'})
print(json.dumps({'objective': sys.argv[1], 'route': 'git-fallback', 'runtime_state': sys.argv[2], 'run_id': None, 'tasks': tasks, 'gates': [], 'status': sys.argv[3], 'exit_code': int(sys.argv[4])}))
" "$OBJECTIVE" "$RUNTIME_STATE" "$FSTATUS" "$FEXIT"
            else
                rflog "  route: git-fallback, status: $FSTATUS (ruta explícita, no éxito simulado)."
            fi
            exit "$FEXIT"
        fi
        ;;

    *)
        echo "Comando no reconocido: $COMMAND" >&2
        echo "Usa --help para ver la lista de comandos disponibles." >&2
        exit 1
        ;;
esac
