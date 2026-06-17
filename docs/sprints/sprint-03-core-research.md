# Research Sprint 03
> Fuente: Perplexity — 2026-06-17
> Tarea principal: Rediseñar el flujo roadmap ↔ sprint ↔ changelog (T-023) y detección de actualizaciones en check-session.sh (T-024)

## Hallazgos clave sobre Detección de Actualizaciones (Bash + Red + Timeout)

### Opción A — timeout + subshell (Recomendada)
Simple y portable. `timeout` es de GNU coreutils.
```bash
_check_remote_updates() {
  local remote_url="$1"
  local local_hash="$2"
  local cache_file="${TMPDIR:-/tmp}/.agent-os-update-check"
  local cache_ttl=3600  # no consultar más de 1 vez por hora

  # Cache: evitar consultas repetidas en la misma hora
  if [[ -f "$cache_file" ]]; then
    local cache_age=$(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0) ))
    if (( cache_age < cache_ttl )); then
      cat "$cache_file"
      return
    fi
  fi

  # Consulta con timeout estricto de 3s, stderr suprimido
  local remote_hash
  remote_hash=$(timeout 3s git ls-remote "$remote_url" HEAD 2>/dev/null | awk '{print $1}')
  local exit_code=$?

  # exit_code 124 = timeout expirado; 128+ = error git; 0 = éxito
  if [[ $exit_code -eq 0 && -n "$remote_hash" ]]; then
    if [[ "$remote_hash" != "$local_hash" ]]; then
      echo "UPDATE_AVAILABLE:$remote_hash"
    else
      echo "UP_TO_DATE"
    fi
    echo "UPDATE_AVAILABLE:$remote_hash" > "$cache_file" 2>/dev/null || true
  else
    echo "OFFLINE_OR_TIMEOUT"
  fi
}
```
*   **Pros**: sin procesos huérfanos, manejo explícito de exit codes, legible.
*   **Contras**: bloquea 3s si no hay red.

### Opción B — Subshell en background con archivo temporal (Asíncrono)
```bash
_check_updates_async() {
  local remote_url="$1"
  local local_hash="$2"
  local result_file="${TMPDIR:-/tmp}/.agent-os-update-result-$$"

  (
    timeout 3s git ls-remote "$remote_url" HEAD 2>/dev/null \
      | awk '{print $1}' \
      > "$result_file" \
    || echo "OFFLINE" > "$result_file"
  ) &
  local bg_pid=$!

  # ... trabajo local ordinario ...
  wait "$bg_pid" 2>/dev/null

  local remote_hash
  remote_hash=$(cat "$result_file" 2>/dev/null)
  rm -f "$result_file"

  if [[ "$remote_hash" != "OFFLINE" && -n "$remote_hash" && "$remote_hash" != "$local_hash" ]]; then
    echo "Hay actualizaciones del core disponibles."
  fi
}
```
*   **Pros**: no bloquea.
*   **Contras**: más complejo de limpiar.

### Opción C — Cache de hash local sin red (Más ligera)
Comparación HEAD vs FETCH_HEAD y cálculo de edad de FETCH_HEAD:
```bash
_check_local_staleness() {
  local head_hash fetch_hash
  head_hash=$(git rev-parse HEAD 2>/dev/null)
  fetch_hash=$(cat .git/FETCH_HEAD 2>/dev/null | awk '{print $1}' | head -1)

  if [[ -n "$fetch_hash" && "$head_hash" != "$fetch_hash" ]]; then
    echo "DIVERGED_FROM_LAST_FETCH"
  fi

  local fetch_age=$(( $(date +%s) - $(stat -c %Y .git/FETCH_HEAD 2>/dev/null || echo 0) ))
  if (( fetch_age > 86400 )); then
    echo "STALE"
  fi
}
```

## Decisiones tomadas
- Para la tarea T-024, se implementará la combinación de pre-filtro local (Opción C) y verificación remota con timeout (Opción A).
- Esto evita sobrecargar consultas de red innecesarias y asegura un comportamiento óptimo y robusto en check-session.sh.
