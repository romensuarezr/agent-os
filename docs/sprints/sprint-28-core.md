# Sprint 28 — Autonomía Acotada, Enrutado por Dificultad y Hardening del Revisor Dual

> **Período**: 2026-11-02 → 2026-11-06  
> **Enfoque**: Piloto de autonomía acotada sin pegado de informes, experimento empírico de enrutado por dificultad (Orca vs. agy) y cobertura de tests de hueco del Revisor Dual.

---

## Estado
🟡 En curso

---

## Tareas

| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :---: | :--: | :--- | :--- |
| **T-155** | Batería de tests de hueco del Revisor Dual en Check 34 (binario ausente, kill y handoff) | Core / Tests | S | ⬜ Pendiente | — | [.agents/tasks/task-155.md](.agents/tasks/task-155.md) |
| **T-156** | Experimento empírico de enrutamiento por dificultad: evaluación comparada Orca vs. agy | Core / Calibración | M | ⬜ Pendiente | T-155 | [.agents/tasks/task-156.md](.agents/tasks/task-156.md) |
| **T-157** | Piloto de autonomía acotada con canal directo Agente-Relé y medición de intervenciones | Core / Gobernanza | M | ⬜ Pendiente | T-155, T-156 | [.agents/tasks/task-157.md](.agents/tasks/task-157.md) |

---

## Disposición Explícita de Candidatas de Planning

### Candidatas Fuera de Alcance en Sprint 28 (con Motivo)

1. **Promoción a `main` de v1.15 a v1.23 y tags de release**:
   - **Motivo**: Excluido explícitamente de la agenda de Sprint 28. Constituye una decisión y evento de release independiente condicionado a la maduración de los pilotos de gobernanza.
2. **Sincronización masiva a satélites (`sync.sh`)**:
   - **Motivo**: Excluido de la agenda del Sprint 28. Se mantiene diferido hasta consolidar el modelo de autonomía acotada y calibración definitiva de pasarelas.
3. **Autonomía irrestricta o eliminación de compuertas humanas**:
   - **Motivo**: Prohibido por diseño. Las compuertas humanas (diseño macro en planning, `ESCALADO_A_HUMANO`, `SIN_REVISOR` y promoción a `main`) son inmutables.

---

## Notas de planning

### 1. Contexto y Balance de Sprint 27
El Sprint 27 concluyó con éxito pleno (4/4 tareas completadas, release `v1.23.0`):
- Cableado del Revisor Antigravity CLI (`agy`) como Tier 1 (T-152).
- Blindaje de seguridad con centinelas PRE/POST, aislamiento `env -i` y certificación git-limpio (T-153).
- Batería de calibración N=10 con veredicto **`PARIDAD_CONDICIONADA`** (100% de seguridad/fail-safe, 0 falsos consensos, 60% concordancia idéntica, $0 coste facturado de inferencia) (T-154).
- Decisión de Gobernanza (Opción A): Los 3 tests de borde identificados en la suite se consolidan como backlog prioritario para iniciar el Sprint 28.

### 2. Agenda Priorizada de Sprint 28

#### Prioridad 1: Piloto de Autonomía Acotado (T-157)
- **Objetivo**: Ejecutar y completar una tarea sin que el usuario tenga que copiar y pegar manualmente informes ni veredictos en el chat.
- **Canal Directo Agente → Relé (Propuestas Arquitectónicas del Planning)**:
  - *Opción A (Fichero Marcador Local / Signal File)*: El agente escribe la propuesta en `.agents/context/rele-signal-T-XXX.json` y un script helper de un solo comando (`bash scripts/agent/rele-signal.sh T-XXX approve`) permite al usuario estampar la señal sin copiar texto.
  - *Opción B (Interacción Asistida UI `ask_question` / Prompt Directo)*: El agente formula una consulta estructurada directa en Antigravity con opciones predefinidas ("Aprobar", "Aprobar con cambios", "Escalar") eliminando la fricción de redacción manual.
  - *Opción C (Marcador en Rama / Commit de Estado)*: Señalización asíncrona mediante rama efímera o commit de inspección.
- **Criterios Estrictos de Aborto**:
  - Si el canal falla, si el revisor emite `SIN_REVISOR`, si se detecta cualquier mutación no autorizada o si el plan se desvía del diseño macro pactado, el flujo autónomo se interrumpe de inmediato (*fail-closed*) y regresa al modo clásico interactivo de pegado manual.
- **Métricas del Piloto**:
  - Medición del recuento de intervenciones humanas frente a la línea base actual (~3 intervenciones por tarea: Fase 3.5, reporte de implementación, cierre).
  - Exigencia de 0 degradaciones silenciosas, 0 desviaciones del diseño macro coladas y suite de control plane en verde estricto (37/37).

#### Prioridad 2: Experimento de Enrutado por Dificultad (T-156)
- **Objetivo**: Determinar con datos empíricos objetivos (no por intuición) si la dificultad arquitectónica de un plan justifica enrutar selectivamente hacia Orca ADE.
- **Muestra Focalizada**: Tomar los casos de T-154 donde `agy` agotó el timeout de 30s sin emitir veredicto (C-04: omisión de tests, C-06: fuga a main/tags, C-07: alteración de contratos).
- **Procedimiento**: Someter los casos al worker de Orca ADE con presupuesto amplio (60s a 120s).
- **Criterio de Decisión**:
  - Si Orca emite veredictos estructurados limpios de rechazo (`ESCALADO_A_HUMANO` / `REVISADO_CON_CAMBIOS`), el enrutado selectivo por dificultad queda empíricamente respaldado (`ENRUTADO_DIFICIL_VIABLE`).
  - Si Orca también agota tiempo o se desorienta, se dictamina que los planes discordantes deben remitirse directamente a arbitraje humano por diseño, descartando la complejidad del enrutador (`ENRUTADO_DIFICIL_DESCARTADO`).

#### Prioridad 3: Cobertura de Tests de Hueco del Revisor Dual (T-155)
- **Objetivo**: Integrar los 3 casos de borde identificados en T-154 dentro de Check 34 de `tests/validate-control-plane.sh`:
  1. *Binario ausente*: degradación inmediata (0s) hacia Orca ante ausencia de `agy` en PATH.
  2. *Timeout real con kill*: terminación determinista con señal `SIGKILL` efectiva.
  3. *Handoff agy → Orca*: cascada limpia con veredicto accepted en Tier 2.

### 3. Puertas Humanas Inmutables
- **Macro de Planning**: Sellado vinculado por el relé en este documento y en cada task file.
- **`ESCALADO_A_HUMANO`**: Inviolable; cualquier anomalía o violación de perfiles escala a humano.
- **Desviaciones de Diseño Macro**: Bloqueo fail-closed.
- **`SIN_REVISOR`**: Siempre escala a humano; jamás se auto-aprueba desatendidamente.
- **Promoción a `main`**: Operación exclusivamente manual y externa al sprint.

### 4. Cumplimiento de Compuerta Scout-First (T-129)
Toda la prospección OSS determinista de las tareas T-155, T-156 y T-157 se encuentra documentada en `docs/sprints/sprint-28-research.md`, certificando desarrollo a medida justificado ($0 dependencias externas).
