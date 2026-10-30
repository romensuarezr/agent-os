#!/usr/bin/env bash
# ==============================================================================
# scripts/agent/lib/orca-reactive-wait.sh — Adaptador reactivo orientado a eventos
# ==============================================================================
# Implementa la espera reactiva basada en el bus de eventos asíncronos de Orca ADE
# (`orca orchestration check --types worker_done --wait` + `worker-read` + `--ack`).
#
# Principios:
#   1. Matching de dispatch: Compara el dispatchId extraído del evento worker_done
#      con el dispatch esperado ANTES de invocar worker-read y antes de emitir --ack.
#   2. NO ackear entregas ajenas: Si la entrega no contiene el dispatch esperado,
#      no se confirma (--ack) y el bucle duerme un intervalo breve para ceder el turno.
#   3. Timeout acotado y decreciente: Calcula y pasa el timeout restante en ms.
#   4. Instrumentación: Registra llamadas a worker-read en $ORCA_CALLS_LOG si está definido.
#   5. Portabilidad POSIX y fallback limpio: Si la espera falla o se interrumpe,
#      retorna no-cero permitiendo fallback a sondeo activo.
# ==============================================================================

SCRIPT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/agent/lib/orca-client.sh
source "$SCRIPT_LIB_DIR/orca-client.sh"

orca_parse_verdict_from_read() {
    local read_json="$1"
    python3 -c '
import json, sys, re

start_delim = "<!-- VERDICT_JSON_START -->"
end_delim = "<!-- VERDICT_JSON_END -->"

try:
    data = json.loads(sys.argv[1], strict=False)
    res = data.get("result", {})
    lines = []
    if "transcript" in res and res["transcript"]:
        t = res["transcript"]
        if isinstance(t, list):
            lines = [str(x) for x in t]
        else:
            lines = [str(t)]
    if not lines and "terminal" in res:
        lines = res.get("terminal", {}).get("tail", [])
    
    full_text = "\n".join(lines)
    matches = []
    pos = 0
    while True:
        s = full_text.find(start_delim, pos)
        if s == -1:
            break
        e = full_text.find(end_delim, s + len(start_delim))
        if e == -1:
            break
        matches.append((s, e))
        pos = e + len(end_delim)

    for s_idx, e_idx in reversed(matches):
        raw_chunk = full_text[s_idx + len(start_delim):e_idx]
        cleaned_lines = []
        for line in raw_chunk.splitlines():
            l = re.sub(r"^[│┃╹╻|\s]+", "", line)
            l = re.sub(r"\s{6,}\S.*$", "", l)
            l = re.sub(r"[│┃╹╻|\s]+$", "", l)
            cleaned_lines.append(l)
        cleaned = "\n".join(cleaned_lines)
        s_brace = cleaned.find("{")
        e_brace = cleaned.rfind("}")
        if s_brace != -1 and e_brace > s_brace:
            json_str = cleaned[s_brace:e_brace + 1]
            try:
                parsed = json.loads(json_str, strict=False)
                v = parsed.get("verdict", "").strip().upper()
                if v in ["CONSENSO", "REVISADO_CON_CAMBIOS", "ESCALADO_A_HUMANO", "RECHAZADO"]:
                    print(json.dumps(parsed))
                    break
            except Exception:
                continue
except Exception:
    pass
' "$read_json" 2>/dev/null || true
}

