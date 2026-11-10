# Task-188: Endurecimiento del flujo desatendido (fuga de agy, paso 6 condicional SearXNG, compuerta proactiva session-start)

## Objetivo
Resolver de forma integral tres fricciones operativas detectadas en la ejecución desatendida del core:
1. Eliminar la fuga de procesos huérfanos de `agy` garantizando que el timeout de 30s de `deliberate-plan.sh` y `portable-timeout.sh` mate todo el grupo de procesos (`PGID`).
2. Hacer condicional el Paso 6 de `sprint-planning.md`: si la investigación fue autónoma (SearXNG activo), suprimir el prompt de Perplexity y la pausa; si SearXNG estaba inactivo, emitir anuncio explícito del motivo/código antes de solicitar la asistencia manual.
3. Estandarizar la compuerta proactiva de `session-start.md` para que ante un sprint con `[PENDIENTE_ARRANQUE]` emita de forma invariable y determinista la consulta estructurada de Régimen (A: Opción D / B: Clásico) y el camino de carriles.

## Contexto técnico
Durante el Sprint 32 y el planning del Sprint 33 se detectaron:
- Procesos huérfanos de `agy --conversation` (ej. PID 814302 activo durante más de 38 minutos) debido a que `portable-timeout.sh` usaba `timeout` básico que solo señalizaba al proceso directo `env` y no a los procesos nietos en el mismo grupo de procesos.
- El Paso 6 de `sprint-planning.md` mantenía un bloqueo asistido redundante cuando SearXNG ya había completado la meta-búsqueda soberana. Además, el operador estipuló que si cae al fallback manual de Perplexity, el aviso debe ser ruidoso y explícito sobre por qué falló SearXNG.
- En `session-start.md`, la compuerta proactiva no se activó con claridad al finalizar el planning, requiriendo un formato rígido y predecible que garantice la consulta obligatoria antes de iniciar tareas.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 33 / 2026-11-10
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - `portable-timeout.sh` / `deliberate-plan.sh`: implementar matanza de todo el grupo de procesos (`os.killpg` en Python o `kill -- -PGID` en bash/timeout con process session independiente) con escalado SIGTERM -> SIGKILL.
  - `sprint-planning.md`: bifurcación estricta en Paso 5 y 6:
    - SearXNG activo (`exit 0`): omite prompt y pausa de Perplexity, transiciona directo a la entrega y solicitud de aprobación macro del sprint.
    - SearXNG inactivo (`exit 2` o fallo): emite anuncio explícito `⚠️ SearXNG inactivo (motivo: <diagnóstico|código>). Activando fallback asistido con Perplexity.` + prompt + pausa.
  - `session-start.md`: formalizar que ante `[PENDIENTE_ARRANQUE]` o primera sesión del sprint, el flujo bloquea y emite exactamente la plantilla interactiva de Régimen (A: Opción D / B: Clásico) y orden de carriles, esperando confirmación.
  - Denominador de suite rígidamente inmutable en 38/38.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/lib/portable-timeout.sh`
- `scripts/agent/deliberate-plan.sh`
- `.agents/workflows/sprint-planning.md`
- `.agents/workflows/session-start.md`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-188.md`

## Criterios de done
- [x] `portable-timeout.sh` y `deliberate-plan.sh` matan todo el grupo de procesos ante timeout (0 procesos huérfanos residuales).
- [x] Paso 6 de `sprint-planning.md` condicional a SearXNG; fallback ruidoso si SearXNG falla.
- [x] Compuerta proactiva de `session-start.md` estandarizada para emitir invariablemente las opciones A/B y carriles.
- [x] Suite de validación `tests/validate-control-plane.sh` 38/38 en verde.
- [x] `locator-hygiene.sh` 100% limpio.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `CONSENSO`
  - **Rol del revisor**: Compuerta técnica determinista (qa-judge).
- [x] Plan presentado al usuario (Fase 3.5 — Opción D sellada en planning)
- [x] APROBADO recibido — fecha/hora: 2026-11-10 21:19 UTC (camino limpio Opción D)
- [x] Rama creada: feat/T-188-endurecimiento-flujo-desatendido
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
