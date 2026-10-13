#!/usr/bin/env bash
# ==============================================================================
# promote-to-main.sh — Automatización determinista de promoción y cierre de ciclo
# ==============================================================================
# Uso:
#   bash scripts/agent/promote-to-main.sh [--source <rama>] [--target <rama>] [--push] [--json]
#
# Opciones:
#   --source <rama>   Rama origen a promover (por defecto: rama activa actual).
#   --target <rama>   Rama destino (por defecto: main).
#   --push            Sube los cambios consolidados a origin <target>.
#   --skip-tests      Omite la ejecución de tests/validate-control-plane.sh.
#   --json            Emite un digest JSON estricto en stdout (logs a stderr).
#   -h, --help        Muestra esta ayuda.
# ==============================================================================

set -euo pipefail

# Pre-flight: verificación determinista de dependencias
for cmd in git cat; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ ERROR: Dependencia requerida no encontrada: $cmd" >&2
    echo "Guía: Instala $cmd en tu sistema antes de continuar." >&2
    exit 1
  fi
done

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SOURCE=""
TARGET="main"
PUSH=false
PUSH_SOURCE=false
MERGE_COMMIT=false
CREATE_PR=false
JSON_MODE=false
SKIP_TESTS=false

# Modo de merge. --ff-only es el valor por defecto histórico: SOLO se relaja cuando
# el usuario pide --merge-commit explícitamente, para no romper los llamadores actuales.
MERGE_MODE="--ff-only"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE="$2"
      shift 2
      ;;
    --target)
      TARGET="$2"
      shift 2
      ;;
    --push)
      PUSH=true
      shift
      ;;
    --push-source)
      PUSH_SOURCE=true
      shift
      ;;
    --merge-commit)
      MERGE_COMMIT=true
      shift
      ;;
    --pr)
      CREATE_PR=true
      shift
      ;;
    --skip-tests)
      SKIP_TESTS=true
      shift
      ;;
    --json)
      JSON_MODE=true
      shift
      ;;
    -h|--help)
      cat <<'USAGE'
Uso: bash scripts/agent/promote-to-main.sh [flags]

  --source <rama>     Rama de tarea a promover (por defecto: la rama activa).
  --target <rama>     Rama destino (por defecto: main).

  --push              Publica la rama DESTINO (--target) en origin, después de fusionar.
                      OJO: esto NO publica la rama de tarea.

  --push-source       Publica la rama ORIGEN (--source) en origin, con tracking (-u),
                      para que el diff quede disponible en origin y sea revisable.
                      Es independiente de --push: pueden usarse juntos o por separado.

  --merge-commit      Fusiona creando un commit de merge (--no-ff) en vez de avanzar
                      en fast-forward. Por defecto el merge es --ff-only; este flag solo
                      relaja esa exigencia cuando la rama destino ya tiene commits propios.

  --pr                Abre un pull request de --source hacia --target con la CLI gh.
                      Implica publicar la rama origen en origin si no lo está ya.
                      Requiere gh instalado y autenticado (se comprueba antes de actuar).

                      ORDEN: el PR se crea DESPUÉS del merge local, porque para entonces
                      la rama ya está integrada en el worktree de destino.

                      NO COMBINAR CON --push. --push sube 'target' a origin tras la
                      fusión, así que el PR se abriría contra un destino que ya contiene
                      la rama origen: saldría vacío, gh lo rechaza, y el script termina
                      con código 1 pese a haber fusionado bien.

                      Revisión con PR:   --source <rama> --push-source --pr
                      Fusión directa:    --source <rama> --push

  --skip-tests        Omite la suite de validación del control plane.
  --json              Emite el resultado como JSON por stdout (los avisos van a stderr).

Ejemplo (revisión completa de una rama de tarea):
  bash scripts/agent/promote-to-main.sh --source feat/mi-tarea \
       --push-source --pr
USAGE
      exit 0
      ;;
    *)
      echo "Argumento no reconocido: $1" >&2
      exit 1
      ;;
  esac
