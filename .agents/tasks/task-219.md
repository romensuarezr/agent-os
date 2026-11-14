# T-219 — Integración Automática de Reporte de Orquestación en close-sprint.sh y session-close.md
Sprint: Sprint 41 | Estado: ⬜ Pendiente | Tamaño: S | Rama propuesta: feat/T-219-orchestration-report-auto-closure | Merge destino: multi-agent

## Diseño macro aprobado en planning
- **Sprint / Fecha**: Sprint 41 — 2026-11-14
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Invocación determinista de `scripts/agent/orchestration-report.sh` durante el ritual de cierre de sprint en `close-sprint.sh`.
  - El digest emitido debe incluir: tareas totales, distribución por playbooks, desglose por worker / harness / modelo y cálculo consolidado de floor cost savings ($0 tokens).
  - Inclusión de la directiva de reporte en `.agents/workflows/session-close.md` y `.opencode/commands/session-close.md`.
  - Modo seguro y resiliente: si no hay ejecuciones registradas en `.agents/context/dispatched.jsonl`, el script degrada limpiamente informando de 0 despachos sin abortar el cierre del sprint.
- **Veredicto de diseño macro**: [APROBADO_EN_PLANNING]

---

## 1. Objetivo
Garantizar que al finalizar un sprint (especialmente en régimen Desatendido), el Coordinador ejecute y presente automáticamente el informe consolidado de orquestación y telemetría multi-agente, haciendo visible el ahorro económico y la actividad de los workers de la flota.

## 2. Contexto técnico
- Herramienta de telemetría: `scripts/agent/orchestration-report.sh` (11.0 KB).
- Script de cierre de sprint: `scripts/agent/close-sprint.sh`.
- Workflows de cierre: `.agents/workflows/session-close.md`, `.opencode/commands/session-close.md`.
- Registro histórico: `.agents/context/dispatched.jsonl`.

## 3. Caja de archivos
- `.agents/tasks/task-219.md`
- `scripts/agent/close-sprint.sh`
- `.agents/workflows/session-close.md`
- `.opencode/commands/session-close.md`
- `docs/sprints/sprint-41.md`

## 4. Plan de implementación
1. Analizar el flujo de cierre en `scripts/agent/close-sprint.sh` e identificar el punto exacto posterior a la validación de changelog y git status para intercalar la llamada a `orchestration-report.sh`.
2. Actualizar `close-sprint.sh` para volcar el resumen del reporte de orquestación en la salida estándar y asegurar su inclusión en el digest del sprint.
3. Actualizar `.agents/workflows/session-close.md` y `.opencode/commands/session-close.md` formalizando el paso del reporte de orquestación previo al empaquetado final.
4. Validar sintaxis y ejecutar simulación no destructiva.

## 5. Criterios de aceptación
- `close-sprint.sh` ejecuta `orchestration-report.sh` sin errores y emite el desglose de telemetría.
- Degradación elegante si no hay histórico en `dispatched.jsonl`.
- `tests/validate-control-plane.sh` permanece en 38/38 checks verdes.
