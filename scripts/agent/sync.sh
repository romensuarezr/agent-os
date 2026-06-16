#!/bin/bash

# sync.sh - Sincroniza las reglas globales de Agent OS con un proyecto
# Uso: ./sync.sh /ruta/al/proyecto

TARGET_PROJECT=$1

if [ -z "$TARGET_PROJECT" ]; then
    RED='\033[0;31m'
    NC='\033[0m'
    echo -e "${RED}❌ ERROR: Debes proporcionar la ruta al proyecto destino.${NC}"
    echo -e "${RED}Guía: Proporciona la ruta al directorio destino (ej: bash scripts/agent/sync.sh ../otro-proyecto).${NC}"
    exit 1
fi

if [ ! -d "$TARGET_PROJECT" ]; then
    RED='\033[0;31m'
    NC='\033[0m'
    echo -e "${RED}❌ ERROR: El directorio destino no existe: $TARGET_PROJECT${NC}"
    echo -e "${RED}Guía: Verifica la ruta provista y asegúrate de que el proyecto existe antes de sincronizar.${NC}"
    exit 1
fi

AGENT_OS_PATH="/home/romen/Proyectos/agent-os"

# Validar que no se intente sincronizar el core sobre sí mismo
REAL_AGENT_OS=$(realpath "$AGENT_OS_PATH" 2>/dev/null || echo "$AGENT_OS_PATH")
REAL_TARGET=$(realpath "$TARGET_PROJECT" 2>/dev/null || echo "$TARGET_PROJECT")

if [ "$REAL_AGENT_OS" = "$REAL_TARGET" ]; then
    RED='\033[0;31m'
    NC='\033[0m'
    echo -e "${RED}❌ ERROR: AGENT_OS_PATH y TARGET_PROJECT apuntan al mismo directorio.${NC}"
    echo -e "${RED}Guía: sync.sh sincroniza el core hacia proyectos hijos, nunca sobre sí mismo.${NC}"
    echo -e "${RED}Abortando.${NC}"
    exit 1
fi

AGENT_OS_RULES="$AGENT_OS_PATH/.agents/rules/global"
AGENT_OS_SCRIPTS="$AGENT_OS_PATH/scripts/agent"
AGENT_OS_SKILLS="$AGENT_OS_PATH/.agents/skills"
TARGET_RULES="$TARGET_PROJECT/.agents/rules"
TARGET_SCRIPTS="$TARGET_PROJECT/scripts/agent"
TARGET_SKILLS="$TARGET_PROJECT/.agents/skills"

echo "🔄 Sincronizando Agent OS con $TARGET_PROJECT..."

# Comprobar actualizaciones de Agent OS Core remoto
if [ -d "$AGENT_OS_PATH/.git" ]; then
    AGENT_OS_LOCAL=$(git -C "$AGENT_OS_PATH" rev-parse HEAD 2>/dev/null)
    AGENT_OS_REMOTE=$(timeout 3 git -C "$AGENT_OS_PATH" ls-remote origin HEAD 2>/dev/null | cut -f1)
    if [[ -n "$AGENT_OS_REMOTE" && "$AGENT_OS_LOCAL" != "$AGENT_OS_REMOTE" ]]; then
        YELLOW='\033[0;33m'
        NC='\033[0m'
        echo -e "${YELLOW}⚠️  WARNING: AGENT OS CORE: El núcleo tiene actualizaciones pendientes en GitHub.${NC}"
        echo -e "${YELLOW}Guía: Haz 'git pull' en $AGENT_OS_PATH para tener la última versión del core antes de sincronizar.${NC}"
        echo "---"
    fi
fi

if [ ! -d "$TARGET_RULES" ]; then
    RED='\033[0;31m'
    NC='\033[0m'
    echo -e "${RED}❌ ERROR: La carpeta $TARGET_RULES no existe.${NC}"
    echo -e "${RED}Guía: Ejecuta 'bash scripts/agent/install.sh $TARGET_PROJECT' primero para configurar la estructura base.${NC}"
    exit 1
fi

# Sincronizar solo los archivos que existen en Agent OS (sin borrar locales)
echo "  Sincronizando reglas..."
for rule in "$AGENT_OS_RULES"/*.md; do
    filename=$(basename "$rule")
    cp "$rule" "$TARGET_RULES/$filename"
    echo "    [sync] $filename"
done

if [ -d "$TARGET_PROJECT/.agents/workflows" ]; then
    echo "  Sincronizando workflows..."
    AGENT_OS_WORKFLOWS="$AGENT_OS_PATH/.agents/workflows"
    TARGET_WORKFLOWS="$TARGET_PROJECT/.agents/workflows"
    for wf in "$AGENT_OS_WORKFLOWS"/*.md; do
        filename=$(basename "$wf")
        cp -n "$wf" "$TARGET_WORKFLOWS/$filename"
        echo "    [sync] $filename"
    done
fi

if [ -d "$TARGET_SCRIPTS" ]; then
    echo "  Sincronizando scripts..."
    for script in "$AGENT_OS_SCRIPTS"/*.sh; do
        filename=$(basename "$script")
        cp "$script" "$TARGET_SCRIPTS/$filename"
        chmod +x "$TARGET_SCRIPTS/$filename"
        echo "    [sync] $filename"
    done
    if [ -d "$AGENT_OS_SCRIPTS/lib" ]; then
        cp -r "$AGENT_OS_SCRIPTS/lib" "$TARGET_SCRIPTS/" 2>/dev/null || true
        chmod +x "$TARGET_SCRIPTS"/lib/*.sh 2>/dev/null || true
        echo "    [sync] folder: lib"
    fi
fi

if [ -d "$AGENT_OS_SKILLS" ]; then
    echo "  Sincronizando skills..."
    mkdir -p "$TARGET_SKILLS"
    for skill in "$AGENT_OS_SKILLS"/*; do
        if [ -d "$skill" ]; then
            skill_name=$(basename "$skill")
            # Copiar la skill de agent-os al proyecto (fusionando/sobrescribiendo)
            cp -r "$skill" "$TARGET_SKILLS/"
            echo "    [sync] skill: $skill_name"
        elif [ -f "$skill" ]; then
            filename=$(basename "$skill")
            cp "$skill" "$TARGET_SKILLS/$filename"
            echo "    [sync] skill file: $filename"
        fi
    done
fi

# Copiar changelog del core a .agents/context/agent-os-changelog.md
mkdir -p "$TARGET_PROJECT/.agents/context"
if [ -f "$AGENT_OS_PATH/changelog.md" ]; then
    cp "$AGENT_OS_PATH/changelog.md" "$TARGET_PROJECT/.agents/context/agent-os-changelog.md"
    echo "  Sincronizando changelog del core..."
fi

# Guardar marca de fecha de última sincronización
echo "$(date -u +%Y-%m-%d)" > "$TARGET_PROJECT/.agents/context/last-sync.md"

echo "✅ Sincronización completada."
