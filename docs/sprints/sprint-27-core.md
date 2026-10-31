# Sprint 27 — Revisor Antigravity CLI, Observabilidad de Liveness y Paridad de Gobernanza

## Estado
🟡 En curso

## Tareas
| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :--- | :--: | :--- | :--- |
| T-151 | Trial de liveness y observabilidad del worker de inferencia en deliberación | Core / Telemetría | S | ⬜ Pendiente | — | [.agents/tasks/task-151.md](.agents/tasks/task-151.md) |
| T-152 | Cableado del Revisor Antigravity CLI (agy) como Tier 1 en deliberate-plan.sh | Core / Gobernanza | M | ⬜ Pendiente | T-151 | [.agents/tasks/task-152.md](.agents/tasks/task-152.md) |
| T-153 | Guardas de seguridad, aislamiento read-only y certificación git-limpio para agy | Core / Seguridad | S | ⬜ Pendiente | T-152 | [.agents/tasks/task-153.md](.agents/tasks/task-153.md) |
| T-154 | Batería de calibración, medición de cuota/coste y paridad Revisor-vs-Relé (T-147) | Core / Calibración | M | ⬜ Pendiente | T-152, T-153 | [.agents/tasks/task-154.md](.agents/tasks/task-154.md) |

## Disposición Explícita de Candidatas de Planning

### Candidatas Fuera de Alcance (con Motivo)
1. **Promoción a `main` de v1.15 a v1.22 y tags de release**:
   - **Motivo**: Excluido explícitamente de la agenda del Sprint 27. Constituye una decisión y evento de release independiente condicionado a la conclusión de los ciclos de validación global.
2. **Sincronización masiva a satélites (`sync.sh`)**:
   - **Motivo**: Excluido de la agenda del Sprint 27. Se gestionará como decisión aparte tras estabilizar el revisor Antigravity y calibrar su paridad.

## Notas de planning

- **Auditoría de Inboxes**: `check-inbox.sh` ejecutado en base previo al planning; inboxes (`docs/external-inbox/` y `docs/idea-inbox/`) 100% vacíos salvo archivos históricos en sus respectivos `_archived/`. Cero entradas pendientes de triaje o clasificación.
- **Objetivo del Sprint**: Ejecutar el trial de liveness previo sobre workers de inferencia sin alterar compuertas técnicas (T-151), cablear Antigravity CLI (`agy`) como Tier 1 prioritario en el motor de arbitraje con wrapper de timeout y robustez ante `exit 0` (T-152), dotar al revisor de contención estricta de solo lectura y certificación de working tree limpio (T-153), y ejecutar la batería de calibración cuantitativa de paridad Revisor-vs-Relé bajo la gobernanza de dos niveles formalizada en T-147 midiendo coste y cuota (T-154).
- **Guardarraíles operativos**:
  - Trabajo estrictamente secuencial en ramas aisladas `feat/T-XXX-*`.
  - Deliberación técnica obligatoria en Fase 3.5 con `deliberate-plan.sh`.
  - Suite de control plane limpia (`tests/validate-control-plane.sh` 37/37).
  - Cero modificaciones a `main`, cero tags de Git.
- **Relación con el Documento de Research**:
  - Toda la prospección scout de T-151, T-152, T-153 y T-154 se encuentra registrada en `docs/sprints/sprint-27-research.md` (Gate Scout-First T-129).
