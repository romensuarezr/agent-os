#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/dispatch-satellite.sh — Despacho de tareas a repos satélite (T-104)
# ==============================================================================
# Resuelve un alias de `.agents/config/satellites.yaml`, detecta si hay runtime
# Orca alcanzable y elige ruta: Orca (`worker-start`) o Git-nativa
# (`worktree-dispatch.sh` con cwd en el satélite). Ambas rutas producen el mismo
# contrato JSON. La ausencia de Orca nunca es un error: es la ruta Git.
#
# El dispatcher SABE lo que despachó porque él mismo lo hizo: anexa una línea
# por despacho a `.agents/context/dispatched.jsonl` (estado local del operador,
# excluido de git, fuera del manifest). Re-despachar (mismo satélite + misma
# tarea) devuelve el registro existente sin crear un segundo worktree, salvo
# --force. El registro es append-only con semántica last-wins.
#
# Salida JSON normalizada (una línea, stdout con --json):
#   {"task_id","satellite","satellite_path","profile","branch","base_ref",
#    "worktree_path","agent_os_root","route","status","dispatched_at",
#    "exit_code", ...campos propios de la ruta...}
#   status: CREATED | IDEMPOTENT | ERROR
#   route:  orca | git
#
# NOTA sobre satellites.yaml: se parsea el subconjunto que usa ese fichero
# (mapa alias → {path, worktree_base?, route?}, comentarios `#`, escalares
# con o sin comillas). No es un parser YAML general: cualquier forma fuera del
# esquema es un error explícito, no una adivinanza.
# ==============================================================================
set -uo pipefail

for cmd in git python3 mkdir cat chmod grep date cut dirname mktemp; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ ERROR: Dependencia requerida no encontrada: $cmd" >&2
    exit 1
  fi
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CORE_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || dirname "$SCRIPT_DIR")"
SATELLITES_FILE="$CORE_ROOT/.agents/config/satellites.yaml"
REGISTRY="$CORE_ROOT/.agents/context/dispatched.jsonl"

SATELLITE=""
TASK_ID=""
PROFILE="coder"
BASE=""
BRANCH=""
AGENT=""
ROUTE_OVERRIDE=""
FORCE=false
JSON_MODE=false
DRY_RUN=false

show_help() {
  cat << 'EOF'
Uso: scripts/agent/dispatch-satellite.sh --satellite <ALIAS> --task-id <ID> [OPCIONES]
     scripts/agent/dispatch-satellite.sh list [--json]

Despacha una tarea a un repositorio satélite (ruta Orca si hay runtime,
Git-nativa si no). Nunca aborta por ausencia de Orca.

Opciones:
  --satellite <ALIAS>   Satélite declarado en satellites.yaml (obligatorio).
  --task-id <ID>        ID de la tarea (obligatorio, ej: T-104).
  --profile <PERFIL>    Perfil del agente (default: coder).
  --base <REF>          Base para la rama (default: HEAD del satélite).
  --branch <RAMA>       Rama aislada (default: feat/<task-id>-<profile>).
  --agent <ID>          Agente Orca para la ruta orca (obligatorio en esa ruta).
  --route <MODO>        auto (default) | orca | git. Sobrescribe el YAML.
  --satellites <F>      Fichero de satélites alternativo (para pruebas).
  --registry <F>        Registro alternativo (para pruebas).
  --force               Re-despacha aunque exista registro (ruta Git: recrea).
  --dry-run             Resuelve y muestra la ruta sin crear nada.
  --json                Emite únicamente JSON plano a stdout.
  list                  Muestra el registro de despachos.
  -h, --help            Muestra esta ayuda.
EOF
}

log() {
  if [ "$JSON_MODE" = false ]; then
    echo -e "$@"
  else
    echo -e "$@" >&2
  fi
}

emit_json_error() {
  local msg="$1"
  python3 -c "import json,sys; print(json.dumps({'task_id':sys.argv[1],'satellite':sys.argv[2],'status':'ERROR','error':sys.argv[3],'exit_code':1}))" \
    "$TASK_ID" "$SATELLITE" "$msg"
}

