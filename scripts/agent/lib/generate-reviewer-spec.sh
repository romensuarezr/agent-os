#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/lib/generate-reviewer-spec.sh
# ==============================================================================
# Compila deterministamente la especificación y directiva de ejecución (--spec)
# para el Revisor Ejecutor en Orca ADE a partir de la Única Fuente de Verdad
# (SSOT) contenida en .agents/profiles/qa-judge.md y .agents/profiles/reviewer.yaml.
#
# Principios y Guardarraíles (T-134):
#   1. SSOT Dinámico: Extrae reglas y herramientas directamente de los perfiles.
#      Soporta PyYAML si está disponible y cuenta con parser puro en Python stdlib.
#   2. Fail-Closed: Si algún perfil falta o está malformado, aborta con código 1.
#      Nunca emite especificaciones parciales o silenciosamente incompletas.
#   3. Unión Verbatim de Prohibiciones: Combina sin alteración las prohibiciones
#      de qa-judge.md y reviewer.yaml (Zero Code Mutation).
#   4. Circuit Breaker: 2 rondas totales de deliberación (1 de corrección).
#   5. Presupuesto Orca: 15 segundos explícitos (el de 5s en reviewer.yaml es HTTP).
#   6. Delimitadores exactos para el veredicto: <!-- VERDICT_JSON_START --> / END.
#   7. Formato JSON: Con --json emite objeto con las 4 claves canónicas:
#      'spec', 'role', 'source_profiles', 'contract_version'.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd 2>/dev/null || git rev-parse --show-toplevel 2>/dev/null || pwd)"

if [ -f "$SCRIPT_DIR/cli-help.sh" ]; then
    # shellcheck source=scripts/agent/lib/cli-help.sh
    source "$SCRIPT_DIR/cli-help.sh"
fi

TASK_ID="T-UNKNOWN"
PLAN_FILE=""
PLAN_TEXT=""
PROFILES_DIR=""
JSON_OUTPUT=false

for arg in "$@"; do
    if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
        if command -v show_help >/dev/null 2>&1; then
            show_help "generate-reviewer-spec.sh" \
                "bash scripts/agent/lib/generate-reviewer-spec.sh [--task-id <ID>] [--plan <PATH> | --plan-text <TEXT>] [--profiles-dir <DIR>] [--json]" \
                "Compila la directiva de ejecución (--spec) para el Revisor Ejecutor de Orca desde qa-judge.md y reviewer.yaml." \
                "--task-id <ID>           ID de la tarea a evaluar (defecto: T-UNKNOWN)." \
                "--plan <PATH>            Ruta al borrador del plan en markdown." \
                "--plan-text <TEXT>       Contenido directo del plan a evaluar." \
                "--profiles-dir <DIR>     Directorio alternativo de perfiles (defecto: .agents/profiles)." \
                "--json                   Emite la salida estructurada en JSON con las 4 claves canónicas." \
                "ejemplo: bash scripts/agent/lib/generate-reviewer-spec.sh --task-id T-135 --plan .agents/context/plan-draft.md"
        else
            echo "Uso: bash scripts/agent/lib/generate-reviewer-spec.sh [--task-id <ID>] [--plan <PATH>] [--json]"
            exit 0
        fi
    fi
done

while [[ $# -gt 0 ]]; do
    case "$1" in
        --task-id)
            TASK_ID="${2:-}"
            shift 2
            ;;
        --plan)
            PLAN_FILE="${2:-}"
            shift 2
            ;;
        --plan-text)
            PLAN_TEXT="${2:-}"
            shift 2
            ;;
        --profiles-dir)
            PROFILES_DIR="${2:-}"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        *)
            echo "❌ ERROR: Argumento desconocido: $1" >&2
            exit 64
            ;;
    esac
done

if [ -z "$PROFILES_DIR" ]; then
    PROFILES_DIR="$REPO_ROOT/.agents/profiles"
fi

