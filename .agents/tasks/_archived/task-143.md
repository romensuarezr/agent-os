# Task-143: Aislamiento concurrente de variables y archivos de contexto

## Objetivo
Garantizar el aislamiento estricto de variables de entorno y archivos de contexto operativo entre ejecuciones concurrentes, particionando las rutas de veredicto por identificador de tarea (`deliberation-<task-id>.json` y `plan-draft-<task-id>.md`), erradicando condiciones de carrera y lecturas parciales (torn reads) mediante escrituras atómicas POSIX, y reforzando la frontera de aislamiento de variables de entorno bajo `env -i` con la whitelist estricta de 10 variables corporativas.

## Contexto técnico
El avance de las tareas previas del Sprint 25 validó componentes fundamentales de la concurrencia:
1. **T-141**: Demostró aislamiento básico a nivel de ejecución en arnés de benchmarking ($N=10, C=2$), usando IDs y ficheros segregados ad-hoc.
2. **T-142**: Implementó el matching determinista de `dispatchId` y el consumo atómico `--ack` en el bus asíncrono de eventos, previniendo colisiones de canal entre workers.

Sin embargo, en el core de producción aún persisten vectores de colisión no cubiertos por T-141 ni T-142:
- **Rutas de contexto no particionadas por omisión**: Si dos coordinadores o tareas ejecutan `deliberate-plan.sh` concurrentemente sin `--output`, ambas colisionan en `.agents/context/plan-deliberation.json`.
- **Condiciones de carrera en disco (torn reads)**: La escritura directa con redirección (`>`) puede provocar que un lector concurrente acceda a un JSON truncado. Se requiere sustitución atómica (`mktemp` + `mv -f`).
- **Aislamiento ambiental en compilación de especificaciones**: `generate-reviewer-spec.sh` y subprocesos deben operar de forma estanca sin contaminar ni heredar variables volátiles del proceso padre.

## Skills relevantes
- `orchestrator`: Gobernanza de espacios de nombres, contratos de concurrencia y prevención de colisiones.
- `agent-os-scripts`: Preservación de la frontera portable y aislamiento `env -i`.

## Caja de archivos
- `scripts/agent/deliberate-plan.sh`
- `scripts/agent/lib/generate-reviewer-spec.sh`
- `.agents/tasks/task-143.md`
- `.gitignore` (regla de exclusión para borradores particionados)

## Criterios de done
- [x] Particionado automático por omisión de veredictos (`.agents/context/deliberation-${TASK_ID}.json`) estandarizado en `deliberate-plan.sh`, con compatibilidad hacia atrás si `TASK_ID` no está definido y escritura única si `OUTPUT==NAMED`.
- [x] Escritura atómica garantizada (`mktemp` + `mv -f`) con limpieza garantizada de temporales ante error para prevenir torn reads bajo concurrencia.
- [x] Soporte caller-driven de borrador de plan particionado (`plan-draft-${TASK_ID}.md`) en `deliberate-plan.sh` y `generate-reviewer-spec.sh`, preservando que `--plan` explícito mande siempre.
- [x] Frontera de aislamiento `env -i` verificada con la whitelist de 10 variables (`HOME`, `PATH`, `USER`, `SHELL`, `LANG`, `LC_ALL`, `TMPDIR`, `ORCA_USER_DATA_PATH`, `ORCA_TERMINAL_HANDLE`, `ORCA_CALLS_LOG`) sin fugas entre procesos concurrentes y prueba canaria en spec.
- [x] Prueba de estrés concurrente validada en reporte (2 escrituras simultáneas, 0 torn reads ni contaminación cruzada).
- [x] Plan de la tarea deliberado en Fase 3.5 con resultado SIN_REVISOR por timeout de pasarela (>60s en FreeLLMAPI) y aprobación manual del relé (humano) — sin consenso vivo de Revisor Ejecutor.
- [x] Suite completa de control plane `tests/validate-control-plane.sh` pasando limpia (37/37) y cero violaciones de higiene.