done

# --merge-commit solo relaja el modo cuando se pide explícitamente.
# El default --ff-only se conserva intacto para no cambiar el comportamiento
# de los llamadores que no usan el flag nuevo.
if [ "$MERGE_COMMIT" = true ]; then
  MERGE_MODE="--no-ff"
fi

# Resolver rama origen por defecto si no se especificó
if [ -z "$SOURCE" ]; then
  SOURCE="$(git branch --show-current 2>/dev/null || git rev-parse --short HEAD)"
fi

log() {
  if [ "$JSON_MODE" = true ]; then
    echo -e "$*" >&2
  else
    echo -e "$*"
  fi
}

err() {
  echo -e "$*" >&2
}

emit_json() {
  local status="$1"
  local merged="$2"
  local pushed="$3"
  local commit_sha="$4"
  local target_wt="$5"
  local msg="$6"
  local code="$7"
  local push_source="${8:-false}"
  local pr_url="${9:-\"\"}"

  cat <<EOF
{
  "status": "$status",
  "source": "$SOURCE",
  "target": "$TARGET",
  "merged": $merged,
  "pushed": $pushed,
  "pushed_source": $push_source,
  "pr_url": $pr_url,
  "commit": "$commit_sha",
  "target_worktree": "$target_wt",
  "merge_mode": "$MERGE_MODE",
  "message": "$msg",
  "exit_code": $code
}
EOF
}

# Pre-flight de --pr: si falta gh o la autenticación, se aborta ANTES de publicar
# o fusionar nada. Nunca dejamos la rama a medio camino por una dependencia ausente.
PR_URL=""
if [ "$CREATE_PR" = true ]; then
  if ! command -v gh >/dev/null 2>&1; then
    err "${RED}❌ ERROR: se pidió --pr pero la CLI 'gh' no está instalada.${NC}"
    err "  Instálala (https://cli.github.com) o quita --pr para promover en local."
    exit 1
  fi
  if ! gh auth status >/dev/null 2>&1; then
    err "${RED}❌ ERROR: se pidió --pr pero 'gh' no está autenticado.${NC}"
    err "  Ejecuta 'gh auth login' o exporta GITHUB_TOKEN. No se ha tocado nada."
    exit 1
  fi
  log "  ℹ️  Pre-flight de 'gh' superado."
fi

log "${BLUE}======================================================${NC}"
log "${BLUE}  PROMOCIÓN DETERMINISTA: ${SOURCE} ➔ ${TARGET}${NC}"
log "${BLUE}======================================================${NC}"

# Publica una ref en origin y VERIFICA que llegó a existir allí.
# No se limita a confiar en el código de salida de git push: un push puede reportar éxito
# y aun así la ref no existir (proxy, credenciales parciales, remoto mal definido).
#   $1 = directorio del worktree ("" para el actual)
#   $2 = ref a publicar
#   $3 = "upstream" para usar -u, o cadena vacía
push_ref() {
  local dir="$1" ref="$2" upstream="$3"
  if [ -n "$dir" ]; then
    git -C "$dir" push $upstream origin "$ref"
  else
    git push $upstream origin "$ref"
  fi
  local rc=$?
  if [ $rc -ne 0 ]; then
    err "${RED}❌ ERROR: 'git push origin ${ref}' falló (código ${rc}).${NC}"
    return 1
  fi
  # Post-condición: la ref debe existir en el remoto, no solo haberlo pedido.
  if ! git ls-remote --exit-code origin "refs/heads/${ref}" >/dev/null 2>&1; then
    err "${RED}❌ ERROR: el push de '${ref}' reportó éxito pero la ref NO existe en origin.${NC}"
    err "  Revisa el remoto: git remote -v / git ls-remote --heads origin"
    return 1
  fi
  return 0
}

