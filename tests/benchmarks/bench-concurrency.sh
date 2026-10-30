#!/usr/bin/env bash
# ==============================================================================
# tests/benchmarks/bench-concurrency.sh — Arnés de benchmarking concurrente
# ==============================================================================
# Ejecuta una batería de deliberaciones concurrentes (N=10, C=2) contra el
# motor determinista scripts/agent/deliberate-plan.sh, calculando percentiles
# bajo el método de rango más cercano (nearest-rank), disponibilidad de Tier 1
# y censo de terminales según el Gate de T-140.
# ==============================================================================

set -uo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR" || exit 1

RUNS=10
CONCURRENCY=2
OUTPUT_FILE="$ROOT_DIR/.agents/context/bench-results-10.json"
KEEP_TEMP=false

show_help() {
  cat << 'EOF'
Uso: tests/benchmarks/bench-concurrency.sh [OPCIONES]

Opciones:
  --runs <N>              Número total de ejecuciones (default: 10)
  --concurrency <C>       Número de ejecuciones simultáneas por lote (default: 2)
  --output <PATH>         Ruta del JSON con los resultados agregados
  --keep-temp             Conserva archivos temporales de plan y veredicto
  -h, --help              Muestra esta ayuda
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --runs)
      RUNS="${2:-10}"
      shift 2
      ;;
    --concurrency)
      CONCURRENCY="${2:-2}"
      shift 2
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --keep-temp)
      KEEP_TEMP=true
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Parámetro desconocido: $1" >&2
      show_help
      exit 1
      ;;
  esac
done

# Verificación de dependencias
for cmd in orca python3 jq git date; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ Dependencia requerida no encontrada: $cmd" >&2
    exit 1
  fi
done

CONTEXT_DIR="$ROOT_DIR/.agents/context"
mkdir -p "$CONTEXT_DIR" "$(dirname "$OUTPUT_FILE")"

echo "======================================================================"
echo "  ARNÉS DE BENCHMARKING CONCURRENTE — AGENT OS (PILOTO SPRINT 25)     "
echo "======================================================================"
echo "Parámetros: N=$RUNS ejecuciones | Concurrencia C=$CONCURRENCY | Timeout default: 60s"
echo "Método de Percentiles: Nearest-Rank [ceil((P/100)*N)]"
echo ""

# 1. Censo inicial de terminales
echo "🔍 [1/3] Auditando censo inicial de terminales en host..."
CENSUS_BEFORE_RAW="$(orca orchestration worker-list --json 2>/dev/null || echo '{}')"
ACTIVE_BEFORE_RAW="$(orca orchestration worker-list --terminal-state active --json 2>/dev/null || echo '{}')"

ACTIVE_BEFORE=$(echo "$ACTIVE_BEFORE_RAW" | jq -r '.result.workers | length // 0' 2>/dev/null || echo 0)
RETAINED_BEFORE=$(echo "$CENSUS_BEFORE_RAW" | jq -r '.result.counts.retained // 0' 2>/dev/null || echo 0)
RECLAIMABLE_BEFORE=$(echo "$CENSUS_BEFORE_RAW" | jq -r '.result.counts.reclaimable // 0' 2>/dev/null || echo 0)
RELEASED_BEFORE=$(echo "$CENSUS_BEFORE_RAW" | jq -r '.result.counts.released // 0' 2>/dev/null || echo 0)

echo "  Terminales activas actuales: $ACTIVE_BEFORE"
echo "  Terminales históricas preexistentes: retained=$RETAINED_BEFORE, reclaimable=$RECLAIMABLE_BEFORE, released=$RELEASED_BEFORE"
echo ""

# 2. Ejecución de la batería por lotes
echo "🚀 [2/3] Ejecutando batería concurrente ($RUNS ejecuciones en lotes de $CONCURRENCY)..."
RESULTS_TMP_DIR="$(mktemp -d "$CONTEXT_DIR/bench-tmp-XXXXXX")"
trap 'rm -rf "$RESULTS_TMP_DIR"' EXIT

