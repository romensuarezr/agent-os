# Task-150: Fallback determinista de mensaje de commit en close-task.sh en ramas no-feat

## Objetivo
Garantizar que al invocar `scripts/agent/close-task.sh [TASK_ID]` sin mensaje personalizado en una rama no-feat (por ejemplo, al cerrar desde ramas principales como `multi-agent`, ramas de hotfix, o ramas de integración que no siguen el esquema `tipo/T-XXX-descripcion`), el mensaje de commit no intente derivar scope ni descripción procesando el nombre de la rama, asignando un fallback canónico y predecible.

## Contexto técnico
El script `scripts/agent/close-task.sh` del core actual ya respeta correctamente el argumento `$1` como `EXPLICIT_TASK_ID`.
Sin embargo, en las líneas 84-91, si el usuario no proporciona un `--message` personalizado (`CUSTOM_MSG`), el script intenta deducir el tipo y la descripción a partir del nombre de la rama activa `$BRANCH` mediante `sed`.
Cuando se ejecuta en ramas que no siguen la convención `tipo/T-XXX-descripcion` (como `multi-agent` o `main`), la extracción sobre `$BRANCH` no corresponde al contexto de la tarea cerrada.
Esta tarea acota exclusivamente la lógica de generación del mensaje por defecto:
- Si `$BRANCH` es una rama de tarea (`^[a-zA-Z0-9_-]+/T-[0-9]+`), mantiene la derivación actual.
- Si `$BRANCH` no sigue este patrón (rama no-feat), asigna un mensaje limpio sin parsear la rama: `feat(${TASK_ID}): cierre de tarea ${TASK_ID}`.

## Diseño macro aprobado en planning
> Registro vinculante de diseño acordado entre el humano y el agente durante el sprint planning del Sprint 26 (Enmienda al Sprint 26).

- **Sprint / Fecha**: Sprint 26 / 2026-10-31
- **Diseño y arquitectura aprobados por**: Relé humano (Aprobación en planning de enmienda)
- **Decisiones e interfaces selladas**:
  - Preservar intacto el soporte existente de `$1` (`EXPLICIT_TASK_ID`). No reimplementar ni alterar el paso de argumentos.
  - Guardarraíl de mensaje: en ausencia de `CUSTOM_MSG`, comprobar si la rama actual cumple el patrón de rama de tarea (`echo "$BRANCH" | grep -qE '^[a-zA-Z0-9_-]+/T-[0-9]+'`).
  - Si es rama no-feat (ej. `multi-agent`, `main`), no ejecutar derivación de tokens sobre el nombre de la rama y asignar directamente como fallback único: `feat(${TASK_ID}): cierre de tarea ${TASK_ID}`.
  - Test de regresión determinista en `tests/validate-control-plane.sh` (integrado en Check 18) validando que `close-task.sh T-XXX` invocado en una rama no-feat emite el mensaje canónico esperado sin corromper el commit message.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `agent-os-scripts`: Mantenimiento y estándares de scripts deterministas del core (`close-task.sh`).
- `testing-flows`: Diseño de aserciones de regresión no destructivas en el control plane.

## Caja de archivos
- `scripts/agent/close-task.sh`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-150.md`

## Criterios de done
- [x] Lógica de derivación de mensaje en `scripts/agent/close-task.sh` actualizada con guardia explícita para ramas no-feat.
- [x] En rama no-feat sin `--message`, `close-task.sh` genera el commit con mensaje determinista `feat(${TASK_ID}): cierre de tarea ${TASK_ID}` sin procesar el nombre de la rama.
- [x] Test de regresión incorporado en `tests/validate-control-plane.sh` (Check 18) validando el mensaje generado en ramas no-feat.
- [x] Plan previo legible presentado en `.agents/context/plan-draft.md` deliberado formalmente mediante `deliberate-plan.sh` (timeout default 60s).
- [x] Suite completa de control plane `tests/validate-control-plane.sh` pasando limpia sin regresiones (37/37).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido
- [x] Rama creada (`feat/T-150-close-task-message-fallback`)
- [ ] Cierre y merge autorizado por el relé
