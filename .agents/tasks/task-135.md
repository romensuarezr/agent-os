# Task-135: Refactor de `deliberate-plan.sh` (Orca Prioritario, Fallback a Cascada HTTP y Degradación Segura)

## Objetivo
Evolucionar `scripts/agent/deliberate-plan.sh` para implementar una jerarquía de arbitraje de 3 niveles: (1) Revisor Ejecutor en Orca ADE como primera opción cuando el runtime esté accesible; (2) Cascada de inferencia HTTP resiliente como fallback (T-130); y (3) Fallback seguro a `SIN_REVISOR` ($0 tokens), garantizando que el bucle de desarrollo nunca quede bloqueado y preservando el presupuesto de tiempos.

## Contexto técnico
En el Sprint 22 (T-130) se implementó la cascada de inferencia HTTP con presupuesto global acotado a 5 segundos. Ahora, se integra la capacidad de que un agente local supervisado en Orca (por ejemplo `opencode` o un agente local) actúe como Revisor Ejecutor, realizando comprobaciones reales sobre el borrador del plan.

El flujo de decisión determinista operará de la siguiente manera:
1. **Nivel 1 — Orca ADE**:
   - Sonda no bloqueante a `orca_status` (<1s). Si está inactivo, salta de inmediato a Nivel 2 sin demora.
   - Si está activo, despacha un worker con `orca_worker_start` inyectando la directiva compilada (T-134) y con aislamiento de entorno estricto (`env -i`).
   - Espera el veredicto con un presupuesto configurable (máx. 15s). Al recibir `worker_done`, lee la respuesta con `orca_worker_read` y libera el terminal con `orca_worker_release`.
2. **Nivel 2 — Cascada HTTP**:
   - Si Orca falla, devuelve error o agota su tiempo (15s), se activa la cascada HTTP con su presupuesto estricto de 5s (`freellmapi` → `omniroute` → `ollama-local`).
3. **Nivel 3 — Degradación Segura**:
   - Si la cascada HTTP falla o no hay conexión, se emite inmediatamente el veredicto `SIN_REVISOR`, activando la aprobación manual clásica de Fase 3.5 a coste $0.

La latencia acumulada en el peor de los casos es de aproximadamente **~21 segundos** (<1s sonda + 15s worker Orca + 5s cascada HTTP), garantizando que el flujo del operador nunca quede bloqueado indefinidamente. Se modifica `.agents/config/routing-policy.yaml` para incluir la configuración de `orca_revisor`.

## Skills relevantes
- `agent-os-scripts`: Regla aplicada: contratos CLI deterministas, manejo estricto de timeouts y degradación en cascada.
- `orchestrator`: Regla aplicada: orquestación desacoplada y arbitraje de tareas multi-agente.

## Caja de archivos
- `scripts/agent/deliberate-plan.sh`
- `.agents/config/routing-policy.yaml`
- `.agents/tasks/task-135.md`

## Criterios de done
- [ ] Jerarquía de 3 niveles implementada en `deliberate-plan.sh`.
- [ ] Detección fail-fast de Orca sin demoras cuando el runtime está apagado.
- [ ] Worker despachado con `env -i` para evitar fugas de credenciales.
- [ ] Liberación obligatoria del worker (`worker-release`) tras procesar el veredicto.
- [ ] Salida estructurada de deliberación (`.agents/context/plan-deliberation.json`) generada fielmente en cualquiera de los 3 niveles.
