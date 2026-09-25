#!/usr/bin/env bash
# ==============================================================================
# Agent OS — Orca ADE Multi-Agent Orchestration CLI (orca-orchestrate.sh)
# ==============================================================================
# Usage:
#   bash scripts/agent/orca-orchestrate.sh <command> [options]
#
# Commands:
#   status                  Check Orca ADE readiness, active runs and worktrees
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Resolver ejecutable de Orca
ORCA_BIN=""
if command -v orca >/dev/null 2>&1; then
    ORCA_BIN="orca"
elif [ -x "/home/romen/.config/orca/linux-orca-cli-shim/orca" ]; then
    ORCA_BIN="/home/romen/.config/orca/linux-orca-cli-shim/orca"
elif [ -x "/opt/Orca/resources/bin/orca-ide" ]; then
    ORCA_BIN="/opt/Orca/resources/bin/orca-ide"
fi

check_orca() {
    if [ -z "$ORCA_BIN" ]; then
        echo "❌ Error: CLI de Orca no encontrado en PATH ni en rutas conocidas." >&2
        exit 1
    fi
    # Verificar si el runtime está respondiendo
    if ! $ORCA_BIN status --json >/dev/null 2>&1; then
        echo "⚠️ Advertencia: Orca Desktop no parece estar abierto o listo." >&2
        echo "Ejecuta 'orca open' para iniciar el runtime." >&2
        return 1
    fi
    return 0
}

usage() {
    echo "=== 🐳 Agent OS — Orca ADE Multi-Agent Orchestrator ==="
    echo "Uso: bash scripts/agent/orca-orchestrate.sh <comando> [opciones]"
    echo ""
    echo "Comandos disponibles:"
    echo "  status                            Diagnóstico del runtime, runs activos y worktrees"
    echo "  create-run --objective <texto>    Crea un nuevo Run de orquestación"
    echo "  list-runs                         Lista todos los Runs registrados"
    echo "  create-task --run <id> --title <t> --spec <s> [--deps <json_array>]"
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
OBJECTIVE=""
TASK_ID=""
TASK_TITLE=""
SPEC=""
SPEC_FILE=""
AGENT="opencode"
ROLE="developer"
WORKTREE="new-top-level"
WORKTREE_NAME=""
REPO_PATH="$REPO_ROOT"
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
            echo "Opción desconocida: $1" >&2
            exit 1
            ;;
    esac
done

# Ejecución según comando
case "$COMMAND" in
    status)
        check_orca || true
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
        if [ "$DRY_RUN" = true ]; then
            echo "🔎 [DRY-RUN] Creando tarea en Run $RUN_ID: ${TASK_TITLE:-'Sin título'}"
            exit 0
        fi
        $ORCA_BIN orchestration task-create --run "$RUN_ID" --spec "$SPEC" "${TASK_TITLE_ARG[@]}" --json
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

    *)
        echo "Comando no reconocido: $COMMAND" >&2
        echo "Usa --help para ver la lista de comandos disponibles." >&2
        exit 1
        ;;
esac