QA_JUDGE_FILE="$PROFILES_DIR/qa-judge.md"
REVIEWER_FILE="$PROFILES_DIR/reviewer.yaml"

# Fail-closed: verificación estricta de existencia de las fuentes SSOT
if [ ! -f "$QA_JUDGE_FILE" ]; then
    echo "❌ ERROR: Archivo de perfil no encontrado (fail-closed): $QA_JUDGE_FILE" >&2
    exit 1
fi

if [ ! -f "$REVIEWER_FILE" ]; then
    echo "❌ ERROR: Archivo de perfil no encontrado (fail-closed): $REVIEWER_FILE" >&2
    exit 1
fi

if [ -n "$PLAN_FILE" ]; then
    # Contrato del escritor (T-143): --plan explícito manda siempre
    if [ ! -f "$PLAN_FILE" ]; then
        echo "❌ ERROR: Archivo de plan especificado no existe: $PLAN_FILE" >&2
        exit 1
    fi
    PLAN_TEXT="$(cat "$PLAN_FILE")"
elif [ -z "$PLAN_TEXT" ]; then
    # Resolución caller-driven (T-143): si no se pasó --plan ni --plan-text,
    # resolver borrador particionado si existe plan-draft-${TASK_ID}.md, o caer a plan-draft.md
    if [ -n "$TASK_ID" ] && [ "$TASK_ID" != "T-UNKNOWN" ] && [ -f "$REPO_ROOT/.agents/context/plan-draft-${TASK_ID}.md" ]; then
        PLAN_TEXT="$(cat "$REPO_ROOT/.agents/context/plan-draft-${TASK_ID}.md")"
    elif [ -f "$REPO_ROOT/.agents/context/plan-draft.md" ]; then
        PLAN_TEXT="$(cat "$REPO_ROOT/.agents/context/plan-draft.md")"
    fi
fi

# Invocación del compilador determinista en Python
python3 - "$QA_JUDGE_FILE" "$REVIEWER_FILE" "$TASK_ID" "$PLAN_TEXT" "$JSON_OUTPUT" "$REPO_ROOT" << 'PYEOF'
import os, sys, json

qa_judge_path = sys.argv[1]
reviewer_path = sys.argv[2]
task_id = sys.argv[3]
plan_content = sys.argv[4]
as_json = sys.argv[5] == "true"
repo_root = sys.argv[6]

def parse_simple_yaml(text):
    """Parser puro de YAML para diccionarios y listas estándar (sin dependencias externas)."""
    data = {}
    current_key = None
    sub_key = None
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        indent = len(raw_line) - len(raw_line.lstrip())
        if line.startswith("- "):
            val = line[2:].strip().strip("\"'\''")
            if sub_key and isinstance(data.get(current_key), dict):
                data[current_key].setdefault(sub_key, []).append(val)
            elif current_key:
                if not isinstance(data.get(current_key), list):
                    data[current_key] = []
                data[current_key].append(val)
            continue
        if ":" in line:
            parts = line.split(":", 1)
            k = parts[0].strip()
            v = parts[1].strip().strip("\"'\''") if len(parts) > 1 else ""
            if indent == 0:
                current_key = k
                sub_key = None
                data[current_key] = v if v else None
            elif indent > 0 and current_key:
                sub_key = k
                if not isinstance(data.get(current_key), dict):
                    data[current_key] = {}
                data[current_key][sub_key] = v if v else []
    return data

