# Task-141: Pre-flight del gate y batería de calibración concurrente (10 ejecuciones)

## Objetivo
Diseñar y ejecutar en el host una batería de pruebas de estrés determinista de al menos 10 ejecuciones concurrentes (pool de hasta 2 workers simultáneos) sobre el motor de deliberación de Agent OS, recopilando telemetría empírica de latencia por turno, percentiles (P50, P90, P95), tasa de resolución en Tier 1 (Orca) y consumo de recursos para contrastar los umbrales del Gate de T-140.

## Contexto técnico
El Gate cuantitativo formalizado en T-140 exige demostrar empíricamente que el despacho concurrente de hasta 2 workers mantiene una latencia P95 < 45s, un máximo individual < 60s y una disponibilidad de Tier 1 ≥ 95%, sin degradaciones espurias ni colisiones de sockets en el runtime de Orca ADE.
Esta tarea implementa el arnés de calibración reproducible (coste $0 en inferencia para el arnés en sí), ejecuta la batería de 10 pruebas simultáneas de dos en dos, y exporta la telemetría estructurada en formato tabular y JSON para su análisis en las tareas posteriores del sprint.

## Skills relevantes
- `orchestrator`: Protocolos de benchmarking multi-agente y métricas de gobernanza concurrente.
- `agent-os-scripts`: Utilidades CLI deterministas en Bash y portabilidad de herramientas.

## Caja de archivos
- `tests/benchmarks/bench-concurrency.sh`
- `.agents/tasks/task-141.md`

## Criterios de done
- [x] Arnés de benchmarking concurrente implementado con soporte de parámetros (ejecuciones N=10, concurrencia C=2).
- [x] Batería de 10 deliberaciones concurrentes ejecutada en host midiendo tiempos de inicio, inferencia y cierre.
- [x] Percentiles P50, P90, P95 y latencia máxima individual calculados con precisión determinista bajo el método nearest-rank.
- [x] Tasa de disponibilidad Tier 1 (Orca) frente a degradaciones registrada empíricamente (90.0%, 9/10).
- [x] Telemetría estructurada generada en `.agents/context/bench-results-10.json`.
- [x] Plan de la tarea deliberado en Fase 3.5 con el Revisor Ejecutor vivo en host (timeout 60s, sin overrides).
- [x] Suite completa de control plane `tests/validate-control-plane.sh` pasando limpia (37/37) y working tree sin residuos.
