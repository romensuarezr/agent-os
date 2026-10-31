# Task-151: Trial de liveness y observabilidad del worker de inferencia en deliberación

## Objetivo
Ejecutar un ensayo empírico no destructivo de observabilidad para evaluar el estado real del worker de inferencia (`Orca ADE`) al producirse un timeout en la deliberación, determinando si el proceso permanece vivo+avanzando, vivo+atascado o muerto, y si el veredicto estructurado llega dentro de una ventana de extensión de gracia (+30 a +60s) o nunca. Emitir un informe de diagnóstico con veredicto concluyente (`LIVENESS_VIABLE` o `LIVENESS_DESCARTADO`) sin alterar el veredicto `SIN_REVISOR` ni la compuerta humana del relé.

## Contexto técnico
En sesiones anteriores (T-145, T-146, T-149, T-150), las deliberaciones contra la pasarela local de inferencia alcanzaron el presupuesto de timeout (15s/60s), provocando la degradación determinista a `SIN_REVISOR`.
Antes de introducir cualquier mecanismo o cableado de liveness en el core, se requiere una comprobación empírica preliminar: medir si el worker realmente sigue computando y logra responder con un margen adicional (+30-60s) o si entra en un estado de bloqueo permanente / inanición.
El resultado de este trial determinará si el liveness se convierte en componente formal o se descarta definitivamente.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 27 / 2026-10-31
- **Diseño y arquitectura aprobados por**: Humano / Relé (Sprint Planning Sprint 27)
- **Decisiones e interfaces selladas**:
  - Trial puramente observacional y de medición: no muta la compuerta de `deliberate-plan.sh`, no altera la emisión de `SIN_REVISOR` ni elimina la puerta obligatoria de aprobación del relé.
  - La suite de control plane (`tests/validate-control-plane.sh`) se utiliza exclusivamente para instrumentación y verificación del reporte del trial, sin tocar `deliberate-plan.sh` ni modificar sus presupuestos de timeout existentes.
  - Sonda empírica que monitorea el worker al agotarse el timeout base:
    1. Inspección de proceso: vivo (activo/consumiendo CPU), atascado (idle/esperando I/O) o muerto (proceso no existe o abortado).
    2. Ventana de extensión de gracia acotada a +30s / +60s post-timeout.
    3. Conclusión binaria: si el veredicto llega dentro de la ventana de gracia y es coherente → veredicto viable; si no llega nunca o el proceso está colgado → veredicto descartado.
  - Emisión de informe estructurado de liveness en `docs/sprints/sprint-27-liveness-trial-report.md`.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `agent-os-scripts`: Inspección de procesos y scripts de orquestación determinista.
- `testing-flows`: Recolección empírica de métricas de telemetría y ejecución controlada.

## Caja de archivos
- `docs/sprints/sprint-27-liveness-trial-report.md`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-151.md`

## Criterios de done
- [ ] Arnés/sonda de medición ejecutado sobre invocaciones reales o simuladas de deliberación.
- [ ] Telemetría registrada: estado del worker al timeout (vivo+avanzando, vivo+atascado, muerto) y tiempo de llegada de respuesta en ventana extendida (+30s / +60s).
- [ ] Informe formal documentado en `docs/sprints/sprint-27-liveness-trial-report.md` con veredicto explícito (`LIVENESS_VIABLE` o `LIVENESS_DESCARTADO`).
- [ ] Suite completa de control plane `tests/validate-control-plane.sh` pasando limpia sin regresiones (37/37), utilizada solo para instrumentación del trial sin mutar `deliberate-plan.sh` ni sus timeouts.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido
- [ ] Rama creada
- [ ] Cierre y merge autorizado por el relé
