# Sprint 24 — Deliberación en Producción durante un Ciclo Completo con el Revisor Vivo

## Estado
🟡 En curso

## Tareas
| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :--- | :--: | :--- | :--- |
| T-137 | Deuda cosmética de T-135 (cabecera y ayuda de `deliberate-plan.sh` en 60s/~66s) | DX / Universalización | S | ✅ Completada | — | [.agents/tasks/task-137.md](.agents/tasks/_archived/task-137.md) |
| T-138 | Corregir y archivar el scout de ciclo de vida Orca (runbooks y guías de arquitectura) | Documentación / Core | S | ✅ Completada | T-137 | [.agents/tasks/task-138.md](.agents/tasks/_archived/task-138.md) |
| T-139 | Verificar el recolector de eventos Orca en host (`check --run --wait` frente a `--types`, payload `worker_done`) | Core / Investigación Empírica | M | ✅ Completada | T-138 | [.agents/tasks/task-139.md](.agents/tasks/_archived/task-139.md) |
| T-140 | Informe de observación del ciclo con criterio de paso al paralelo | Documentación / Gobernanza | S | ✅ Completada | T-137, T-138, T-139 | [.agents/tasks/task-140.md](.agents/tasks/_archived/task-140.md) |

## Notas de planning

- **Objetivo Estratégico**: Operar y observar el motor de deliberación determinista de Agent OS (`deliberate-plan.sh` + Orca ADE + OpenCode) en un ciclo de desarrollo real y completo. Durante este sprint, cada tarea someterá obligatoriamente su plan de Fase 3.5 a la deliberación con el Revisor Ejecutor vivo en el host, confirmando la estabilidad de la jerarquía de 3 niveles certificada en el Sprint 23 (Orca Revisor 60s → Cascada HTTP 5s → `SIN_REVISOR` $0) y contrastando empíricamente los mecanismos de eventos asíncronos de Orca para sentar las bases del paralelismo multi-agente futuro.
- **Guardarraíles Operativos (Mandatorios)**:
  1. **Deliberación Viva en Fase 3.5**: Cada plan de tarea se somete al revisor vivo en host (`scripts/agent/deliberate-plan.sh`), no a mocks ni a degradación forzada por defecto.
  2. **Una Sola Tarea Activa**: Flujo secuencial estricto. Cada tarea requiere su plan deliberado y aprobado antes de escribir una sola línea de código, seguido de su merge a `multi-agent` y cierre individual con `close-task.sh`.
  3. **Aislamiento `env -i` y Coste $0**: Toda interacción con el worker de Orca preserva la whitelist de variables declarada en T-135/T-136, previniendo fugas de credenciales en argv o entornos compartidos.
  4. **Límites de Alcance Estrictos**:
     - Fuera de alcance: despacho paralelo en sí (múltiples workers concurrentes), Bane, satélites y promoción de ramas a `main` (queda reservada para decisión explícita posterior).
- **Relación con el Documento de Research**:
  - Toda decisión técnica, selección de bibliotecas y parámetros operativos se encuentran respaldados por prospección determinista previa ($0 inferencia) en `docs/sprints/sprint-24-research.md`.