ACTION=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    list) ACTION="list"; shift ;;
    --satellite) SATELLITE="$2"; shift 2 ;;
    --task-id) TASK_ID="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --base) BASE="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --agent) AGENT="$2"; shift 2 ;;
    --route) ROUTE_OVERRIDE="$2"; shift 2 ;;
    --satellites) SATELLITES_FILE="$2"; shift 2 ;;
    --registry) REGISTRY="$2"; shift 2 ;;
    --force) FORCE=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --json) JSON_MODE=true; shift ;;
    -h|--help) show_help; exit 0 ;;
    *) echo "❌ ERROR: argumento desconocido: $1" >&2; show_help >&2; exit 1 ;;
  esac
done

# ------------------------------------------------------------------------------
# list: muestra el registro y termina
# ------------------------------------------------------------------------------
if [ "$ACTION" = "list" ]; then
  if [ ! -s "$REGISTRY" ]; then
    if [ "$JSON_MODE" = true ]; then echo "[]"; else echo "  (sin despachos registrados)"; fi
    exit 0
  fi
  if [ "$JSON_MODE" = true ]; then
    cat "$REGISTRY"
  else
    python3 -c "
import json,sys
for line in open(sys.argv[1]):
    line=line.strip()
    if not line: continue
    d=json.loads(line)
    print('  %s  %s -> %s  [%s] %s' % (d.get('dispatched_at','?'),d.get('task_id','?'),d.get('satellite','?'),d.get('route','?'),d.get('status','?')))
" "$REGISTRY"
  fi
  exit 0
fi

if [ -z "$SATELLITE" ] || [ -z "$TASK_ID" ]; then
  if [ "$JSON_MODE" = true ]; then emit_json_error "Faltan --satellite y/o --task-id"; else
    echo "❌ ERROR: --satellite y --task-id son obligatorios." >&2; fi
  exit 1
fi

if [[ ! "$SATELLITE" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
  if [ "$JSON_MODE" = true ]; then emit_json_error "Alias de satélite inválido: $SATELLITE"; else
    echo "❌ ERROR: alias de satélite inválido: $SATELLITE" >&2; fi
  exit 1
fi

[ -z "$BRANCH" ] && BRANCH="feat/${TASK_ID}-${PROFILE}"

# ------------------------------------------------------------------------------
# 1. Resolver el satélite (parseo estricto del subconjunto YAML)
# ------------------------------------------------------------------------------
if [ ! -f "$SATELLITES_FILE" ]; then
  if [ "$JSON_MODE" = true ]; then emit_json_error "No existe $SATELLITES_FILE"; else
    echo "❌ ERROR: no existe el fichero de satélites: $SATELLITES_FILE" >&2; fi
  exit 1
fi

RESOLVED="$(python3 - "$SATELLITES_FILE" "$SATELLITE" << 'PYEOF'
import sys
path, alias = sys.argv[1], sys.argv[2]
sats, cur, version = {}, None, None
for ln, raw in enumerate(open(path), 1):
    line = raw.split(' #', 1)[0].rstrip()
    if not line.strip() or line.strip().startswith('#'):
        continue
    indent = len(line) - len(line.lstrip(' '))
    key, _, val = line.strip().partition(':')
    key, val = key.strip(), val.strip().strip('"').strip("'")
    if indent == 0:
        cur = None
        if key == 'version':
            version = val
        elif key == 'satellites':
            pass
        else:
            sys.exit('linea %d: clave de nivel 0 desconocida: %s' % (ln, key))
    elif indent == 2:
        if not key or val:
            sys.exit('linea %d: se esperaba un alias' % ln)
        cur = key
        sats[cur] = {}
    elif indent == 4:
        if cur is None:
            sys.exit('linea %d: clave sin satélite: %s' % (ln, key))
        if key not in ('path', 'worktree_base', 'route'):
            sys.exit('linea %d: clave desconocida en %s: %s' % (ln, cur, key))
        sats[cur][key] = val
    else:
        sys.exit('linea %d: indentación inválida' % ln)
if version != '1.0':
    sys.exit('version no soportada: %s (se esperaba 1.0)' % version)
if alias not in sats:
    sys.exit('satélite no declarado: %s' % alias)
d = sats[alias]
if 'path' not in d or not d['path']:
    sys.exit('el satélite %s no declara path' % alias)
route = d.get('route', 'auto')
if route not in ('auto', 'orca', 'git'):
    sys.exit('route inválida en %s: %s (auto|orca|git)' % (alias, route))
print('%s\t%s\t%s' % (d['path'], d.get('worktree_base', ''), route))
PYEOF
)" || {
  if [ "$JSON_MODE" = true ]; then emit_json_error "satélites: $RESOLVED"; else
    echo "❌ ERROR en satellites.yaml: $RESOLVED" >&2; fi
  exit 1
}

