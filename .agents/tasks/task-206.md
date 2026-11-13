# Task-206: Telemetría de arnés/modelo en orchestration-report.sh y sincronización a la flota

## Objetivo
Actualizar la utilidad determinista `scripts/agent/orchestration-report.sh` para procesar y presentar métricas de arnés (`antigravity-subagent`, `opencode`, `direct`), modelo (`gemini-3.8-flash-*`, `claude-sonnet-*`, etc.) y nivel de esfuerzo empleados en cada tarea, y sincronizar los contratos y reglas de Sprint 38 a los repositorios satélite (`<satelites>/annascheer-web`) mediante `sync.sh --force --cleanup --commit`.

## Contexto técnico
- En T-203 se creó `orchestration-report.sh` para auditar tareas, playbooks y ahorro de tokens.
- Para ofrecer total transparencia sobre "quién hizo qué y con qué modelo", el reporte debe exponer el desglose de modelos/arneses empleados a partir de los datos registrados en `dispatched.jsonl` o task digests.
- La flota satélite debe recibir estas mejoras de inmediato para que las próximas sesiones en `annascheer-web` y otros satélites se beneficien de la selección dinámica de esfuerzo.

### Research integrado (`docs/sprints/sprint-38-research.md` → `### T-206`)
- **Scout OSS**: Integración determinista en scripts CLI existentes.
- **Veredicto**: `Desarrollo a medida justificado`.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 38 / 2026-11-13
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - Modificar `scripts/agent/orchestration-report.sh` para soportar columnas opcionales de `ARNÉS`, `MODELO` y `ESFUERZO` en la tabla de tareas y campos correspondientes en la salida `--json`.
  - Sincronizar todos los cambios a `<satelites>/annascheer-web` usando `bash scripts/agent/sync.sh --force --cleanup --commit <satelites>/annascheer-web`.
  - Auditar que `audit-satellites.sh` confirme satélites LIMPIOS.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/orchestration-report.sh`
- `docs/sprints/sprint-38.md`
- `.agents/tasks/task-206.md`
- Referencia externa: `<satelites>/annascheer-web` (solo vía `sync.sh`)

## Criterios de done
- [ ] Script `orchestration-report.sh` actualizado con soporte para arnés, modelo y nivel de esfuerzo.
- [ ] Ejecución de `orchestration-report.sh` validada tanto en modo terminal como con `--json`.
- [ ] Sincronización a satélite real (`<satelites>/annascheer-web`) ejecutada limpiamente.
- [ ] `audit-satellites.sh` reporta satélite LIMPIO (61/61 scripts OK).
- [ ] Suite `tests/validate-control-plane.sh` pasando limpia sin regresiones (38/38 checks verdes).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] Rama de trabajo creada
- [ ] Verificación con verify-goal.sh
- [ ] Cierre y merge formalizado
