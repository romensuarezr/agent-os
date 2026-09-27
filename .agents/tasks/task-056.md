# Task-056: Perfiles Especialistas Declarativos (coordinator.md, coder.md, qa-judge.md, docs-researcher.md)

## Objetivo
Estandarizar y documentar los perfiles declarativos de especialistas en `.agents/profiles/*.md`, formalizando el principio de responsabilidad única (SRP), interfaces de entrada/salida, herramientas autorizadas y restricciones anti-alucinación para la orquestación multi-agente.

## Contexto técnico
- Basado en los requerimientos del sprint y los hallazgos de `docs/sprints/sprint-09-core-research.md`:
  - `.agents/profiles/coordinator.md`:
    - Rol: Front-door y orquestador principal (Single-Pane of Glass).
    - Responsabilidades: Triage de peticiones del usuario, desglose de `/goal` en `/subgoal`, despacho de workers en worktrees efímeros, recepción de digests de evaluación y presentación de resumen final consolidado.
    - Restricción estricta: Prohibido modificar directamente archivos de código en producción o resolver tareas técnicas por sí mismo (debe delegar a workers).
  - `.agents/profiles/coder.md`:
    - Rol: Obrero de desarrollo técnico e implementación.
    - Responsabilidades: Implementación atómica de código dentro de la Caja de Archivos Autorizados de su task file asignado.
    - Restricción estricta: Prohibido modificar archivos fuera del allowlist o realizar merge/push a ramas principales.
  - `.agents/profiles/qa-judge.md`:
    - Rol: Evaluador de compuertas y calidad (Ralph Loop).
    - Responsabilidades: Ejecutar `verify-goal.sh`, analizar diffs y reportar veredicto binario (`PASS` / `FAIL`).
    - Regla de parada: Máximo 3 reintentos al worker; al tercer fallo consecutivo emite `escalated_to_human`.
    - Restricción estricta: Prohibido proponer o inyectar código; solo emite diagnóstico estructurado del fallo.
  - `.agents/profiles/docs-researcher.md`:
    - Rol: Especialista en prospección técnica, documentación, síntesis y ADRs.
    - Responsabilidades: Redacción de research, actualización de runbooks, mantenimiento de changelogs y roadmaps.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `.agents/profiles/coordinator.md`
- `.agents/profiles/coder.md`
- `.agents/profiles/qa-judge.md`
- `.agents/profiles/docs-researcher.md`
- `docs/sprints/sprint-09-core.md`
- `.agents/tasks/task-056.md`

## Criterios de done
- [ ] Perfil `.agents/profiles/coordinator.md` creado con contrato de orquestación desatendida y límites claros.
- [ ] Perfil `.agents/profiles/coder.md` creado con especificación de worker técnico acotado a la Caja de Archivos.
- [ ] Perfil `.agents/profiles/qa-judge.md` creado con el protocolo del bucle Ralph Loop, circuit breaker de 3 intentos y veredicto binario.
- [ ] Perfil `.agents/profiles/docs-researcher.md` creado para tareas de análisis, prospección OSS y documentación.
- [ ] Consistencia de roles y herramientas frente a los principios de `AGENTS.md`.
- [ ] Estado reflejado en `docs/sprints/sprint-09-core.md` y `.agents/tasks/task-056.md`.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
