#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/lib/release-version.sh — Agent OS
# Sincroniza el fichero VERSION con la release declarada en changelog.md.
#
# Por qué existe (T-113): close-sprint.sh ya leía la versión del changelog para el
# mensaje del commit, pero nunca escribía VERSION. La release v1.14.0 se publicó con
# VERSION=1.12.0 y el desfase se propaga al ledger de los satélites.
#
# Regla de lectura (T-108): la versión es la PRIMERA cabecera con semver válido
# (`## [X.Y.Z]`), no la primera `## [` a secas. Un `## [Unreleased]` arriba no debe
# romper la sincronización ni resolver a una versión inventada.
#
# Garantías:
#   - NUNCA escribe una versión vacía, `unknown` ni la anterior.
#   - Idempotente: si VERSION ya coincide, no toca el fichero.
#   - Solo escribe VERSION; no hace stage ni commit (eso es de close-sprint.sh).
# ==============================================================================

# Imprime la primera versión semver del changelog. Sale 1 si no hay ninguna.
agent_read_changelog_version() {
    local changelog="${1:-}"
    [ -n "$changelog" ] && [ -f "$changelog" ] || return 1
    grep -E '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "$changelog" 2>/dev/null \
        | head -1 \
        | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' \
        | head -1
}

# Sincroniza <root>/VERSION con la release del changelog.
# Uso: agent_sync_version <root> [changelog]
# Sale 0 si VERSION queda alineado (escrito o ya correcto). Sale 1 sin escribir nada
# si no hay changelog o no contiene ninguna versión semver.
agent_sync_version() {
    local root="${1:-}" changelog="${2:-}" version current version_file
    if [ -z "$root" ] || [ ! -d "$root" ]; then
        echo "⚠️  VERSION no sincronizado: directorio raíz inválido (${root:-<vacío>})." >&2
        return 1
    fi
    [ -n "$changelog" ] || changelog="$root/changelog.md"
    if [ ! -f "$changelog" ]; then
        echo "⚠️  VERSION no sincronizado: no existe $changelog." >&2
        return 1
    fi

    version="$(agent_read_changelog_version "$changelog")"
    if [ -z "$version" ]; then
        echo "⚠️  VERSION no sincronizado: el changelog no tiene ninguna cabecera semver (## [X.Y.Z])." >&2
        return 1
    fi

    version_file="$root/VERSION"
    current=""
    [ -f "$version_file" ] && current="$(tr -d '[:space:]' < "$version_file" 2>/dev/null || true)"

    if [ "$current" = "$version" ]; then
        echo "🔖 VERSION ya alineado con el changelog (${version})."
        return 0
    fi

    printf '%s\n' "$version" > "$version_file"
    echo "🔖 VERSION sincronizado: ${current:-<vacío>} → ${version}"
    return 0
}
