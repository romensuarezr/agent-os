#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/generate-flow-map.sh — Agent OS
# Genera el mapa de flujos a partir de UNA única fuente: docs/critical-flows.md
#
# Por qué existe: la topología de este core estaba escrita a mano en varios sitios
# (critical-flows.md, architecture/control-plane-topology.md, el diagrama ASCII de
# AGENTS.md) y ninguno se generaba, así que ninguno se podía verificar. Esto es el
# mismo patrón de fallo que T-100 y T-101 corrigieron en los scripts de cierre:
# afirmar sin comprobar. El mapa se genera, y el check 21 exige que esté sincronizado.
#
#.restricciones deliberadas:
#   1. FUENTE ÚNICA. Solo lee $ROOT/docs/critical-flows.md.
#   2. NO lee docs/architecture/control-plane-topology.md en ningún caso. Ese fichero
#      contiene hostnames de infraestructura reales y la fuente prohíbe expresamente
#      los literales de infraestructura; leerlo los arrastraría al mapa. El
#      incumplimiento de esa política está anotado en roadmap.md.
#   3. DETERMINISTA. Sin fechas, sin SHAs, sin aleatoriedad: la misma entrada produce
#      byte a byte la misma salida, que es lo que hace posible --check.
#   4. Sin dependencias: awk + bash, portable entre Linux y macOS. El diagrama es
#      Mermaid, que GitHub renderiza de forma nativa dentro del propio .md, así que no
#      hay build, ni binario, ni paso de renderizado.
#
# Uso:
#   bash scripts/agent/generate-flow-map.sh [--root <dir>] [--check]
#
#   --root <dir>   Raíz del proyecto. Por defecto, la del propio core. Existe para que
#                  un proyecto hijo pueda generar su propio mapa contra su raíz.
#   --check        No escribe nada: regenera en memoria y falla (código 1) si las
#                  salidas versionadas no coinciden con la fuente. Es el modo que usa
#                  el check 21 de la suite.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CHECK_MODE=false

while [ $# -gt 0 ]; do
    case "$1" in
        --root)
            ROOT="$2"
            shift 2
            ;;
        --check)
            CHECK_MODE=true
            shift
            ;;
        -h|--help)
            sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Argumento no reconocido: $1" >&2
            exit 1
            ;;
    esac
done

SOURCE="$ROOT/docs/critical-flows.md"
OUT_MAP="$ROOT/docs/flow-map.md"
OUT_DIGEST="$ROOT/docs/flow-map.digest.md"

if [ ! -f "$SOURCE" ]; then
    echo "ERROR: no se encuentra la fuente $SOURCE" >&2
    exit 1
fi

# ── Lectura de la fuente ──────────────────────────────────────────────────────
# Niveles:  | L1 | Sistema | descripción |
read_levels() {
    awk -F'|' '
        /^\| L[0-9] / {
            gsub(/^ +| +$/, "", $2); gsub(/^ +| +$/, "", $3); gsub(/^ +| +$/, "", $4)
            if ($2 != "") print $2 "\t" $3 "\t" $4
        }
    ' "$SOURCE"
}

# Flujos:    | 1 | **Nombre** | L2 | riesgo | 🟡 | T-098 |
read_flows() {
    awk -F'|' '
        /^\| [0-9]+ \|/ {
            gsub(/^ +| +$/, "", $2); gsub(/^ +| +$/, "", $3); gsub(/^ +| +$/, "", $4)
            gsub(/^ +| +$/, "", $5); gsub(/^ +| +$/, "", $6); gsub(/^ +| +$/, "", $7)
            # El 4o campo debe ser un nivel (L1..L4). Sin esta condicion, las filas de la
            # tabla de relaciones ("| 3 | 4 | mecanismo |") se colaban como flujos.
            if ($2 ~ /^[0-9]+$/ && $4 ~ /^L[0-9]+$/) print $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7
        }
    ' "$SOURCE"
}

# Relaciones: | 3 | 4 | mecanismo |
read_relations() {
    awk -F'|' '
        /^\| [0-9]+ \| [0-9]+ \|/ {
            gsub(/^ +| +$/, "", $2); gsub(/^ +| +$/, "", $3); gsub(/^ +| +$/, "", $4)
            if ($2 ~ /^[0-9]+$/ && $3 ~ /^[0-9]+$/) print $2 "\t" $3 "\t" $4
        }
    ' "$SOURCE"
}

# El nombre del flujo viene en negrita (**...**); Mermaid y el digest lo quieren plano.
clean_name() { echo "$1" | sed 's/\*\*//g'; }

