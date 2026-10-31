# Task-149: Gate mecánico fail-closed de skills declaradas en plan contra .agents/skills/

## Objetivo
Implementar una compuerta determinista fail-closed en el motor de deliberación y pre-flight de planes (`scripts/agent/deliberate-plan.sh`) que verifique que toda skill declarada en el plan borrador existe efectivamente en el directorio `.agents/skills/` del repositorio. Si alguna skill declarada no existe en disco, abortar inmediatamente de forma fail-closed con mensaje explícito y código de error, impidiendo que planes con skills inexistentes o fantasma superen la compuerta técnica.

## Contexto técnico
En el plan T-124 del satélite leaderboard, se declaró la skill `modern-web-guidance` como ACTIVA a pesar de no existir en `.agents/skills/` del repositorio origin.
El Check 5 actual de `tests/validate-control-plane.sh` solo valida la integridad de las skills que ya existen físicamente en disco (`SKILL.md` intacto), pero no existe ningún mecanismo que contraste lo que el agente *declara* en su plan contra el inventario real instalado.
Esta tarea introduce una compuerta mecánica análoga a la comprobación de existencia de ficheros de la caja, garantizando que ninguna skill no instalada pueda ser dada por buena en un plan.

## Diseño macro aprobado en planning
> Registro vinculante de diseño acordado entre el humano y el agente durante el sprint planning del Sprint 26 (Enmienda al Sprint 26).

- **Sprint / Fecha**: Sprint 26 / 2026-10-31
- **Diseño y arquitectura aprobados por**: Relé humano (Aprobación en planning de enmienda)
- **Decisiones e interfaces selladas**:
  - Validación mecánica determinista previa a la deliberación dentro de `scripts/agent/deliberate-plan.sh`.
  - Extracción estática de los identificadores de skills declaradas en el bloque de skills del plan (`plan-draft.md` como fuente autoritativa, sección `## Cláusula de Skills` / `## 6. Cláusula de Skills` / `🧠 5. SKILLS APLICADAS`). El parser ignora valores nulos o informativos como "No aplica", "no aplica", "ninguna" o "-" y valida únicamente skills concretas.
  - Verificación de existencia de directorio y archivo de definición: `test -d "$ROOT/.agents/skills/$skill"` y `test -f "$ROOT/.agents/skills/$skill/SKILL.md"`.
  - Comportamiento fail-closed: si alguna skill declarada como activa/aplicada no existe en disco, emitir error visible (`❌ ERROR: Skill declarada no existe en .agents/skills/: <skill>`) y salir con código != 0 (o veredicto estructurado de bloqueo), deteniendo el arbitraje.
  - Test de regresión determinista en `tests/validate-control-plane.sh` (integrado en Check 5 o Check 34) validando que un plan que declare una skill inexistente (ej: `modern-web-guidance`) es rechazado de forma fail-closed.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `agent-os-scripts`: Mantenimiento y robustez de scripts deterministas del core (`deliberate-plan.sh`).
- `testing-flows`: Diseño de pruebas de regresión y fixtures no destructivos en el control plane.

## Caja de archivos
- `scripts/agent/deliberate-plan.sh`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-149.md`

## Criterios de done
- [x] Función de validación de skills declaradas implementada en `scripts/agent/deliberate-plan.sh`.
- [x] Si el plan declara una skill inexistente en `.agents/skills/`, `deliberate-plan.sh` aborta fail-closed con mensaje legible y código de error antes de enviar a inferencia/revisor.
- [x] Test de regresión determinista incorporado en `tests/validate-control-plane.sh` (Check 34) comprobando que una skill declarada inexistente gatilla fallo inmediato y que skills válidas con "No aplica" pasan.
- [x] Plan previo legible presentado en `.agents/context/plan-draft.md` deliberado formalmente mediante `deliberate-plan.sh` (timeout default 60s).
- [x] Suite completa de control plane `tests/validate-control-plane.sh` pasando limpia sin regresiones (37/37).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido
- [x] Rama creada (`feat/T-149-skills-fail-closed-gate`)
- [ ] Cierre y merge autorizado por el relé
