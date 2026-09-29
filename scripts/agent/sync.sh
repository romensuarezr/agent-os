#!/usr/bin/env bash
set -euo pipefail

# sync.sh - Sincroniza las reglas globales y assets de Agent OS con un proyecto
# Uso: ./sync.sh [opciones] /ruta/al/proyecto
# Opciones:
#   --dry-run   Simula la sincronización y lista diferencias sin escribir en disco.
#   --force     Sobrescribe personalizaciones locales sin confirmación interactiva.
#   --cleanup   Elimina archivos deprecados según assets-manifest.txt.

TARGET_PROJECT=""
CLEANUP=false
FORCE=false
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --cleanup)
            CLEANUP=true
            ;;
        --force)
            FORCE=true
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        -h|--help)
            echo "Uso: sync.sh [opciones] /ruta/al/proyecto"
            echo "Opciones:"
            echo "  --dry-run   Simula la sincronización y detecta diferencias sin escribir en disco."
            echo "  --force     Sobrescribe personalizaciones locales sin pedir confirmación."
            echo "  --cleanup   Elimina archivos deprecados marcados en assets-manifest.txt."
            exit 0
            ;;
        *)
            if [ -z "$TARGET_PROJECT" ]; then
                TARGET_PROJECT="$arg"
            fi
            ;;
    esac
done

# ==============================================================================
# PRE-FLIGHTS DETERMINISTAS (BLOQUE UNIFICADO)
# ==============================================================================
PREFLIGHT_FAIL=false

for cmd in git cp mkdir; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "❌ Error: Dependencia requerida '$cmd' no encontrada." >&2
        echo "💡 Guía: Instálala mediante: apt-get install -y $cmd (Linux) o brew install $cmd (macOS)." >&2
        PREFLIGHT_FAIL=true
    fi
done

if command -v gh >/dev/null 2>&1; then
    if ! gh auth status >/dev/null 2>&1; then
        echo "⚠️  Advertencia: 'gh' está instalado pero no autenticado." >&2
    fi
else
    echo "ℹ️  Nota: 'gh' no está instalado en PATH." >&2
fi

if command -v infisical >/dev/null 2>&1; then
    if ! infisical export --env=dev --dry-run >/dev/null 2>&1 && ! infisical user get >/dev/null 2>&1; then
        echo "⚠️  Advertencia: Infisical CLI instalado pero sin sesión activa detectada." >&2
    fi
else
    echo "ℹ️  Nota: 'infisical' CLI no encontrado en PATH." >&2
fi

if [ "$PREFLIGHT_FAIL" = true ]; then
    echo "❌ Fallo en pre-flights bloqueantes. Abortando." >&2
    exit 1
fi

if [ -z "$TARGET_PROJECT" ]; then
    echo "❌ ERROR: Debes proporcionar la ruta al proyecto destino." >&2
    echo "💡 Guía: bash scripts/agent/sync.sh /ruta/al/proyecto" >&2
    exit 1
fi

if [ ! -d "$TARGET_PROJECT" ]; then
    echo "❌ ERROR: El directorio destino no existe: $TARGET_PROJECT" >&2
    echo "💡 Guía: Verifica la ruta provista y asegúrate de que el proyecto existe antes de sincronizar." >&2
    exit 1
fi

if [ ! -w "$TARGET_PROJECT" ]; then
    echo "❌ ERROR: Sin permisos de escritura en el directorio destino: $TARGET_PROJECT" >&2
    echo "💡 Guía: Verifica los permisos de usuario sobre el directorio antes de sincronizar." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/portable-timeout.sh"
DEFAULT_CORE="$(cd "$SCRIPT_DIR/../.." && pwd)"
AGENT_OS_PATH="${AGENT_OS_PATH:-$DEFAULT_CORE}"

