# Task-211: Heartbeat Proactivo & Telemetría de Latidos en Orquestación Multi-Agente

## Objetivo
Actualizar los contratos del Coordinador en `.agents/profiles/coordinator.md`, `.agents/rules/global/coordinator-boot.md`, `.agents/skills/orchestrator/SKILL.md` y `.agents/config/orchestration-playbooks.yaml` para incorporar el protocolo de **Latidos Proactivos (*Progress Heartbeats*)**. Cuando se despachan tareas a subagentes en paralelo y la ejecución supera un umbral de tiempo (ej. 3–5 minutos), el Coordinador o monitor debe emitir periódicamente un resumen conciso del estado de cada worker y una estimación de tiempo, eliminando la "ansiedad de la caja negra" y el silencio de radio hacia el operador.

## Contexto técnico
- En el ensayo real del Sprint 03 de `annascheer-web`, 3 agentes tardaron más de 30 minutos en compilar 34 rutas de Next.js y resolver tests.
- La ausencia de reportes intermedios provocó que el usuario pensara que el sistema estaba colgado o bloqueado, obligándolo a intervenir manualmente para solicitar un diagnóstico.
- La comunidad de orquestación multi-agente resuelve esto mediante sondas de latidos (*Heartbeats*) emitidas en intervalos configurables.

### Research integrado (`docs/sprints/sprint-39-research.md` → `### T-211`)
- **Scout OSS**: Modelos de heartbeat y telemetría no bloqueante.
- **Veredicto**: `Desarrollo a medida justificado` dentro de las directivas del Coordinador.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 39 / 2026-11-13
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - Incorporar en `coordinator.md` la sección "8. Protocolo de Latidos Proactivos (Heartbeats anti-ansiedad)".
  - Actualizar `orchestration-playbooks.yaml` con la directiva `heartbeat: { enabled: true, interval_minutes: 3, verbose_threshold_minutes: 5 }`.
  - Definir la plantilla de reporte de latido en `orchestrator/SKILL.md` y `coordinator-boot.md`.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/profiles/coordinator.md`
- `.agents/rules/global/coordinator-boot.md`
- `.agents/skills/orchestrator/SKILL.md`
- `.agents/config/orchestration-playbooks.yaml`
- `docs/sprints/sprint-39.md`
- `.agents/tasks/task-211.md`

## Criterios de done
- [x] Protocolo de latidos incorporado en `coordinator.md` y `coordinator-boot.md`.
- [x] Especificación de formato de latido documentada en `orchestrator/SKILL.md`.
- [x] Configuración `heartbeat` añadida a `orchestration-playbooks.yaml`.
- [x] Suite `tests/validate-control-plane.sh` pasando limpia sin regresiones (38/38 checks verdes).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
- [x] Plan presentado al usuario (Fase 3.5)
- [x] Rama de trabajo creada
- [x] Verificación con verify-goal.sh
- [x] Cierre y merge formalizado
