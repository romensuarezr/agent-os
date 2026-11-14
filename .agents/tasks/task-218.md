# Task-218: Validación E2E del Conserje y Ensayo de Flota

## Objetivo
Realizar la prueba de extremo a extremo (E2E) del flujo completo del Conserje Hermes en el VPS: recepción de orden por WhatsApp -> invocación de Antigravity en worktree efímero en el VPS -> consulta interactiva/compuerta retransmitida a WhatsApp -> respuesta inyectada -> finalización con `verify-goal.sh` -> reporte final en WhatsApp.

## Contexto técnico
- Esta tarea consolida el trabajo de T-214 a T-217.
- Debe probar que un mensaje enviado desde el móvil o simulado a través del gateway de WhatsApp de Hermes activa a Antigravity en `<nodo-inferencia>`, trabaja sobre un repositorio satélite o de prueba respetando las reglas de Agent OS, y cierra el ciclo de comunicación sin requerir que el operador toque una terminal.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 40 / 2026-11-14
- **Diseño y arquitectura aprobados por**: Humano (Romén)
- **Decisiones e interfaces selladas**:
  - Ensayo real no destructivo a través del gateway de WhatsApp de Hermes.
  - Verificación del ciclo completo de ida y vuelta de mensajes (prompt, compuerta, resultado).
  - Comprobación de que no quedan worktrees huérfanos ni procesos colgados en el VPS.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `docs/sprints/sprint-40.md`
- `changelog.md`
- `roadmap.md`

## Criterios de done
- [ ] Ejecución E2E del flujo Conserje superada con éxito.
- [ ] Mensaje de reporte final recibido en WhatsApp con formato sintético y claro.
- [ ] Control plane validado en su totalidad (`tests/validate-control-plane.sh` en verde).
- [ ] Documentación, changelog y roadmap actualizados.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `[CONSENSO | REVISADO_CON_CAMBIOS | ESCALADO_A_HUMANO | SIN_REVISOR]`
  - **Rol del revisor**: Compuerta técnica determinista (caja de archivos, tests, realidad repo, fidelidad a diseño macro).
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
