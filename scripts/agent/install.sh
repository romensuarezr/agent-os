#!/bin/bash

# install.sh - Instala Agent OS en un proyecto destino
# Uso: ./install.sh /ruta/al/proyecto

TARGET_PROJECT=$1

if [ -z "$TARGET_PROJECT" ]; then
    echo "❌ Error: Debes proporcionar la ruta al proyecto destino."
    echo "Uso: ./install.sh /home/romen/Proyectos/mi-proyecto"
    exit 1
fi

if [ ! -d "$TARGET_PROJECT" ]; then
    echo "❌ Error: El directorio destino no existe: $TARGET_PROJECT"
    exit 1
fi

AGENT_OS_PATH="/home/romen/Proyectos/agent-os"
AGENT_OS_RULES="$AGENT_OS_PATH/.agents/rules/global"
AGENT_OS_WORKFLOWS="$AGENT_OS_PATH/.agents/workflows"
AGENT_OS_SKILLS="$AGENT_OS_PATH/.agents/skills"
AGENT_OS_TEMPLATES="$AGENT_OS_PATH/templates/docs"

TARGET_AGENTS="$TARGET_PROJECT/.agents"
TARGET_RULES="$TARGET_AGENTS/rules"
TARGET_WORKFLOWS="$TARGET_AGENTS/workflows"
TARGET_SKILLS="$TARGET_AGENTS/skills"
TARGET_SCRIPTS="$TARGET_PROJECT/scripts/agent"

echo "🚀 Instalando Agent OS en $TARGET_PROJECT..."

# 1. Crear estructura de agentes y scripts
mkdir -p "$TARGET_RULES"
mkdir -p "$TARGET_WORKFLOWS"
mkdir -p "$TARGET_SKILLS"
mkdir -p "$TARGET_SCRIPTS"

# 2. Crear estructura de documentación
mkdir -p "$TARGET_PROJECT/docs/sprints"
mkdir -p "$TARGET_PROJECT/docs/adrs"
mkdir -p "$TARGET_PROJECT/docs/idea-inbox"
mkdir -p "$TARGET_PROJECT/docs/external-inbox"

# 3. Copiar reglas globales (plano)
if [ -d "$AGENT_OS_RULES" ]; then
    cp "$AGENT_OS_RULES"/*.md "$TARGET_RULES/"
    echo "✅ Reglas globales instaladas."
fi

# 4. Copiar workflows (sin sobreescribir)
if [ -d "$AGENT_OS_WORKFLOWS" ]; then
    cp -n "$AGENT_OS_WORKFLOWS"/*.md "$TARGET_WORKFLOWS/"
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
    cp -n "$AGENT_OS_PATH/scripts/agent"/*.sh "$TARGET_SCRIPTS/"
    chmod +x "$TARGET_SCRIPTS"/*.sh
    echo "✅ Scripts de agente instalados (sin sobreescribir)."
fi

# 7. Copiar templates de documentos (sin sobreescribir)
if [ -d "$AGENT_OS_TEMPLATES" ]; then
    # Copiar recursivamente sin sobreescribir archivos existentes
    # Usamos un truco con cp -n y subcarpetas
    cp -rn "$AGENT_OS_TEMPLATES/"* "$TARGET_PROJECT/docs/"
    echo "✅ Templates de documentación instalados (sin sobreescribir)."
fi

echo "✨ Instalación de Agent OS completada en $TARGET_PROJECT"
echo "💡 Recuerda configurar el AGENT_ONBOARDING.md del proyecto."
