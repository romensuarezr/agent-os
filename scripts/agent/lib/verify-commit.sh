#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/lib/verify-commit.sh — Agent OS
# Verificación post-condición de un commit: validar ANTES de mover el ref.
#
# Por qué existe: un script que hace `git commit` y dice "✅ hecho" sin comprobar que
# el commit contenga lo que afirma haber hecho. Pasó en producción: el cierre de
# sprint-14 commiteó `0 insertions / 0 deletions` (solo el rename) y dejó las
# modificaciones sin stagear colgando en el working tree.
#
# Patrón (investigación de Perplexity, sprint-15):
#   1. Índice temporal → write-tree → commit-tree   (no se mueve ningún ref)
#   2. diff-tree -r --no-commit-id --name-status    (tabla binaria, no texto)
#   3. Si el patrón esperado aparece → update-ref   (el commit existe a partir de aquí)
#   Si la aserción falla NO se crea ningún commit y el repo queda intacto: no hace
#   falta `git reset --soft` porque nunca se llegó a mover el ref.
#
# CONSECUENCIA DOCUMENTADA: `git update-ref` NO dispara los hooks de git
# (pre-commit, commit-msg). Un repo cuyo hook bloquee commits deja de estar
# protegido en el commit de cierre. Es el precio de validar antes de commitear.
#
# Uso:
#   source lib/verify-commit.sh
#   agent_verify_commit <root> <mensaje> <patrón-esperado> "<descripción>"
#
# Códigos de retorno:
#   0 → commit creado y verificado (o fallback con aviso explícito)
#   1 → la aserción falló: NO se creó commit, el repo queda intacto
# ==============================================================================

# Aviso explícito y ruidoso para cualquier commit que quede SIN verificar.
agent_unverified_warning() {
    local motivo="$1" fallback="$2"
    echo "" >&2
    printf "  ╔%s╗\n" "$(printf '═%.0s' $(seq 1 60))" >&2
    printf "  ║ %-60s ║\n" "⚠️  COMMIT CREADO SIN VERIFICAR" >&2
    printf "  ║ %-60s ║\n" "Motivo: $motivo" >&2
    printf "  ║ %-60s ║\n" "Fallback usado: $fallback" >&2
    printf "  ║ %-60s ║\n" "El commit existe pero no se ha comprobado su contenido." >&2
    printf "  ║ %-60s ║\n" "Revísalo a mano: git show --stat HEAD" >&2
    printf "  ╚%s╝\n" "$(printf '═%.0s' $(seq 1 60))" >&2
    echo "" >&2
}

# agent_verify_commit <root> <mensaje> <patrón> <descripción>
agent_verify_commit() {
    local root="$1" msg="$2" expect="$3" desc="${4:-el cambio}"
    local tmp_index tree staged_tree sha diff_out

    tmp_index="$(mktemp)" || {
        agent_unverified_warning "no se pudo crear el índice temporal" "git commit directo"
        git -C "$root" commit -m "$msg"; return 0
    }
    rm -f "$tmp_index"          # git exige que el fichero de índice no exista aún

    if ! GIT_INDEX_FILE="$tmp_index" git -C "$root" read-tree HEAD 2>/dev/null; then
        rm -f "$tmp_index"
        agent_unverified_warning "no se pudo leer HEAD al índice temporal" "git commit directo"
        git -C "$root" commit -m "$msg"; return 0
    fi

    # Vaciar el stage actual (lo que el script ya ha preparado) dentro del temporal
    staged_tree="$(git -C "$root" write-tree)" || {
        rm -f "$tmp_index"
        agent_unverified_warning "no se pudo escribir el árbol del stage" "git commit directo"
        git -C "$root" commit -m "$msg"; return 0
    }
    if ! GIT_INDEX_FILE="$tmp_index" git -C "$root" read-tree "$staged_tree" 2>/dev/null; then
        rm -f "$tmp_index"
        agent_unverified_warning "no se pudo cargar el árbol del stage" "git commit directo"
        git -C "$root" commit -m "$msg"; return 0
    fi

    tree="$(GIT_INDEX_FILE="$tmp_index" git -C "$root" write-tree)" || {
        rm -f "$tmp_index"
        agent_unverified_warning "no se pudo construir el árbol temporal" "git commit directo"
        git -C "$root" commit -m "$msg"; return 0
    }

    # El mensaje se toma del ARGUMENTO ($msg), nunca de una global del script llamador.
    sha="$(printf '%s\n' "$msg" | git -C "$root" commit-tree "$tree" -p HEAD)" || {
        rm -f "$tmp_index"
        agent_unverified_warning "no se pudo crear el objeto commit" "git commit directo"
        git -C "$root" commit -m "$msg"; return 0
    }

    # -c core.quotePath=false: sin esto, rutas con espacios o no-ASCII se entrecomillan
    # y el patrón no casaría justo en los casos límite que queremos detectar.
    diff_out="$(git -C "$root" -c core.quotePath=false \
                    diff-tree -r --no-commit-id --name-status "$sha" 2>/dev/null || true)"

    if printf '%s' "$diff_out" | grep -q -- "$expect"; then
        git -C "$root" update-ref HEAD "$sha" "$(git -C "$root" rev-parse HEAD)"
        rm -f "$tmp_index"
        echo "  ✅ $desc verificado en el commit antes de mover el ref"
        return 0
    fi

    rm -f "$tmp_index"
    echo "  ╔$(printf '═%.0s' $(seq 1 60))╗" >&2
    printf "  ║ %-60s ║\n" "❌ ABORTADO: el commit no contiene lo que el" >&2
    printf "  ║ %-60s ║\n" "script afirma hacer." >&2
    printf "  ║ %-60s ║\n" "Esperado: $expect" >&2
    printf "  ║ %-60s ║\n" "Obtenido:" >&2
    if [ -n "$diff_out" ]; then
        printf '%s\n' "$diff_out" | head -8 | sed 's/^/     /' >&2
    else
        printf "  ║ %-60s ║\n" "(vacío: el commit no cambia nada respecto a HEAD)" >&2
    fi
    printf "  ║ %-60s ║\n" "No se ha creado ningún commit; el repo queda intacto." >&2
    printf "  ╚%s╝\n" "$(printf '═%.0s' $(seq 1 60))" >&2
    return 1
}