# Task-177: Formalizar el flujo inteligente (pregunta proactiva al arrancar el sprint)

## Objetivo
Formalizar en los workflows canónicos de agent-os (`session-start.md`, `sprint-planning.md` y plantilla de acta) el flujo inteligente de arranque de sprint: consulta proactiva al operador, una sola vez, para elegir (1) régimen (desatendida Opción D vs. tarea a tarea clásica) y (2) camino (orden de carriles derivado de las dependencias del acta).

## Contexto técnico
El estándar de gobernanza de dos niveles de agent-os cuenta con el régimen Opción D (autonomía acotada en camino limpio mediada por `deliberate-plan.sh`), pero la inicialización operativa al inicio de un sprint no contaba con una compuerta proactiva formalizada en `session-start.md` que interrogue al operador una única vez sobre el modo de ejecución deseado para el sprint y el orden de los carriles derivado del grafo de dependencias definido en planning.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Transición Sprint 31 → 32 / 2026-11-10
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - **Consulta proactiva única**: Al arrancar un sprint (primera sesión o sin régimen sellado en el acta), el flujo pregunta proactivamente una sola vez:
    1. *Régimen*: Desatendida (Opción D: encadena tareas en camino limpio sin volver al usuario entre ellas, aborta a humano ante anomalía) o Tarea a tarea (clásico: revisión/aprobación en cada puerta antes de la siguiente).
    2. *Camino*: Orden de carriles derivado de la tabla de dependencias del acta (siguiendo el piloto de Sprint 31).
  - **Sellado en acta**: La elección queda registrada en el acta del sprint bajo `## Régimen Operativo del Sprint` para no volver a preguntar en sesiones subsiguientes del sprint.
  - **Flujo en session-start.md**: Integración en Fase 1/1b de la compuerta proactiva de arranque y encadenamiento desatendido en Fase 6 si el régimen es Opción D. El encadenamiento en Opción D aborta inmediatamente a humano si la verificación del relé de la tarea recién cerrada falla.
  - **Flujo en sprint-planning.md**: Incorporación explícita de la definición de dependencias por tarea y orden de carriles en el acta.
  - **Plantilla de acta (`sprint-template.md`)**: Inclusión de la columna `Dependencias` en la tabla de tareas y bloque declarativo para `Régimen Operativo` y `Orden de Carriles`.
  - **Guardarraíles**: No tocar código ejecutable ni otros workflows fuera de los especificados.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/workflows/session-start.md`
- `.agents/workflows/sprint-planning.md`
- `templates/docs/sprints/sprint-template.md`

## Criterios de done
- [x] `.agents/workflows/session-start.md` incorpora la compuerta proactiva al arrancar el sprint (pregunta única de régimen y camino de carriles, sellado en acta y encadenamiento en camino limpio con aborto a humano si la verificación del relé de la tarea recién cerrada falla).
- [x] `.agents/workflows/sprint-planning.md` formaliza el modelado de dependencias entre tareas, orden de carriles y estructura del acta.
- [x] `templates/docs/sprints/sprint-template.md` actualizado con columna `Dependencias` y sección declarativa de régimen y carriles.
- [x] Validación determinista de higiene y suite de control plane `tests/validate-control-plane.sh` 38/38 en verde sin regresiones.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `CONSENSO`
  - **Rol del revisor**: Compuerta técnica determinista (caja de archivos, tests, realidad repo, fidelidad a diseño macro).
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO CON CAMBIOS recibido — fecha/hora: 2026-11-10 18:16 UTC (incorporado aborto a humano si la verificación del relé de la tarea recién cerrada falla)
- [x] Rama creada: feat/T-177-flujo-inteligente-arranque-sprint
- [x] Lock activo: .agent-session.lock
- [ ] Sesión cerrada correctamente