SAT_PATH_RAW="$(printf '%s' "$RESOLVED" | cut -f1)"
WT_BASE_RAW="$(printf '%s' "$RESOLVED" | cut -f2)"
ROUTE_CFG="$(printf '%s' "$RESOLVED" | cut -f3)"
[ -n "$ROUTE_OVERRIDE" ] && ROUTE_CFG="$ROUTE_OVERRIDE"
if [[ "$ROUTE_CFG" != auto && "$ROUTE_CFG" != orca && "$ROUTE_CFG" != git ]]; then
  if [ "$JSON_MODE" = true ]; then emit_json_error "route inválida: $ROUTE_CFG (auto|orca|git)"; else
    echo "❌ ERROR: --route inválida: $ROUTE_CFG (auto|orca|git)" >&2; fi
  exit 1
fi

# Expansión de `~`: solo el prefijo literal `~/` contra $HOME. Sin eval.
expand_tilde() {
  case "$1" in
    "~") printf '%s' "$HOME" ;;
    "~/"*) printf '%s' "$HOME/${1#~/}" ;;
    "~"*) echo "REFUSED:$1" ;;
    *) printf '%s' "$1" ;;
  esac
}

SAT_PATH="$(expand_tilde "$SAT_PATH_RAW")"
case "$SAT_PATH" in REFUSED:*)
  if [ "$JSON_MODE" = true ]; then emit_json_error "ruta con ~usuario no soportada: $SAT_PATH_RAW (usa ~/...)"; else
    echo "❌ ERROR: rutas ~usuario no soportadas: $SAT_PATH_RAW (usa ~/...)" >&2; fi
  exit 1 ;;
esac

# ------------------------------------------------------------------------------
# 2. Validar el destino (R2: existe y es repo git; si no, error, nunca adivinar)
# ------------------------------------------------------------------------------
if [ ! -d "$SAT_PATH" ] || ! git -C "$SAT_PATH" rev-parse --git-dir >/dev/null 2>&1; then
  if [ "$JSON_MODE" = true ]; then emit_json_error "el satélite $SATELLITE no es un repo git accesible: $SAT_PATH_RAW"; else
    echo "❌ ERROR: el satélite '$SATELLITE' no es un repo git accesible: $SAT_PATH_RAW" >&2; fi
  exit 1
fi
SAT_ABS="$(cd "$SAT_PATH" && pwd -P)"

# Canónico T-107: sin worktree_base declarado, hermano al satélite, fuera del
# árbol (<padre>/<repo>-<task-id>/). Con worktree_base explícito se mantiene la
# semántica anterior (relativo→satélite, absoluta/`~`→tal cual).
if [ -z "$WT_BASE_RAW" ]; then
  WT_ABS="${SAT_ABS%/*}/${SAT_ABS##*/}-${TASK_ID}"
