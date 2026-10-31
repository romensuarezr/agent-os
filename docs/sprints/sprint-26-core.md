# Sprint 26 — Cierre Determinista de Sprint y Hardening de Gobernanza

## Estado
🟡 En curso

## Tareas
| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :--- | :--: | :--- | :--- |
| T-146 | Cierre de sprint en invocación única concatenada y determinista (`close-sprint.sh` + `update-changelog.sh`) | Core / Gobernanza | S | ✅ Completada | — | [.agents/tasks/task-146.md](.agents/tasks/_archived/task-146.md) |
| T-147 | Definición del nuevo flujo de gobernanza (diseño en planning + revisor puerta por tarea) | Core / Gobernanza | S | ✅ Completada | — | [.agents/tasks/task-147.md](.agents/tasks/_archived/task-147.md) |
| T-148 | Corrección de literal CHANGELOG.md a changelog.md en propuesta de audit-repo.sh y test de regresión | Core / DX / Gobernanza | S | ✅ Completada | — | [.agents/tasks/task-148.md](.agents/tasks/_archived/task-148.md) |

## Actividades Piloto (No T-XXX)

### Ensayo Manual con Antigravity CLI
Actividad de pilotaje exploratorio asistido por CLI (no tarea formal T-XXX) para evaluar ergonomía, robustez y telemetría de interacción con el agente en entorno local.
- **Criterios de Éxito**:
  1. **Aislamiento de contexto**: La ejecución manual vía CLI no colisiona con variables de entorno ni archivos de sesión activos (`.agents/context/`).
  2. **Respeto a guardarraíles del core**: La herramienta CLI opera con $0 tokens en scripts deterministas locales, working tree limpio y sin mutaciones no autorizadas sobre ramas protegidas (`main`).
  3. **Feedback cualitativo**: Registro de observaciones de latencia, ergonomía de comandos y estabilidad de sesiones documentado en las notas del sprint sin generar deuda técnica.

## Disposición Explícita de Candidatas de Planning

### Candidatas Diferidas (con Motivo y Destino)
1. **Nota Scout Exhaustiva (diferida desde Sprint 24)**:
   - **Motivo**: La compuerta estricta Scout-First por tarea (T-129) ya cubre de forma determinista y a $0 tokens toda prospección necesaria para cada módulo activo en `docs/sprints/sprint-26-research.md`. Redactar una nota scout transversal sin módulos nuevos de producto en curso constituiría trabajo redundante de relleno.
   - **Destino**: Diferida a **Sprint 27+** (o cuando se abran módulos de integración con satélites).
2. **Medición de Paridad Revisor-vs-Relé**:
   - **Motivo**: Tras la saturación/timeout observado en la pasarela local de inferencia durante T-145 y T-146 (degradando limpiamente a `SIN_REVISOR`), medir paridad empírica viva carece de validez estadística hasta contar con una pasarela disponible sin contención. Además, la medición cuantitativa debe evaluarse operando bajo las compuertas del nuevo flujo que formalizará T-147.
   - **Destino**: Diferida a **Sprint 27** (como hito de calibración post-estabilización de pasarela).

### Candidatas Fuera de Alcance (con Motivo)
1. **Promoción a `main`**:
   - **Motivo**: `main` es una rama protegida y la promoción desde `multi-agent` es un evento de release formal e independiente, condicionado a la conclusión de ciclos completos de gobernanza y validación global. Queda explícitamente fuera del sprint de trabajo ordinario.
2. **REA / Bane / SearXNG**:
   - **Motivo**: Componentes de búsqueda profunda e infraestructuras pesadas externas que requieren stacks Docker dedicados y consumo de red. Agent OS mantiene el núcleo ligero, agnóstico, autónomo y con coste $0 de infraestructura; estas herramientas no forman parte del core operativo.
   - **Destino**: Registrado como ideas de largo plazo en `docs/idea-inbox/2026-10-30-front-door-orca-kb-soberana.md`.

## Notas de planning

- **Objetivo del Sprint**: Garantizar que el cierre de cualquier sprint en el ecosistema de Agent OS sea determinista en una única llamada (T-146), formalizar la arquitectura de gobernanza desacoplada en dos niveles (T-147: usuario valida diseño macro en planning, revisor actúa como compuerta técnica por tarea) y subsanar inconsistencias residuales de literales en herramientas de auditoría (T-148).
- **Guardarraíles operativos**:
  - Trabajo estrictamente secuencial en ramas aisladas `feat/T-XXX-*`.
  - Deliberación obligatoria en Fase 3.5 con `deliberate-plan.sh` (timeout default 60s).
  - Suite de control plane limpia (`tests/validate-control-plane.sh` 37/37).
  - Cero modificaciones a `main`, cero tags de Git.
- **Relación con el Documento de Research**:
  - Toda la prospección scout de T-146, T-147 y T-148 se encuentra registrada en `docs/sprints/sprint-26-research.md` (Gate Scout-First T-129).
