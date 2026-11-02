# Sprint 28 — Autonomía Acotada (Opción D), Enrutado por Dificultad e Integración Soberana de Bane

> **Período**: 2026-11-02 → 2026-11-06  
> **Enfoque**: Blindaje de tests de hueco del Revisor Dual, experimento empírico de enrutamiento por dificultad, marco del piloto de autonomía Opción D, y mini-sprint de integración soberana de Bane (T-158 a T-161) ejecutado como trabajo testigo real.

---

## Estado
🟡 En curso

---

## Tareas

| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :---: | :--: | :--- | :--- |
| **T-155** | Batería de tests de hueco del Revisor Dual en Check 34 (binario ausente, kill y handoff) | Core / Tests | S | ✅ Completada | — | [.agents/tasks/task-155.md](.agents/tasks/_archived/task-155.md) |
| **T-156** | Experimento empírico de enrutamiento por dificultad: evaluación comparada Orca vs. agy | Core / Calibración | M | ✅ Completada | T-155 | [.agents/tasks/task-156.md](.agents/tasks/task-156.md) |
| **T-157** | Marco del piloto de autonomía Opción D, arnés de compuertas deterministas e informe | Core / Gobernanza | M | ✅ Completada | T-155, T-156 | [.agents/tasks/task-157.md](.agents/tasks/task-157.md) |
| **T-158** | Plantillas Docker Compose y configuración de flota de Bane con frontera portable | Core / Infraestructura | S | ✅ Completada | T-157 | [.agents/tasks/task-158.md](.agents/tasks/task-158.md) |
| **T-159** | Cliente CLI determinista para Bane (`bane-client.sh`) con salida stdout y sonda | Core / Tooling | M | ✅ Completada | T-158 | [.agents/tasks/task-159.md](.agents/tasks/task-159.md) |
| **T-160** | Workflow `deep-research` con bifurcación autónomo (Bane activo) / manual (Perplexity) | Core / Workflows | M | ✅ Completada | T-159 | [.agents/tasks/task-160.md](.agents/tasks/task-160.md) |
| **T-161** | Diagnóstico de flota (`fleet-doctor`), compuerta técnica, runbook y suite (38/38) | Core / Calibración & Suite | S | ⬜ Pendiente | T-160 | [.agents/tasks/task-161.md](.agents/tasks/task-161.md) |

---

## Disposición Explícita de Candidatas de Planning

### Excepción a la Regla de Selección (3 a 5 tareas)
- **Autorización**: Concedida explícitamente por el usuario / relé en la enmienda de planning del Sprint 28.
- **Motivo**: El Sprint 28 se compone formalmente de **7 tareas** para articular en un único sprint el hardening del revisor (T-155), el experimento de enrutado (T-156), el marco de gobernanza del piloto Opción D (T-157) y el mini-sprint de Bane (T-158 a T-161) que actúa como batería testigo real para evaluar empíricamente la autonomía desatendida.

### Candidatas Fuera de Alcance en Sprint 28 (con Motivo)
1. **Promoción a `main` de v1.15 a v1.23 y tags de release**:
   - **Motivo**: Excluido explícitamente. Se mantiene como decisión y evento de release independiente.
2. **Sincronización masiva a satélites (`sync.sh`)**:
   - **Motivo**: Excluido de la agenda del Sprint 28 hasta la conclusión del piloto de autonomía.

---

## Notas de planning

### 1. Marco del Piloto de Autonomía (Opción D)
Aprobado por el usuario como el modelo operativo para el trabajo testigo del Sprint 28:
- **Reglas del Camino Limpio**:
  - Si el Revisor emite `CONSENSO`, la suite de tests está en verde, el diff está estrictamente contenido en la caja de archivos autorizada y el diseño macro se respeta íntegramente: **el agente avanza sin requerir señal humana interactiva por puerta**.
  - El avance autónomo incluye la implementación, commits atómicos en rama, el merge `--no-ff` a `multi-agent`, push a `origin` y ejecución de `close-task.sh`.
- **Auditoría *A Posteriori***:
  - Todo el ciclo queda publicado y trazable en `origin` (rama de feat, recibo `.agents/context/deliberation-T-XXX.json` y digest en `docs/sprints/design-decisions/`) para la inspección y supervisión asíncrona del relé.
- **Compuerta de Aborto Inmediato (Fail-Closed)**:
  - Ante cualquiera de las siguientes condiciones:
    1. Veredicto `SIN_REVISOR` (la pasarela cae o no responde).
    2. Veredicto `ESCALADO_A_HUMANO` o `RECHAZADO`.
    3. Desviación explícita o implícita del diseño macro aprobado en planning.
    4. Modificación de archivos fuera de la caja autorizada.
    5. Disparo de centinelas de seguridad PRE o POST (mutación no autorizada).
    6. Fallo en la suite de validación `tests/validate-control-plane.sh`.
  - **Acción**: El agente detiene inmediatamente la ejecución autónoma, no realiza merge y escala de forma obligatoria al operador humano en el chat.
- **Puertas Humanas Inmutables**:
  - El diseño macro en planning (sellado previo).
  - La gestión de anomalías y abortos.
  - `SIN_REVISOR` jamás se auto-aprueba desatendidamente.
  - La promoción a `main` (siempre manual y externa al sprint).

### 2. Mini-Sprint Bane como Trabajo Testigo Real (T-158 a T-161)
Bane (motor open-source de búsqueda con razonamiento profundo / clon de Perplexity Pro) se integra en la flota de Agent OS resolviendo los 4 hitos atómicos del spec bajo las reglas del piloto Opción D:
1. **T-158**: Plantilla Compose agnóstica (`templates/bane/docker-compose.yml`) y esquema en `.agents/config/fleet.example.yaml` bajo estricta frontera portable (cero literales personales en el core).
2. **T-159**: Cliente CLI determinista `scripts/agent/lib/bane-client.sh` con salida Markdown por stdout y semántica de disponibilidad estricta: *"Activo" = configurado Y alcanzable dentro de un timeout corto (≤3s)*; si no, degrada limpiamente a modo inactivo sin bloquear al agente.
3. **T-160**: Workflow `.agents/workflows/deep-research.md` integrado en `sprint-planning.md` con bifurcación determinista: si Bane está activo → deep research autónomo desatendido; si está inactivo/ausente → preserva el prompt manual clásico de Perplexity Pro sin alteraciones.
4. **T-161**: Sonda en `scripts/agent/fleet-doctor.sh` (modo warn-only), runbook operativo en `docs/runbooks/bane-deep-research-service.md` y aserciones en `tests/validate-control-plane.sh` con **denominador explícito de suite actualizado de 37/37 a 38/38**.

### 3. Orden de Ejecución y Dependencias
- **Secuencia de trabajo**: `T-155 → T-156 → T-157 → T-158 → T-159 → T-160 → T-161`.
- **Régimen de puertas**:
  - `T-155` y `T-156` se ejecutan bajo las **puertas interactivas clásicas del relé** (el piloto Opción D aún no aplica).
  - `T-157` formaliza y documenta el arnés del piloto Opción D.
  - `T-158`, `T-159`, `T-160` y `T-161` se ejecutan bajo las **reglas autónomas de Opción D** como batería testigo, midiendo intervenciones del usuario frente a la línea base (~3 por tarea).

### 4. Cumplimiento de Compuerta Scout-First (T-129)
Las 7 tareas cuentan con su respectiva prospección determinista registrada en [docs/sprints/sprint-28-research.md](sprint-28-research.md), garantizando 0 dependencias ajenas y $0 coste de tokens.
