#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/lib/orca-client.sh — Cliente unificado y portable de Orca ADE
# ==============================================================================
# Centraliza la resolución inequívoca de ejecutables (evitando colisiones con el
# lector de pantalla /usr/bin/orca de GNOME y eliminando rutas personales),
# la sonda fail-fast de salud del runtime (<1s) y las operaciones de ciclo de
# vida de workers bajo una whitelist estricta de variables de entorno.
#
# Principios:
#   - Portabilidad POSIX (Linux y macOS sin dependencias de GNU timeout).
#   - Cero fugas de credenciales (aislamiento estricto con env -i).
#   - Sin efectos colaterales al ser importado con source.
# ==============================================================================

# Whitelist estricta y única de variables de entorno propagadas a workers supervisados.
# Previene la fuga de tokens de proveedores LLM, claves de bóveda o secretos del coordinador.
# Resuelve HOME al directorio real del usuario si la sesión activa usa un HOME sobreescrito.
ORCA_REAL_HOME="$(getent passwd "$(id -un 2>/dev/null)" 2>/dev/null | cut -d: -f6 || echo "$HOME")"
[ -n "$ORCA_REAL_HOME" ] || ORCA_REAL_HOME="$HOME"

# Nombres canónicos de variables autorizadas para cruzar la frontera env -i
export ORCA_WORKER_ENV_WHITELIST=(
    HOME
    PATH
    USER
    SHELL
    LANG
    LC_ALL
    TMPDIR
    ORCA_USER_DATA_PATH
    ORCA_TERMINAL_HANDLE
    ORCA_CALLS_LOG
)

# Resuelve el binario auténtico de Orca ADE en el host.
# Prioriza binarios en PATH respetando el orden de directorios ('orca-ide' y 'orca' no-GNOME),
# con fallback a shims estándar vía $HOME, descartando explícitamente el lector de GNOME (/usr/bin/orca).
orca_resolve_bin() {
    if [ -n "${ORCA_BIN_OVERRIDE:-}" ] && [ -x "${ORCA_BIN_OVERRIDE}" ]; then
        echo "${ORCA_BIN_OVERRIDE}"
        return 0
    fi

    # 1 y 2. Búsqueda a lo largo de PATH respetando el orden de precedencia de directorios.
    # En cada directorio se prefiere 'orca-ide', seguido de 'orca' (siempre que no sea GNOME).
    local dir
    local -a path_dirs
    IFS=':' read -ra path_dirs <<< "${PATH:-}"
    for dir in "${path_dirs[@]}"; do
        [ -z "$dir" ] && continue
        if [ -x "$dir/orca-ide" ]; then
            echo "$dir/orca-ide"
            return 0
        fi
        if [ -x "$dir/orca" ]; then
            local real_target
            real_target="$(readlink -f "$dir/orca" 2>/dev/null || echo "$dir/orca")"
            if [ "$dir/orca" != "/usr/bin/orca" ] && [ "$dir/orca" != "/bin/orca" ] && \
               [ "$real_target" != "/usr/bin/orca" ] && [ "$real_target" != "/bin/orca" ]; then
                echo "$dir/orca"
                return 0
            fi
        fi
    done

    # 3. Shims estándar de usuario vía $HOME (nunca rutas absolutas personales ni fijas de sistema)
    local candidates=(
        "$HOME/.local/bin/orca-ide"
        "$HOME/.local/bin/orca"
        "$HOME/.config/orca/linux-orca-cli-shim/orca"
    )

    local c
    for c in "${candidates[@]}"; do
        if [ -x "$c" ]; then
            echo "$c"
            return 0
        fi
    done

    return 1
}

# Sonda determinista fail-fast (<1s de timeout).
# Retorna 0 si el runtime está respondiendo correctamente a comandos CLI, 1 si está inactivo/sordo.
orca_is_ready() {
    local bin
    bin="$(orca_resolve_bin 2>/dev/null)" || return 1

    python3 -c "
import subprocess, sys
try:
    p = subprocess.run(['$bin', 'status', '--json'], capture_output=True, timeout=1)
    sys.exit(p.returncode)
except Exception:
    sys.exit(1)
" >/dev/null 2>&1
}

# Consulta el estado del runtime y la topología de la ADE.
orca_status() {
    local bin
    bin="$(orca_resolve_bin)" || {
        echo "❌ Error: ejecutable de Orca ADE no encontrado." >&2
        return 1
    }
    "$bin" status "$@"
}

# Despacha un worker supervisado aislando el entorno bajo la whitelist corporativa.
# Pasa transparentemente todos los argumentos al subcomando 'orchestration worker-start'.
orca_worker_start() {
    local bin
    bin="$(orca_resolve_bin)" || {
        echo "❌ Error: ejecutable de Orca ADE no encontrado." >&2
        return 1
    }

    local env_args=()
    local var val
    for var in "${ORCA_WORKER_ENV_WHITELIST[@]}"; do
        case "$var" in
            HOME)
                val="${ORCA_REAL_HOME:-$HOME}"
                env_args+=("HOME=$val")
                ;;
            ORCA_USER_DATA_PATH)
                val="${ORCA_USER_DATA_PATH:-${ORCA_REAL_HOME:-$HOME}/.config/orca}"
                env_args+=("ORCA_USER_DATA_PATH=$val")
                ;;
            *)
                if [ -n "${!var+x}" ]; then
                    env_args+=("$var=${!var}")
                fi
                ;;
        esac
    done

    env -i "${env_args[@]}" "$bin" orchestration worker-start "$@"
}

# Lee la salida o transcripción de un worker supervisado.
orca_worker_read() {
    local bin
    bin="$(orca_resolve_bin)" || {
        echo "❌ Error: ejecutable de Orca ADE no encontrado." >&2
        return 1
    }
    "$bin" orchestration worker-read "$@"
}

# Libera el terminal de un worker que ha finalizado su labor (idempotente).
orca_worker_release() {
    local bin
    bin="$(orca_resolve_bin)" || {
        echo "❌ Error: ejecutable de Orca ADE no encontrado." >&2
        return 1
    }
    "$bin" orchestration worker-release "$@"
}

# Invocador genérico para otros subcomandos CLI de Orca.
orca_cmd() {
    local bin
    bin="$(orca_resolve_bin)" || {
        echo "❌ Error: ejecutable de Orca ADE no encontrado." >&2
        return 1
    }
    "$bin" "$@"
}
