#!/usr/bin/env bash
set -euo pipefail

# install.sh - Instala Agent OS en un proyecto destino
# Uso: ./install.sh [opciones] /ruta/al/proyecto
# Uso (bootstrapping del core): ./install.sh . --self
# Uso (simulación / dry-run): ./install.sh --check /ruta/al/proyecto
# Uso (instalación mínima): ./install.sh --minimal /ruta/al/proyecto
# Uso (instalación completa): ./install.sh --full /ruta/al/proyecto

TARGET_PROJECT=""
SELF_MODE=false
CHECK_MODE=false
CREATE_REPO=false
MINIMAL_MODE=false
FULL_MODE=false
REQUESTED_TAG=""

while [ $# -gt 0 ]; do
    case "$1" in
        --self)
            SELF_MODE=true
            shift
            ;;
        --check)
            CHECK_MODE=true
            shift
            ;;
        --minimal)
            MINIMAL_MODE=true
            shift
            ;;
        --full)
            FULL_MODE=true
            shift
            ;;
        --create-repo)
            CREATE_REPO=true
            shift
            ;;
        --tag)
            if [ -n "${2:-}" ]; then
                REQUESTED_TAG="$2"
                shift 2
            else
                echo "❌ Error: La opción --tag requiere un valor (ej: --tag v1.11.0)." >&2
                exit 1
            fi
            ;;
        --tag=*)
            REQUESTED_TAG="${1#*=}"
            shift
            ;;
        -h|--help)
            echo "Uso: install.sh [opciones] /ruta/al/proyecto"
            echo "Opciones:"
            echo "  --tag <version> Pinear la instalación a un release tag específico (ej: v1.11.0)."
            echo "  --minimal      Instala únicamente el conjunto base universal de habilidades."
            echo "  --full         Instala todas las habilidades (incluyendo stack e infraestructura)."
            echo "  --check        Modo simulación (dry-run): valida pre-flights y describe qué se instalaría sin tocar disco."
            echo "  --self         Modo self-hosted: bootstrapping del propio core (omite copiar scripts sobre sí mismos)."
            echo "  --create-repo  Requiere autenticación con GitHub CLI ('gh auth status') para operaciones remotas."
            exit 0
            ;;
        *)
            if [ -z "$TARGET_PROJECT" ]; then
                TARGET_PROJECT="$1"
            fi
            shift
            ;;
    esac
done

if [[ "$MINIMAL_MODE" == true && "$FULL_MODE" == true ]]; then
    echo "❌ Error: Las opciones --minimal y --full son mutuamente excluyentes." >&2
    exit 1
fi

if [[ "$SELF_MODE" == true && -z "$TARGET_PROJECT" ]]; then
    TARGET_PROJECT="."
fi

# ==============================================================================
# PRE-FLIGHTS DETERMINISTAS (BLOQUE UNIFICADO)
# ==============================================================================
PREFLIGHT_FAIL=false

# 1. Dependencias esenciales del sistema (bloqueantes)
for cmd in git cp mkdir; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "❌ Error: Dependencia requerida '$cmd' no encontrada." >&2
        echo "💡 Guía: Instálala mediante: apt-get install -y $cmd (Linux) o brew install $cmd (macOS)." >&2
        PREFLIGHT_FAIL=true
    fi
done

# 2. GitHub CLI (gh) - bloqueante solo si --create-repo, advertencia/nota en otros casos
if command -v gh >/dev/null 2>&1; then
    if ! gh auth status >/dev/null 2>&1; then
        if [ "$CREATE_REPO" = true ]; then
            echo "❌ Error: GitHub CLI ('gh') está instalado pero NO autenticado, y se requirió --create-repo." >&2
            echo "💡 Guía: Ejecuta 'gh auth login' antes de continuar con la creación del repositorio remoto." >&2
            PREFLIGHT_FAIL=true
        else
            echo "⚠️  Advertencia: 'gh' está instalado pero no autenticado. Operaciones remotas requerirán 'gh auth login'." >&2
        fi
    else
        echo "✅ GitHub CLI ('gh') autenticado." >&2
    fi
else
    if [ "$CREATE_REPO" = true ]; then
        echo "❌ Error: Dependencia requerida 'gh' no encontrada para --create-repo." >&2
        echo "💡 Guía: Instala GitHub CLI: https://cli.github.com/ o ejecuta apt-get install gh / brew install gh." >&2
        PREFLIGHT_FAIL=true
    else
        echo "ℹ️  Nota: 'gh' no está instalado en PATH. Operaciones remotas con GitHub CLI no estarán disponibles." >&2
    fi