else
  case "$WT_BASE_RAW" in
    "~"|"~/"*|"~"*) WT_BASE_EXPANDED="$(expand_tilde "$WT_BASE_RAW")" ;;
    /*) WT_BASE_EXPANDED="$WT_BASE_RAW" ;;
    *) WT_BASE_EXPANDED="$SAT_ABS/$WT_BASE_RAW" ;;
  esac
  case "$WT_BASE_EXPANDED" in REFUSED:*)
    if [ "$JSON_MODE" = true ]; then emit_json_error "worktree_base con ~usuario no soportada"; else
      echo "❌ ERROR: worktree_base con ~usuario no soportada" >&2; fi
    exit 1 ;;
  esac
  WT_ABS="${WT_BASE_EXPANDED%/}/${TASK_ID}"
fi

# ------------------------------------------------------------------------------
# 3. Idempotencia: el registro manda (last-wins, append-only)
# ------------------------------------------------------------------------------
PRIOR="$(python3 -c "
import json,sys
reg, sat, tid = sys.argv[1], sys.argv[2], sys.argv[3]
found = None
try:
    for line in open(reg):
        line = line.strip()
        if not line: continue
        try: d = json.loads(line)
        except ValueError: continue
        if d.get('satellite') == sat and d.get('task_id') == tid and d.get('status') in ('CREATED','IDEMPOTENT'):
            found = line
except FileNotFoundError:
    pass
if found: print(found)
" "$REGISTRY" "$SATELLITE" "$TASK_ID")"

if [ -n "$PRIOR" ] && [ "$FORCE" = false ]; then
  OUT="$(python3 -c "
import json,sys
d = json.loads(sys.argv[1])
d['status'] = 'IDEMPOTENT'
d['exit_code'] = 0
print(json.dumps(d))
" "$PRIOR")"
  if [ "$JSON_MODE" = true ]; then echo "$OUT"; else
    log "ℹ️  Ya despachado: $TASK_ID -> $SATELLITE (idempotente, no se crea nada)."
    echo "$OUT"; fi
  exit 0
fi

# ------------------------------------------------------------------------------
# 4. Detección de runtime (la ausencia de Orca es una ruta, no un error)
#
# La sonda usa orca_is_ready (<1s de timeout) de lib/orca-client.sh (T-133),
# evitando cuelgues ante homónimos conflictivos como /usr/bin/orca de GNOME.
# ------------------------------------------------------------------------------
# shellcheck source=scripts/agent/lib/orca-client.sh
source "$SCRIPT_DIR/lib/orca-client.sh" 2>/dev/null || true

HAS_RUNTIME=false
if command -v orca_is_ready >/dev/null 2>&1 && orca_is_ready; then
  HAS_RUNTIME=true
fi

ROUTE="$ROUTE_CFG"
if [ "$ROUTE" = "auto" ]; then
  if [ "$HAS_RUNTIME" = true ]; then ROUTE="orca"; else ROUTE="git"; fi
fi
if [ "$ROUTE" = "orca" ] && [ "$HAS_RUNTIME" = false ]; then
  if [ "$JSON_MODE" = true ]; then emit_json_error "route=orca sin runtime Orca alcanzable"; else
    echo "❌ ERROR: route=orca pero no hay runtime Orca alcanzable." >&2; fi
  exit 1
fi

log "🚀 [dispatch-satellite] $TASK_ID -> $SATELLITE ($SAT_ABS) por ruta $ROUTE"

if [ "$DRY_RUN" = true ]; then
  python3 -c "import json,sys; print(json.dumps({'task_id':sys.argv[1],'satellite':sys.argv[2],'satellite_path':sys.argv[3],'branch':sys.argv[4],'worktree_path':sys.argv[5],'route':sys.argv[6],'status':'DRY_RUN','exit_code':0}))" \
    "$TASK_ID" "$SATELLITE" "$SAT_ABS" "$BRANCH" "$WT_ABS" "$ROUTE"
  exit 0
fi

STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# ------------------------------------------------------------------------------
# 5a. Ruta Orca (flags verificados contra `orca orchestration worker-start --help`)
# ------------------------------------------------------------------------------
if [ "$ROUTE" = "orca" ]; then
  if [ -z "$AGENT" ]; then
    if [ "$JSON_MODE" = true ]; then emit_json_error "la ruta orca requiere --agent"; else
      echo "❌ ERROR: la ruta orca requiere --agent <id>." >&2; fi
    exit 1
  fi
  [ -z "$BASE" ] && BASE="$(git -C "$SAT_ABS" rev-parse --abbrev-ref HEAD 2>/dev/null || echo HEAD)"
  RAW="$(orca_worker_start \
    --task-title "dispatch $TASK_ID -> $SATELLITE" \
    --spec "Agent-OS dispatch: tarea $TASK_ID (perfil $PROFILE, rama $BRANCH) en el satélite $SATELLITE" \
    --repo "path:$SAT_ABS" --worktree new-child --agent "$AGENT" --json 2>&1)" || {
    if [ "$JSON_MODE" = true ]; then emit_json_error "worker-start falló: $RAW"; else
      echo "❌ ERROR: orca worker-start falló: $RAW" >&2; fi
    exit 1
  }
  OUT="$(TASK_ID="$TASK_ID" SATELLITE="$SATELLITE" SAT_ABS="$SAT_ABS" PROFILE="$PROFILE" \
    BRANCH="$BRANCH" BASE="$BASE" AGENT="$AGENT" STAMP="$STAMP" RAW="$RAW" python3 -c "
import json,os
raw = os.environ['RAW']
try: remote = json.loads(raw)
except ValueError: remote = {'raw': raw}
d = {'task_id':os.environ['TASK_ID'],'satellite':os.environ['SATELLITE'],
'satellite_path':os.environ['SAT_ABS'],'profile':os.environ['PROFILE'],
'branch':os.environ['BRANCH'],'base_ref':os.environ['BASE'],
'worktree_path':remote.get('worktree_path') or remote.get('worktree'),
'agent':os.environ['AGENT'],'route':'orca','status':'CREATED',
'dispatched_at':os.environ['STAMP'],'exit_code':0,'remote':remote}
print(json.dumps(d))
")"
  # ------------------------------------------------------------------------------
  # 5b. Ruta Git-nativa: worktree-dispatch.sh con cwd en el satélite (sin cambios)
# ------------------------------------------------------------------------------
else
  # stdout trae el JSON; stderr, el diagnóstico humano. No se mezclan: el
  # normalizador necesita JSON puro.
  ERRF="$(mktemp)"
  if RAW="$(cd "$SAT_ABS" && bash "$CORE_ROOT/scripts/agent/worktree-dispatch.sh" \
    --task-id "$TASK_ID" --profile "$PROFILE" --branch "$BRANCH" \
    ${BASE:+--base "$BASE"} --path "$WT_ABS" \
    $([ "$FORCE" = true ] && echo --force) --json 2>"$ERRF")"; then
    rm -f "$ERRF"
  else
    ERRMSG="$(cat "$ERRF" 2>/dev/null; rm -f "$ERRF")"
    [ -z "$ERRMSG" ] && ERRMSG="$RAW"
    if [ "$JSON_MODE" = true ]; then emit_json_error "worktree-dispatch falló: $ERRMSG"; else
      echo "❌ ERROR: worktree-dispatch.sh falló: $ERRMSG" >&2; fi
    exit 1
  fi
  OUT="$(TASK_ID="$TASK_ID" SATELLITE="$SATELLITE" STAMP="$STAMP" RAW="$RAW" python3 -c "
import json,os
base = json.loads(os.environ['RAW'])
base.update({'satellite':os.environ['SATELLITE'],'satellite_path':base.get('agent_os_root'),
'route':'git','status':base.get('status','CREATED'),'dispatched_at':os.environ['STAMP'],
'exit_code':0,'task_id':os.environ['TASK_ID']})
print(json.dumps(base))
")"
fi

# ------------------------------------------------------------------------------
# 6. Registrar (el dispatcher sabe lo que despachó porque él lo hizo)
# ------------------------------------------------------------------------------
mkdir -p "$(dirname "$REGISTRY")"
printf '%s\n' "$OUT" >> "$REGISTRY"

if [ "$JSON_MODE" = true ]; then
  echo "$OUT"
else
  log "✅ Despachado por ruta $ROUTE. Registrado en $REGISTRY."
  echo "$OUT"
fi
exit 0
