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

AGENT_OS_RULES="/home/romen/Proyectos/agent-os/.agents/rules/global"
TARGET_RULES="$TARGET_PROJECT/.agents/rules"

echo "🔄 Sincronizando Agent OS con $TARGET_PROJECT..."

if [ ! -d "$TARGET_RULES" ]; then
    echo "⚠️ La carpeta $TARGET_RULES no existe. ¿Has ejecutado install.sh primero?"
    exit 1
fi

# Sincronizar solo los archivos que existen en Agent OS (sin borrar locales)
for rule in "$AGENT_OS_RULES"/*.md; do
    filename=$(basename "$rule")
    cp "$rule" "$TARGET_RULES/$filename"
    echo "  [sync] $filename"
done

echo "✅ Sincronización completada."