# ── Salida humana ────────────────────────────────────────────────────────────
build_map() {
    cat <<'HEADER'
# Mapa de flujos — Agent OS Core

> 🔒 **GENERADO AUTOMÁTICAMENTE — NO EDITAR A MANO.**
> Fuente única: [`docs/critical-flows.md`](critical-flows.md). Regenerar con:
> `bash scripts/agent/generate-flow-map.sh`
>
> El mapa no es una fuente independiente: es una proyección de la fuente. Si algo aquí
> no cuadra con `critical-flows.md`, **la fuente es lo que vale** y el mapa está
> desactualizado. El check 21 de la suite falla mientras eso siga siendo cierto.

## Niveles C4 adaptados

Los nombres C4 se conservan; lo que se define aquí es qué representa cada nivel en un
core bash (scripts, worktrees y assets), para que la columna no sea decorativa.

HEADER
    read_levels | while IFS=$'\t' read -r lvl name desc; do
        echo "- **$lvl — $name** — $desc"
    done

    cat <<'MID'

## Diagrama

```mermaid
flowchart TD
MID
    # Un subgrafo por nivel. Los flujos se declaran vacíos aunque no haya ninguno:
    # un subgraph sin contenido rompe el render de Mermaid.
    local local_niveles lvl_name nodos
    local_niveles="$(read_levels | cut -f1)"
    for lvl in $local_niveles; do
        lvl_name="$(read_levels | awk -F'\t' -v l="$lvl" '$1==l{print $2}')"
        echo "  subgraph $lvl[\"$lvl — $lvl_name\"]"
        echo "    direction TB"
        nodos=""
        while IFS=$'\t' read -r num name flow_lvl _risk _cov _task; do
            [ "$flow_lvl" = "$lvl" ] || continue
            nodos="${nodos}    F${num}[\"${num} · $(clean_name "$name")\"]
"
        done <<< "$(read_flows)"
        if [ -n "$nodos" ]; then
            printf '%s' "$nodos"
        else
            # Un subgraph sin ningún nodo rompe el render de Mermaid.
            echo "    vacio[\"(sin flujos registrados)\"]"
        fi
        echo "  end"
    done
    read_relations | while IFS=$'\t' read -r from to mech; do
        echo "  F$from --- F$to"
    done

    cat <<'MID2'
```

## Registro de flujos

| # | Flujo | Nivel | Riesgo principal | Cobertura | Última tarea |
| :-- | :--- | :--- | :--- | :--: | :--- |
MID2
    read_flows | while IFS=$'\t' read -r num name lvl risk cov task; do
        echo "| $num | $(clean_name "$name") | $lvl | $risk | $cov | $task |"
    done

    cat <<'TAIL'

## Relaciones

| Desde | Hacia | Mecanismo |
| :-- | :-- | :--- |
TAIL
    read_relations | while IFS=$'\t' read -r from to mech; do
        echo "| $from | $to | $mech |"
    done

    cat <<'TAIL2'

---

## Sobre este mapa

- **Una sola fuente**: `docs/critical-flows.md`. Este fichero es una proyección suya.
- **Sin literales de infraestructura**: por política de la fuente, el mapa no contiene IPs,
  dominios ni hostnames. `docs/architecture/control-plane-topology.md` sí los contiene y
  **no se lee** para generar este mapa; su incumplimiento está anotado en `roadmap.md`.
- **Sin build**: el diagrama es Mermaid, que GitHub renderiza dentro de este mismo `.md`.
- **Vista para agentes**: [`flow-map.digest.md`](flow-map.digest.md), plana y acotada.
TAIL2
}

# ── Digest para agentes ──────────────────────────────────────────────────────
# Plano, acotado y sin prosa: es lo que un agente lee para saber qué flujos existen
# y cuál es su cobertura, sin gastar contexto en explicaciones.
build_digest() {
    echo "# flow-map.digest — Agent OS Core (generado; fuente: docs/critical-flows.md)"
    echo "# líneas: $(read_flows | wc -l | tr -d ' ') flujos · no editar a mano"
    echo
    read_flows | while IFS=$'\t' read -r num name lvl risk cov task; do
        echo "$num|$lvl|$cov|$(clean_name "$name")|tarea:$task"
    done
    echo
    echo "relaciones:"
    read_relations | while IFS=$'\t' read -r from to mech; do
        echo "  $from->$to"
    done
    echo
    echo "niveles:"
    read_levels | while IFS=$'\t' read -r lvl name desc; do
        echo "  $lvl=$name"
    done
}

# ── Escritura o verificación ─────────────────────────────────────────────────
if [ "$CHECK_MODE" = true ]; then
    MAP_TMP="$(mktemp)"; DIGEST_TMP="$(mktemp)"
    trap 'rm -f "$MAP_TMP" "$DIGEST_TMP"' EXIT
    build_map > "$MAP_TMP"
    build_digest > "$DIGEST_TMP"

    RC=0
    for pair in "$OUT_MAP:$MAP_TMP" "$OUT_DIGEST:$DIGEST_TMP"; do
        target="${pair%%:*}"; tmpf="${pair#*:}"
        if [ ! -f "$target" ]; then
            echo "❌ $target no existe: ejecuta generate-flow-map.sh" >&2
            RC=1
        elif ! diff -u "$target" "$tmpf" > /dev/null 2>&1; then
            echo "❌ $target está DESACTUALIZADO respecto a la fuente:" >&2
            diff -u "$target" "$tmpf" | head -20 >&2
            echo "   → ejecuta: bash scripts/agent/generate-flow-map.sh" >&2
            RC=1
        fi
    done
    if [ $RC -eq 0 ]; then
        echo "✅ flow-map.md y flow-map.digest.md están sincronizados con la fuente."
    fi
    exit $RC
fi

MAP_TMP="$(mktemp)"; DIGEST_TMP="$(mktemp)"
trap 'rm -f "$MAP_TMP" "$DIGEST_TMP"' EXIT
build_map > "$MAP_TMP"
build_digest > "$DIGEST_TMP"
mv "$MAP_TMP" "$OUT_MAP"
mv "$DIGEST_TMP" "$OUT_DIGEST"
echo "✅ Mapa generado:"
echo "   - $OUT_MAP"
echo "   - $OUT_DIGEST"