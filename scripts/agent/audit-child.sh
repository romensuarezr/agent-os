#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/audit-child.sh — Auditoría de salud y drift en proyectos satélite
# ==============================================================================
# Uso: bash scripts/agent/audit-child.sh [--path /ruta/al/satelite]
# Opciones:
#   --path <dir>   Ruta al proyecto satélite a auditar (por defecto: directorio actual).
#   -h, --help     Muestra este mensaje de ayuda.
#
# Salida determinista:
#   exit 0 + ✅ CONFORME       → Repositorio 100% íntegro y sincronizado.
#   exit 0 + ⚠️  DRIFT DETECTADO → Advertencias leves o desactualización de sync.
#   exit 1 + ❌ NO CONFORME     → Errores estructurales críticos o scripts corruptos.
#
# 100% LOCAL Y OFFLINE: Cero llamadas de red, cero telemetría.
# ==============================================================================

set -euo pipefail

# Constantes nombradas de umbral de drift temporal
DRIFT_WARN_DAYS=7
DRIFT_CRITICAL_DAYS=14

TARGET_DIR=""
EXPLICIT_PATH=false

while [ $# -gt 0 ]; do
    case "$1" in
        --path)
            if [ -n "${2:-}" ]; then
                TARGET_DIR="$2"
                EXPLICIT_PATH=true
                shift 2
            else
                echo "❌ Error: La opción --path requiere una ruta como argumento." >&2
                exit 1
            fi
            ;;
        --path=*)
            TARGET_DIR="${1#*=}"
            EXPLICIT_PATH=true
            shift
            ;;
        -h|--help)
            echo "Uso: audit-child.sh [opciones]"
            echo ""
            echo "Auditoría de salud y detección de drift en proyectos satélite de Agent OS."
            echo "100% local y offline: no realiza llamadas de red ni telemetría."
            echo ""
            echo "Opciones:"
            echo "  --path <ruta>  Ruta al proyecto a auditar (por defecto: directorio de trabajo actual)"
            echo "  -h, --help     Muestra esta ayuda"
            exit 0
            ;;
        *)
            if [ -z "$TARGET_DIR" ]; then
                TARGET_DIR="$1"
                EXPLICIT_PATH=true
            fi
            shift
            ;;
    esac
done

# Resolver directorio destino
if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="$(pwd -P)"
else
    if [ ! -d "$TARGET_DIR" ]; then
        echo "❌ ERROR: El directorio destino no existe: $TARGET_DIR" >&2
        exit 1
    fi
    TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd -P || echo "$TARGET_DIR")"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P || pwd)"

# Detección de versión canónica del core (solo si se ejecuta con --path o desde un clon del core)
CANONICAL_CORE_DIR=""
CANONICAL_VERSION=""
if [[ "$EXPLICIT_PATH" == true ]]; then
    # Cuando se invoca explícitamente con --path, verificar si el script vive dentro de un core
    CANDIDATE_CORE="$(cd "$SCRIPT_DIR/../.." 2>/dev/null && pwd -P || true)"
    if [ -n "$CANDIDATE_CORE" ] && [ -f "$CANDIDATE_CORE/VERSION" ] && [ -f "$CANDIDATE_CORE/AGENTS.md" ]; then
        CANONICAL_CORE_DIR="$CANDIDATE_CORE"
    fi
elif [ -n "${AGENT_OS_PATH:-}" ] && [ -f "${AGENT_OS_PATH}/VERSION" ]; then
    CANONICAL_CORE_DIR="${AGENT_OS_PATH}"
fi

if [ -n "$CANONICAL_CORE_DIR" ] && [ -f "$CANONICAL_CORE_DIR/VERSION" ]; then
    CANONICAL_VERSION=$(tr -d '[:space:]' < "$CANONICAL_CORE_DIR/VERSION" 2>/dev/null || true)
fi

echo "=================================================="
echo "🩺 AUDITORÍA DE SALUD AGENT OS"
echo "Directorio inspeccionado: $TARGET_DIR"
if [ -n "$CANONICAL_VERSION" ]; then
    echo "Modo: Referenciado al core (versión canónica: $CANONICAL_VERSION)"
else
    echo "Modo: Standalone (autodiagnóstico local offline)"
fi
echo "=================================================="

CRITICAL_COUNT=0
WARN_COUNT=0
OK_COUNT=0