fi

# 3. Infisical CLI (no bloqueante, diagnóstico con guía)
if command -v infisical >/dev/null 2>&1; then
    if infisical export --env=dev --dry-run >/dev/null 2>&1 || infisical user get >/dev/null 2>&1; then
        echo "✅ Infisical CLI detectado y con sesión activa." >&2
    else
        echo "⚠️  Advertencia: Infisical CLI instalado pero sin sesión activa detectada." >&2
        echo "💡 Guía: Ejecuta 'infisical login' o inyecta variables vía .env / INFISICAL_TOKEN para gestión centralizada de secretos." >&2
    fi
else
    echo "ℹ️  Nota: 'infisical' CLI no encontrado en PATH. Para sincronización centralizada de secretos, consulta https://infisical.com" >&2
fi

# Abortar si algún pre-flight bloqueante falló (aplica tanto a modo normal como a --check)
if [ "$PREFLIGHT_FAIL" = true ]; then
    echo "❌ Fallo en pre-flights bloqueantes. Abortando." >&2
    exit 1
fi

if [ -z "$TARGET_PROJECT" ]; then
    echo "❌ ERROR: Debes proporcionar la ruta al proyecto destino." >&2
    echo "💡 Guía: bash scripts/agent/install.sh /ruta/al/proyecto (o usa --self si es bootstrapping del core)." >&2
    exit 1
fi

# Pre-flight de comprobación de permisos de escritura en destino (SCR-B4)
if [ -d "$TARGET_PROJECT" ]; then
    if [ ! -w "$TARGET_PROJECT" ]; then
        echo "❌ ERROR: Sin permisos de escritura en el directorio destino: $TARGET_PROJECT" >&2
        echo "💡 Guía: Verifica los permisos de usuario sobre el directorio antes de instalar." >&2
        exit 1
    fi
else
    TARGET_PARENT="$(dirname "$TARGET_PROJECT")"
    if [ ! -d "$TARGET_PARENT" ] || [ ! -w "$TARGET_PARENT" ]; then
        echo "❌ ERROR: No se puede crear el directorio destino (sin permisos de escritura en: $TARGET_PARENT)." >&2
        echo "💡 Guía: Crea el directorio con permisos adecuados o instala en una ruta con permisos de escritura." >&2
        exit 1
    fi
fi

