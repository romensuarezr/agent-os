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

## Diseño macro aprobado en planning
> Registro vinculante de diseño acordado entre el humano y el agente durante el sprint planning del Sprint 26.

- **Sprint / Fecha**: Sprint 26 / 2026-10-31
- **Diseño y arquitectura aprobados por**: Relé humano (Aprobación con cambios de Fase 3.5)
- **Decisiones e interfaces selladas**:
  - Arquitectura de dos niveles: Nivel Macro (humano en planning) y Nivel Micro (revisor como compuerta técnica por tarea).
  - Escalado vinculante `ESCALADO_A_HUMANO` ante cualquier desalineación entre el plan y el diseño macro aprobado, suspendiendo ejecución desatendida.
  - Papel del relé en transición: fallback operativo `SIN_REVISOR` y freno de merges hasta paridad en Sprint 27.
  - Artefacto concreto: sección canónica `## Diseño macro aprobado en planning` en `_template.md` y tasks instanciadas.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `orchestrator`: Gobernanza de roles, contratos y compuertas de calidad multi-agente.
- `workflow-designer`: Refactor y formalización de workflows en `.agents/workflows/`.
- `rule-creator`: Alineación de reglas operativas para agentes del ecosistema.

## Caja de archivos
- `.agents/workflows/session-start.md`
- `.agents/workflows/sprint-planning.md`
- `.agents/tasks/_template.md`
- `.agents/tasks/task-147.md`

## Criterios de done
- [x] Workflow `.agents/workflows/session-start.md` actualizado formalizando el flujo de compuerta técnica por tarea en Fase 3.5 (auditoría de caja, interfaces y escalado vinculante `ESCALADO_A_HUMANO` ante desviación de diseño macro), junto con el papel del relé en transición (fallback `SIN_REVISOR` y freno de merges hasta paridad en Sprint 27).
- [x] Workflow `.agents/workflows/sprint-planning.md` clarificado estableciendo el consenso de diseño arquitectónico y de producto como prerequisito obligatorio de planning, sellando la sección de diseño de las tareas.
- [x] Plantilla `.agents/tasks/_template.md` sincronizada con la sección de artefacto `## Diseño macro aprobado en planning` y los estados canónicos de deliberación/compuerta técnica.
- [x] Plan previo legible presentado en `.agents/context/plan-draft.md` y deliberado mediante `deliberate-plan.sh` (timeout default 60s).
- [x] Suite completa de control plane `tests/validate-control-plane.sh` pasando limpia (37/37) sin regresiones.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `SIN_REVISOR` (degradación segura por timeout en pasarela).
  - **Rol del revisor**: Compuerta técnica determinista (caja de archivos, tests, realidad repo, fidelidad a diseño macro).
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO CON CAMBIOS recibido — fecha/hora: 2026-10-31 14:02 UTC
- [x] Rama creada: `feat/T-147-two-tier-governance-flow`
- [x] Cierre y merge autorizado por el relé
