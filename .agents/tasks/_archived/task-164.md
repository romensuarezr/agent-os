# Task-164: Formalizar Opción D como régimen por defecto (workflows y docs)

## Objetivo
Formalizar el régimen de autonomía acotada Opción D como el flujo operativo predeterminado del core en los workflows canónicos (`session-start.md`, `sprint-planning.md`), la guía maestra de arquitectura (`AGENTS.md`) y la suite de validación, eliminando contradicciones entre la documentación y la práctica validada en el Sprint 28.

## Contexto técnico
El piloto de autonomía Opción D ejecutado en el Sprint 28 sobre las tareas testigo T-158 a T-161 redujo la fricción interactiva en un 91.7% con cero consensos falsos y cero desviaciones arquitectónicas. Actualmente, `session-start.md` aún estipula una pausa humana obligatoria en Fase 3.5 para cada tarea individual, lo cual choca con la operativa real de autonomía desatendida aprobada.
Se requiere:
1. Actualizar `.agents/workflows/session-start.md` para consagrar el camino limpio desatendido ante veredicto `CONSENSO` y las compuertas estrictas de aborto fail-closed ante cualquier anomalía.
2. Actualizar `.agents/workflows/sprint-planning.md` para explicitar que el diseño macro aprobado en planning es la única autorización vinculante que habilita la ejecución autónoma posterior.
3. Actualizar `AGENTS.md` para reflejar la Opción D como el estándar operativo del core.
4. Actualizar la suite de control plane para validar la coherencia de estos contratos en los checks correspondientes.

Esta tarea se ejecuta bajo el régimen estándar de **Opción D**.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 29 / 2026-11-02
- **Diseño y arquitectura aprobados por**: Humano / Relé (Sprint Planning Sprint 29)
- **Decisiones e interfaces selladas**:
  - En `.agents/workflows/session-start.md`:
    - Rediseñar Fase 3.4 y Fase 3.5: si el veredicto es estrictamente `CONSENSO`, la suite está verde, el diff está en la caja de archivos y se respeta el diseño macro, el agente ejecuta el camino limpio desatendido (implementación, tests, commits atómicos, condición pre-merge refinada, merge `--no-ff` a la rama base, push y `close-task.sh`).
    - Formalizar la regla pre-merge refinada (Precision 2 relé): condición pre-merge = rama + informe/notas publicados en origin ANTES del merge, y recibo de deliberación debidamente acreditado (referenciado con su veredicto/SHA); la persistencia del digest y del raw JSON de deliberación se captura formalmente en el cierre (`close-task.sh` vía `design-digest.sh`), sin exigir publicación literal aislada del archivo de recibo en origin previa al merge.
    - Si el veredicto es != `CONSENSO` (`SIN_REVISOR`, `REVISADO_CON_CAMBIOS`, `ESCALADO_A_HUMANO`, `RECHAZADO`), la suite falla, hay mutaciones de centinelas o archivos fuera de caja: aborto inmediato fail-closed y escalado al chat.
    - Preservar la auditoría *a posteriori* en `origin` con el digest histórico y el raw JSON redactado en `docs/sprints/design-decisions/`.
  - En `.agents/workflows/sprint-planning.md`:
    - Formalizar el sellado de diseño macro en planning como el requisito indispensable para la autonomía en la sesión.
  - En `AGENTS.md`:
    - Documentar el régimen Opción D en la sección de principios de diseño y workflows.
  - En `tests/validate-control-plane.sh`:
    - Actualizar comprobaciones de texto/patrones de `session-start.md` en Check 34/35.
  - Denominador de la suite de control plane se mantiene en **38/38** (0 errores).
  - Régimen Opción D: avance desatendido en camino limpio ante veredicto `CONSENSO`.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `workflow-designer`: Consistencia y formalización de workflows canónicos de Antigravity.
- `orchestrator`: Protocolos de compuertas y despacho autónomo.

## Caja de archivos
- `.agents/workflows/session-start.md`
- `.agents/workflows/sprint-planning.md`
- `AGENTS.md`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-164.md`

## Criterios de done
- [x] `.agents/workflows/session-start.md` actualizado consagrando el camino limpio desatendido y el aborto fail-closed.
- [x] `.agents/workflows/sprint-planning.md` actualizado con el requisito habilitante de sellado de diseño macro.
- [x] `AGENTS.md` actualizado reflejando el régimen Opción D como estándar.
- [x] Check 34 y Check 35 de `tests/validate-control-plane.sh` adaptados sin regresiones.
- [x] Suite de control plane 38/38 pasando limpia (0 errores).
- [x] Ejecutada y registrada bajo las reglas de Opción D.

## Recibo de deliberación acreditado
- Veredicto: `CONSENSO` (Tier 1 `agy: qa-judge`)
- Archivo: `.agents/context/deliberation-T-164.json`
- Ronda: 1 (Consenso inicial sin objeciones de inventario)
- Hash deliberación: `d3600f6805179cbff7d97e3fc55c635be9d375bb6a445d43fb60fe7322987115`
