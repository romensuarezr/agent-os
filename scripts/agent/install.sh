#!/usr/bin/env bash
set -euo pipefail

# install.sh - Instala Agent OS en un proyecto destino
# Uso: ./install.sh [opciones] /ruta/al/proyecto
# Uso (bootstrapping del core): ./install.sh . --self
# Uso (simulación / dry-run): ./install.sh --check /ruta/al/proyecto

TARGET_PROJECT=""
SELF_MODE=false
CHECK_MODE=false
CREATE_REPO=false

for arg in "$@"; do
    case "$arg" in
        --self)
            SELF_MODE=true
            ;;
        --check)
            CHECK_MODE=true
            ;;
        --create-repo)
            CREATE_REPO=true
            ;;
        -h|--help)
            echo "Uso: install.sh [opciones] /ruta/al/proyecto"
            echo "Opciones:"
            echo "  --check        Modo simulación (dry-run): valida pre-flights y describe qué se instalaría sin tocar disco."
            echo "  --self         Modo self-hosted: bootstrapping del propio core (omite copiar scripts sobre sí mismos)."
            echo "  --create-repo  Requiere autenticación con GitHub CLI ('gh auth status') para operaciones remotas."
            exit 0
            ;;
        *)
            if [ -z "$TARGET_PROJECT" ]; then
                TARGET_PROJECT="$arg"
            fi
            ;;
    esac
done

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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_CORE="$(cd "$SCRIPT_DIR/../.." && pwd)"
AGENT_OS_PATH="${AGENT_OS_PATH:-$DEFAULT_CORE}"
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

    echo "  🛠️  Skills a instalar (sin sobreescribir):"
    if [ -d "$AGENT_OS_SKILLS" ]; then
        for skill in "$AGENT_OS_SKILLS"/*; do
            [ -e "$skill" ] || continue
            sname=$(basename "$skill")
            if [ -e "$TARGET_SKILLS/$sname" ]; then
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
        cp "$rule" "$TARGET_RULES/"
    done
    echo "✅ Reglas globales instaladas."
fi

# 4. Copiar workflows (sin sobreescribir)
if [ -d "$AGENT_OS_WORKFLOWS" ]; then
    for wf in "$AGENT_OS_WORKFLOWS"/*.md; do
        [ -f "$wf" ] || continue
        cp -n "$wf" "$TARGET_WORKFLOWS/"
    done
    echo "✅ Workflows instalados (sin sobreescribir)."
fi

# 5. Copiar skills (sin sobreescribir las existentes del proyecto destino)
if [ -d "$AGENT_OS_SKILLS" ]; then
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