# Crea el PR y verifica que la URL devuelta es una URL real.
create_pr() {
  if ! command -v gh >/dev/null 2>&1; then
    err "${RED}❌ ERROR: se pidió --pr pero la CLI 'gh' no está instalada.${NC}"
    err "  Instálala (https://cli.github.com) o quita --pr para promover en local."
    return 1
  fi
  if ! gh auth status >/dev/null 2>&1; then
    err "${RED}❌ ERROR: se pidió --pr pero 'gh' no está autenticado.${NC}"
    err "  Ejecuta 'gh auth login' o usa GITHUB_TOKEN en el entorno. No se ha tocado nada."
    return 1
  fi
  local url
  if ! url="$(gh pr create --base "$TARGET" --head "$SOURCE" \
                  --title "Promoción: ${SOURCE} ➔ ${TARGET}" \
                  --body "Promovido con scripts/agent/promote-to-main.sh" 2>&1)"; then
    err "${RED}❌ ERROR: 'gh pr create' falló:${NC}"
    err "$url"
    if printf '%s' "$url" | grep -qiE "no commits between|already exists"; then
      err "  Causa probable: '${SOURCE}' no tiene commits propios frente a '${TARGET}'."
      if [ "$PUSH" = true ]; then
        err "  Causa más probable: --push ya subió '${TARGET}' con el trabajo integrado,"
        err "  así que el PR saldría vacío. Revisa si --push es lo que querías."
      fi
      err "  También puede ser que ya exista un PR abierto: gh pr list"
    fi
    return 1
  fi
  url="$(printf '%s' "$url" | grep -oE 'https://[^[:space:]]+' | tail -1)"
  if [ -z "$url" ]; then
    err "${RED}❌ ERROR: 'gh pr create' terminó sin devolver una URL utilizable.${NC}"
    err "$url"
    return 1
  fi
  PR_URL="$url"
  return 0
}

# 1. Comprobar que el working tree actual está limpio
log "🔍 [1/4] Verificando estado del working tree actual..."
DIRTY_FILES="$(git status --porcelain 2>/dev/null || true)"
if [ -n "$DIRTY_FILES" ]; then
  err "${RED}❌ ERROR: El working tree actual contiene archivos modificados o sin trackear:${NC}"
  err "$DIRTY_FILES"
  if [ "$JSON_MODE" = true ]; then
    emit_json "FAIL" false false "" "" "Working tree actual sucio" 1
  fi
  exit 1
fi
log "  ✅ Working tree actual limpio."

# 2. Localizar worktree donde target esté activo (si aplica)
log "🔍 [2/4] Resolviendo destino en topología de worktrees..."
find_target_worktree() {
  local target_ref="refs/heads/$1"
  local current_wt=""
  while IFS= read -r line; do
    if [[ "$line" =~ ^worktree[[:space:]]+(.*)$ ]]; then
      current_wt="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^branch[[:space:]]+(.*)$ ]]; then
      if [ "${BASH_REMATCH[1]}" = "$target_ref" ]; then
        echo "$current_wt"
        return 0
      fi
    fi
  done < <(git worktree list --porcelain)
  return 1
}

TARGET_WT="$(find_target_worktree "$TARGET" || true)"

if [ -n "$TARGET_WT" ]; then
  log "  ℹ️  Rama '${TARGET}' detectada en worktree: ${TARGET_WT}"
  # Validar que TARGET_WT no tenga cambios sin commitear
  TARGET_DIRTY="$(git -C "$TARGET_WT" status --porcelain 2>/dev/null || true)"
  if [ -n "$TARGET_DIRTY" ]; then
    err "${RED}❌ ERROR: El worktree destino (${TARGET_WT}) contiene cambios pendientes:${NC}"
    err "$TARGET_DIRTY"
    if [ "$JSON_MODE" = true ]; then
      emit_json "FAIL" false false "" "$TARGET_WT" "Worktree destino sucio" 1
    fi
    exit 1
  fi
else
  log "  ℹ️  Rama '${TARGET}' no está en uso por ningún otro worktree."
