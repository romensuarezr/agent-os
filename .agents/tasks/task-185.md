# Task-185: Refinamiento y paridad de session-close.md con régimen Opción D

## Objetivo
Actualizar `.agents/workflows/session-close.md` para armonizarlo plenamente con las reglas de gobernanza de Opción D, el cierre atómico con `close-task.sh`, la verificación obligatoria del relé con aborto fail-closed a humano si falla, y el encadenamiento autónomo a la siguiente tarea del carril.

## Contexto técnico
El workflow `session-start.md` fue refactorizado y modernizado en T-177 para incorporar el flujo inteligente, los carriles y la consulta proactiva de Opción D. Sin embargo, `session-close.md` aún arrastra instrucciones de etapas previas (Octubre 2026), desalineadas con la verificación post-cierre y el avance continuo desatendido en camino limpio.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 33 / 2026-11-10
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Incorporar el protocolo de cierre atómico con `bash scripts/agent/close-task.sh T-XXX`.
  - Especificar la verificación obligatoria del relé: ejecución de `tests/validate-control-plane.sh` y `locator-hygiene.sh` tras el commit de cierre.
  - Formalizar la compuerta fail-closed: si la verificación del relé falla, el encadenamiento desatendido se aborta inmediatamente a humano.
  - Describir el handoff hacia la siguiente tarea en el carril bajo Opción D sin interrupción del operador si todas las compuertas están en verde.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/workflows/session-close.md`
- `.agents/tasks/task-185.md`

## Criterios de done
- [ ] `.agents/workflows/session-close.md` actualizado con protocolo Opción D y `close-task.sh`.
- [ ] Documentada la compuerta de verificación del relé post-cierre y su fail-closed.
- [ ] Protocolo de encadenamiento entre tareas del carril estandarizado.
- [ ] Suite de validación `tests/validate-control-plane.sh` 38/38 en verde.
- [ ] `locator-hygiene.sh` 100% limpio.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
- [ ] Plan presentado al usuario
- [ ] APROBADO recibido
- [ ] Rama creada
- [ ] Lock activo: .agent-session.lock
- [ ] Sesión cerrada correctamente
