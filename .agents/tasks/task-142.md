# Task-142: Despacho paralelo supervisado con patrón reactivo Orca (`check --wait` + `worker-read` + `--ack`)

## Objetivo
Implementar el adaptador reactivo determinista en `scripts/agent/lib/orca-reactive-wait.sh` basado en el bus de eventos asíncronos de Orca ADE (`orca orchestration check --types worker_done --wait` + `worker-read` + `--ack`), reemplazando el sondeo activo periódico (`sleep 1.5`, ~20 llamadas por deliberación) por una espera orientada a eventos con consumo seguro del lote FIFO, delimitando con honestidad técnica qué cambia (reducción drástica de llamadas CLI y detección instantánea de fin de turno) y qué no cambia (la latencia intrínseca de inferencia ni la contención en pasarela que originó el NO-GO de T-141).

## Contexto técnico
El runbook de verificación certificado en T-139 (`docs/runbooks/orca-event-collector-verification.md`) y el research del Sprint 25 caracterizaron el contrato reactivo de Orca ADE:
1. `--types` opera como condición de despertar (wake condition) para `--wait`, entregando el lote FIFO completo sin filtrar.
2. `worker_done` actúa como señal pura de sincronización (no lleva el veredicto en su payload), requiriendo extraer `dispatchId` para una llamada subsiguiente única a `worker-read --dispatch <id>`.
3. Es obligatorio emitir acuse de recibo explícito (`--ack <deliveryId>`) para prevenir que el buzón FIFO re-entregue mensajes antiguos en iteraciones concurrentes.
4. Los keepalives emitidos a stderr cada 15s deben ser filtrados estrictamente mediante `jq "select(._keepalive|not)"`.

Frente al dictamen NO-GO obtenido en la batería de T-141 (donde `T-BENCH-10` superó los 60s por contención en pasarela), T-142 no promete convertir mágicamente el NO-GO en GO: su éxito se mide objetivamente en la reducción de llamadas CLI (de ~20 a 1 check + 1 read) y en la erradicación del tráfico espurio en el socket local.

## Skills relevantes
- `orchestrator`: Arquitectura de mensajería asíncrona, sincronización por eventos reactivos y consumo FIFO.
- `agent-os-scripts`: Integración modular de librerías universales en `scripts/agent/lib/`.

## Caja de archivos
- `scripts/agent/lib/orca-reactive-wait.sh` (nuevo módulo helper determinista)
- `scripts/agent/deliberate-plan.sh` (adopción del adaptador reactivo con fallback transparente a polling)
- `.agents/tasks/task-142.md`

## Criterios de done
- [x] Módulo helper `scripts/agent/lib/orca-reactive-wait.sh` implementado siguiendo el patrón reactivo certificado en T-139.
- [x] Filtrado estricto de keepalives en stderr (`._keepalive`) y extracción atómica de `deliveryId` y `dispatchId`.
- [x] Acuse de recibo automático (`--ack <deliveryId>`) implementado tras cada consumo de entrega, omitiéndolo estrictamente ante entregas ajenas.
- [x] Integración en `deliberate-plan.sh` con cálculo de timeout decreciente y fallback transparente a sondeo activo (`sleep 1.5`) ante cualquier anomalía.
- [x] Medición comparativa documentada en el reporte: cuantificación de la reducción de llamadas CLI (1 check + 1 read frente a ~20 de polling mediante `ORCA_CALLS_LOG`) sin alterar la latencia base de inferencia.
- [x] Ausencia demostrada de re-emisiones de eventos residuales en el buzón FIFO de orquestación.
- [x] Plan de la tarea deliberado en Fase 3.5 con el Revisor Ejecutor vivo en host (timeout 60s, sin overrides).
- [x] Suite completa de control plane `tests/validate-control-plane.sh` pasando limpia (37/37) y cero violaciones de higiene.
