# Task-204: Ensayo y validación E2E en satélite real (annascheer-web)

## Objetivo
Ejecutar la validación práctica de extremo a extremo de las innovaciones del Sprint 37 sincronizándolas al satélite real `<satelites>/annascheer-web`, verificando deterministamente la presencia de `AGENTS.md`, la activación de la regla de boot del Coordinador y la selección de playbooks, y dejando una guía operativa paso a paso para que el operador humano realice la prueba manual directa en una terminal de Antigravity sobre la web de Anna.

## Contexto técnico
- El usuario solicitó explícitamente validar la implementación en un satélite real antes de dar por cerrado el sprint: *"incluye la prueba real como tarea del sprint, para testear que está bien implementado. y luego lo hago yo manualmente en un proyecto que me digas, como la web de anna"*.
- `annascheer-web` es el satélite ideal: tiene el Sprint 02 activo con T-006 y T-007 hechas, y 3 tareas pendientes listas (T-008, T-009, T-010).
- Permite verificar el ciclo completo: distribución de `AGENTS.md`, reconocimiento del rol de Coordinador, diagnóstico del sprint a coste $0 y selección del playbook adecuado (`parallel-worktrees` o `plan-big-execute-small`).

### Research integrado (`docs/sprints/sprint-37-research.md` → `### T-204`)
- **Scout OSS**: Validación empírica directa en proyecto real sin intermediarios sintéticos.
- **Veredicto**: `Desarrollo a medida justificado`.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 37 / 2026-11-12
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - Sincronizar todos los activos nuevos de T-201, T-202 y T-203 a `<satelites>/annascheer-web` usando `bash scripts/agent/sync.sh --force --cleanup --commit <satelites>/annascheer-web`.
  - Verificar deterministamente en el satélite:
    1. Existencia y contenido de `AGENTS.md` en la raíz de `annascheer-web`.
    2. Existencia de `.agents/rules/global/coordinator-boot.md` y `.agents/config/orchestration-playbooks.yaml`.
    3. Ejecución de `check-sprint.sh` y `orchestration-report.sh` devolviendo códigos de salida limpios (exit 0).
  - Documentar en el task file y en el informe de cierre la **Guía de Verificación Manual para el Operador**:
    - Comando para abrir la terminal en `annascheer-web`.
    - Qué debe responder el nuevo agente de Antigravity al abrir la sesión (saludo como Coordinador, estado del Sprint 02 y menú interactivo de opciones).
    - Cómo verificar que el agente propone el playbook correcto para las tareas pendientes.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `docs/sprints/sprint-37.md`
- `.agents/tasks/task-204.md`
- Referencia externa: `<satelites>/annascheer-web` (solo vía `sync.sh`)

## Criterios de done
- [ ] `sync.sh --force --cleanup --commit` ejecutado satisfactoriamente sobre `<satelites>/annascheer-web`.
- [ ] Verificado que `annascheer-web/AGENTS.md` existe y está en paridad con la plantilla canónica.
- [ ] Verificado que `audit-satellites.sh` reporta `annascheer-web` como LIMPIO (60/60 scripts OK o nueva cuenta con `orchestration-report.sh`).
- [ ] Guía paso a paso documentada para la prueba manual del operador humano en `annascheer-web`.
- [ ] Suite `tests/validate-control-plane.sh` pasando limpia sin regresiones (38/38 checks verdes).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] Rama de trabajo creada
- [ ] Verificación con verify-goal.sh
- [ ] Cierre y merge formalizado
