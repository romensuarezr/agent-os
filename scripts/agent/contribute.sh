#!/bin/bash

# contribute.sh - Promoción inversa: de proyecto local a Agent OS
# Uso: ./scripts/agent/contribute.sh /ruta/proyecto nombre-archivo.md [--workflow|--skill]

PROJECT_PATH=$1
FILE_NAME=$2
TYPE=$3

AGENT_OS_PATH="/home/romen/Proyectos/agent-os"

if [ -z "$PROJECT_PATH" ] || [ -z "$FILE_NAME" ]; then
    echo "❌ Error: Faltan argumentos."
    echo "Uso: ./scripts/agent/contribute.sh /ruta/proyecto nombre-archivo.md [--workflow|--skill]"
    exit 1
fi

case $TYPE in
    --workflow)
        SRC_DIR="$PROJECT_PATH/.agents/workflows"
        DEST_DIR="$AGENT_OS_PATH/.agents/workflows"
        TYPE_NAME="workflow"
        ;;
    --skill)
        SRC_DIR="$PROJECT_PATH/.agents/skills"
        DEST_DIR="$AGENT_OS_PATH/.agents/skills"
        TYPE_NAME="skill"
        ;;
    *)
        SRC_DIR="$PROJECT_PATH/.agents/rules"
        DEST_DIR="$AGENT_OS_PATH/.agents/rules/global"
        TYPE_NAME="rule"
        ;;
esac

if [ ! -f "$SRC_DIR/$FILE_NAME" ]; then
    echo "❌ Error: El archivo no existe en el proyecto: $SRC_DIR/$FILE_NAME"
    exit 1
fi

mkdir -p "$DEST_DIR"
cp "$SRC_DIR/$FILE_NAME" "$DEST_DIR/"

echo "🚀 Promoviendo $FILE_NAME desde $PROJECT_PATH..."

cd "$AGENT_OS_PATH"
git add .
git commit -m "feat: promote $FILE_NAME ($TYPE_NAME) from $(basename "$PROJECT_PATH")"

echo "✅ Promovido. Ejecuta sync.sh en los otros proyectos para propagar."