orca_reactive_wait_for_verdict() {
    local target_dispatch_id="$1"
    local run_id="${2:-}"
    local remaining_timeout="${3:-60}"

    if [ -z "$target_dispatch_id" ]; then
        echo "❌ Error: dispatch_id es obligatorio para orca_reactive_wait_for_verdict" >&2
        return 1
    fi

    if [ "$remaining_timeout" -le 0 ]; then
        return 1
    fi

    local run_args=()
    if [ -n "$run_id" ]; then
        run_args+=(--run "$run_id")
    fi

    local start_ts
    start_ts="$(date +%s)"
    local deadline_ts=$(( start_ts + remaining_timeout ))

    while true; do
        local now_ts
        now_ts="$(date +%s)"
        local remaining_s=$(( deadline_ts - now_ts ))
        if [ "$remaining_s" -le 0 ]; then
            return 1
        fi

        local remaining_ms=$(( remaining_s * 1000 ))

        # 1. Espera reactiva bloqueante en el socket de eventos de Orca ADE
        local check_rc=0
        local check_out
        check_out="$(orca_cmd orchestration check "${run_args[@]}" --types worker_done --wait --timeout-ms "$remaining_ms" --json 2> >(grep -v "_keepalive" >&2))" || check_rc=$?

        if [ "$check_rc" -ne 0 ] || [ -z "$check_out" ]; then
            # Si el comando check falla o retorna vacío, degradar de inmediato
            return 1
        fi

        # 2. Matching de dispatch: inspeccionar el payload antes de worker-read y antes de --ack
        local match_analysis
        match_analysis="$(python3 -c '
import json, sys

raw = sys.argv[1]
target = sys.argv[2]
res = {"supported": False, "matched": False, "deliveryId": None, "timedOut": False}

try:
    data = json.loads(raw, strict=False)
    if "result" in data and isinstance(data["result"], dict) and "messages" in data["result"]:
        res["supported"] = True
        r = data["result"]
        res["deliveryId"] = r.get("deliveryId")
        res["timedOut"] = r.get("timedOut", False)
        
        for msg in r.get("messages", []):
            if msg.get("type") == "worker_done":
                payload = msg.get("payload", {})
                if isinstance(payload, str):
                    try:
                        payload = json.loads(payload)
                    except Exception:
                        payload = {}
                if isinstance(payload, dict):
                    disp = payload.get("dispatchId")
                    if disp == target:
                        res["matched"] = True
                        break
except Exception:
    pass

print(json.dumps(res))
' "$check_out" "$target_dispatch_id" 2>/dev/null || echo '{"supported":false,"matched":false,"deliveryId":null,"timedOut":false}')"

        local supported matched delivery_id timed_out
        supported="$(python3 -c 'import json, sys; print("true" if json.loads(sys.argv[1]).get("supported") else "false")' "$match_analysis" 2>/dev/null || echo false)"
        matched="$(python3 -c 'import json, sys; print("true" if json.loads(sys.argv[1]).get("matched") else "false")' "$match_analysis" 2>/dev/null || echo false)"
        delivery_id="$(python3 -c 'import json, sys; print(json.loads(sys.argv[1]).get("deliveryId") or "")' "$match_analysis" 2>/dev/null || true)"
        timed_out="$(python3 -c 'import json, sys; print("true" if json.loads(sys.argv[1]).get("timedOut") else "false")' "$match_analysis" 2>/dev/null || echo false)"

        if [ "$supported" != "true" ]; then
            # El runtime/stub no implementa orca orchestration check estructurado
            return 1
        fi

        if [ "$timed_out" = "true" ]; then
            return 1
        fi

        # 3. Condición de no-coincidencia (entrega ajena o sin worker_done target)
        if [ "$matched" != "true" ]; then
            # REGLA VINCULANTE: NO ackear entregas ajenas.
            # Dormir breve intervalo (0.5s) para ceder el socket y evitar loop de sondeo acelerado
            # mientras la entrega no coincidente es procesada por su destinatario.
            sleep 0.5
            continue
        fi

        # 4. Coincidencia verificada: proceder a worker-read
        if [ -n "${ORCA_CALLS_LOG:-}" ]; then
            echo "reactive worker-read $(date +%s%N) $target_dispatch_id" >> "$ORCA_CALLS_LOG"
        fi

        local read_out
        read_out="$(orca_worker_read --dispatch "$target_dispatch_id" --limit 100 --json 2>/dev/null || true)"

        local parsed_verdict
        parsed_verdict="$(orca_parse_verdict_from_read "$read_out")"

        if [ -z "$parsed_verdict" ]; then
            # Breve gracia defensiva de 0.5s si el buffer de terminal tarda en consolidarse
            sleep 0.5
            if [ -n "${ORCA_CALLS_LOG:-}" ]; then
                echo "reactive worker-read $(date +%s%N) $target_dispatch_id" >> "$ORCA_CALLS_LOG"
            fi
            read_out="$(orca_worker_read --dispatch "$target_dispatch_id" --limit 100 --json 2>/dev/null || true)"
            parsed_verdict="$(orca_parse_verdict_from_read "$read_out")"
        fi

        # 5. Acuse de recibo (--ack) de nuestra entrega
        if [ -n "$delivery_id" ]; then
            orca_cmd orchestration check "${run_args[@]}" --ack "$delivery_id" --json >/dev/null 2>&1 || true
        fi

        # 6. Retorno de veredicto
        if [ -n "$parsed_verdict" ]; then
            echo "$parsed_verdict"
            return 0
        else
            return 1
        fi
    done
}