BATCHES=$(( (RUNS + CONCURRENCY - 1) / CONCURRENCY ))
EXEC_COUNT=0

for (( b=1; b<=BATCHES; b++ )); do
  PIDS=()
  BATCH_IDS=()
  echo "--- Lote $b/$BATCHES ---"

  for (( c=1; c<=CONCURRENCY; c++ )); do
    EXEC_COUNT=$((EXEC_COUNT + 1))
    [ "$EXEC_COUNT" -gt "$RUNS" ] && break

    TASK_ID=$(printf "T-BENCH-%02d" "$EXEC_COUNT")
    PLAN_FILE="$CONTEXT_DIR/bench-plan-${TASK_ID}.md"
    DELIB_FILE="$CONTEXT_DIR/bench-deliberation-${TASK_ID}.json"
    LOG_FILE="$RESULTS_TMP_DIR/${TASK_ID}.log"
    META_FILE="$RESULTS_TMP_DIR/${TASK_ID}.json"
    BATCH_IDS+=("$TASK_ID")

    # Generar borrador sintético de plan
    cat << EOF > "$PLAN_FILE"
# Plan de Calibración Concurrente — ${TASK_ID}

## 1. Contexto y Diagnóstico
Prueba sintética ${EXEC_COUNT}/${RUNS} de calibración concurrente (C=${CONCURRENCY}) para validación del gate de paralelismo.

## 2. Alcance
Evaluación de latencia, estabilidad y consistencia sin mutación de código ni persistencia core.

## 3. Skills
- orchestrator
- agent-os-scripts

## 4. Criterios de Aceptación
1. Evaluación resuelta en Tier 1 (Orca ADE).
2. Latencia dentro del umbral de gate (<60s).
3. Veredicto emitido sin residuos en host.
EOF

    # Ejecutar worker en background
    (
      START_EPOCH=$(python3 -c "import time; print(f'{time.time():.4f}')")
      RAW_OUT="$(bash "$ROOT_DIR/scripts/agent/deliberate-plan.sh" --plan "$PLAN_FILE" --task-id "$TASK_ID" --output "$DELIB_FILE" --json 2>&1 || true)"
      END_EPOCH=$(python3 -c "import time; print(f'{time.time():.4f}')")
      DURATION=$(python3 -c "print(f'{$END_EPOCH - $START_EPOCH:.4f}')")

      echo "$RAW_OUT" > "$LOG_FILE"

      # Extraer veredicto y tier
      TIER="sin_revisor"
      VERDICT="DESCONOCIDO"
      ROUNDS=0
      if [ -f "$DELIB_FILE" ]; then
        TIER=$(jq -r '.evaluator_tier // "sin_revisor"' "$DELIB_FILE" 2>/dev/null || echo "sin_revisor")
        VERDICT=$(jq -r '.verdict // "DESCONOCIDO"' "$DELIB_FILE" 2>/dev/null || echo "DESCONOCIDO")
        ROUNDS=$(jq -r '.rounds_executed // 0' "$DELIB_FILE" 2>/dev/null || echo 0)
      fi

      cat << JSON_ENTRY > "$META_FILE"
{
  "task_id": "$TASK_ID",
  "batch": $b,
  "start_epoch": $START_EPOCH,
  "end_epoch": $END_EPOCH,
  "duration_seconds": $DURATION,
  "evaluator_tier": "$TIER",
  "verdict": "$VERDICT",
  "rounds_executed": $ROUNDS
}
JSON_ENTRY
    ) &
    PIDS+=($!)
    echo "  [Lanzado] $TASK_ID (PID: ${PIDS[-1]})"
  done

  # Esperar a que todos los procesos del lote terminen
  for pid in "${PIDS[@]}"; do
    wait "$pid"
  done

  # Resumen del lote
  for task_id in "${BATCH_IDS[@]}"; do
    if [ -f "$RESULTS_TMP_DIR/${task_id}.json" ]; then
      dur=$(jq -r '.duration_seconds' "$RESULTS_TMP_DIR/${task_id}.json")
      tier=$(jq -r '.evaluator_tier' "$RESULTS_TMP_DIR/${task_id}.json")
      verd=$(jq -r '.verdict' "$RESULTS_TMP_DIR/${task_id}.json")
      echo "  [Finalizado] $task_id: ${dur}s | tier: $tier | veredicto: $verd"
    else
      echo "  [Error] $task_id: sin metadatos generados"
    fi
  done