# Helper para calcular época de una fecha (Linux + macOS + Python fallback)
calc_epoch() {
    local d="${1:-}"
    if [ -z "$d" ]; then
        echo 0
        return
    fi
    local res=""
    if command -v date >/dev/null 2>&1; then
        res=$(date -d "$d" +%s 2>/dev/null || true)
        [ -z "$res" ] && res=$(date -j -f "%Y-%m-%d" "$d" +%s 2>/dev/null || true)
    fi
    if [ -z "$res" ] && command -v python3 >/dev/null 2>&1; then
        res=$(DATE_VAL="$d" python3 -c '
import os, datetime, sys
v = os.environ.get("DATE_VAL", "").strip()
try:
    dt = datetime.datetime.strptime(v, "%Y-%m-%d")
    print(int(dt.replace(tzinfo=datetime.timezone.utc).timestamp()))
except Exception:
    sys.exit(1)
' 2>/dev/null || true)
    fi
    echo "${res:-0}"
}

# ------------------------------------------------------------------------------
# Check 1: Estructura base de Agent OS
# ------------------------------------------------------------------------------
echo ""
echo "▶ 1. Estructura base de Agent OS..."
MISSING_DIRS=()
for required_dir in ".agents/rules" ".agents/workflows" ".agents/skills" ".agents/profiles" ".agents/config" "scripts/agent"; do
    if [ ! -d "$TARGET_DIR/$required_dir" ]; then
        MISSING_DIRS+=("$required_dir")
    fi
done

if [ ${#MISSING_DIRS[@]} -gt 0 ]; then
    for m in "${MISSING_DIRS[@]}"; do
        echo "  ❌ [ESTRUCTURA] Directorio requerido ausente: $m"
        CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
    done
else
    echo "  ✅ [ESTRUCTURA] Estructura base completa (.agents/* y scripts/agent/)."
    OK_COUNT=$((OK_COUNT + 1))
fi

# ------------------------------------------------------------------------------
# Check 2: Detección de drift de configuración (rutas obsoletas)
# ------------------------------------------------------------------------------
echo ""
echo "▶ 2. Drift de rutas obsoletas de configuración..."
DEPRECATED_FOUND=()
for old_conf in "config/fleet.yaml" "config/fleet.yml" "config/skills-manifest.yaml" "config/skills-manifest.yml"; do
    if [ -f "$TARGET_DIR/$old_conf" ]; then
        DEPRECATED_FOUND+=("$old_conf")
    fi
done

if [ ${#DEPRECATED_FOUND[@]} -gt 0 ]; then
    for d in "${DEPRECATED_FOUND[@]}"; do
        echo "  ⚠️  [CONFIG-DRIFT] Ruta obsoleta detectada: $d (migrar hacia .agents/$d)."
        WARN_COUNT=$((WARN_COUNT + 1))
    done
else
    echo "  ✅ [CONFIG-DRIFT] Sin rutas obsoletas en config/ (alineado con estándar .agents/config/)."
    OK_COUNT=$((OK_COUNT + 1))
fi

# ------------------------------------------------------------------------------
# Check 3: Vigencia y Ledger de Versión (.agents/context/last-sync.md)
# ------------------------------------------------------------------------------
echo ""
echo "▶ 3. Vigencia y trazabilidad de versión (.agents/context/last-sync.md)..."
LAST_SYNC_FILE="$TARGET_DIR/.agents/context/last-sync.md"
if [ ! -f "$LAST_SYNC_FILE" ]; then
    echo "  ⚠️  [LEDGER] No existe .agents/context/last-sync.md (satélite sin ledger de sincronización)."
    WARN_COUNT=$((WARN_COUNT + 1))
else
    # Parsear archivo de sincronización
    SYNC_DATE=$(head -n 1 "$LAST_SYNC_FILE" 2>/dev/null | sed 's/skipped: //g' | awk '{print $1}' || echo "")
    SYNC_VER=$(grep -E '^version:' "$LAST_SYNC_FILE" 2>/dev/null | awk '{print $2}' || echo "")
    SYNC_TAG=$(grep -E '^tag:' "$LAST_SYNC_FILE" 2>/dev/null | awk '{print $2}' || echo "")
    SYNC_COMMIT=$(grep -E '^commit:' "$LAST_SYNC_FILE" 2>/dev/null | awk '{print $2}' || echo "")

    if [ -z "$SYNC_VER" ]; then
        SYNC_VER="legacy"
    fi

    if [ -z "$SYNC_DATE" ]; then
        echo "  ⚠️  [LEDGER] .agents/context/last-sync.md no contiene fecha válida de sincronización."
        WARN_COUNT=$((WARN_COUNT + 1))
    else
        SYNC_EPOCH=$(calc_epoch "$SYNC_DATE")
        NOW_EPOCH=$(date +%s)
        if [ "$SYNC_EPOCH" -gt 0 ] && [ "$NOW_EPOCH" -ge "$SYNC_EPOCH" ]; then
            DIFF_DAYS=$(( (NOW_EPOCH - SYNC_EPOCH) / 86400 ))
            if [ "$DIFF_DAYS" -ge "$DRIFT_CRITICAL_DAYS" ]; then
                echo "  ⚠️  [LEDGER] Desactualización severa: $DIFF_DAYS días sin sincronizar ($SYNC_DATE) >= umbral crítico ($DRIFT_CRITICAL_DAYS días)."
                WARN_COUNT=$((WARN_COUNT + 1))
            elif [ "$DIFF_DAYS" -ge "$DRIFT_WARN_DAYS" ]; then
                echo "  ⚠️  [LEDGER] Desactualización leve: $DIFF_DAYS días sin sincronizar ($SYNC_DATE) >= umbral aviso ($DRIFT_WARN_DAYS días)."
                WARN_COUNT=$((WARN_COUNT + 1))
            else
                echo "  ✅ [LEDGER] Ledger vigente ($DIFF_DAYS días transcurridos, fecha: $SYNC_DATE, versión: $SYNC_VER, commit: ${SYNC_COMMIT:0:7})."
                OK_COUNT=$((OK_COUNT + 1))
            fi
        else
            echo "  ℹ️  [LEDGER] Fecha registrada en ledger: $SYNC_DATE (versión: $SYNC_VER)."
            OK_COUNT=$((OK_COUNT + 1))
        fi
    fi

    # Comparación de versión con el core si está disponible
    if [ -n "$CANONICAL_VERSION" ]; then
        CLEAN_SYNC_VER="${SYNC_VER#v}"
        CLEAN_CANONICAL="${CANONICAL_VERSION#v}"
        if [ "$CLEAN_SYNC_VER" != "legacy" ] && [ "$CLEAN_SYNC_VER" != "unknown" ]; then
            if [ "$CLEAN_SYNC_VER" != "$CLEAN_CANONICAL" ]; then
                echo "  ⚠️  [VERSION] Desalineado con el core: satélite=${CLEAN_SYNC_VER} vs core=${CLEAN_CANONICAL}. Ejecuta sync.sh."
                WARN_COUNT=$((WARN_COUNT + 1))
            else
                echo "  ✅ [VERSION] Versión del satélite alineada con la versión canónica del core ($CANONICAL_VERSION)."
                OK_COUNT=$((OK_COUNT + 1))
            fi
        else
            echo "  ⚠️  [VERSION] El satélite posee versión legacy/no declarada mientras el core está en v$CLEAN_CANONICAL."
            WARN_COUNT=$((WARN_COUNT + 1))
        fi
    fi
fi

# ------------------------------------------------------------------------------
# Check 4: Integridad de Onboarding (.agents/AGENT_ONBOARDING.md)
# ------------------------------------------------------------------------------
echo ""
echo "▶ 4. Integridad de Onboarding (.agents/AGENT_ONBOARDING.md)..."
ONBOARDING_FILE="$TARGET_DIR/.agents/AGENT_ONBOARDING.md"
if [ ! -f "$ONBOARDING_FILE" ]; then
    echo "  ⚠️  [ONBOARDING] No existe .agents/AGENT_ONBOARDING.md en el satélite."
    WARN_COUNT=$((WARN_COUNT + 1))
elif [ ! -s "$ONBOARDING_FILE" ]; then
    echo "  ⚠️  [ONBOARDING] .agents/AGENT_ONBOARDING.md existe pero está vacío (0 bytes)."
    WARN_COUNT=$((WARN_COUNT + 1))
elif grep -q "\[React / Next\.js / etc\.\]" "$ONBOARDING_FILE" 2>/dev/null || grep -q "Copia este archivo en \.agents/" "$ONBOARDING_FILE" 2>/dev/null; then
    echo "  ⚠️  [ONBOARDING] .agents/AGENT_ONBOARDING.md contiene marcadores de plantilla genérica sin completar."
    WARN_COUNT=$((WARN_COUNT + 1))
else
    echo "  ✅ [ONBOARDING] .agents/AGENT_ONBOARDING.md presente y personalizado."
    OK_COUNT=$((OK_COUNT + 1))
fi

# ------------------------------------------------------------------------------
# Check 5: Permisos de ejecución en scripts/agent/*.sh
# ------------------------------------------------------------------------------
echo ""
echo "▶ 5. Permisos de ejecución en scripts/agent/..."
SCRIPTS_DIR="$TARGET_DIR/scripts/agent"
NON_EXEC_SCRIPTS=()
FOUND_ANY_SCRIPT=false

if [ -d "$SCRIPTS_DIR" ]; then
    while IFS= read -r script_path; do
        [ -z "$script_path" ] && continue
        FOUND_ANY_SCRIPT=true
        if [ ! -x "$script_path" ]; then
            rel_path="${script_path#$TARGET_DIR/}"
            NON_EXEC_SCRIPTS+=("$rel_path")
        fi
    done < <(find "$SCRIPTS_DIR" -type f -name "*.sh" 2>/dev/null || true)
fi

if [ "$FOUND_ANY_SCRIPT" = false ]; then
    echo "  ❌ [PERMISOS] No se encontraron scripts .sh en scripts/agent/."
    CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
elif [ ${#NON_EXEC_SCRIPTS[@]} -gt 0 ]; then
    for s in "${NON_EXEC_SCRIPTS[@]}"; do
        echo "  ❌ [PERMISOS] Script sin permiso de ejecución (+x): $s"
        CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
    done
else
    echo "  ✅ [PERMISOS] Todos los scripts en scripts/agent/ disponen de permiso de ejecución (+x)."
    OK_COUNT=$((OK_COUNT + 1))
fi

# ------------------------------------------------------------------------------
# Check 6: Detección defensiva de Stack
# ------------------------------------------------------------------------------
echo ""
echo "▶ 6. Detección defensiva de stack (detect-stack.sh)..."
DETECT_STACK_SCRIPT="$TARGET_DIR/scripts/agent/lib/detect-stack.sh"
if [ ! -f "$DETECT_STACK_SCRIPT" ]; then
    echo "  ⚠️  [STACK] scripts/agent/lib/detect-stack.sh no existe en el satélite."
    WARN_COUNT=$((WARN_COUNT + 1))
else
    # Ejecutar detect_stack en subshell aislada para capturar variables y advertencias de stderr
    DETECT_STDERR_FILE=$(mktemp)
    DETECT_STDOUT_FILE=$(mktemp)

    (
        cd "$TARGET_DIR"
        source "$DETECT_STACK_SCRIPT"
        detect_stack "$TARGET_DIR" > "$DETECT_STDOUT_FILE" 2> "$DETECT_STDERR_FILE"
        echo "AGENT_OS_STACK=${AGENT_OS_STACK:-unknown}" >> "$DETECT_STDOUT_FILE"
        echo "AGENT_OS_PACKAGE_MANAGER=${AGENT_OS_PACKAGE_MANAGER:-none}" >> "$DETECT_STDOUT_FILE"
        echo "AGENT_OS_DETECTED_LOCKFILE=${AGENT_OS_DETECTED_LOCKFILE:-none}" >> "$DETECT_STDOUT_FILE"
    ) || true

    STDERR_CONTENT=$(cat "$DETECT_STDERR_FILE" 2>/dev/null || true)
    PARSED_STACK=$(grep -E '^AGENT_OS_STACK=' "$DETECT_STDOUT_FILE" 2>/dev/null | tail -n 1 | cut -d= -f2- || echo "unknown")
    PARSED_PM=$(grep -E '^AGENT_OS_PACKAGE_MANAGER=' "$DETECT_STDOUT_FILE" 2>/dev/null | tail -n 1 | cut -d= -f2- || echo "none")
    PARSED_LOCK=$(grep -E '^AGENT_OS_DETECTED_LOCKFILE=' "$DETECT_STDOUT_FILE" 2>/dev/null | tail -n 1 | cut -d= -f2- || echo "none")

    rm -f "$DETECT_STDERR_FILE" "$DETECT_STDOUT_FILE"

    if echo "$STDERR_CONTENT" | grep -q -E '(⚠️|DIVERGENCIA|DEPRECATED)'; then
        echo "  ⚠️  [STACK] Divergencia o advertencia detectada en gestor de paquetes:"
        echo "$STDERR_CONTENT" | sed 's/^/      /'
        WARN_COUNT=$((WARN_COUNT + 1))
    else
        echo "  ✅ [STACK] Stack detectado: '$PARSED_STACK' | Gestor verificado: '$PARSED_PM' | Lockfile: '$PARSED_LOCK'."
        OK_COUNT=$((OK_COUNT + 1))
    fi
fi

# ------------------------------------------------------------------------------
# Resumen y Código de Retorno
# ------------------------------------------------------------------------------
echo ""
echo "=================================================="
echo "📊 RESUMEN DE AUDITORÍA"
echo "=================================================="

if [ "$CRITICAL_COUNT" -gt 0 ]; then
    echo "❌ NO CONFORME ($CRITICAL_COUNT error(es) crítico(s), $WARN_COUNT advertencia(s))."
    echo "💡 Guía: Subsanar los errores críticos antes de operar en el repositorio."
    exit 1
elif [ "$WARN_COUNT" -gt 0 ]; then
    echo "⚠️  DRIFT DETECTADO ($WARN_COUNT advertencia(s) detectada(s), 0 errores críticos)."
    echo "💡 Guía: Se recomienda ejecutar 'bash scripts/agent/sync.sh' para alinear el satélite."
    exit 0
else
    echo "✅ CONFORME (Todos los diagnósticos superados con éxito: $OK_COUNT checks OK)."
    exit 0
fi
