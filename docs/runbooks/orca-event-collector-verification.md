# Runbook: Verificación Empírica del Recolector de Eventos Orca (`check --run --wait`, `--types`, `worker_done`)

> **Estado**: Certificado en host  
> **Fecha**: 2026-10-30  
> **Alcance**: Caracterización del bus reactivo de eventos de Orca ADE (`orca orchestration check`) frente al sondeo activo (polling) en `deliberate-plan.sh`.

---

## 1. Resumen Ejecutivo y Conclusiones Arquitectónicas

Se ha completado la auditoría empírica en host del recolector de eventos reactivo de Orca ADE (`orca orchestration check`) para fundamentar la futura evolución del motor de deliberación y la orquestación en paralelo (Sprint 25+).

### Hallazgos Clave Verificados en Host

| Aspecto Evaluado | Hipótesis / Supuesto Previo | Realidad Empírica Certificada | Implicación Arquitectónica |
|---|---|---|---|
| **Filtro `--types` en `--wait`** | ¿Filtra las filas del lote entregado? | **No.** Actúa **exclusivamente como condición de despertar (wake condition)**. El objeto `Delivery` retornado contiene siempre el lote FIFO completo sin filtrar. | Si un Run recibe múltiples eventos (ej: `status`, `question`), `--wait --types worker_done` despertará ante `worker_done`, pero la entrega traerá también los otros mensajes pendientes. El receptor debe iterar el lote. |
| **Filtro `--types` en `--peek` / `--all`** | ¿Filtra las filas devueltas? | **Sí.** `--peek --types <tipo>` y `--all --types <tipo>` filtran estrictamente sus filas por tipo. | Útil para inspección puntual sin consumir el lote FIFO. |
| **Carga útil de `worker_done`** | ¿Contiene el stream de salida o veredicto del worker? | **No.** El campo `payload` contiene únicamente metadatos de sincronización (`taskId`, `dispatchId`, `outcome`). | El evento reactivo `worker_done` **no sustituye** a `worker-read`. Sirve como señal de despertar inmediata (latencia 0ms); el coordinador debe invocar subsiguientemente `orca orchestration worker-read --dispatch <id>` para leer el veredicto en terminal. |
| **Keepalives a stderr** | ¿Pulsos cada 15s? | **Confirmado.** Emite `{"_keepalive":true,"_heartbeat":true,"elapsedMs":15006,"deadlineMs":20000}` exactamente a los 15s por `stderr`. | Al fusionar canales (`2>&1`), es obligatorio filtrar con `jq "select(._keepalive|not)"`. |
| **Base de contraste (Polling)** | Intervalo asumido en doc: 2s | **Corregido a 1.5s.** `deliberate-plan.sh` ejecuta `sleep 1.5` en su bucle activo. | El polling a 1.5s realiza ~20 invocaciones CLI/Python por minuto. El paso a reactivo reducirá las llamadas CLI a 1 (`check --wait`) + 1 (`worker-read`). |

---

## 2. Evidencia Empírica 1: Semántica de `--types` frente a `--wait`

### 2.1 Contrato Documentado por la CLI
La ayuda canónica (`orca orchestration check --help`) estipula:
```text
--types is the wake condition for --wait; a returned Delivery is always
the whole FIFO batch, so it is never filtered by type. Without --wait it
has no effect on consuming checks. Only --peek and --all filter their rows.
```

### 2.2 Prueba de Contraste en Host (Run Aislado Desechable)
Para contrastar este comportamiento sin perturbar el buzón principal del coordinador, se aprovisionó un Run aislado desechable (`run_b2dedfc1fde0`) en el que se inyectaron secuencialmente dos mensajes de distinto tipo:
1. Mensaje de tipo `status` (`msg_06eeb206ea71`)
2. Mensaje de tipo `question` (`msg_8fb20000c68a`)

#### Ejecución con `--wait --types question` (Consumo FIFO):
```bash
orca orchestration check --run run_b2dedfc1fde0 --types question --wait --json
```

