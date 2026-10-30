# Task-137: Deuda cosmética de T-135 (cabecera y ayuda de deliberate-plan.sh en 60s/~66s)

## Objetivo
Actualizar los comentarios de cabecera y el texto de ayuda CLI en `scripts/agent/deliberate-plan.sh` para reflejar con precisión el timeout de Orca fijado en 60s y la latencia máxima en el peor caso de ~66s acordados en T-135, explicitando la precedencia de configuración (`CLI > routing-policy.yaml > default sentinel`).

## Contexto técnico
En T-135 se ajustó el timeout del Revisor Orca a 60 segundos en `.agents/config/routing-policy.yaml` (`orca_revisor.timeout_seconds: 60`) y la instrucción del worker a 60s, situando el peor caso en ~66s (<1s sonda + 60s Orca + 5s cascada HTTP). Sin embargo, la cabecera del script conservó referencias residuales a 15s y ~21s (líneas 10 y 19), y la ayuda CLI en `show_help` documentaba `(default: 15)` sin clarificar que `15` en código actúa como valor centinela para permitir que la directiva de `routing-policy.yaml` prevalezca cuando el flag CLI no se pasa explícitamente.

Esta tarea aborda estrictamente la deuda cosmética y documental del script sin alterar la lógica de arbitraje ni los tests certificados por el Check 37.

## Skills relevantes
- `agent-os-scripts`: Contratos de interfaces CLI deterministas y consistencia de opciones de ayuda.

## Caja de archivos
- `scripts/agent/deliberate-plan.sh`
- `.agents/tasks/task-137.md`

## Criterios de done
- [ ] Comentarios de cabecera de `scripts/agent/deliberate-plan.sh` actualizados a 60s de timeout del Revisor y ~66s de latencia peor caso.
- [ ] Texto de ayuda CLI (`show_help`) documenta con claridad la jerarquía de precedencia: argumento CLI `--orca-timeout` > directiva `orca_revisor.timeout_seconds` de `routing-policy.yaml` (60s) > valor centinela por defecto (15s).
- [ ] Valor centinela `15` en el código de inicialización de variables de `deliberate-plan.sh` preservado para mantener intacta la precedencia algorítmica.
- [ ] Plan de la tarea deliberado en Fase 3.5 con el Revisor Ejecutor vivo en host.
- [ ] Suite completa de control plane `tests/validate-control-plane.sh` pasando limpia (37/37) y cero violaciones de higiene de secretos/rutas.
