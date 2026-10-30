# Sprint 25 — Despacho Paralelo Controlado (Piloto de Validación del Gate de Paralelismo)

## Estado
🟡 En curso

## Tareas
| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :--- | :--: | :--- | :--- |
| T-141 | Pre-flight del gate y batería de calibración concurrente (10 ejecuciones) | Core / Benchmarking | M | ⬜ Pendiente | — | [.agents/tasks/task-141.md](.agents/tasks/task-141.md) |
| T-142 | Despacho paralelo supervisado con patrón reactivo Orca (`check --wait` + `worker-read` + `--ack`) | Core / Orquestación | M | ⬜ Pendiente | T-141 | [.agents/tasks/task-142.md](.agents/tasks/task-142.md) |
| T-143 | Aislamiento concurrente de variables y archivos de contexto | Core / Hardening | S | ⬜ Pendiente | T-142 | [.agents/tasks/task-143.md](.agents/tasks/task-143.md) |
| T-144 | Estabilidad de terminales, censo `worker-list` y recolección de basura | Core / Resiliencia | S | ⬜ Pendiente | T-143 | [.agents/tasks/task-144.md](.agents/tasks/task-144.md) |
| T-145 | Informe final y evaluación de compuerta GO/NO-GO del piloto paralelo | Documentación / Gobernanza | S | ⬜ Pendiente | T-141, T-142, T-143, T-144 | [.agents/tasks/task-145.md](.agents/tasks/task-145.md) |

## Notas de planning

- **Objetivo Estratégico**: Demostrar empíricamente si el despacho concurrente de hasta 2 workers simultáneos cumple con rigor los criterios cuantitativos del Gate formalizado en T-140 (`docs/sprints/sprint-24-observation-report.md`). El sprint opera como un **piloto controlado**, no como una activación forzada del paralelismo. Si los datos demuestran cumplimiento íntegro, se emitirá el GO; si se detecta contención o degradación, el sprint cerrará en NO-GO y el sistema permanecerá en secuencial.
- **Criterio de Salida Literal (Gate de T-140)**:
  - Latencia P95 < 45.0s con hasta 2 workers simultáneos en host.
  - Máximo individual < 60.0s (respetando el timeout default de `routing-policy.yaml`).
  - Disponibilidad Tier 1 (Orca) ≥ 95.0% en batería mínima de 10 ejecuciones.
  - 0 terminales huérfanas tras `worker-release`.
  - Criterios de bloqueo inmediato (NO-GO): Latencias > 55s sostenidas, terminales residuales en `worker-list`, mensajes FIFO sin `--ack` o colisión de locks de archivo.
- **Guardarraíles Operativos (Mandatorios y Vinculantes)**:
  1. **Una Sola Tarea Activa y Gate de Aprobación**: Flujo estrictamente secuencial. Cada tarea requiere la presentación de un plan legible en `.agents/context/plan-draft.md` y la **aprobación explícita del usuario ANTES de escribir código o docs**.
  2. **Deliberación Viva en Fase 3.5**: Cada plan se delibera obligatoriamente con el Revisor Ejecutor vivo en host (`scripts/agent/deliberate-plan.sh`) usando el timeout default de **60s**. Queda prohibido cualquier override a 90s sin un caso empírico previo que sobrepase los 60s.
  3. **Git Workflow Riguroso**: Ramas de trabajo aisladas `feat/T-XXX-*`, push a origin + SHA + diffstat + evidencia de pruebas; merge con `--no-ff` a `multi-agent` únicamente tras la revisión y autorización humana. Prohibido merge directo, squash o reabrir ramas fusionadas.
  4. **Core Portable y Cero Fugas**: Cero rutas personales o literales de infraestructura, cero secretos en repositorio, y los helpers modulares se declaran una sola vez en `scripts/agent/lib/`.
  5. **Principio de No Forzar el Paralelo**: Si los umbrales de la compuerta no se alcanzan satisfactoriamente, el sprint concluye en veredicto NO-GO sin degradar la estabilidad del core.
- **Límites de Alcance (FUERA del Sprint 25)**:
  - Nota scout exhaustiva (diferida a Sprint 26+ / gobernanza).
  - Dispatcher front-door.
  - Bases de conocimiento nuevas (Outline/Qdrant).
  - Satélites y promoción de ramas a `main` (decisión aparte).
- **Relación con el Documento de Research**:
  - Toda la arquitectura, resolución de incógnitas (dueño del worktree, matriz de merge/delete, reapers y RAM) y prospección scout OSS ($0 inferencia) se encuentran formalizadas en `docs/sprints/sprint-25-research.md`.