def load_yaml_safe(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        sys.stderr.write(f"❌ ERROR: No se pudo leer {path}: {e}\n")
        sys.exit(1)

    # Intentar PyYAML si está instalado
    try:
        import yaml
        parsed = yaml.safe_load(content)
        if isinstance(parsed, dict):
            return parsed
    except ImportError:
        pass
    except Exception:
        pass

    # Fallback determinista con parser stdlib
    try:
        return parse_simple_yaml(content)
    except Exception as e:
        sys.stderr.write(f"❌ ERROR: Fallo al parsear YAML en {path}: {e}\n")
        sys.exit(1)

def load_frontmatter_safe(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        sys.stderr.write(f"❌ ERROR: No se pudo leer {path}: {e}\n")
        sys.exit(1)

    parts = content.split("---")
    if len(parts) < 3:
        sys.stderr.write(f"❌ ERROR: {path} no contiene frontmatter YAML delimitado por ---\n")
        sys.exit(1)

    fm_text = parts[1]
    body_text = "---".join(parts[2:])

    # Intentar PyYAML
    try:
        import yaml
        parsed = yaml.safe_load(fm_text)
        if isinstance(parsed, dict):
            return parsed, body_text
    except ImportError:
        pass
    except Exception:
        pass

    try:
        return parse_simple_yaml(fm_text), body_text
    except Exception as e:
        sys.stderr.write(f"❌ ERROR: Fallo al parsear frontmatter de {path}: {e}\n")
        sys.exit(1)

# Carga fail-closed de los dos perfiles SSOT
qa_judge_data, qa_body = load_frontmatter_safe(qa_judge_path)
reviewer_data = load_yaml_safe(reviewer_path)

if not qa_judge_data or not isinstance(qa_judge_data, dict):
    sys.stderr.write(f"❌ ERROR: Datos de qa-judge inválidos o vacíos en {qa_judge_path}\n")
    sys.exit(1)

if not reviewer_data or not isinstance(reviewer_data, dict):
    sys.stderr.write(f"❌ ERROR: Datos de reviewer inválidos o vacíos en {reviewer_path}\n")
    sys.exit(1)

# Extracción de campos obligatorios (fail-closed si falta alguno)
qa_role = qa_judge_data.get("role") or qa_judge_data.get("name")
reviewer_purpose = reviewer_data.get("purpose")
if not qa_role or not reviewer_purpose:
    sys.stderr.write("❌ ERROR: Campos obligatorios role/purpose ausentes en los perfiles SSOT\n")
    sys.exit(1)

# Extracción y unión verbatim de prohibiciones (Zero Code Mutation)
q_tooling = qa_judge_data.get("tooling") or {}
if not isinstance(q_tooling, dict):
    q_tooling = {}
q_forbidden = q_tooling.get("forbidden") or []
if isinstance(q_forbidden, str):
    q_forbidden = [q_forbidden]

q_skills = qa_judge_data.get("skills") or {}
if not isinstance(q_skills, dict):
    q_skills = {}
q_skills_forbidden = q_skills.get("forbidden") or []
if isinstance(q_skills_forbidden, str):
    q_skills_forbidden = [q_skills_forbidden]

r_forbidden = reviewer_data.get("forbidden_actions") or []
if isinstance(r_forbidden, str):
    r_forbidden = [r_forbidden]

# Preservar el orden y unir sin duplicados exactos
all_forbidden = []
seen_f = set()
for item in list(q_forbidden) + list(r_forbidden):
    item_str = str(item).strip()
    if item_str and item_str not in seen_f:
        seen_f.add(item_str)
        all_forbidden.append(item_str)

if not all_forbidden:
    sys.stderr.write("❌ ERROR: Lista de prohibiciones vacía tras extraer de SSOT (fail-closed)\n")
    sys.exit(1)

# Herramientas permitidas
q_allowed = q_tooling.get("allowed") or []
r_allowed = reviewer_data.get("allowed_tools") or []
all_allowed = []
seen_a = set()
for item in list(q_allowed) + list(r_allowed):
    item_str = str(item).strip()
    if item_str and item_str not in seen_a:
        seen_a.add(item_str)
        all_allowed.append(item_str)

# Triggers de escalado
escalations = reviewer_data.get("escalation_triggers") or []
decision_gates = qa_judge_data.get("decision_gates") or []
all_triggers = []
seen_t = set()
for item in list(escalations) + list(decision_gates):
    item_str = str(item).strip()
    if item_str and item_str not in seen_t:
        seen_t.add(item_str)
        all_triggers.append(item_str)

# Construcción de la especificación ensamblada
lines = [
    "# DIRECTIVA DE EJECUCIÓN — REVISOR EJECUTOR AUTÓNOMO (RALPH LOOP)",
    "",
    f"Tarea asignada: {task_id}",
    f"Rol operativo: {qa_role}",
    "Presupuesto de ejecución en Orca ADE: 15 segundos (el límite de 5s en reviewer.yaml corresponde al tier de pasarela HTTP en deliberate-plan.sh, no al worker ejecutor).",
    "Circuit breaker: Máximo 2 rondas de deliberación en total (1 ronda de corrección automática; si en la ronda 2 no hay consenso, el veredicto debe ser ESCALADO_A_HUMANO).",
    "",
    "## 1. PRINCIPIO FUNDAMENTAL Y PROHIBICIONES ESTRICTAS (ZERO CODE MUTATION)",
    "El Revisor Ejecutor actúa exclusivamente como compuerta técnica y árbitro imparcial.",
    "Bajo ninguna circunstancia escribe código nuevo, arregla tests o soluciona bugs.",
    "Queda terminantemente prohibido:",
]

for f_item in all_forbidden:
    lines.append(f"- {f_item}")

if q_skills_forbidden:
    lines.extend([
        "",
        "Skills explícitamente prohibidas (skills.forbidden):",
    ])
    for s_item in q_skills_forbidden:
        lines.append(f"- {s_item}")

lines.extend([
    "",
    "## 2. HERRAMIENTAS AUTORIZADAS Y AUDITORÍA DETERMINISTA",
    "El Revisor debe basar su veredicto en hechos comprobables mediante herramientas de solo lectura:",
])

for a_item in all_allowed:
    lines.append(f"- {a_item}")

lines.extend([
    "",
    "## 3. DISPARADORES DE ESCALADO A HUMANO",
    "Cualquiera de las siguientes condiciones detiene inmediatamente la ejecución desatendida:",
])

for t_item in all_triggers:
    lines.append(f"- {t_item}")

lines.extend([
    "",
    "## 4. CONTRATO Y DELIMITADORES EXACTOS DE VEREDICTO",
    "El veredicto final DEBE emitirse obligatoriamente en stdout delimitado exactamente por las etiquetas:",
    "",
    "<!-- VERDICT_JSON_START -->",
    "{",
    '  "verdict": "CONSENSO" | "REVISADO_CON_CAMBIOS" | "ESCALADO_A_HUMANO" | "RECHAZADO",',
    '  "objections": ["lista de objeciones tecnicas o vacia si hay consenso"],',
    '  "proposed_corrections": ["correcciones requeridas o vacia"],',
    '  "skills_evaluation": {',
    '    "status": "verified" | "objection",',
    '    "details": "analisis de skills declaradas"',
    "  },",
    '  "design_summary": "sintesis tecnica de buenas practicas y justificacion"',
    "}",
    "<!-- VERDICT_JSON_END -->",
])

if plan_content.strip():
    lines.extend([
        "",
        "## 5. PLAN DE TRABAJO A EVALUAR",
        "```markdown",
        plan_content.strip(),
        "```",
    ])

compiled_spec = "\n".join(lines)

if as_json:
    # Ruta relativa para el manifest de orígenes
    rel_qa = os.path.relpath(qa_judge_path, repo_root) if os.path.isabs(qa_judge_path) else qa_judge_path
    rel_rev = os.path.relpath(reviewer_path, repo_root) if os.path.isabs(reviewer_path) else reviewer_path
    output_obj = {
        "spec": compiled_spec,
        "role": "qa-judge",
        "source_profiles": [rel_qa, rel_rev],
        "contract_version": "1.0.0"
    }
    sys.stdout.write(json.dumps(output_obj, indent=2, ensure_ascii=False) + "\n")
else:
    sys.stdout.write(compiled_spec + "\n")
PYEOF
