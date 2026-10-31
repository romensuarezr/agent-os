# Task-147: Definición del nuevo flujo de gobernanza (diseño en planning + revisor puerta por tarea)

## Objetivo
Formalizar en los workflows y plantillas del core el nuevo flujo de gobernanza de dos niveles desacoplados:
1. **Nivel Macro (Diseño y Arquitectura)**: El usuario humano evalúa y aprueba formalmente las decisiones arquitectónicas, interfaces y alcance funcional durante el ritual de sprint planning (o Fase 1 de sesión).
2. **Nivel Micro (Compuerta Técnica de Tarea)**: El Revisor Ejecutor (o relé en degradación segura a `SIN_REVISOR`) actúa como compuerta técnica estricta en Fase 3.5 mediante `deliberate-plan.sh`, auditando que el plan de implementación respeta la caja de archivos, la realidad del repositorio y los guardarraíles del diseño ya aprobado, sin reabrir discusiones de diseño macro.

## Contexto técnico
La experiencia de los Sprints 20 a 25 demostró que mezclar la toma de decisiones de diseño con la revisión técnica por tarea generaba fricción operativa o delegaba diseño conceptual en revisores locales cuya función óptima es la auditoría determinista de cumplimiento y límites de alcance.
Este nuevo flujo delimita con claridad:
- Qué valida el humano (diseño conceptual, estrategia, aprobación en planning).
- Qué audita la máquina (fuga de scope, respeto de interfaces, cobertura de tests, verificación determinista previa a escribir código).

## Skills relevantes
- `orchestrator`: Gobernanza de roles, contratos y compuertas de calidad multi-agente.
- `workflow-designer`: Refactor y formalización de workflows en `.agents/workflows/`.
- `rule-creator`: Alineación de reglas operativas para agentes del ecosistema.

## Caja de archivos
- `.agents/workflows/session-start.md`
- `.agents/workflows/sprint-planning.md`
- `.agents/templates/TASK_TEMPLATE.md`
- `.agents/tasks/task-147.md`

## Criterios de done
- [ ] Workflow `.agents/workflows/session-start.md` actualizado formalizando el flujo de compuerta técnica por tarea en Fase 3.5 sin reabrir diseño macro.
- [ ] Workflow `.agents/workflows/sprint-planning.md` clarificado estableciendo el consenso de diseño arquitectónico y de producto como prerequisito obligatorio de planning.
- [ ] Plantilla `.agents/templates/TASK_TEMPLATE.md` y `.agents/templates/TASK_CONTRACT.md` sincronizadas con los estados canónicos de deliberación y compuerta de tarea.
- [ ] Plan previo legible presentado en `.agents/context/plan-draft.md` y deliberado mediante `deliberate-plan.sh` (timeout default 60s).
- [ ] Suite completa de control plane `tests/validate-control-plane.sh` pasando limpia (37/37) sin regresiones.
