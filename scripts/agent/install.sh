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
    cp -rn "$AGENT_OS_PATH/scripts/agent/lib" "$TARGET_SCRIPTS/" 2>/dev/null || true
    chmod +x "$TARGET_SCRIPTS"/*.sh 2>/dev/null || true
    chmod +x "$TARGET_SCRIPTS"/lib/*.sh 2>/dev/null || true
    echo "✅ Scripts de agente instalados (sin sobreescribir)."
fi

# 7. Copiar templates de documentos en docs (sin sobreescribir si existen candidatos fuzzy)
if [ -d "$AGENT_OS_TEMPLATES" ]; then
    mkdir -p "$TARGET_PROJECT/docs"
    for template_path in "$AGENT_OS_TEMPLATES"/*; do
        if [ -f "$template_path" ]; then
            filename=$(basename "$template_path")
            
            existing_fuzzy=""
            if [ "$filename" = "mvp-tracker.md" ]; then
                existing_fuzzy=$( (find "$TARGET_PROJECT" -maxdepth 1 -type f \( -iname "*mvp*" -o -iname "*track*" \) 2>/dev/null; find "$TARGET_PROJECT/docs" -maxdepth 1 -type f \( -iname "*mvp*" -o -iname "*track*" \) 2>/dev/null) | head -n 1 )
            elif [ "$filename" = "implemented.md" ]; then
                existing_fuzzy=$( (find "$TARGET_PROJECT" -maxdepth 1 -type f \( -iname "*implement*" -o -iname "*hito*" -o -iname "*milestone*" \) 2>/dev/null; find "$TARGET_PROJECT/docs" -maxdepth 1 -type f \( -iname "*implement*" -o -iname "*hito*" -o -iname "*milestone*" \) 2>/dev/null) | head -n 1 )
            fi
            
            if [ -z "$existing_fuzzy" ]; then
                cp "$template_path" "$TARGET_PROJECT/docs/$filename"
            fi
        fi
    done
    echo "✅ Templates de documentación en docs/ instalados (sin sobreescribir)."
fi

# 8. Copiar templates de documentos en la raíz (sin sobreescribir si existen candidatos fuzzy)
AGENT_OS_ROOT_TEMPLATES="$AGENT_OS_PATH/templates/root"
if [ -d "$AGENT_OS_ROOT_TEMPLATES" ]; then
    for template_path in "$AGENT_OS_ROOT_TEMPLATES"/*; do
        if [ -f "$template_path" ]; then
            filename=$(basename "$template_path")
            
            existing_fuzzy=""
            if [ "$filename" = "roadmap.md" ]; then
                existing_fuzzy=$(find "$TARGET_PROJECT" -maxdepth 1 -type f \( -iname "*road*" -o -iname "*map*" \) 2>/dev/null | head -n 1)
            elif [ "$filename" = "changelog.md" ]; then
                existing_fuzzy=$(find "$TARGET_PROJECT" -maxdepth 1 -type f \( -iname "*change*" -o -iname "*log*" -o -iname "*history*" \) 2>/dev/null | head -n 1)
            fi
            
            if [ -z "$existing_fuzzy" ]; then
                cp "$template_path" "$TARGET_PROJECT/$filename"
            fi
        fi
    done
    echo "✅ Templates de documentación en la raíz instalados (sin sobreescribir)."
fi

echo "✨ Instalación de Agent OS completada en $TARGET_PROJECT"
echo "💡 Recuerda configurar el AGENT_ONBOARDING.md del proyecto."
