# Task-142: Despacho paralelo supervisado con patrón reactivo Orca (`check --wait` + `worker-read` + `--ack`)

## Objetivo
Implementar el adaptador reactivo determinista basado en el bus de eventos asíncronos de Orca ADE (`orca orchestration check --wait` + `worker-read` + `--ack`), reemplazando el sondeo activo periódico (`sleep 1.5`, ~20 llamadas por deliberación) por una espera orientada a eventos con consumo seguro del lote FIFO para el soporte de múltiples workers paralelos.

## Contexto técnico
El runbook de verificación certificado en T-139 (`docs/runbooks/orca-event-collector-verification.md`) caracterizó con precisión los tres pilares del recolector de eventos:
1. `--types` opera como condición de despertar para `--wait`, entregando el lote FIFO completo.
2. `worker_done` es una señal pura de sincronización (no lleva el veredicto en su payload), requiriendo lectura posterior vía `worker-read --dispatch <id>`.
3. Es obligatorio emitir acuse de recibo explícito (`--ack <deliveryId>`) para prevenir que el buzón FIFO re-entregue mensajes antiguos en ciclos subsiguientes.
Esta tarea materializa este patrón canónico en `scripts/agent/lib/` e integra el modo reactivo en el flujo de deliberación, filtrando keepalives de stderr (`jq "select(._keepalive|not)"`) y eliminando el overhead de sondeo activo en ejecuciones concurrentes.

## Skills relevantes
- `orchestrator`: Arquitectura de mensajería asíncrona, sincronización por eventos reactivos y consumo FIFO.
- `agent-os-scripts`: Integración modular de librerías universales en `scripts/agent/lib/`.

## Caja de archivos
- `scripts/agent/lib/orca-reactive-wait.sh` (nuevo módulo helper determinista)
- `scripts/agent/deliberate-plan.sh` (adopción del adaptador reactivo con fallback a polling)
- `.agents/tasks/task-142.md`

## Criterios de done
- [ ] Módulo helper `scripts/agent/lib/orca-reactive-wait.sh` implementado siguiendo el patrón reactivo certificado en T-139.
- [ ] Filtrado estricto de keepalives en stderr (`._keepalive`) y captura atómica de `deliveryId` y `dispatchId`.
- [ ] Acuse de recibo automático (`--ack <deliveryId>`) verificado tras cada consumo de entrega.
- [ ] Integración en `deliberate-plan.sh` manteniendo degradación suave y compatibilidad hacia atrás.
- [ ] Ausencia demostrada de re-emisiones de eventos residuales en el buzón FIFO de orquestación.
- [ ] Plan de la tarea deliberado en Fase 3.5 con el Revisor Ejecutor vivo en host (timeout 60s, sin overrides).
- [ ] Suite completa de control plane `tests/validate-control-plane.sh` pasando limpia (37/37) y cero violaciones de higiene.
