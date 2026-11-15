#!/usr/bin/env bash
# ==============================================================================
# sync_agent_os_core.sh — Sincronización determinista de Agent OS Core y Skills
# Entorno: Hermes Gateway / Concierge Host
# Coste de inferencia: $0 tokens
# ==============================================================================
set -euo pipefail

REPO_DIR="${AGENT_OS_DIR:-$HOME/projects/agent-os}"
HERMES_SKILLS_DIR="${HERMES_SKILLS_DIR:-$HOME/.hermes/skills/agent-os}"
RUNTIME_DIR="${HERMES_RUNTIME_DIR:-$HOME/.hermes/runtime}"
STATUS_FILE="${RUNTIME_DIR}/last_core_update.json"

mkdir -p "${HERMES_SKILLS_DIR}" "${RUNTIME_DIR}"

if [ ! -d "${REPO_DIR}/.git" ]; then
    echo "❌ ERROR: No se encontró el repositorio git en ${REPO_DIR}" >&2
    exit 1
fi

cd "${REPO_DIR}"

OLD_REV="$(git rev-parse HEAD 2>/dev/null || echo 'unknown')"
OLD_VERSION="unknown"
[ -f "VERSION" ] && OLD_VERSION="$(cat VERSION | tr -d '[:space:]')"

# 1. Fetch y pull si hay cambios en la rama activa
git fetch origin multi-agent --quiet
LOCAL_REV="$(git rev-parse HEAD)"
REMOTE_REV="$(git rev-parse origin/multi-agent)"
UPDATED=false

if [ "${LOCAL_REV}" != "${REMOTE_REV}" ]; then
    git pull --ff-only origin multi-agent --quiet
    UPDATED=true
fi

NEW_REV="$(git rev-parse HEAD)"
NEW_VERSION="unknown"
[ -f "VERSION" ] && NEW_VERSION="$(cat VERSION | tr -d '[:space:]')"

# 2. Sincronización atómica de symlinks de skills
TOTAL_SKILLS=0
NEW_LINKS=0

if [ -d ".agents/skills" ]; then
    for skill_path in .agents/skills/*; do
        [ -d "${skill_path}" ] || continue
        skill_name="$(basename "${skill_path}")"
        abs_skill_path="$(readlink -f "${skill_path}")"
        target_link="${HERMES_SKILLS_DIR}/${skill_name}"
        
        TOTAL_SKILLS=$((TOTAL_SKILLS + 1))
        
        if [ ! -L "${target_link}" ] || [ "$(readlink -f "${target_link}" 2>/dev/null || true)" != "${abs_skill_path}" ]; then
            ln -sfn "${abs_skill_path}" "${target_link}"
            NEW_LINKS=$((NEW_LINKS + 1))
        fi
    done
fi

# Limpieza de symlinks rotos en el directorio de skills de Hermes
for existing_link in "${HERMES_SKILLS_DIR}"/*; do
    [ -L "${existing_link}" ] || continue
    if [ ! -e "${existing_link}" ]; then
        rm -f "${existing_link}"
    fi
done

# 3. Permisos ejecutables a scripts
chmod +x "${REPO_DIR}"/scripts/agent/*.sh 2>/dev/null || true
chmod +x "${REPO_DIR}"/scripts/ops/*.sh 2>/dev/null || true

# 4. Registro de estado
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat <<STATUS_EOF > "${STATUS_FILE}"
{
  "version": "${NEW_VERSION}",
  "commit": "${NEW_REV}",
  "updated_at": "${TIMESTAMP}",
  "updated": ${UPDATED},
  "previous_commit": "${OLD_REV}",
  "previous_version": "${OLD_VERSION}",
  "skills_count": ${TOTAL_SKILLS},
  "new_skills_linked": ${NEW_LINKS}
}
STATUS_EOF

# 5. Salida determinista:
# Si hay novedades (update o nueva skill), emite reporte para WhatsApp / logs.
# Si no hay cambios y corre sin TTY (cronjob), permanece silencioso (wakeAgent=false / silent run).
INTERACTIVE=false
[ -t 1 ] && INTERACTIVE=true

if [ "${UPDATED}" = true ] || [ "${NEW_LINKS}" -gt 0 ]; then
    echo "🚀 *Agent OS Core*: Actualizado a v${NEW_VERSION} (${NEW_REV:0:7})"
    echo "• Estado: Cambios de versión sincronizados en nodo de inferencia"
    echo "• Habilidades activas: ${TOTAL_SKILLS} (nuevas enlazadas: ${NEW_LINKS})"
    echo "• Scripts del Core: permisos (+x) verificados"
    echo "💡 Puedes enviar /reload-skills para recargar herramientas en caliente."
elif [ "${INTERACTIVE}" = true ] || [ "${1:-}" = "--verbose" ] || [ "${1:-}" = "-v" ]; then
    echo "🚀 Agent OS Core: v${NEW_VERSION} (${NEW_REV:0:7}) | Sin cambios pendientes | Skills: ${TOTAL_SKILLS}"
fi