fi

# 3. Comprobar que target puede avanzar fast-forward a source
if git rev-parse --verify "refs/heads/$TARGET" >/dev/null 2>&1; then
  if [ "$MERGE_MODE" = "--ff-only" ]; then
    if ! git merge-base --is-ancestor "$TARGET" "$SOURCE" 2>/dev/null; then
      err "${RED}❌ ERROR: '${TARGET}' no es ancestro de '${SOURCE}'. Se requiere rebase antes de --ff-only, o usa --merge-commit.${NC}"
      if [ "$JSON_MODE" = true ]; then
        emit_json "FAIL" false false "" "$TARGET_WT" "Requiere rebase, target no es ancestro" 1
      fi
      exit 1
    fi
    log "  ✅ Verificación fast-forward superada (${TARGET} es ancestro de ${SOURCE})."
  else
    log "  ℹ️  Modo --merge-commit: no se exige que ${TARGET} sea ancestro de ${SOURCE}."
  fi
fi

# 4. Ejecutar tests del control plane (si existen)
if [ "$SKIP_TESTS" = false ]; then
  if [ -f "$ROOT/tests/validate-control-plane.sh" ]; then
    log "🔍 [3/4] Ejecutando suite de validación determinista del Control Plane..."
    if ! bash "$ROOT/tests/validate-control-plane.sh" >&2; then
      err "${RED}❌ ERROR: Fallaron las pruebas del Control Plane. Promoción abortada.${NC}"
      if [ "$JSON_MODE" = true ]; then
        emit_json "FAIL" false false "" "$TARGET_WT" "Pruebas del control plane fallidas" 1
      fi
      exit 1
    fi
    log "  ✅ Control Plane 100% verificado."
  fi
else
  log "⚠️  [3/4] Tests omitidos por flag --skip-tests."
fi

# Publicar la rama ORIGEN (--push-source) ANTES de fusionar, por dos razones:
#   a) --pr la necesita en el remoto para poder abrir el PR.
#   b) Si la publicación falla, abortamos sin haber tocado TARGET. Publicar antes
#      deja, en el peor caso, la rama visible para revisión pero sin fusionar, que
#      es un estado recuperable; fusionar antes dejaría main modificado sin que
#      exista el diff en origin, que es el estado a medias que esta tarea prohíbe.
if [ "$PUSH_SOURCE" = true ] || [ "$CREATE_PR" = true ]; then
  if [ "$PUSH_SOURCE" = false ]; then
    log "  ℹ️  --pr implica publicar la rama origen en origin."
  fi
  log "  📤 Publicando la rama ORIGEN '${SOURCE}' en origin (con tracking)..."
  if push_ref "" "$SOURCE" "-u"; then
    PUSH_SOURCE=true
    log "  ✅ Rama '${SOURCE}' publicada y verificada en origin."
  else
    err "${RED}❌ ERROR: no se pudo publicar '${SOURCE}' en origin.${NC}"
    exit 1
  fi
fi


# 5. Ejecutar merge
log "🚀 [4/4] Ejecutando consolidación fast-forward en '${TARGET}'..."
MERGED_COMMIT=""

if [ -n "$TARGET_WT" ]; then
  # En modo --json, stdout es exclusivo del JSON. La redirección va literal: meter
  # ">&2" en una variable NO funciona, porque bash no reparsea el resultado de una
  # expansión como operador de redirección y git lo acabaría leyendo como una ref.
  if [ "$JSON_MODE" = true ]; then
    git -C "$TARGET_WT" merge "$MERGE_MODE" "$SOURCE" >&2
  else
    git -C "$TARGET_WT" merge "$MERGE_MODE" "$SOURCE"
  fi
  MERGED_COMMIT="$(git -C "$TARGET_WT" rev-parse HEAD)"
  log "  ✅ Consolidado en ${TARGET_WT} -> ${MERGED_COMMIT} (${MERGE_MODE})"

  if [ "$PUSH" = true ]; then
    log "  📤 Empujando la rama DESTINO '${TARGET}' hacia 'origin' desde ${TARGET_WT}..."
    push_ref "$TARGET_WT" "$TARGET" "" || exit 1
    log "  ✅ Push de '${TARGET}' verificado en origin."
  fi
