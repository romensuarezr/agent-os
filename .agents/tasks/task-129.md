# Task-129: Enforcement Scout y Auditoría de Completitud en Workflow de Planning

## Objetivo
Formalizar el enforcement de la prospección scout determinista (`scripts/agent/scout.sh`) en el workflow `.agents/workflows/sprint-planning.md` y en la generación de digests con `scripts/agent/design-digest.sh`, exigiendo la existencia y completitud del archivo de investigación `docs/sprints/sprint-XX-research.md` antes de autorizar la publicación de un sprint.

## Contexto técnico
En el Sprint 21 se observó que el planning inicial se publicó omitiendo el research scout previo que prescribe el estándar de agent-os (pasos 2d y 2e). Se requirió un paso de respaldo posterior para restituir la disciplina scout.
Para evitar recurrencias y garantizar la gobernanza del core:
1. `.agents/workflows/sprint-planning.md` se actualiza para incorporar una compuerta estricta: la Fase 2 (Prospección Tecnológica y Scout-First) exige ejecutar `scout.sh` y redactar `docs/sprints/sprint-<NUM>-research.md` con subsecciones por tarea antes de pasar al Decision Gate.
2. `scripts/agent/design-digest.sh` añade soporte para registrar el estado de investigación scout en los digests de planificación o validar la presencia de la sección `## Descubrimientos Scout (por tarea)`.
3. Se documenta la regla: "Sin research scout estructurado no hay plan de sprint admisible".

## Skills relevantes
- `workflow-designer`: Estándares de diseño y gobernanza de workflows en Antigravity.
- `tech-scout`: Protocolos de prospección determinista de paquetes y librerías OSS.
- `agent-os-scripts`: Verificación determinista CLI y manejo de contratos en scripts de agent-os.

## Caja de archivos
- `.agents/workflows/sprint-planning.md`
- `scripts/agent/design-digest.sh`
- `.agents/tasks/task-129.md`

## Criterios de done
- [ ] `sprint-planning.md` actualizado con la compuerta obligatoria de prospección scout-first y persistencia de research.
- [ ] `design-digest.sh` verifica o reporta la presencia y completitud del documento de research en contextos de planning.
- [ ] Verificación de ejecución determinista y fail-closed sin dependencias de red externas.