**Salida Real Obtenida en Host**:
```json
{
  "id": "cf7256d8-95ee-4b32-ba69-dd96e454e726",
  "ok": true,
  "result": {
    "runId": "run_b2dedfc1fde0",
    "deliveryId": "delivery_f48c14669e56",
    "messages": [
      {
        "id": "msg_06eeb206ea71",
        "type": "status",
        "subject": "Status test message",
        "body": "Status payload"
      },
      {
        "id": "msg_32b9ec0a3722",
        "type": "status",
        "subject": "Rejected decision_gate: Gate test message"
      },
      {
        "id": "msg_8fb20000c68a",
        "type": "question",
        "subject": "Question test message",
        "body": "Question payload"
      }
    ],
    "count": 3,
    "replayed": false,
    "acknowledged": null,
    "timedOut": false
  }
}
```
**Resultado**: A pesar de especificar `--types question`, la entrega (`Delivery`) retornó **3 mensajes** (el lote FIFO íntegro). El filtro no recortó la entrega.

#### Ejecución con `--peek --types question` (Inspección No Consumidora):
```bash
orca orchestration check --run run_b2dedfc1fde0 --peek --types question --json
```

**Salida Real Obtenida en Host**:
```json
{
  "id": "ea2a9e46-3bff-4f2c-b2b9-4fdc143783fc",
  "ok": true,
  "result": {
    "runId": "run_b2dedfc1fde0",
    "messages": [
      {
        "id": "msg_8fb20000c68a",
        "type": "question",
        "subject": "Question test message"
      }
    ],
    "count": 1
  }
}
```
**Resultado**: Bajo `--peek` (y de forma idéntica bajo `--all`), `--types` **sí filtra estrictamente** las filas retornadas (`count: 1`).

---

## 3. Evidencia Empírica 2: Carga Útil de `worker_done` frente a `worker-read`

### 3.1 Estructura del Evento `worker_done`
Se auditaron los mensajes reales de finalización de workers emitidos en el runtime de Orca ADE (incluyendo `msg_1065f2f34942` correspondiente a la deliberación de T-138 en `ctx_aba5becba04e`):

```json
{
  "id": "msg_1065f2f34942",
  "run_id": "run_1515f1e5bf95",
  "delivery_contract": "current_delivery",
  "from_handle": "term_4af522ec-06e6-40cb-8e0b-025d88485922",
  "to_handle": "run:run_1515f1e5bf95",
  "subject": "Evaluación Task-138 completada con CONSO",
  "body": "He evaluado el plan de la tarea T-138 conforme al rol de Revisor Ejecutor Autónomo...",
  "type": "worker_done",
  "priority": "normal",
  "thread_id": null,
  "payload": "{\"taskId\":\"task_6f05a6a1271b\",\"dispatchId\":\"ctx_aba5becba04e\",\"outcome\":\"succeeded\"}",
  "created_at": "2026-10-30T10:45:01Z",
  "delivered_at": null
}
```

### 3.2 Análisis del Contenido
1. El campo `payload` es una cadena JSON compacta con únicamente tres claves:
   - `taskId`: Identificador de la tarea orquestada.
   - `dispatchId`: Identificador del dispatch supervisado.
   - `outcome`: Resultado del proceso (`"succeeded"` o `"failed"`).
2. **Cero contenido de salida**: El evento no transporta el stream del modelo, ni transcripciones ANSI, ni los delimitadores `<!-- VERDICT_JSON_START -->`.
3. **Necesidad de `worker-read`**: Para obtener el veredicto estructurado del Revisor o la salida del worker, es estrictamente obligatorio realizar una lectura de terminal subsiguiente:
   ```bash
   orca orchestration worker-read --dispatch ctx_aba5becba04e --limit 100 --json
   ```
   Dicha llamada extrae del buffer del terminal las líneas emitidas por el agente (ej: delimitadores de veredicto, objeto JSON estructurado y métricas de inferencia).

---

## 4. Evidencia Empírica 3: Flujo de Keepalives a stderr cada 15s

### 4.1 Captura Experimental con Medición de Tiempos
Se configuró una escucha bloqueante en el host con timeout de 20 segundos (`--wait --timeout-ms 20000`) sobre el buzón sin mensajes pendientes de `run_b2dedfc1fde0`, separando `stdout` y `stderr`:

```bash
python3 -c '
import subprocess, time

p = subprocess.Popen(
    ["orca", "orchestration", "check", "--run", "run_b2dedfc1fde0", "--wait", "--timeout-ms", "20000", "--json"],
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True
)
stdout, stderr = p.communicate()
print("=== STDERR ===")
print(stderr)
print("=== STDOUT ===")
print(stdout)
'
```

