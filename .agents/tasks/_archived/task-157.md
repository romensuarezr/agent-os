# Task-157: Marco del piloto de autonomía Opción D, arnés de compuertas deterministas e informe

## Objetivo
Formalizar la arquitectura operativa, reglas de compuerta y arnés determinista del **Piloto de Autonomía Opción D** (avance autónomo en camino limpio con merge desatendido a `multi-agent`, publicación en `origin` para auditoría *a posteriori* y aborto fail-closed ante cualquier anomalía), preparando el marco de ejecución e instrumentación de métricas de intervención para el mini-sprint testigo de Bane (T-158 a T-161), y documentando la estructura base del informe en `docs/sprints/sprint-28-autonomy-pilot-report.md`.

## Contexto técnico
En la enmienda de planning del Sprint 28, el relé humano aprobó la **Opción D** como el modelo de autonomía para evaluar en el core:
- **Camino Limpio**:
  1. Revisor técnico emite veredicto estructurado de `CONSENSO`.
  2. Suite de pruebas `tests/validate-control-plane.sh` pasa limpia al 100% (37/37).
  3. El diff del código está estrictamente circunscrito a la caja de archivos autorizada.
  4. El plan técnico no presenta ninguna desviación frente al `## Diseño macro aprobado en planning`.
  5. Centinelas PRE y POST de seguridad certifican cero mutaciones espurias fuera del perímetro de trabajo.
- **Avance Autónomo Autorizado**: En este camino limpio, el agente avanza de forma continua y desatendida a través de las compuertas internas de sesión, ejecutando el commit de implementación, el merge `--no-ff` a `multi-agent`, push a `origin` y ejecución de `close-task.sh`, eliminando las ~3 intervenciones rutinarias de copiado y pegado por parte del usuario.
- **Auditoría *A Posteriori***: Todo el rastro queda publicado en `origin` para revisión asíncrona del relé humano (recibos `.agents/context/deliberation-T-XXX.json` y digests redactados).
- **Compuertas de Aborto Inmediato (Fail-Closed)**: Ante `SIN_REVISOR`, `ESCALADO_A_HUMANO`, `RECHAZADO`, desviación del diseño macro, mutación de centinelas o fallo en la suite, el agente aborta de inmediato la autonomía y escala al chat interactivo.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 28 / 2026-11-02
- **Diseño y arquitectura aprobados por**: Humano / Relé (Sprint Planning Sprint 28 - Enmienda Opción D)
- **Decisiones e interfaces selladas**:
  - Definición explícita de las reglas de Opción D documentadas en la base operativa del core.
  - Creación del arnés de métricas en `docs/sprints/sprint-28-autonomy-pilot-report.md` para registrar sistemáticamente las intervenciones por tarea (baseline ~3/tarea vs. piloto Opción D).
  - Reglas de compuerta inviolables:
    - Humano interviene exclusivamente en: sellado del diseño macro en planning, resolución de anomalías/abortos y promoción manual a `main`.
    - `SIN_REVISOR` jamás se auto-aprueba desatendidamente; escala siempre de forma obligatoria al humano.
  - T-157 se ejecuta como la última tarea bajo el régimen de puertas interactivas del relé, dejando el marco listo para que T-158..T-161 operen bajo Opción D.
  - Denominador de la suite de control plane se mantiene en **37/37** (0 errores).
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `agent-os-scripts`: Integración con workflows de sesión y scripts de gobernanza.
- `orchestrator`: Reglas de compuerta y protocolos de autonomía multi-agente / relé.
- `testing-flows`: Aserciones de control plane y verificación de compuertas fail-closed.

## Caja de archivos
- `docs/sprints/sprint-28-autonomy-pilot-report.md`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-157.md`

## Criterios de done
- [x] Marco operativo y reglas del piloto Opción D formalizadas y documentadas.
- [x] Criterios de aborto fail-closed explícitamente declarados y blindados.
- [x] Estructura del informe del piloto e instrumentación de métricas de intervención creada en `docs/sprints/sprint-28-autonomy-pilot-report.md`.
- [x] Aserción en Check 34 de `tests/validate-control-plane.sh` verificando la presencia del informe del piloto.
- [x] Suite de control plane pasando limpia (37/37) con 0 errores.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido
- [x] Rama creada
- [ ] Cierre y merge autorizado por el relé
