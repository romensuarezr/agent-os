# Task-135: Refactor de `deliberate-plan.sh` (Orca Prioritario, Fallback a Cascada HTTP y Degradación Segura)

## Objetivo
Evolucionar `scripts/agent/deliberate-plan.sh` para implementar una jerarquía de arbitraje de 3 niveles: (1) Revisor Ejecutor en Orca ADE como primera opción cuando el runtime esté accesible; (2) Cascada de inferencia HTTP resiliente como fallback (T-130); y (3) Fallback seguro a `SIN_REVISOR` ($0 tokens), garantizando que el bucle de desarrollo nunca quede bloqueado y preservando el presupuesto de tiempos.

## Contexto técnico
En el Sprint 22 (T-130) se implementó la cascada de inferencia HTTP con presupuesto global acotado a 5 segundos. Ahora, se integra la capacidad de que un agente local supervisado en Orca (por ejemplo `opencode` o un agente local) actúe como Revisor Ejecutor, realizando comprobaciones reales sobre el borrador del plan.

El flujo de decisión determinista opera de la siguiente manera:
1. **Nivel 1 — Orca ADE**:
   - Sonda no bloqueante a `orca_is_ready` (<1s). Si está inactivo o deshabilitado (`enabled: false`), salta de inmediato a Nivel 2 sin demora.
   - Si está activo, compila la directiva de ejecución (T-134) y despacha un worker con `orca_worker_start` bajo aislamiento de entorno estricto (`env -i`).
   - Espera el veredicto con un presupuesto configurable (máx. 15s). Al recibir `worker_done` o el veredicto estructurado entre delimitadores `<!-- VERDICT_JSON_START -->` y `<!-- VERDICT_JSON_END -->`, lee la respuesta con `orca_worker_read` y libera el terminal con `orca_worker_release` (garantizado en todos los caminos vía `trap`).
2. **Nivel 2 — Cascada HTTP**:
   - Si Orca falla, devuelve error de transporte, JSON no parseable o agota su tiempo (15s), se activa la cascada HTTP con su presupuesto estricto de 5s (`freellmapi` → `omniroute` → `ollama-local`).
3. **Nivel 3 — Degradación Segura**:
   - Si la cascada HTTP falla o no hay conexión, se emite inmediatamente el veredicto `SIN_REVISOR`, activando la aprobación manual clásica de Fase 3.5 a coste $0.

La latencia acumulada en el peor de los casos es de aproximadamente **~21 segundos** (<1s sonda + 15s worker Orca + 5s cascada HTTP), garantizando que el flujo del operador nunca quede bloqueado indefinidamente. Se modifica `.agents/config/routing-policy.yaml` para incluir la configuración declarativa de `orca_revisor`.

## Skills relevantes
- `agent-os-scripts`: Regla aplicada: contratos CLI deterministas, manejo estricto de timeouts y degradación en cascada.
- `orchestrator`: Regla aplicada: orquestación desacoplada y arbitraje de tareas multi-agente.

## Caja de archivos
- `scripts/agent/deliberate-plan.sh`
- `.agents/config/routing-policy.yaml`
- `.agents/tasks/task-135.md`

## Criterios de done
- [x] Jerarquía de 3 niveles implementada en `deliberate-plan.sh`.
- [x] Detección fail-fast de Orca sin demoras cuando el runtime está apagado o deshabilitado (`enabled: false`).
- [x] Worker despachado con `env -i` para evitar fugas de credenciales.
- [x] Liberación obligatoria del worker (`worker-release`) tras procesar el veredicto en todos los caminos (vía `trap`).
- [x] Salida estructurada de deliberación (`.agents/context/plan-deliberation.json`) generada fielmente en cualquiera de los 3 niveles con delimitadores exactos y mapeo `proposed_corrections` → `corrections`.