# Validar que no se intente sincronizar el core sobre sí mismo
REAL_AGENT_OS=$(realpath "$AGENT_OS_PATH" 2>/dev/null || echo "$AGENT_OS_PATH")
REAL_TARGET=$(realpath "$TARGET_PROJECT" 2>/dev/null || echo "$TARGET_PROJECT")

if [ "$REAL_AGENT_OS" = "$REAL_TARGET" ]; then
    echo "❌ ERROR: AGENT_OS_PATH y TARGET_PROJECT apuntan al mismo directorio." >&2
    echo "Guía: sync.sh sincroniza el core hacia proyectos hijos, nunca sobre sí mismo." >&2
    exit 1
fi

# Validar que AGENT_OS_PATH apunta a un core real de Agent OS con marcadores canónicos
if [ ! -f "$AGENT_OS_PATH/AGENTS.md" ] || [ ! -d "$AGENT_OS_PATH/.agents" ] || [ ! -d "$AGENT_OS_PATH/scripts/agent" ]; then
    echo "❌ ERROR: AGENT_OS_PATH ($AGENT_OS_PATH) no contiene los marcadores canónicos de un núcleo válido de Agent OS." >&2
    echo "💡 Guía: Asegúrate de que AGENT_OS_PATH contenga AGENTS.md, .agents/ y scripts/agent/." >&2
    exit 1
fi

AGENT_OS_RULES="$AGENT_OS_PATH/.agents/rules/global"
AGENT_OS_SCRIPTS="$AGENT_OS_PATH/scripts/agent"
AGENT_OS_SKILLS="$AGENT_OS_PATH/.agents/skills"
AGENT_OS_PROFILES="$AGENT_OS_PATH/.agents/profiles"
AGENT_OS_GOALS="$AGENT_OS_PATH/templates/goals"
TARGET_RULES="$TARGET_PROJECT/.agents/rules"
TARGET_SCRIPTS="$TARGET_PROJECT/scripts/agent"
TARGET_SKILLS="$TARGET_PROJECT/.agents/skills"
TARGET_PROFILES="$TARGET_PROJECT/.agents/profiles"
TARGET_GOALS="$TARGET_PROJECT/templates/goals"

if [ "$DRY_RUN" = true ]; then
    echo "🔍 [DRY-RUN] Simulando sincronización con $TARGET_PROJECT (cero escrituras en disco)..."
else
    echo "🔄 Sincronizando Agent OS con $TARGET_PROJECT..."
fi

# Comprobar actualizaciones de Agent OS Core remoto
if [ -d "$AGENT_OS_PATH/.git" ]; then
    AGENT_OS_LOCAL=$(git -C "$AGENT_OS_PATH" rev-parse HEAD 2>/dev/null || true)
    AGENT_OS_REMOTE=$(portable_timeout 3 git -C "$AGENT_OS_PATH" ls-remote origin HEAD 2>/dev/null | cut -f1 || true)
    if [[ -n "$AGENT_OS_REMOTE" && -n "$AGENT_OS_LOCAL" && "$AGENT_OS_LOCAL" != "$AGENT_OS_REMOTE" ]]; then
        echo "⚠️  WARNING: El núcleo tiene actualizaciones pendientes en origin/main." >&2
        echo "💡 Guía: Haz 'git pull' en $AGENT_OS_PATH antes de propagar cambios a los proyectos hijos." >&2
        echo "---" >&2
    fi
fi

if [ ! -d "$TARGET_RULES" ]; then
    echo "❌ ERROR: La carpeta $TARGET_RULES no existe." >&2
    echo "💡 Guía: Ejecuta 'bash scripts/agent/install.sh $TARGET_PROJECT' primero para configurar la estructura base." >&2
    exit 1
fi

