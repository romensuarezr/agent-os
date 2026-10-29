# Task-130: Cascada de Inferencia y Fallback Resiliente en Routing Policy

## Objetivo
Implementar un mecanismo de enrutamiento escalonado (cascada de inferencia) en `.agents/config/routing-policy.yaml` y `scripts/agent/deliberate-plan.sh`, permitiendo que el motor de arbitraje pruebe de forma determinista una lista ordenada de endpoints o tiers de inferencia antes de degradar al veredicto offline `SIN_REVISOR`.

## Contexto técnico
Actualmente:
- `routing-policy.yaml` define `timeout_seconds: 5` y un único endpoint base configurable vía `INFERENCE_BASE_URL` o configuración de flota.
- Si ese endpoint falla o no responde dentro del timeout, `deliberate-plan.sh` salta de inmediato a `SIN_REVISOR`.
Esta tarea formaliza la propuesta evaluada del inbox de vídeos respecto a la resiliencia de inferencia:
1. `routing-policy.yaml` permite declarar una cascada de tiers (`inference_cascade` o endpoints secundarios de fallback, ej: `primary-reliable` → `freellmapi_fallback` → `offline`).
2. `deliberate-plan.sh` itera secuencialmente respetando el timeout de 5 segundos por intento en cada tier configurado.
3. Si todos los tiers fallan o no hay ninguno accesible, degrada limpiamente a `SIN_REVISOR` con diagnóstico descriptivo en la síntesis de diseño.

## Skills relevantes
- `agent-os-scripts`: Robustez en bash, manejo de timeouts con curl/python y fail-closed seguro.
- `orchestrator`: Políticas de enrutamiento y asignación de modelos en flotas distribuidas.

## Caja de archivos
- `.agents/config/routing-policy.yaml`
- `scripts/agent/deliberate-plan.sh`
- `.agents/tasks/task-130.md`

## Criterios de done
- [ ] `routing-policy.yaml` enriquecido con esquema declarativo para cascada de inferencia y timeouts acotados.
- [ ] `deliberate-plan.sh` implementa la evaluación de endpoints en cascada sin superar los límites temporales globales.
- [ ] Degradación determinista a `SIN_REVISOR` preservada cuando ningún tier de la cascada responde.
- [ ] Cero dependencias duras ni exposición de credenciales o URLs hardcodeadas en el core.
