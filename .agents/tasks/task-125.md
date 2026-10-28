# Task-125: Protocolo de Handover y Contratos Inter-Agente en Perfiles Declarativos

## Objetivo
Formalizar el protocolo de handover entre roles declarativos del sistema (`coordinator`, `coder`, `reviewer`, `qa-judge`), definiendo las compuertas de paso de información, contratos de estado y artefactos intercambiados para que la colaboración multi-agente sea determinista, trazable y sin ambigüedades.

## Contexto técnico
La arquitectura multi-agente de Agent OS cuenta con perfiles declarativos en `.agents/profiles/`:
- `coordinator`: Despacha tareas y orquesta el flujo general.
- `coder`: Desarrolla las soluciones técnicas en aislamiento.
- `reviewer`: Audita planes y decisiones técnicas (deliberación a $0 tokens).
- `qa-judge`: Evalúa desacopladamente el resultado mediante `verify-goal.sh` y Ralph Loop.
Actualmente, los contratos de traspaso entre estos roles no contemplan explícitamente el bucle de deliberación de Sprint 20 ni las compuertas de handover. Esta tarea formaliza:
1. Contrato Coordinator → Coder: asignación de tarea, worktree base y límites de contexto (<4KB).
2. Contrato Coder ↔ Reviewer: protocolo de deliberación de planes (Fase 3.4/3.5).
3. Contrato Coder → QA-Judge: emisión de evidencias de verificación y diffs para arbitraje.
4. Contrato QA-Judge / Coordinator → Merge: criterios de autorización antes de `worktree-merge.sh`.

## Skills relevantes
- `orchestrator`: Orquestación multi-agente declarativa y contratos de roles.
- `doc-maintainer`: Estructura y mantenimiento de los perfiles declarativos.
- `goal-evaluation`: Protocolos de compuertas de calidad deterministas.

## Caja de archivos
- `.agents/profiles/coordinator.md`
- `.agents/profiles/coder.md`
- `.agents/profiles/qa-judge.md`
- `.agents/profiles/reviewer.yaml`
- `.agents/tasks/task-125.md`

## Criterios de done
- [ ] Perfiles declarativos actualizados con la sección de Protocolo de Handover y artefactos esperados.
- [ ] Especificación formal del contrato inter-agente y estados de traspaso (DISPATCHED, DELIBERATING, REVIEWED, EVALUATED, MERGED).
- [ ] Validación de consistencia sintáctica y semántica con `validate-control-plane.sh` (Checks 1, 2, 10).