# ==============================================================================
# FUNCIÓN HELPER: SINCRONIZACIÓN NO DESTRUCTIVA DE UN FICHERO
# ==============================================================================
sync_file() {
    local src="$1"
    local dst="$2"
    local label="${3:-$(basename "$src")}"

    # Caso 1: El archivo no existe en destino -> Se crea
    if [ ! -f "$dst" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "    [dry-run] crear: $label"
        else
            mkdir -p "$(dirname "$dst")"
            cp "$src" "$dst"
            echo "    [creado] $label"
        fi
        return 0
    fi

    # Caso 2: El archivo existe y es idéntico -> Sin cambios
    if cmp -s "$src" "$dst"; then
        if [ "$DRY_RUN" = true ]; then
            echo "    [dry-run] idéntico: $label"
        else
            echo "    [sync] $label (idéntico)"
        fi
        return 0
    fi

    # Caso 3: El archivo existe y difiere del core (personalización o actualización)
    if [ "$DRY_RUN" = true ]; then
        echo "    [dry-run] diferir: $label (personalización local o actualización disponible)"
        return 0
    fi

    if [ "$FORCE" = true ]; then
        cp "$src" "$dst"
        echo "    [force] sobrescrito: $label"
        return 0
    fi

    # Sin --force: comportamiento según TTY
    if [ -t 0 ]; then
        echo -n "⚠️  Personalización local en $label difiere del core. ¿Sobrescribir con versión del core? (s/N): "
        local resp=""
        read -r resp || resp="n"
        resp=$(echo "$resp" | tr '[:upper:]' '[:lower:]')
        if [[ "$resp" == "s" || "$resp" == "si" ]]; then
            cp "$src" "$dst"
            echo "    [sobrescrito] $label"
        else
            echo "    [omitido] $label mantenido sin cambios"
        fi
    else
        # Entorno no interactivo (CI, script, agentes): OMITIR sin bloquear stdin
        echo "    ⚠️  Aviso: Omitido por personalización local (difiere del core): $label. Usa --force para sobrescribir."
    fi
}

# 1. Reglas globales
echo "  Sincronizando reglas..."
if [ -d "$AGENT_OS_RULES" ]; then
    for rule in "$AGENT_OS_RULES"/*.md; do
        [ -f "$rule" ] || continue
        rname=$(basename "$rule")
        sync_file "$rule" "$TARGET_RULES/$rname" "regla: $rname"
    done
fi

# 2. Workflows
if [ -d "$TARGET_PROJECT/.agents/workflows" ]; then
    echo "  Sincronizando workflows..."
    AGENT_OS_WORKFLOWS="$AGENT_OS_PATH/.agents/workflows"
    TARGET_WORKFLOWS="$TARGET_PROJECT/.agents/workflows"
    if [ -d "$AGENT_OS_WORKFLOWS" ]; then
        for wf in "$AGENT_OS_WORKFLOWS"/*.md; do
            [ -f "$wf" ] || continue
            wname=$(basename "$wf")
            sync_file "$wf" "$TARGET_WORKFLOWS/$wname" "workflow: $wname"
        done
    fi
fi

# 3. Scripts de agente
if [ -d "$TARGET_SCRIPTS" ]; then
    echo "  Sincronizando scripts..."
    if [ -d "$AGENT_OS_SCRIPTS" ]; then
        for script in "$AGENT_OS_SCRIPTS"/*.sh; do
            [ -f "$script" ] || continue
            scname=$(basename "$script")
            sync_file "$script" "$TARGET_SCRIPTS/$scname" "script: $scname"
            if [ "$DRY_RUN" = false ]; then
                chmod +x "$TARGET_SCRIPTS/$scname" 2>/dev/null || true
            fi
        done
        if [ -d "$AGENT_OS_SCRIPTS/lib" ]; then
            for lib_file in "$AGENT_OS_SCRIPTS/lib"/*.sh; do
                [ -f "$lib_file" ] || continue
                lfname=$(basename "$lib_file")
                sync_file "$lib_file" "$TARGET_SCRIPTS/lib/$lfname" "lib: $lfname"
                if [ "$DRY_RUN" = false ]; then
                    chmod +x "$TARGET_SCRIPTS/lib/$lfname" 2>/dev/null || true
                fi
            done
        fi
        if [ "$DRY_RUN" = false ]; then
            chmod +x "$TARGET_SCRIPTS/verify-goal.sh" "$TARGET_SCRIPTS/worktree-dispatch.sh" "$TARGET_SCRIPTS/worktree-merge.sh" "$TARGET_SCRIPTS/promote-to-main.sh" 2>/dev/null || true
        fi
    fi
fi

# 4. Skills (sincroniza solo skills activas en destino, sin reintroducir descartadas)
if [ -d "$AGENT_OS_SKILLS" ]; then
    echo "  Sincronizando skills activas en destino..."
    mkdir -p "$TARGET_SKILLS"
    for skill in "$AGENT_OS_SKILLS"/*; do
        [ -e "$skill" ] || continue
        skill_name=$(basename "$skill")
        
        # Si el proyecto hijo no tiene instalada esta skill, no reintroducirla
        if [ ! -e "$TARGET_SKILLS/$skill_name" ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "    [dry-run] omitir skill no presente en hijo: $skill_name"
            fi
            continue
        fi

        if [ -d "$skill" ]; then
            # Sincronizar recursivamente respetando personalizaciones locales
            find "$skill" -type f | while IFS= read -r fsrc; do
                rel_path="${fsrc#"$AGENT_OS_SKILLS/"}"
                fdst="$TARGET_SKILLS/$rel_path"
                sync_file "$fsrc" "$fdst" "skill: $rel_path"
            done
        elif [ -f "$skill" ]; then
            sync_file "$skill" "$TARGET_SKILLS/$skill_name" "skill: $skill_name"
        fi
    done
fi

# 5. Perfiles de agente
if [ -d "$AGENT_OS_PROFILES" ]; then
    echo "  Sincronizando perfiles..."
    mkdir -p "$TARGET_PROFILES"
    for profile in "$AGENT_OS_PROFILES"/*; do
        [ -f "$profile" ] || continue
        pname=$(basename "$profile")
        sync_file "$profile" "$TARGET_PROFILES/$pname" "perfil: $pname"
    done
fi

# 6. Templates de metas
if [ -d "$AGENT_OS_GOALS" ]; then
    echo "  Sincronizando templates de metas..."
    mkdir -p "$TARGET_GOALS"
    for goal_tmpl in "$AGENT_OS_GOALS"/*; do
        [ -f "$goal_tmpl" ] || continue
        gname=$(basename "$goal_tmpl")
        sync_file "$goal_tmpl" "$TARGET_GOALS/$gname" "meta: $gname"
    done
fi

# 7. Propagación de templates de docs y templates de root a proyectos hijos existentes
echo "  Propagando templates de documentación faltantes..."
if [ -d "$AGENT_OS_PATH/templates/docs" ]; then
    mkdir -p "$TARGET_PROJECT/docs"
    for tmpl in "$AGENT_OS_PATH/templates/docs"/*; do
        [ -f "$tmpl" ] || continue
        fname=$(basename "$tmpl")
        existing_fuzzy=""
        if [ "$fname" = "mvp-tracker.md" ]; then
            existing_fuzzy=$( (find "$TARGET_PROJECT" -maxdepth 1 -type f \( -iname "*mvp*" -o -iname "*track*" \) 2>/dev/null || true; find "$TARGET_PROJECT/docs" -maxdepth 1 -type f \( -iname "*mvp*" -o -iname "*track*" \) 2>/dev/null || true) | head -n 1 || true )
        elif [ "$fname" = "implemented.md" ]; then
            existing_fuzzy=$( (find "$TARGET_PROJECT" -maxdepth 1 -type f \( -iname "*implement*" -o -iname "*hito*" -o -iname "*milestone*" \) 2>/dev/null || true; find "$TARGET_PROJECT/docs" -maxdepth 1 -type f \( -iname "*implement*" -o -iname "*hito*" -o -iname "*milestone*" \) 2>/dev/null || true) | head -n 1 || true )
        fi
        if [ -z "$existing_fuzzy" ] && [ ! -f "$TARGET_PROJECT/docs/$fname" ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "    [dry-run] propagar template doc: $fname"
            else
                cp "$tmpl" "$TARGET_PROJECT/docs/$fname"
                echo "    [propagado] template doc: $fname"
            fi
        fi
    done
fi

if [ -d "$AGENT_OS_PATH/templates/root" ]; then
    for tmpl in "$AGENT_OS_PATH/templates/root"/*; do
        [ -f "$tmpl" ] || continue
        fname=$(basename "$tmpl")
        existing_fuzzy=""
        if [ "$fname" = "roadmap.md" ]; then
            existing_fuzzy=$(find "$TARGET_PROJECT" -maxdepth 1 -type f \( -iname "*road*" -o -iname "*map*" \) 2>/dev/null | head -n 1 || true)
        elif [ "$fname" = "changelog.md" ]; then
            existing_fuzzy=$(find "$TARGET_PROJECT" -maxdepth 1 -type f \( -iname "*change*" -o -iname "*log*" -o -iname "*history*" \) 2>/dev/null | head -n 1 || true)
        fi
        if [ -z "$existing_fuzzy" ] && [ ! -f "$TARGET_PROJECT/$fname" ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "    [dry-run] propagar template root: $fname"
            else
                cp "$tmpl" "$TARGET_PROJECT/$fname"
                echo "    [propagado] template root: $fname"
            fi
        fi
    done
fi

# Propagar plantilla de onboarding si falta
PROJECT_ONBOARDING_SRC="$AGENT_OS_PATH/.agents/templates/AGENT_ONBOARDING.project.md"
TARGET_ONBOARDING="$TARGET_PROJECT/.agents/AGENT_ONBOARDING.md"
if [ -f "$PROJECT_ONBOARDING_SRC" ] && [ ! -f "$TARGET_ONBOARDING" ]; then
    if [ "$DRY_RUN" = true ]; then
        echo "    [dry-run] propagar plantilla: .agents/AGENT_ONBOARDING.md"
    else
        cp "$PROJECT_ONBOARDING_SRC" "$TARGET_ONBOARDING"
        echo "    [propagado] plantilla: .agents/AGENT_ONBOARDING.md"
    fi
fi

# 8. Sincronizar marcas de contexto (solo si no es dry-run)
mkdir -p "$TARGET_PROJECT/.agents/context"
if [ "$DRY_RUN" = false ]; then
    if [ -f "$AGENT_OS_PATH/changelog.md" ]; then
        cp "$AGENT_OS_PATH/changelog.md" "$TARGET_PROJECT/.agents/context/agent-os-changelog.md"
        echo "  Sincronizando changelog del core..."
    fi
    CORE_SHA=$(git -C "$AGENT_OS_PATH" rev-parse HEAD 2>/dev/null || echo "unknown")
    {
        date -u +%Y-%m-%d
        echo "commit: $CORE_SHA"
    } > "$TARGET_PROJECT/.agents/context/last-sync.md"
    if [ -f "$AGENT_OS_PATH/scripts/agent/assets-manifest.txt" ]; then
        cp "$AGENT_OS_PATH/scripts/agent/assets-manifest.txt" "$TARGET_PROJECT/.agents/context/assets-manifest.txt"
        echo "  Sincronizando manifiesto de assets..."
    fi
else
    echo "  [dry-run] marcas de contexto omitidas (last-sync.md, changelog.md, assets-manifest.txt)."
fi

# ==============================================================================
# DETECCIÓN Y GESTIÓN DE ARCHIVOS DEPRECADOS
# ==============================================================================
MANIFEST_FILE="$AGENT_OS_PATH/scripts/agent/assets-manifest.txt"
DEPRECATED_FILES=()
DEPRECATED_MOTIVES=()

if [ -f "$MANIFEST_FILE" ]; then
    in_deprecated=false
    while IFS= read -r line || [ -n "$line" ]; do
        line=$(echo "$line" | xargs)
        if [ "$line" = "[deprecated]" ]; then
            in_deprecated=true
            continue
        elif [[ "$line" =~ ^\[.*\]$ ]]; then
            in_deprecated=false
            continue
        fi
        
        if [ "$in_deprecated" = "true" ]; then
            if [[ -z "$line" || "$line" =~ ^# ]]; then
                continue
            fi
            read -r _ dep_file dep_motive <<< "$line" || true
            if [ -n "$dep_file" ]; then
                DEPRECATED_FILES+=("$dep_file")
                DEPRECATED_MOTIVES+=("$dep_motive")
            fi
        fi
    done < "$MANIFEST_FILE"
fi

DETECTED_DEPRECATED=()
DETECTED_MOTIVES=()
for i in "${!DEPRECATED_FILES[@]}"; do
    dep_file="${DEPRECATED_FILES[$i]}"
    dep_motive="${DEPRECATED_MOTIVES[$i]}"
    if [ -f "$TARGET_PROJECT/$dep_file" ]; then
        DETECTED_DEPRECATED+=("$dep_file")
        DETECTED_MOTIVES+=("$dep_motive")
    fi
done

if [ "${#DETECTED_DEPRECATED[@]}" -gt 0 ]; then
    if [ "$CLEANUP" = "false" ]; then
        echo ""
        echo "⚠️  ARCHIVOS DEPRECADOS DETECTADOS en este proyecto:"
        for i in "${!DETECTED_DEPRECATED[@]}"; do
            echo "    - ${DETECTED_DEPRECATED[$i]} (${DETECTED_MOTIVES[$i]})"
        done
        echo ""
        echo "Estos archivos ya no forman parte de agent-os."
        echo "Si no los usas, puedes eliminarlos con:"
        echo "    bash scripts/agent/sync.sh $TARGET_PROJECT --cleanup"
        echo ""
    else
        if [ "$DRY_RUN" = true ]; then
            echo "  [dry-run] Archivos deprecados que se eliminarían con --cleanup:"
            for i in "${!DETECTED_DEPRECATED[@]}"; do
                echo "    - ${DETECTED_DEPRECATED[$i]}"
            done
        else
            if [ "$FORCE" = "false" ] && [ ! -t 0 ]; then
                echo "❌ ERROR: El entorno no es interactivo y no se ha especificado el flag --force para --cleanup." >&2
                echo "💡 Guía: bash scripts/agent/sync.sh $TARGET_PROJECT --cleanup --force" >&2
                exit 1
            fi
            
            for i in "${!DETECTED_DEPRECATED[@]}"; do
                dep_file="${DETECTED_DEPRECATED[$i]}"
                full_path="$TARGET_PROJECT/$dep_file"
                if [ -f "$full_path" ]; then
                    confirm="n"
                    if [ "$FORCE" = "true" ]; then
                        confirm="s"
                    else
                        echo ""
                        echo "Primeras 5 líneas de $dep_file:"
                        head -n 5 "$full_path"
                        echo "--------------------------------------"
                        echo -n "¿Eliminar $dep_file? (s/N): "
                        read -r confirm || confirm="n"
                    fi
                    
                    confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')
                    if [ "$confirm" = "s" ] || [ "$confirm" = "si" ]; then
                        if git -C "$TARGET_PROJECT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
                            git -C "$TARGET_PROJECT" rm -f "$dep_file" >/dev/null 2>&1 || true
                        fi
                        rm -f "$full_path"
                        echo "✅ Eliminado: $dep_file"
                    else
                        echo "Omitido: $dep_file"
                    fi
                fi
            done
        fi
    fi
fi

if [ "$DRY_RUN" = true ]; then
    echo "✅ [DRY-RUN] Simulación completada sin escrituras en disco."
else
    echo "✅ Sincronización completada."
fi