done
echo ""

# 3. Censo final de terminales
echo "🔍 [3/3] Auditando censo final de terminales post-batería..."
CENSUS_AFTER_RAW="$(orca orchestration worker-list --json 2>/dev/null || echo '{}')"
ACTIVE_AFTER_RAW="$(orca orchestration worker-list --terminal-state active --json 2>/dev/null || echo '{}')"

ACTIVE_AFTER=$(echo "$ACTIVE_AFTER_RAW" | jq -r '.result.workers | length // 0' 2>/dev/null || echo 0)
RETAINED_AFTER=$(echo "$CENSUS_AFTER_RAW" | jq -r '.result.counts.retained // 0' 2>/dev/null || echo 0)
RECLAIMABLE_AFTER=$(echo "$CENSUS_AFTER_RAW" | jq -r '.result.counts.reclaimable // 0' 2>/dev/null || echo 0)
RELEASED_AFTER=$(echo "$CENSUS_AFTER_RAW" | jq -r '.result.counts.released // 0' 2>/dev/null || echo 0)

# 4. Procesamiento estadístico determinista con Python
COMBINED_RUNS="$RESULTS_TMP_DIR/combined.json"
jq -s '.' "$RESULTS_TMP_DIR"/T-BENCH-*.json > "$COMBINED_RUNS"

python3 - << PYEOF > "$OUTPUT_FILE"
import json
import math
import sys

with open("$COMBINED_RUNS", "r") as f:
    runs = json.load(f)

runs.sort(key=lambda r: r["task_id"])
durations = [r["duration_seconds"] for r in runs]
sorted_durations = sorted(durations)
n = len(sorted_durations)

def nearest_rank(p, values):
    """Método de rango más cercano (nearest-rank): rank = ceil((p/100) * N)"""
    if not values:
        return 0.0
    rank = math.ceil((p / 100.0) * len(values))
    idx = max(0, min(rank - 1, len(values) - 1))
    return values[idx]

p50 = nearest_rank(50, sorted_durations)
p90 = nearest_rank(90, sorted_durations)
p95 = nearest_rank(95, sorted_durations)
min_dur = sorted_durations[0] if sorted_durations else 0.0
max_dur = sorted_durations[-1] if sorted_durations else 0.0

tier_1_count = sum(1 for r in runs if r.get("evaluator_tier") == "orca")
tier_1_ratio = (tier_1_count / float(n)) * 100.0 if n > 0 else 0.0

active_before = int("$ACTIVE_BEFORE")
active_after = int("$ACTIVE_AFTER")
new_orphaned = max(0, active_after - active_before)

# Criterios del Gate de T-140
p95_pass = p95 < 45.0
max_pass = max_dur < 60.0
tier1_pass = tier_1_ratio >= 95.0
orphans_pass = active_after == 0

causales = []
if not p95_pass:
    causales.append(f"P95 ({p95:.2f}s) >= 45.0s")
if not max_pass:
    causales.append(f"Latencia máxima individual ({max_dur:.2f}s) >= 60.0s")
if not tier1_pass:
    causales.append(f"Disponibilidad Tier 1 ({tier_1_ratio:.1f}%) < 95.0%")
if not orphans_pass:
    causales.append(f"Terminales activas huérfanas detectadas ({active_after} > 0)")

