# Task-186: Cobertura de control plane y hardening determinista de rotate-freellmapi-token.sh

## Objetivo
Incorporar cobertura determinista completa de pruebas en `tests/validate-control-plane.sh` para `scripts/agent/lib/rotate-freellmapi-token.sh`, asegurando además que el script utilice `scripts/agent/lib/cli-help.sh` y mantenga invariantes sus salvaguardas de seguridad (cero exposición de credenciales, modos secos y pre-flights).

## Contexto técnico
En T-182 se creó `scripts/agent/lib/rotate-freellmapi-token.sh` como solución a la remediación de tokens de FreeLLMAPI en Hermes y OpenCode. Si bien fue probado en producción y validado con liveness real, la suite del control plane actualmente no verifica su integridad, permisos ni comportamiento ante flags estándar.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 33 / 2026-11-10
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Refactorizar la función de ayuda en `scripts/agent/lib/rotate-freellmapi-token.sh` con `lib/cli-help.sh`.
  - Integrar comprobación estática en `tests/validate-control-plane.sh` (ej. en Check 9 o Check 13): sintaxis bash, permisos 0755, flags `-h/--help`, y rechazo seguro sin target/conectividad.
  - Denominador de la suite rígidamente inmutable en 38/38 (0 errores).
  - Cero eco de secretos o tokens en pantalla ni logs.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/lib/rotate-freellmapi-token.sh`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-186.md`

## Criterios de done
- [ ] `rotate-freellmapi-token.sh` migrado a `lib/cli-help.sh`.
- [ ] Test determinista añadido en `tests/validate-control-plane.sh`.
- [ ] Suite `tests/validate-control-plane.sh` 38/38 verde.
- [ ] `locator-hygiene.sh` 100% limpio.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
- [ ] Plan presentado al usuario
- [ ] APROBADO recibido
- [ ] Rama creada
- [ ] Lock activo: .agent-session.lock
- [ ] Sesión cerrada correctamente
