# Task-203: Contrato de retorno compacto anti-context rot y script de telemetría

## Objetivo
Establecer en los contratos de agentes que los workers entreguen únicamente digests estructurados y evidencia determinista al Coordinador (evitando el vertido de transcripciones crudas que saturan la ventana de contexto), e implementar el script determinista `scripts/agent/orchestration-report.sh` para telemetría de ejecución, métricas de playbook empleado y estimación de ahorro de tokens/tiempo a coste $0.

## Contexto técnico
- El fenómeno del *context rot* (deterioro cognitivo del modelo coordinador por exceso de historial de chat) ocurre cuando los subagentes o workers devuelven transcripciones completas de sus acciones.
- El patrón de Anthropic y Alethe exige que los workers devuelvan únicamente evidencia: diffstat (`git diff --stat`), lista de archivos tocados y estado de verificación binaria (`verify-goal.sh --json`).
- Agent OS cuenta con `dispatched.jsonl` y metadatos de cierre de tarea (`close-task.sh`), pero no dispone de un comando unificado de reporte y telemetría de orquestación.

### Research integrado (`docs/sprints/sprint-37-research.md` → `### T-203`)
- **Scout OSS**: Evaluadas utilidades de telemetría (`Aireceipts`, `Lowfat`, `@microsoft/agents-telemetry`).
- **Veredicto**: `Desarrollo a medida justificado` en Bash POSIX ($0 tokens) con salida JSON/Markdown estructurada.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 37 / 2026-11-12
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - Actualizar `.agents/profiles/coder.md` y `.agents/profiles/coordinator.md`: fijar la cláusula contractual de "Retorno Compacto" (prohibido volcar logs crudos de ejecución; el handover debe ser un digest de evidencia $\le 30$ líneas con diffstat, lista de archivos y salida JSON de `verify-goal.sh`).
  - Crear script `scripts/agent/orchestration-report.sh`:
    - Opciones: `--sprint <ID>`, `--task-id <ID>`, `--json`, `--help`.
    - Agrega los datos de `dispatched.jsonl`, `docs/sprints/` y task files: calcula tiempo total de ejecución, playbook empleado, modelo/tier y resumen de compuertas pasadas.
    - Emite reporte Markdown conciso o JSON estructurado.
  - Cero dependencias externas (Bash estándar + `date`/`python3` stdlib).
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/orchestration-report.sh` (nuevo)
- `.agents/profiles/coder.md`
- `.agents/profiles/coordinator.md`
- `scripts/agent/assets-manifest.txt`
- `.agents/tasks/task-203.md`

## Criterios de done
- [x] Script `scripts/agent/orchestration-report.sh` implementado con permisos de ejecución (+x) y soporte `--help`, `--json` y agregación por tarea/sprint.
- [x] Perfiles `coder.md` y `coordinator.md` actualizados con la cláusula contractual de retorno compacto.
- [x] Manifiesto `assets-manifest.txt` actualizado con `orchestration-report.sh`.
- [x] Suite `tests/validate-control-plane.sh` pasando limpia sin regresiones (38/38 checks verdes).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
- [x] Plan presentado al usuario (Fase 3.5)
- [x] Rama de trabajo creada
- [x] Verificación con verify-goal.sh
- [x] Cierre y merge formalizado
