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
- [x] Telemetría del ciclo consolidada: 3/3 CONSENSO vivo tier orca, 1 ronda por tarea, T-137 23.4s (default 60s), T-138 37.2s (override 90s), T-139 ~28s (override 90s), 0 objeciones en los tres.
- [x] Patrón de timeout documentado: el override de 90s se usó en T-138/T-139 pero no fue necesario (37.2s y ~28s < 60s); el default de 60s bastó para todo el sprint. Conclusión estricta de no subir routing-policy a 90s sin un caso empírico que supere 60s.
- [x] Cifra de sondeo activo de T-139 citada con rigor: ~20 invocaciones CLI/Python por deliberación de 30s (§5), corrigiendo el error conceptual de 'por minuto'.
- [x] Arrastre abierto explicitado: nota de prospección scout exhaustiva diferida a Sprint 26+/gobernanza, y la línea de resumen §1 de T-139 pendiente de retoque.
- [x] Criterio cuantitativo de paso al paralelo (Sprint 25) formalizado: umbrales numéricos de latencia, tasa admisible de degradación, estabilidad de terminales (cero huérfanos) y aislamiento concurrente para el GO, junto a las condiciones de bloqueo (NO-GO).
- [x] Documento canónico redactado en `docs/sprints/sprint-24-observation-report.md` cumpliendo la caja estricta (cero código).
- [x] Plan de la tarea deliberado y aprobado en Fase 3.5 con el Revisor Ejecutor vivo en host.
- [x] Suite completa de control plane `tests/validate-control-plane.sh` pasando limpia (37/37) y cero violaciones de higiene de secretos/rutas.
