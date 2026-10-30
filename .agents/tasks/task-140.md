# Task-140: Informe de observación del ciclo con criterio de paso al paralelo

## Objetivo
Sintetizar la telemetría, métricas de rendimiento y lecciones aprendidas durante la ejecución de los ciclos de deliberación con el Revisor Ejecutor vivo en el Sprint 24, formalizando en un informe canónico los criterios cuantitativos y de estabilidad necesarios para autorizar el paso al despacho paralelo de múltiples workers.

## Contexto técnico
El Sprint 24 evalúa por primera vez el Revisor Ejecutor en condiciones de producción real (arbitrando los planes de las tareas T-137, T-138 y T-139). Para dar el siguiente salto arquitectónico hacia el paralelismo (ejecución concurrente de workers supervisados, worktrees paralelos o despacho masivo de subagentes en sprints posteriores), es imprescindible contar con un diagnóstico empírico consolidado:
1. Latencia real observada por ronda de deliberación (tiempo de inicio, tiempo de inferencia del LLM en host, tiempo de parseo).
2. Tasa de éxito del Revisor Orca de Nivel 1 frente a degradaciones a Cascada HTTP (Nivel 2) o `SIN_REVISOR` (Nivel 3).
3. Estabilidad en la gestión de sockets y terminales en el host (ausencia de procesos huérfanos o fugas de recursos tras `worker-release`).
4. Requisitos para el aislamiento concurrente: suficiencia de puertos, contención de concurrencia en la API de inferencia y robustez de bloqueos (locks).

Esta tarea recopila los datos reales del sprint y redacta el informe analítico `docs/sprints/sprint-24-observation-report.md`, estableciendo el umbral de preparación ("gate") para habilitar el paralelismo en el backlog de futuros sprints.

## Skills relevantes
- `orchestrator`: Métricas de gobernanza multi-agente y criterios de paralelismo.
- `doc-maintainer`: Estructuración de reportes técnicos ejecutivos y documentación de arquitectura de sistemas.

## Caja de archivos
- `docs/sprints/sprint-24-observation-report.md`
- `.agents/tasks/task-140.md`

## Criterios de done
- [ ] Datos de telemetría y métricas operativas de T-137, T-138 y T-139 consolidados en el informe.
- [ ] Distribución de latencias (sonda, inferencia del worker, lectura, veredicto) documentada con tiempos reales del host.
- [ ] Tasa de disponibilidad del Nivel 1 (Orca) y eficacia del fallback analizadas.
- [ ] Criterios cuantitativos y salvaguardas arquitectónicas para el paso al despacho paralelo formalizados.
- [ ] Documento `docs/sprints/sprint-24-observation-report.md` redactado y enlazado en la documentación del core.
- [ ] Plan de la tarea deliberado en Fase 3.5 con el Revisor Ejecutor vivo en host.
- [ ] Suite completa de control plane `tests/validate-control-plane.sh` pasando limpia (37/37) y cero violaciones de higiene de secretos/rutas.
