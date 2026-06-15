#!/bin/bash

# sync.sh - Sincroniza las reglas globales de Agent OS con un proyecto
# Uso: ./sync.sh /ruta/al/proyecto

TARGET_PROJECT=$1

if [ -z "$TARGET_PROJECT" ]; then
    echo "❌ Error: Debes proporcionar la ruta al proyecto destino."
    echo "Uso: ./sync.sh /home/romen/Proyectos/mi-proyecto"
    exit 1
fi

if [ ! -d "$TARGET_PROJECT" ]; then
    echo "❌ Error: El directorio destino no existe: $TARGET_PROJECT"
    exit 1
fi

AGENT_OS_PATH="/home/romen/Proyectos/agent-os"
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
        echo "⚠️  AGENT OS CORE: El núcleo tiene actualizaciones pendientes en GitHub."
        echo "   Haz 'git pull' en $AGENT_OS_PATH y vuelve a ejecutar sync.sh."
        echo "---"
    fi
fi

if [ ! -d "$TARGET_RULES" ]; then
    echo "⚠️ La carpeta $TARGET_RULES no existe. ¿Has ejecutado install.sh primero?"
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