else
  ORIGINAL_BRANCH="$(git branch --show-current 2>/dev/null || true)"
  if [ "$JSON_MODE" = true ]; then git checkout "$TARGET" >&2; else git checkout "$TARGET"; fi
  if [ "$JSON_MODE" = true ]; then
    git merge "$MERGE_MODE" "$SOURCE" >&2
  else
    git merge "$MERGE_MODE" "$SOURCE"
  fi
  MERGED_COMMIT="$(git rev-parse HEAD)"
  log "  ✅ Consolidado en ${TARGET} -> ${MERGED_COMMIT} (${MERGE_MODE})"

  if [ "$PUSH" = true ]; then
    log "  📤 Empujando la rama DESTINO '${TARGET}' hacia 'origin'..."
    push_ref "" "$TARGET" "" || exit 1
    log "  ✅ Push de '${TARGET}' verificado en origin."
  fi

  if [ -n "$ORIGINAL_BRANCH" ] && [ "$ORIGINAL_BRANCH" != "$TARGET" ]; then
    if [ "$JSON_MODE" = true ]; then git checkout "$ORIGINAL_BRANCH" >&2; else git checkout "$ORIGINAL_BRANCH"; fi
    log "  ↩️  Restaurada rama activa: ${ORIGINAL_BRANCH}"
  fi
fi

# 7. Pull request (--pr)
if [ "$CREATE_PR" = true ]; then
  log "  🔀 Abriendo pull request '${SOURCE}' ➔ '${TARGET}'..."
  if ! create_pr; then
    exit 1
  fi
  log "  ✅ PR creado: ${PR_URL}"
fi

# Post-condición del merge: el commit de la rama origen tiene que quedar ANCESTRO del
# destino. Es la comprobación que faltaba en el script original: si el merge falló,
# aquí se detecta, en lugar de imprimir "PROMOCIÓN COMPLETADA".
if ! git merge-base --is-ancestor "$SOURCE" "$TARGET" 2>/dev/null; then
  err "${RED}❌ ERROR: la fusión no dejó '${SOURCE}' como ancestro de '${TARGET}'.${NC}"
  err "  El merge pudo no haberse aplicado. Revisa: git log --oneline ${TARGET}"
  if [ "$JSON_MODE" = true ]; then
    emit_json "FAIL" false "$PUSH" "" "$TARGET_WT" "El merge no dejó source ancestro de target" 1 "$PUSH_SOURCE" "${PR_URL:-}"
  fi
  exit 1
fi
log "  ✅ Post-condición verificada: '${SOURCE}' es ancestro de '${TARGET}'."

log ""
log "${GREEN}======================================================${NC}"
log "${GREEN}  ✅ PROMOCIÓN COMPLETADA EXITOSAMENTE               ${NC}"
log "${GREEN}  Rama:   ${TARGET}                                   ${NC}"
log "${GREEN}  Commit: ${MERGED_COMMIT}                            ${NC}"
log "${GREEN}  Merge:  ${MERGE_MODE}                                ${NC}"
log "${GREEN}  Push destino (--push):       ${PUSH}                ${NC}"
log "${GREEN}  Push origen (--push-source): ${PUSH_SOURCE}         ${NC}"
if [ "$CREATE_PR" = true ]; then
  log "${GREEN}  PR: ${PR_URL}${NC}"
fi
log "${GREEN}======================================================${NC}"

if [ "$JSON_MODE" = true ]; then
  emit_json "PASS" true "$PUSH" "$MERGED_COMMIT" "$TARGET_WT" "Promoción completada exitosamente" 0 "$PUSH_SOURCE" "${PR_URL:-}"
fi

exit 0
