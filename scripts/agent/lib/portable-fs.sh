#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/lib/portable-fs.sh — Copias no destructivas portables (Linux + macOS)
# ==============================================================================
# Uso:
#   source "$(dirname "$0")/lib/portable-fs.sh"
#   agent_cp_n <flags...> <origen...> <destino>
#
# Comportamiento:
#   - Si el 'cp' acepta '--update=none' (GNU coreutils >= 9.3) lo usa: '-n' está
#     desaconsejado en esas versiones y emite un warning por stderr.
#   - Si no (macOS/BSD, coreutils antiguos) cae a '-n', soportado nativamente.
#   - Reenvía el resto de flags: 'agent_cp_n -r origen destino' equivale a 'cp -rn'.
#   - Nunca sobrescribe: es un reemplazo 1:1 de 'cp -n' / 'cp -rn'.
# ==============================================================================

# Sonda sin escrituras: un 'cp' que no reconoce '--update=none' falla antes de
# tocar el sistema de ficheros, y se descarta la rama nueva.
_AGENT_CP_UPDATE_NONE=false
if cp --update=none --version >/dev/null 2>&1; then
    _AGENT_CP_UPDATE_NONE=true
fi

agent_cp_n() {
    if [ "$_AGENT_CP_UPDATE_NONE" = true ]; then
        cp --update=none "$@"
    else
        cp -n "$@"
    fi
}
