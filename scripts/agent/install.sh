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

AGENT_OS_RULES="/home/romen/Proyectos/agent-os/.agents/rules/global"
TARGET_RULES="$TARGET_PROJECT/.agents/rules"

echo "🚀 Instalando Agent OS en $TARGET_PROJECT..."

# Crear carpeta .agents/rules si no existe
mkdir -p "$TARGET_RULES"

# Copiar reglas globales de forma plana
cp "$AGENT_OS_RULES"/*.md "$TARGET_RULES/"

echo "✅ Reglas globales instaladas en $TARGET_RULES"
echo "💡 Recuerda configurar el AGENT_ONBOARDING.md del proyecto."
