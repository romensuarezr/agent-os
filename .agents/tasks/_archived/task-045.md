# Task-045: Salvaguarda de prospección determinista en sprint-planning.md y tool-decision-flow.md

## Objetivo
Incorporar una salvaguarda obligatoria de prospección OSS determinista en el workflow `sprint-planning.md` y reforzar la regla `tool-decision-flow.md`. Toda nueva tarea de desarrollo que plantee crear herramientas, integraciones o módulos debe consultar primero `scout.sh` (a coste 0 de tokens) y presentar las alternativas de código abierto detectadas en el informe de planificación para que el usuario decida si reutilizar una solución existente antes de codificar desde cero.

## Contexto técnico
En T-038 se creó el script determinista `scripts/agent/scout.sh` (GitHub, npm, PyPI) con coste de inferencia $0. Sin embargo, no estaba integrado de forma mandatoria en el ritual de planificación semanal `sprint-planning.md`, lo que propiciaba reinventar herramientas o desarrollar soluciones locales sin contrastar con el ecosistema OSS existente (como se comprobó en la prospección de MCP y enrutadores de modelos).
Esta tarea cierra la brecha de gobernanza asegurando que el agente presente un digest OSS estructurado durante la planificación de sprint.

## Caja de archivos
Archivos autorizados para modificación:
- `docs/sprints/sprint-07-core.md`
- `.agents/tasks/task-045.md`
- `.agents/workflows/sprint-planning.md`
- `.agents/rules/global/tool-decision-flow.md`
- `AGENTS.md`
- `CONTRIBUTING.md`

## Criterios de done
- [x] Workflow `sprint-planning.md` actualizado con un paso explícito de salvaguarda de prospección determinista (`2d. Prospección determinista OSS — scout.sh`) para tareas candidatas antes de la aprobación del sprint.
- [x] Plantilla del informe de sprint planning enriquecida para incluir la sección de alternativas OSS detectadas por `scout.sh` (con estrellas, licencias y recomendación de adopción).
- [x] Regla `.agents/rules/global/tool-decision-flow.md` reforzada con política estricta de "OSS-First & Pre-Code Scouting Obligatorio" y mandato de "Scripts Locales para Acciones Deterministas".
- [x] Principio formalizado en `AGENTS.md` (Principio 6 de diseño) y en `CONTRIBUTING.md` para priorizar scripts deterministas a coste $0 sobre inferencia del LLM.
- [x] Verificación de sintaxis de workflows y reglas conforme a los estándares de Agent OS.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-25T11:07:39+01:00
- [x] Rama creada: feat/T-045-sprint-scout-safeguard
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
