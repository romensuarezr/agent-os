# Task-057: Skill y Workflow de Orquestación Paralela Multi-Agente (orchestrator/SKILL.md, parallel-orchestration.md)

## Objetivo
Diseñar la skill `.agents/skills/orchestrator/SKILL.md` con los comandos declarativos (`/goal`, `/subgoal`, `/dispatch`, `/gate`) y redactar el workflow `.agents/workflows/parallel-orchestration.md` que formaliza el ciclo de vida completo de ejecución paralela desatendida y consolidación en terminal única.

## Contexto técnico
- Basado en los requerimientos del sprint y los hallazgos de `docs/sprints/sprint-09-core-research.md`:
  - `.agents/skills/orchestrator/SKILL.md`:
    - Interfaz de comandos operativos:
      - `/goal <descripción>`: Registra una meta de alto nivel con End State Contract.
      - `/subgoal <task-id> <perfil> <caja_archivos>`: Descompone la meta en un sub-objetivo asignado a un perfil especialista.
      - `/dispatch <task-id>`: Invoca `worktree-dispatch.sh` para levantar el worktree y poner en marcha al worker.
      - `/gate <task-id>`: Invoca `verify-goal.sh` y el protocolo Judge de `goal-evaluation` para evaluar la terminación.
    - Soporte para emitir `consolidated-digest.json` con el avance global de todos los workers activos.
  - `.agents/workflows/parallel-orchestration.md`:
    - Runbook paso a paso del ciclo de vida de una tarea paralela:
      1. Planificación y aprobación del DAG de tareas en la terminal principal.
      2. Despacho concurrente de workers aislados en `.worktrees/<task-id>/`.
      3. Ejecución independiente sin interferencia de archivos.
      4. Bucle Ralph Loop de validación (QA Judge + `verify-goal.sh`).
      5. Resolución de compuertas (Merge seguro vía `worktree-merge.sh` o escalado humano ante 3 fallos).
      6. Entrega consolidada en la terminal del Coordinador (Single-Pane of Glass).

## Caja de archivos
Archivos autorizados para modificación / creación:
- `.agents/skills/orchestrator/SKILL.md`
- `.agents/workflows/parallel-orchestration.md`
- `docs/sprints/sprint-09-core.md`
- `.agents/tasks/task-057.md`

## Criterios de done
- [ ] Skill `.agents/skills/orchestrator/SKILL.md` creada con sintaxis de comandos declarativos (`/goal`, `/subgoal`, `/dispatch`, `/gate`) y especificación de flujos.
- [ ] Workflow `.agents/workflows/parallel-orchestration.md` documentado como runbook exhaustivo con diagramas de flujo y control de errores.
- [ ] Integración con el patrón de consolidación desatendida (Single-Pane of Glass del Coordinador).
- [ ] Reglas de control de concurrencia y límites de carga de trabajo.
- [ ] Estado reflejado en `docs/sprints/sprint-09-core.md` y `.agents/tasks/task-057.md`.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