gate_verdict = "GO" if (p95_pass and max_pass and tier1_pass and orphans_pass) else "NO-GO"
causal_str = "Ninguna (Todos los umbrales cumplidos)" if gate_verdict == "GO" else "; ".join(causales)

report = {
    "benchmark": {
        "runs": n,
        "concurrency": int("$CONCURRENCY"),
        "method": "nearest-rank",
        "percentile_formula": "ceil((P / 100) * N)"
    },
    "census": {
        "active_before": active_before,
        "active_after": active_after,
        "new_orphaned": new_orphaned,
        "historical_preexisting": {
            "retained": int("$RETAINED_BEFORE"),
            "reclaimable": int("$RECLAIMABLE_BEFORE"),
            "released": int("$RELEASED_BEFORE")
        },
        "historical_post": {
            "retained": int("$RETAINED_AFTER"),
            "reclaimable": int("$RECLAIMABLE_AFTER"),
            "released": int("$RELEASED_AFTER")
        }
    },
    "metrics": {
        "min_seconds": min_dur,
        "max_seconds": max_dur,
        "p50_seconds": p50,
        "p90_seconds": p90,
        "p95_seconds": p95,
        "tier_1_orca_count": tier_1_count,
        "tier_1_ratio_percent": tier_1_ratio
    },
    "gate_evaluation": {
        "gate_contract": "T-140 (sprint-24-observation-report.md)",
        "verdict": gate_verdict,
        "causal": causal_str,
        "checks": {
            "p95_under_45s": p95_pass,
            "max_under_60s": max_pass,
            "tier_1_gte_95_percent": tier1_pass,
            "zero_orphaned_terminals": orphans_pass
        }
    },
    "runs": runs
}

print(json.dumps(report, indent=2))
PYEOF

# 5. Limpieza de archivos intermedios si no se solicitó conservarlos
if [ "$KEEP_TEMP" = false ]; then
  echo "🧹 Limpiando artefactos temporales de plan y deliberación..."
  rm -f "$CONTEXT_DIR"/bench-plan-T-BENCH-*.md
  rm -f "$CONTEXT_DIR"/bench-deliberation-T-BENCH-*.json
fi

echo "======================================================================"
echo "  RESULTADO DE LA BATERÍA DE CALIBRACIÓN (N=$RUNS, C=$CONCURRENCY)    "
echo "======================================================================"
cat << EOF
📊 Resumen de Latencias (Método: Nearest-Rank):
  - Mínima: $(jq -r '.metrics.min_seconds' "$OUTPUT_FILE")s
  - Mediana (P50): $(jq -r '.metrics.p50_seconds' "$OUTPUT_FILE")s
  - P90: $(jq -r '.metrics.p90_seconds' "$OUTPUT_FILE")s
  - P95: $(jq -r '.metrics.p95_seconds' "$OUTPUT_FILE")s
  - Máxima individual: $(jq -r '.metrics.max_seconds' "$OUTPUT_FILE")s

🎯 Disponibilidad e Higiene:
  - Tasa Tier 1 (Orca): $(jq -r '.metrics.tier_1_ratio_percent' "$OUTPUT_FILE")% ($(jq -r '.metrics.tier_1_orca_count' "$OUTPUT_FILE")/$RUNS)
  - Censo terminales activas: antes=$(jq -r '.census.active_before' "$OUTPUT_FILE"), después=$(jq -r '.census.active_after' "$OUTPUT_FILE") (nuevas huérfanas: $(jq -r '.census.new_orphaned' "$OUTPUT_FILE"))

⚖️ Veredicto Gate T-140:
  - Resultado: $(jq -r '.gate_evaluation.verdict' "$OUTPUT_FILE")
  - Causal: $(jq -r '.gate_evaluation.causal' "$OUTPUT_FILE")
======================================================================
EOF
echo "📄 Reporte estructurado guardado en: $OUTPUT_FILE"
