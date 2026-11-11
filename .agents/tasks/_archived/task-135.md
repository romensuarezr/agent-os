# Task-135: Refactor de `deliberate-plan.sh` (Orca Prioritario, Fallback a Cascada HTTP y Degradación Segura)

## Objetivo
Evolucionar `scripts/agent/deliberate-plan.sh` para implementar una jerarquía de arbitraje de 3 niveles: (1) Revisor Ejecutor en Orca ADE como primera opción cuando el runtime esté accesible; (2) Cascada de inferencia HTTP resiliente como fallback (T-130); y (3) Fallback seguro a `SIN_REVISOR` ($0 tokens), garantizando que el bucle de desarrollo nunca quede bloqueado y preservando el presupuesto de tiempos.

## Contexto técnico
En el Sprint 22 (T-130) se implementó la cascada de inferencia HTTP con presupuesto global acotado a 5 segundos. Ahora, se integra la capacidad de que un agente local supervisado en Orca (por ejemplo `opencode` o un agente local) actúe como Revisor Ejecutor, realizando comprobaciones reales sobre el borrador del plan.

El flujo de decisión determinista opera de la siguiente manera:
1. **Nivel 1 — Orca ADE**:
   - Sonda no bloqueante a `orca_is_ready` (<1s). Si está inactivo o deshabilitado (`enabled: false`), salta de inmediato a Nivel 2 sin demora.
   - Si está activo, compila la directiva de ejecución (T-134) y despacha un worker con `orca_worker_start` bajo aislamiento de entorno estricto (`env -i`).
   - Espera el veredicto con un presupuesto configurable (máx. 60s según `routing-policy.yaml`). Al recibir `worker_done` o el veredicto estructurado entre delimitadores `<!-- VERDICT_JSON_START -->` y `<!-- VERDICT_JSON_END -->`, lee la respuesta con `orca_worker_read` y libera el terminal con `orca_worker_release` (garantizado en todos los caminos vía `trap`).
2. **Nivel 2 — Cascada HTTP**:
   - Si Orca falla, devuelve error de transporte, JSON no parseable o agota su tiempo (60s), se activa la cascada HTTP con su presupuesto estricto de 5s (`freellmapi` → `omniroute` → `ollama-local`).
3. **Nivel 3 — Degradación Segura**:
   - Si la cascada HTTP falla o no hay conexión, se emite inmediatamente el veredicto `SIN_REVISOR`, activando la aprobación manual clásica de Fase 3.5 a coste $0.

La latencia acumulada en el peor de los casos es de aproximadamente **~66 segundos** (<1s sonda + 60s worker Orca + 5s cascada HTTP), garantizando que el flujo del operador nunca quede bloqueado indefinidamente. Se modifica `.agents/config/routing-policy.yaml` para incluir la configuración declarativa de `orca_revisor`.

## Semántica de Rondas y Veredicto RECHAZADO
- **1 ronda por invocación CLI**: Cada ejecución de `deliberate-plan.sh` corresponde a una ronda de evaluación sobre el plan actual. Si el veredicto es `CONSENSO` o `SIN_REVISOR`, la tarea queda lista o degradada registrando `rounds_executed: 1`. Cuando se detectan objeciones (`REVISADO_CON_CAMBIOS`, `RECHAZADO` o `ESCALADO_A_HUMANO`), la invocación registra `rounds_executed: 2`, marcando formalmente que el plan debe pasar a su segunda ronda (ajuste automático/humano).
- **Tope absoluto de 2 rondas (Circuit Breaker)**: La política de routing (`max_automatic_rounds: 1`) impone un tope de 2 rondas de deliberación entre invocaciones del Coder y Revisor. Si tras el ajuste de la ronda 1 no se alcanza `CONSENSO` en la segunda deliberación, el veredicto debe ser obligatoriamente `ESCALADO_A_HUMANO`, evitando bucles infinitos.
- **`RECHAZADO` como estado final de invocación**: El veredicto `RECHAZADO` explicita que el plan viola guardarraíles arquitectónicos fundamentales, caja de archivos o directivas estrictas (ej. invocación de skills prohibidas). Es un veredicto terminal para la invocación activa, requiriendo reestructuración profunda previa a una re-deliberación.

## Evaluación Estática del Revisor de Plan (Presupuesto 60s)
- **Ámbito estático (<4KB)**: El Revisor Ejecutor evalúa estáticamente el borrador del plan (`plan-draft.md`) contra el inventario git acotado (<4KB), las directivas de arquitectura y la cláusula de skills dentro de su presupuesto acotado de 60 segundos.
- **Separación de responsabilidades**: Queda expresamente formalizado que la ejecución de la suite completa de pruebas (`tests/validate-control-plane.sh`) y scripts de verificación funcional (`scripts/agent/verify-goal.sh`) pertenece a la fase de **revisión y certificación de código implementado** (Ralph Loop en PR o compuerta previa al merge), NO a la deliberación del borrador del plan. Esto evita que el worker consuma su presupuesto de 60s ejecutando comandos de test o mutaciones de entorno en la etapa previa a la codificación.

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
- [x] Semántica de rondas (1 por invocación, tope de 2 entre invocaciones) y veredicto `RECHAZADO` documentados.
- [x] Evaluación estática del plan delimitada dentro de los 60s, reservando suites de test para revisión de código.