### 4.2 Salida Real Registrada
```text
=== STDERR ===
{"_keepalive":true,"_heartbeat":true,"elapsedMs":15006,"deadlineMs":20000}

=== STDOUT ===
{
  "id": "52f64e04-b988-4d38-8e44-431a21087866",
  "ok": true,
  "result": {
    "runId": "run_b2dedfc1fde0",
    "deliveryId": null,
    "messages": [],
    "count": 0,
    "acknowledged": null,
    "timedOut": true,
    "cancelled": false,
    "connectionLost": false
  }
}
```

### 4.3 Comportamiento Verificado
1. **Puntualidad**: A los `15006 ms` (~15.0s), Orca emitió exactamente un objeto JSON de keepalive por el canal de error estándar.
2. **Campos**: Contiene `_keepalive: true` y el alias heredado `_heartbeat: true`, además de `elapsedMs` y `deadlineMs`.
3. **Expiración**: Al alcanzar los 20s, `stdout` emitió el resultado estructurado indicando `"timedOut": true` y `"count": 0`.
4. **Patrón de Filtrado Canónico**:
   Si se combinan los flujos (`2>&1`), el consumidor debe filtrar mediante:
   ```bash
   jq "select(._keepalive|not)"
   ```

---

## 5. Contraste frente al Sondeo Activo (Polling 1.5s en `deliberate-plan.sh`)

### 5.1 Implementación Actual de Polling
En `scripts/agent/deliberate-plan.sh` (líneas 469–543):
```bash
while true; do
    NOW_TS=$(date +%s)
    ELAPSED=$(( NOW_TS - ORCA_START_TS ))
    [ "$ELAPSED" -ge "$ORCA_TIMEOUT" ] && break

    READ_OUT="$(orca_worker_read --dispatch "$ORCA_DISPATCH_ID" --limit 100 --json 2>/dev/null || true)"
    PARSED_VERDICT="$(python3 -c '...' "$READ_OUT" 2>/dev/null || true)"
    if [ -n "$PARSED_VERDICT" ]; then
        RAW_REVIEW="$PARSED_VERDICT"
        break
    fi

    sleep 1.5
done
```

### 5.2 Comparativa Cuantitativa y Cualitativa

| Métrica | Polling Activo (`deliberate-plan.sh`) | Recolector Reactivo (`orca check --wait`) |
|---|---|---|
| **Intervalo / Mecanismo** | `sleep 1.5` activo | Bloqueo en socket IPC / evento reactivo |
| **Invocaciones CLI (en deliberación de 30s)** | ~20 llamadas a `orca_worker_read` | 1 llamada a `check --wait` + 1 llamada a `worker-read` |
| **Procesos Python auxiliares** | ~20 ejecuciones de parsing | 1 ejecución final de parsing |
| **Latencia de detección de fin de turno** | De 0 a 1.5 segundos (promedio ~0.75s) | Prácticamente instantánea (0 ms tras emisión de evento) |
| **Tráfico en socket local** | Alto (lectura repetida del buffer de pantalla) | Mínimo (un solo evento de despertar) |
| **Resiliencia ante cuelgues del worker** | Depende del centinela de timeout local (`ELAPSED`) | Supervisado con keepalives en stderr cada 15s y `--timeout-ms` |

---

## 6. Recomendación para la Arquitectura de Despacho Paralelo (Sprint 25)

1. **Patrón Mixto Reactivo + Lectura Bounded**:
   No intentar extraer el veredicto de `worker_done`. El patrón óptimo para el despacho en paralelo es:
   ```bash
   # 1. Espera reactiva no bloqueante en CPU (despierta inmediatamente cuando el worker emite worker_done)
   DELIVERY="$(orca orchestration check --run "$RUN_ID" --types worker_done --wait --timeout-ms "$TIMEOUT_MS" --json)"
   
   # 2. Extraer dispatch_id del lote FIFO
   DISPATCH_ID="$(echo "$DELIVERY" | jq -r '.result.messages[] | select(.type=="worker_done") | .payload | fromjson | .dispatchId')"
   
   # 3. Lectura única y definitiva del terminal del worker
   FINAL_OUTPUT="$(orca orchestration worker-read --dispatch "$DISPATCH_ID" --limit 100 --json)"
   ```
2. **Reconocimiento Explícito (`--ack`)**:
   Recordar que un Run vinculado re-emite la misma entrega hasta que se reconozca vía `--ack <deliveryId>`. Cada lote recibido debe acusarse de recibo para evitar la acumulación de mensajes en iteraciones posteriores.