_has_local_core_assets() {
    local path="${1:-}"
    [ -n "$path" ] && [ -d "$path/.agents" ] && [ -f "$path/scripts/agent/install.sh" ]
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
DEFAULT_CORE=""
if [ -n "$SCRIPT_DIR" ]; then
    DEFAULT_CORE="$(cd "$SCRIPT_DIR/../.." 2>/dev/null && pwd || true)"
fi
AGENT_OS_PATH="${AGENT_OS_PATH:-$DEFAULT_CORE}"

# Leer VERSION canónica si está disponible localmente
CANONICAL_VERSION_FILE=""
if [ -f "$AGENT_OS_PATH/VERSION" ]; then
    CANONICAL_VERSION_FILE="$AGENT_OS_PATH/VERSION"
elif [ -n "$DEFAULT_CORE" ] && [ -f "$DEFAULT_CORE/VERSION" ]; then
    CANONICAL_VERSION_FILE="$DEFAULT_CORE/VERSION"
fi

LOCAL_CANONICAL_VERSION=""
if [ -n "$CANONICAL_VERSION_FILE" ]; then
    LOCAL_CANONICAL_VERSION=$(tr -d '[:space:]' < "$CANONICAL_VERSION_FILE" 2>/dev/null || true)
fi

# Determinar tag canónico a utilizar:
# 1. Flag --tag explícito
# 2. Variable de entorno AGENT_OS_TAG
# 3. Archivo VERSION local (si corre desde clon del core)
# 4. Fallback canónico de seguridad (v1.11.0)
TAG="${REQUESTED_TAG:-${AGENT_OS_TAG:-}}"
if [ -z "$TAG" ]; then
    if [ -n "$LOCAL_CANONICAL_VERSION" ]; then
        TAG="v${LOCAL_CANONICAL_VERSION#v}"
    else
        TAG="v1.11.0"
    fi
fi

# Advertir si se especificaron ramas flotantes en lugar de tags inmutables
if [[ "$TAG" == "main" || "$TAG" == "master" || "$TAG" == "latest" ]]; then
    echo "⚠️  ADVERTENCIA: Se especificó '$TAG'. Para garantizar reproducibilidad y estabilidad, se recomienda pinear siempre a un tag de release inmutable (ej: v1.11.0)." >&2
fi

EPHEMERAL_CORE=false
TEMP_CORE_DIR=""

# Si no tenemos los assets locales de Agent OS (ej. ejecutado vía `curl ... | bash`):
if ! _has_local_core_assets "$AGENT_OS_PATH"; then
    CORE_REPO_URL="${AGENT_OS_CORE_URL:-https://github.com/romensuarezr/agent-os.git}"
    TEMP_CORE_DIR=$(mktemp -d -t agent-os-core-XXXXXX)
    EPHEMERAL_CORE=true

    # Registro de trampa determinista para garantizar limpieza de assets efímeros
    trap 'if [ "$EPHEMERAL_CORE" = true ] && [ -d "$TEMP_CORE_DIR" ]; then rm -rf "$TEMP_CORE_DIR"; fi' EXIT INT TERM

    echo "📥 Aprovisionando assets del núcleo Agent OS ($TAG) desde $CORE_REPO_URL..." >&2

    DOWNLOAD_OK=false
    if command -v git >/dev/null 2>&1; then
        if git clone --depth 1 --branch "$TAG" "$CORE_REPO_URL" "$TEMP_CORE_DIR" >/dev/null 2>&1; then
            DOWNLOAD_OK=true
        fi
    fi

    if [ "$DOWNLOAD_OK" = false ] && command -v curl >/dev/null 2>&1 && command -v tar >/dev/null 2>&1; then
        TARBALL_URL="https://github.com/romensuarezr/agent-os/archive/refs/tags/${TAG}.tar.gz"
        if curl -fsSL "$TARBALL_URL" 2>/dev/null | tar -xz -C "$TEMP_CORE_DIR" --strip-components=1 2>/dev/null; then
            DOWNLOAD_OK=true
        fi
    fi

    if [ "$DOWNLOAD_OK" = true ] && _has_local_core_assets "$TEMP_CORE_DIR"; then
        AGENT_OS_PATH="$TEMP_CORE_DIR"
        echo "✅ Núcleo Agent OS ($TAG) aprovisionado temporalmente para la instalación." >&2
    else
        echo "❌ ERROR: No se pudieron obtener los assets del núcleo de Agent OS para el tag '$TAG'." >&2
        echo "💡 Guía: Verifica tu conexión a internet o especifica un repositorio/directorio válido mediante AGENT_OS_PATH o AGENT_OS_CORE_URL." >&2
        exit 1
    fi
fi
AGENT_OS_RULES="$AGENT_OS_PATH/.agents/rules/global"
AGENT_OS_WORKFLOWS="$AGENT_OS_PATH/.agents/workflows"
AGENT_OS_SKILLS="$AGENT_OS_PATH/.agents/skills"
AGENT_OS_PROFILES="$AGENT_OS_PATH/.agents/profiles"
AGENT_OS_GOALS="$AGENT_OS_PATH/templates/goals"
AGENT_OS_TEMPLATES="$AGENT_OS_PATH/templates/docs"
AGENT_OS_ROOT_TEMPLATES="$AGENT_OS_PATH/templates/root"
PROJECT_ONBOARDING_SRC="$AGENT_OS_PATH/.agents/templates/AGENT_ONBOARDING.project.md"

TARGET_AGENTS="$TARGET_PROJECT/.agents"
TARGET_RULES="$TARGET_AGENTS/rules"
TARGET_WORKFLOWS="$TARGET_AGENTS/workflows"
TARGET_SKILLS="$TARGET_AGENTS/skills"
TARGET_PROFILES="$TARGET_PROJECT/.agents/profiles"
TARGET_GOALS="$TARGET_PROJECT/templates/goals"
TARGET_SCRIPTS="$TARGET_PROJECT/scripts/agent"
TARGET_ONBOARDING="$TARGET_PROJECT/.agents/AGENT_ONBOARDING.md"

# ==============================================================================
# DETECCIÓN DE STACK Y RESOLUCIÓN SELECTIVA DE HABILIDADES (T-076)
# ==============================================================================
DETECTED_STACK="unknown"
HAS_NEXTJS=false
if [ -f "$AGENT_OS_PATH/scripts/agent/lib/detect-stack.sh" ]; then
    # shellcheck disable=SC1090
    source "$AGENT_OS_PATH/scripts/agent/lib/detect-stack.sh"
    if [ -d "$TARGET_PROJECT" ]; then
        detect_stack "$TARGET_PROJECT"
        DETECTED_STACK="$AGENT_OS_STACK"
    fi
fi

if [ -f "$TARGET_PROJECT/package.json" ] && grep -q '"next"' "$TARGET_PROJECT/package.json" 2>/dev/null; then
    HAS_NEXTJS=true
elif compgen -G "$TARGET_PROJECT/next.config.*" >/dev/null 2>&1; then
    HAS_NEXTJS=true
fi

SKILL_MODE="recommended"
if [ "$MINIMAL_MODE" = true ]; then
    SKILL_MODE="minimal"
elif [ "$FULL_MODE" = true ]; then
    SKILL_MODE="full"
fi

resolve_skills_from_manifest() {
    local manifest="$1"
    local mode="$2"
    local stack="$3"
    local has_nextjs="$4"

    if command -v python3 >/dev/null 2>&1 && python3 -c "import yaml" >/dev/null 2>&1; then
        python3 - "$manifest" "$mode" "$stack" "$has_nextjs" <<'EOF'
import os, sys, yaml

manifest_path = sys.argv[1]
mode = sys.argv[2]
stack = sys.argv[3].lower()
has_nextjs = sys.argv[4].lower() == "true"

if not os.path.isfile(manifest_path):
    sys.exit(0)

with open(manifest_path, "r", encoding="utf-8") as f:
    data = yaml.safe_load(f) or {}

skills = data.get("skills", {})
for sname, sdata in skills.items():
    scope = sdata.get("scope", "universal")
    stacks = [str(x).lower() for x in sdata.get("stacks", [])]
    infra = [str(x).lower() for x in sdata.get("infra", [])]
    
    include = False
    tag = scope
    reason = "Habilidad base universal"

    if mode == "minimal":
        if scope == "universal":
            include = True
    elif mode == "full":
        include = True
        if scope == "stack":
            tag = f"stack: {','.join(stacks)}"
            reason = f"Específica de stack ({', '.join(stacks)})"
        elif scope == "infra":
            tag = f"infra: {','.join(infra)}"
            reason = f"Específica de infra ({', '.join(infra)})"
    else: # recommended / default
        if scope == "universal":
            include = True
        elif scope == "stack":
            if has_nextjs and "nextjs" in stacks:
                include = True
                tag = "stack: nextjs"
                reason = "Detectado framework Next.js en proyecto destino"
            elif stack in stacks:
                include = True
                tag = f"stack: {stack}"
                reason = f"Detectado stack {stack} en proyecto destino"
        elif scope == "infra":
            pass

    if include:
        print(f"{sname}|{tag}|{reason}")
EOF
    else
        if [ "$mode" = "recommended" ]; then
            echo "⚠️  Aviso: python3 con módulo 'yaml' (PyYAML) no disponible. Degradando a resolución awk (el emparejamiento avanzado por stack es limitado; se seleccionarán habilidades universales)." >&2
        fi
        awk -v m="$mode" '
            /^  [a-zA-Z0-9_-]+:/ {
                gsub(/^  |:$/, "", $1)
                curr = $1
            }
            /scope: universal/ {
                print curr "|universal|Habilidad base universal"
            }
            /scope: (stack|infra)/ && m == "full" {
                print curr "|especifica|Específica de stack/infra"
            }
        ' "$manifest"
    fi
}

# ==============================================================================
# MODO --check (DRY-RUN / SIMULACIÓN SIN TOCAR DISCO)
# ==============================================================================
if [[ "$CHECK_MODE" == true ]]; then
    echo "🔍 [CHECK] Modo simulación activo. Evaluando instalación en: $TARGET_PROJECT"
    if [ -d "$TARGET_PROJECT" ]; then
        echo "  📁 Directorio destino existe: $TARGET_PROJECT"
    else
        echo "  📁 Directorio destino NO existe: se crearía $TARGET_PROJECT"
    fi

    echo "  📁 Estructura de carpetas a verificar/crear:"
    echo "     - $TARGET_RULES"
    echo "     - $TARGET_WORKFLOWS"
    echo "     - $TARGET_SKILLS"
    echo "     - $TARGET_PROFILES"
    echo "     - $TARGET_GOALS"
    echo "     - $TARGET_PROJECT/.agents/context"
    echo "     - $TARGET_SCRIPTS"
    echo "     - $TARGET_PROJECT/docs/sprints"
    echo "     - $TARGET_PROJECT/docs/adrs"
    echo "     - $TARGET_PROJECT/docs/idea-inbox"
    echo "     - $TARGET_PROJECT/docs/external-inbox"

    if [[ "$SELF_MODE" == true ]]; then
        echo "  🔄 Modo self-hosted detectado: solo carpetas operativas (scripts omitidos)."
        echo "✅ [CHECK] Verificación completada con éxito. Cero cambios en disco."
        exit 0
    fi

    echo "  📄 Reglas globales a instalar:"
    if [ -d "$AGENT_OS_RULES" ]; then
        for rule in "$AGENT_OS_RULES"/*.md; do
            [ -f "$rule" ] || continue
            rname=$(basename "$rule")
            if [ -f "$TARGET_RULES/$rname" ]; then
                echo "     - $rname (ya existe en destino)"
            else
                echo "     + $rname (nueva)"
            fi
        done
    fi

    echo "  ⚡ Workflows a instalar (sin sobreescribir):"
    if [ -d "$AGENT_OS_WORKFLOWS" ]; then
        for wf in "$AGENT_OS_WORKFLOWS"/*.md; do
            [ -f "$wf" ] || continue
            wname=$(basename "$wf")
            if [ -f "$TARGET_WORKFLOWS/$wname" ]; then
                echo "     - $wname (ya existe en destino)"
            else
                echo "     + $wname (nuevo)"
            fi
        done
    fi

    echo "  🛠️  Skills a instalar (modo: $SKILL_MODE, stack detectado: $DETECTED_STACK):"
    MANIFEST_FILE="$AGENT_OS_PATH/.agents/config/skills-manifest.yaml"
    if [ ! -f "$MANIFEST_FILE" ] && [ -f "$AGENT_OS_PATH/config/skills-manifest.yaml" ]; then
        echo "⚠️  DEPRECATED: $AGENT_OS_PATH/config/skills-manifest.yaml es una ruta obsoleta. Migrar a .agents/config/skills-manifest.yaml" >&2
        MANIFEST_FILE="$AGENT_OS_PATH/config/skills-manifest.yaml"
    fi
    if [ -f "$MANIFEST_FILE" ]; then
        while IFS="|" read -r sname stag sreason; do
            [ -n "$sname" ] || continue
            if [ -e "$TARGET_SKILLS/$sname" ] || [ -e "$TARGET_SKILLS/${sname}.md" ]; then
                echo "     - skill: $sname [$stag] (ya existe en destino) — $sreason"
            else
                echo "     + skill: $sname [$stag] (nueva) — $sreason"
            fi
        done < <(resolve_skills_from_manifest "$MANIFEST_FILE" "$SKILL_MODE" "$DETECTED_STACK" "$HAS_NEXTJS")
    else
        for skill in "$AGENT_OS_SKILLS"/*; do
            [ -e "$skill" ] || continue
            sname=$(basename "$skill")
            if [ -e "$TARGET_SKILLS/$sname" ] || [ -e "$TARGET_SKILLS/${sname}.md" ]; then
                echo "     - skill: $sname (ya existe en destino)"
            else
                echo "     + skill: $sname (nueva)"
            fi
        done
    fi

    echo "  📜 Scripts de agente a instalar (sin sobreescribir):"
    if [ -d "$AGENT_OS_PATH/scripts/agent" ]; then
        for sc in "$AGENT_OS_PATH/scripts/agent"/*.sh; do
            [ -f "$sc" ] || continue
            scname=$(basename "$sc")
            if [ -f "$TARGET_SCRIPTS/$scname" ]; then
                echo "     - script: $scname (ya existe en destino)"
            else
                echo "     + script: $scname (nuevo)"
            fi
        done
        if [ -d "$AGENT_OS_PATH/scripts/agent/lib" ]; then
            echo "     + scripts/agent/lib (carpeta de librerías portables)"
        fi
    fi

    echo "  👤 Perfiles y templates de metas:"
    if [ -d "$AGENT_OS_PROFILES" ]; then
        for pf in "$AGENT_OS_PROFILES"/*; do
            [ -f "$pf" ] || continue
            pfname=$(basename "$pf")
            echo "     - perfil: $pfname"
        done
    fi

    echo "  📋 Onboarding de proyecto destino:"
    if [ -f "$TARGET_ONBOARDING" ]; then
        echo "     - $TARGET_ONBOARDING (ya existe en destino, no se sobreescribirá)"
    else
        echo "     + $TARGET_ONBOARDING (se instalará plantilla desde AGENT_ONBOARDING.project.md)"
    fi

    echo "  🏷️  Configuración .gitignore:"
    GITIGNORE="$TARGET_PROJECT/.gitignore"
    AGENT_OS_MARKER="# Agent OS — generated context files"
    if [ -f "$GITIGNORE" ] && grep -q "$AGENT_OS_MARKER" "$GITIGNORE" 2>/dev/null; then
        echo "     - .gitignore ya contiene bloque de Agent OS"
    else
        echo "     + .gitignore recibirá bloque de exclusiones de Agent OS"
    fi

    echo "✅ [CHECK] Verificación completada con éxito. Cero cambios en disco. El entorno está listo para instalación."
    exit 0
fi

# ==============================================================================
# MODO INSTALACIÓN ACTIVA
# ==============================================================================
if [ ! -d "$TARGET_PROJECT" ]; then
    echo "❌ ERROR: El directorio destino no existe: $TARGET_PROJECT" >&2
    echo "💡 Guía: Crea el directorio primero (ej: mkdir -p $TARGET_PROJECT) antes de instalar." >&2
    exit 1
fi

if [[ "$SELF_MODE" == true ]]; then
    echo "🔄 Modo self-hosted: bootstrapping del propio core agent-os..."
else
    echo "🚀 Instalando Agent OS en $TARGET_PROJECT..."
fi

# 1. Crear estructura de agentes y scripts
mkdir -p "$TARGET_RULES"
mkdir -p "$TARGET_WORKFLOWS"
mkdir -p "$TARGET_SKILLS"
mkdir -p "$TARGET_PROFILES"
mkdir -p "$TARGET_GOALS"
mkdir -p "$TARGET_PROJECT/.agents/context"
mkdir -p "$TARGET_PROJECT/.agents/config"
mkdir -p "$TARGET_SCRIPTS"

# 2. Crear estructura de documentación
mkdir -p "$TARGET_PROJECT/docs/sprints"
mkdir -p "$TARGET_PROJECT/docs/adrs"
mkdir -p "$TARGET_PROJECT/docs/idea-inbox"
mkdir -p "$TARGET_PROJECT/docs/external-inbox"

if [[ "$SELF_MODE" == true ]]; then
    echo "✅ Estructura de carpetas operativas creada (modo self: scripts omitidos)."
    echo "✨ Bootstrapping del core completado."
    echo "💡 Puedes verificar el estado con: bash scripts/agent/check-sprint.sh"
    exit 0
fi

# 3. Copiar reglas globales (plano)
if [ -d "$AGENT_OS_RULES" ]; then
    for rule in "$AGENT_OS_RULES"/*.md; do
        [ -f "$rule" ] || continue
        cp -n "$rule" "$TARGET_RULES/"
    done
    echo "✅ Reglas globales instaladas (sin sobreescribir)."
fi

# 4. Copiar workflows (sin sobreescribir)
if [ -d "$AGENT_OS_WORKFLOWS" ]; then
    for wf in "$AGENT_OS_WORKFLOWS"/*.md; do
        [ -f "$wf" ] || continue
        cp -n "$wf" "$TARGET_WORKFLOWS/"
    done
    echo "✅ Workflows instalados (sin sobreescribir)."
fi

# 5. Copiar skills (instalación selectiva según manifiesto)
MANIFEST_FILE="$AGENT_OS_PATH/.agents/config/skills-manifest.yaml"
if [ ! -f "$MANIFEST_FILE" ] && [ -f "$AGENT_OS_PATH/config/skills-manifest.yaml" ]; then
    echo "⚠️  DEPRECATED: $AGENT_OS_PATH/config/skills-manifest.yaml es una ruta obsoleta. Migrar a .agents/config/skills-manifest.yaml" >&2
    MANIFEST_FILE="$AGENT_OS_PATH/config/skills-manifest.yaml"
fi
if [ -f "$MANIFEST_FILE" ]; then
    if [ "$SKILL_MODE" = "recommended" ]; then
        if [ -t 0 ]; then
            echo ""
            echo "🔎 Stack detectado en destino: $DETECTED_STACK (Next.js: $HAS_NEXTJS)"
            echo "💡 Modo adaptativo: se seleccionará el conjunto de habilidades recomendado para este proyecto."
            echo -n "¿Instalar habilidades recomendadas? (S/n) [o presiona 'n' para elegir --minimal]: "
            read -r resp || resp="s"
            resp=$(echo "$resp" | tr '[:upper:]' '[:lower:]')
            if [[ "$resp" == "n" || "$resp" == "no" ]]; then
                echo -n "¿Instalar únicamente el conjunto --minimal (solo base universal)? (s/N): "
                read -r min_resp || min_resp="n"
                min_resp=$(echo "$min_resp" | tr '[:upper:]' '[:lower:]')
                if [[ "$min_resp" == "s" || "$min_resp" == "si" ]]; then
                    SKILL_MODE="minimal"
                    echo "ℹ️  Cambiando a modo --minimal (solo habilidades universales)."
                else
                    echo "❌ Instalación cancelada por el usuario."
                    exit 0
                fi
            fi
        else
            echo "ℹ️  Modo adaptativo: instalando habilidades recomendadas para stack '$DETECTED_STACK'."
        fi
    elif [ "$SKILL_MODE" = "full" ]; then
        echo "⚠️  Modo --full: se instalarán también habilidades específicas de stack (Next.js) e infra (Coolify, Infisical, SSH)."
    elif [ "$SKILL_MODE" = "minimal" ]; then
        echo "ℹ️  Modo --minimal: instalando únicamente el conjunto base universal de habilidades."
    fi

    SKILLS_COUNT=0
    while IFS="|" read -r sname stag sreason; do
        [ -n "$sname" ] || continue
        skill_src="$AGENT_OS_SKILLS/$sname"
        if [ ! -e "$skill_src" ] && [ -f "${skill_src}.md" ]; then
            skill_src="${skill_src}.md"
        fi
        if [ -d "$skill_src" ]; then
            cp -rn "$skill_src" "$TARGET_SKILLS/"
            SKILLS_COUNT=$((SKILLS_COUNT + 1))
        elif [ -f "$skill_src" ]; then
            cp -n "$skill_src" "$TARGET_SKILLS/"
            SKILLS_COUNT=$((SKILLS_COUNT + 1))
        fi
    done < <(resolve_skills_from_manifest "$MANIFEST_FILE" "$SKILL_MODE" "$DETECTED_STACK" "$HAS_NEXTJS")

    echo "✅ Skills instaladas ($SKILLS_COUNT seleccionadas en modo $SKILL_MODE, sin sobreescribir existentes)."
elif [ -d "$AGENT_OS_SKILLS" ]; then
    for skill in "$AGENT_OS_SKILLS"/*; do
        if [ -d "$skill" ]; then
            cp -rn "$skill" "$TARGET_SKILLS/"
        elif [ -f "$skill" ]; then
            cp -n "$skill" "$TARGET_SKILLS/"
        fi
    done
    echo "✅ Skills globales instaladas (sin sobreescribir)."
fi

# 6. Copiar scripts (sin sobreescribir)
if [ -d "$AGENT_OS_PATH/scripts/agent" ]; then
    for sc in "$AGENT_OS_PATH/scripts/agent"/*.sh; do
        [ -f "$sc" ] || continue
        cp -n "$sc" "$TARGET_SCRIPTS/"
    done
    if [ -d "$AGENT_OS_PATH/scripts/agent/lib" ]; then
        cp -rn "$AGENT_OS_PATH/scripts/agent/lib" "$TARGET_SCRIPTS/" 2>/dev/null || true
    fi
    chmod +x "$TARGET_SCRIPTS"/*.sh 2>/dev/null || true
    if [ -d "$TARGET_SCRIPTS/lib" ]; then
        chmod +x "$TARGET_SCRIPTS"/lib/*.sh 2>/dev/null || true
    fi
    echo "✅ Scripts de agente instalados (sin sobreescribir)."
fi

# 7. Copiar perfiles de agente (sin sobreescribir)
if [ -d "$AGENT_OS_PROFILES" ]; then
    mkdir -p "$TARGET_PROFILES"
    for profile in "$AGENT_OS_PROFILES"/*; do
        if [ -f "$profile" ]; then
            cp -n "$profile" "$TARGET_PROFILES/"
        fi
    done
    echo "✅ Perfiles de agente instalados (sin sobreescribir)."
fi

# 7b. Copiar configuraciones runtime base (excluyendo explícitamente fleet.yaml y fleet.local.yaml)
if [ -d "$AGENT_OS_PATH/.agents/config" ]; then
    mkdir -p "$TARGET_PROJECT/.agents/config"
    for cfg in "$AGENT_OS_PATH/.agents/config"/*; do
        [ -f "$cfg" ] || continue
        cfg_name=$(basename "$cfg")
        # EXCLUSIÓN CRÍTICA: Nunca copiar overlays privados de flota
        if [ "$cfg_name" = "fleet.yaml" ] || [ "$cfg_name" = "fleet.local.yaml" ]; then
            continue
        fi
        cp -n "$cfg" "$TARGET_PROJECT/.agents/config/"
    done
    echo "✅ Configuraciones runtime instaladas en .agents/config/ (overlay privado fleet.yaml excluido)."
fi

# 8. Copiar templates de metas (sin sobreescribir)
if [ -d "$AGENT_OS_GOALS" ]; then
    mkdir -p "$TARGET_GOALS"
    for goal_tmpl in "$AGENT_OS_GOALS"/*; do
        if [ -f "$goal_tmpl" ]; then
            cp -n "$goal_tmpl" "$TARGET_GOALS/"
        fi
    done
    echo "✅ Templates de metas instalados (sin sobreescribir)."
fi

# 9. Copiar templates de documentos en docs (sin sobreescribir si existen candidatos fuzzy)
if [ -d "$AGENT_OS_TEMPLATES" ]; then
    mkdir -p "$TARGET_PROJECT/docs"
    for template_path in "$AGENT_OS_TEMPLATES"/*; do
        if [ -f "$template_path" ]; then
            filename=$(basename "$template_path")
            existing_fuzzy=""
            if [ "$filename" = "mvp-tracker.md" ]; then
                existing_fuzzy=$( (find "$TARGET_PROJECT" -maxdepth 1 -type f \( -iname "*mvp*" -o -iname "*track*" \) 2>/dev/null || true; find "$TARGET_PROJECT/docs" -maxdepth 1 -type f \( -iname "*mvp*" -o -iname "*track*" \) 2>/dev/null || true) | head -n 1 || true )
            elif [ "$filename" = "implemented.md" ]; then
                existing_fuzzy=$( (find "$TARGET_PROJECT" -maxdepth 1 -type f \( -iname "*implement*" -o -iname "*hito*" -o -iname "*milestone*" \) 2>/dev/null || true; find "$TARGET_PROJECT/docs" -maxdepth 1 -type f \( -iname "*implement*" -o -iname "*hito*" -o -iname "*milestone*" \) 2>/dev/null || true) | head -n 1 || true )
            fi
            
            if [ -z "$existing_fuzzy" ] && [ ! -f "$TARGET_PROJECT/docs/$filename" ]; then
                cp "$template_path" "$TARGET_PROJECT/docs/$filename"
            fi
        fi
    done
    echo "✅ Templates de documentación en docs/ instalados (sin sobreescribir)."
fi

# 10. Copiar templates de documentos en la raíz (sin sobreescribir si existen candidatos fuzzy)
if [ -d "$AGENT_OS_ROOT_TEMPLATES" ]; then
    for template_path in "$AGENT_OS_ROOT_TEMPLATES"/*; do
        if [ -f "$template_path" ]; then
            filename=$(basename "$template_path")
            existing_fuzzy=""
            if [ "$filename" = "roadmap.md" ]; then
                existing_fuzzy=$(find "$TARGET_PROJECT" -maxdepth 1 -type f \( -iname "*road*" -o -iname "*map*" \) 2>/dev/null | head -n 1 || true)
            elif [ "$filename" = "changelog.md" ]; then
                existing_fuzzy=$(find "$TARGET_PROJECT" -maxdepth 1 -type f \( -iname "*change*" -o -iname "*log*" -o -iname "*history*" \) 2>/dev/null | head -n 1 || true)
            fi
            
            if [ -z "$existing_fuzzy" ] && [ ! -f "$TARGET_PROJECT/$filename" ]; then
                cp "$template_path" "$TARGET_PROJECT/$filename"
            fi
        fi
    done
    echo "✅ Templates de documentación en la raíz instalados (sin sobreescribir)."
fi

# 10b. Copiar plantilla de AGENT_ONBOARDING.md en .agents/ (sin sobreescribir)
if [ -f "$PROJECT_ONBOARDING_SRC" ] && [ ! -f "$TARGET_ONBOARDING" ]; then
    cp "$PROJECT_ONBOARDING_SRC" "$TARGET_ONBOARDING"
    echo "✅ Plantilla de AGENT_ONBOARDING.md instalada en .agents/ (sin sobreescribir)."
fi

# 11. Configurar .gitignore (idempotente)
GITIGNORE="$TARGET_PROJECT/.gitignore"
AGENT_OS_MARKER="# Agent OS — generated context files"

[ ! -f "$GITIGNORE" ] && touch "$GITIGNORE"

if grep -q "$AGENT_OS_MARKER" "$GITIGNORE" 2>/dev/null; then
    echo "✅ .gitignore ya contiene entradas de Agent OS."
else
    echo "" >> "$GITIGNORE"
    cat "$AGENT_OS_PATH/templates/.gitignore-agent-os" >> "$GITIGNORE"
    echo "✅ Entradas de Agent OS añadidas a .gitignore."
fi

echo "✨ Instalación de Agent OS completada en $TARGET_PROJECT"
echo "💡 Recuerda configurar el .agents/AGENT_ONBOARDING.md del proyecto."
