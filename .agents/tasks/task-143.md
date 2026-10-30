# Task-143: Aislamiento concurrente de variables y archivos de contexto

## Objetivo
Garantizar el aislamiento estricto de variables de entorno y archivos de contexto operativo entre ejecuciones concurrentes, particionando las rutas de veredicto por identificador de tarea (`plan-deliberation-<task-id>.json`), erradicando condiciones de carrera sobre artefactos compartidos y reforzando la whitelist de 10 variables bajo `env -i`.

## Contexto técnico
En el flujo secuencial original del Sprint 24, el archivo por defecto de veredicto residía en `.agents/context/plan-deliberation.json`. En un escenario de despacho simultáneo de 2 workers, la concurrencia desprotegida originaría colisiones de escritura (race conditions), corrompiendo la salida de una tarea con el veredicto de otra.
Esta tarea refactoriza las convenciones de persistencia temporal para aislar obligatoriamente cada ejecución en su propio espacio de nombres (`plan-deliberation-<task-id>.json` y `plan-draft-<task-id>.md`), asegura que los locks de archivo sean atómicos y verifica que el aislamiento de entorno mediante `env -i` prevenga la contaminación cruzada de variables en argv o memoria compartida.

## Skills relevantes
- `orchestrator`: Gobernanza de espacios de nombres, contratos de concurrencia y prevención de colisiones.
- `agent-os-scripts`: Preservación de la frontera portable y aislamiento `env -i`.

## Caja de archivos
- `scripts/agent/deliberate-plan.sh`
- `scripts/agent/lib/generate-reviewer-spec.sh`
- `.agents/tasks/task-143.md`

## Criterios de done
- [ ] Soporte de nombres de archivo de veredicto particionados por tarea (`plan-deliberation-${TASK_ID}.json`) estandarizado.
- [ ] Erradicación total de condiciones de carrera en lectura/escritura de contexto en `.agents/context/`.
- [ ] Aislamiento estricto `env -i` reforzado con la whitelist validada de 10 variables (`PATH`, `HOME`, `USER`, etc.) en todas las ramas de ejecución concurrente.
- [ ] Prueba de estrés de escritura simultánea sin colisiones validada mediante arnés de test.
- [ ] Plan de la tarea deliberado en Fase 3.5 con el Revisor Ejecutor vivo en host (timeout 60s, sin overrides).
- [ ] Suite completa de control plane `tests/validate-control-plane.sh` pasando limpia (37/37) y cero violaciones de higiene de secretos.
