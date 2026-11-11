#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/lib/project-harness.sh — Proyección determinista multi-harness
# ==============================================================================
# Proyecta adaptadores estáticos (OpenCode commands, etc.) a partir de los
# flujos canónicos en .agents/workflows/.
# Garantiza paridad de comandos slash en todos los runtimes sin colisiones.

project_opencode_commands() {
    local target_dir="${1:-.}"
    local workflows_dir="$target_dir/.agents/workflows"
    local commands_dir="$target_dir/.opencode/commands"

    [ -d "$workflows_dir" ] || return 0

    mkdir -p "$commands_dir"

    for wf in "$workflows_dir"/*.md; do
        [ -f "$wf" ] || continue
        local wname
        wname="$(basename "$wf" .md)"
        local shim="$commands_dir/${wname}.md"

        # Extraer descripción del frontmatter si existe
        local desc
        desc=$(sed -n '/^---$/,/^---$/p' "$wf" | grep -E '^description:' | head -n 1 | sed -E 's/^description:[[:space:]]*//' | tr -d '"'\''')
        [ -z "$desc" ] && desc="Ejecuta el workflow ${wname} de agent-os"

        cat <<EOF > "$shim"
---
description: ${desc}
---

Sigue y ejecuta de inmediato y de forma autónoma el workflow en .agents/workflows/${wname}.md \$ARGUMENTS (pasos en orden estricto).
EOF
    done
}

# Invocación directa como CLI si no es sourceado
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    target="${1:-.}"
    project_opencode_commands "$target"
    echo "✅ Comandos de OpenCode proyectados en $target/.opencode/commands/"
fi
