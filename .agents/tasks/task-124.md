# Task-124: Persistencia y Handover de Deliberación Multi-Sesión

## Objetivo
Resolver de forma determinista la pérdida de contexto de deliberación entre sesiones de desarrollo y sesiones de cierre (como ocurrió en T-123), implementando el anclaje del artefacto de deliberación por identificador de tarea (`.agents/context/deliberation-${TASK_ID}.json`), de modo que `close-task.sh` y `design-digest.sh` capturen siempre el veredicto real, objeciones y correcciones acordadas sin degradar falsamente a fallback frío N/A.

## Contexto técnico
En el flujo actual de Sprint 20:
- `deliberate-plan.sh` emite por defecto a `.agents/context/plan-deliberation.json`.
- Si el cierre de tarea ocurre en un proceso posterior o en un contexto donde el archivo fue sobreescrito o limpiado, `design-digest.sh` no encuentra la deliberación activa y genera un digest con veredicto `N/A (Rondas: 1, Cierre de tarea sin deliberación interactiva)`.
- En esta tarea:
  1. `deliberate-plan.sh` guardará automáticamente una copia en `.agents/context/deliberation-${TASK_ID}.json` cuando se especifique `--task-id`.
  2. `design-digest.sh` buscará prioritariamente `.agents/context/deliberation-${TASK_ID}.json` antes de caer a `plan-deliberation.json` y finalmente al fallback en frío.
  3. Se asegurará que la redacción obligatoria y la higiene en `.gitignore` apliquen a los nuevos archivos nombrados (`.agents/context/deliberation-*.json`).

## Skills relevantes
- `agent-os-scripts`: Consistencia CLI y manejo determinista de rutas en bash.
- `infisical-secrets`: Redacción y frontera portable de los nuevos artefactos de deliberación.
- `doc-maintainer`: Preservación de la fidelidad histórica en los digests generados.

## Caja de archivos
- `scripts/agent/deliberate-plan.sh`
- `scripts/agent/design-digest.sh`
- `.gitignore`
- `.agents/tasks/task-124.md`

## Criterios de done
- [ ] `deliberate-plan.sh` persiste `.agents/context/deliberation-${TASK_ID}.json` cuando `--task-id` está presente.
- [ ] `design-digest.sh` prioriza la lectura de `deliberation-${TASK_ID}.json` antes de caer a fallback.
- [ ] `.gitignore` excluye `.agents/context/deliberation-*.json`.
- [ ] Verificación de que un cierre de tarea tras deliberación conserva el veredicto real y objeciones en el digest generado sin caer en N/A.
