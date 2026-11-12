# Task-202: Declaración de Playbooks de orquestación y regla de umbral (<= 3 archivos)

## Objetivo
Formalizar el catálogo declarativo de estrategias de orquestación en `.agents/config/orchestration-playbooks.yaml` e implementar la regla de umbral determinista de $\le 3$ archivos en el flujo de trabajo (`session-start.md` y `orchestrator`), evitando el sobrecoste (*overhead*) de tokens y tiempo que supone coordinar subagentes o worktrees para tareas mecánicas o acotadas.

## Contexto técnico
- La investigación empírica de Anthropic y Dev Knives confirma que delegar tareas de $\le 3$ archivos multiplica el consumo de tokens innecesariamente respecto a la ejecución directa en el hilo principal (*floor cost* de delegación).
- El catálogo de Alethe (`alethe-orchestrate-skill`) formaliza playbooks específicos (`direct`, `scout-then-build`, `plan-big-execute-small`, `parallel-worktrees`, `review-gate`).
- En Agent OS, carecemos de un fichero declarativo de playbooks y de una regla dura que fuerce el modo `direct` cuando la allowlist del task file es pequeña.

### Research integrado (`docs/sprints/sprint-37-research.md` → `### T-202`)
- **Scout OSS**: Alternativas evaluadas (`jjanczur/tyran`, `sammyjason39/agent-build-playbook`, `alethe-orchestrate-skill`).
- **Veredicto**: `Desarrollo a medida justificado` adaptando el esquema YAML declarativo a los roles nativos de Agent OS (`coordinator`, `coder`, `qa-judge`).

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 37 / 2026-11-12
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - Crear `.agents/config/orchestration-playbooks.yaml` definiendo las 5 estrategias canónicas:
    1. `direct`: tareas de $\le 3$ archivos (ejecución sin worktree en sesión local).
    2. `scout-then-build`: exploración previa de solo lectura con `scout.sh` / `searxng-client.sh`.
    3. `plan-big-execute-small`: deliberación y diseño en tier fuerte (Antigravity), ejecución acotada en tier económico/gratuito (OpenCode / OmniRoute).
    4. `parallel-worktrees`: carriles independientes del sprint ejecutados en paralelo con `worktree-dispatch.sh`.
    5. `review-gate`: compuerta de revisión desacoplada previa a merge (`verify-goal.sh`).
  - Implementar la compuerta de umbral en `.agents/workflows/session-start.md`: si la Caja de Archivos del task file tiene $\le 3$ archivos, forzar playbook `direct` y prohibir el despacho de worktrees efímeros redundantes.
  - Actualizar la skill `orchestrator` ([orchestrator/SKILL.md](.agents/skills/orchestrator/SKILL.md)) para referenciar el catálogo de playbooks.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/config/orchestration-playbooks.yaml` (nuevo)
- `.agents/workflows/session-start.md`
- `.agents/skills/orchestrator/SKILL.md`
- `scripts/agent/assets-manifest.txt`
- `.agents/tasks/task-202.md`

## Criterios de done
- [x] Archivo `.agents/config/orchestration-playbooks.yaml` creado con esquema declarativo válido y descripciones claras.
- [x] Regla de umbral ($\le 3$ archivos) integrada en `session-start.md` documentando el bypass del despacho de worktrees.
- [x] Skill `orchestrator` alineada con la selección de playbooks.
- [x] Manifiesto `assets-manifest.txt` actualizado.
- [x] Suite `tests/validate-control-plane.sh` pasando limpia sin regresiones (38/38 checks verdes).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
- [x] Plan presentado al usuario (Fase 3.5)
- [x] Rama de trabajo creada
- [x] Verificación con verify-goal.sh
- [x] Cierre y merge formalizado
