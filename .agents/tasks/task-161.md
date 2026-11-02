# Task-161: Diagnóstico de flota (`fleet-doctor`), compuerta técnica, runbook y suite (38/38)

## Objetivo
Consolidar el ciclo completo de integración de Bane incorporando la sonda de diagnóstico en `scripts/agent/fleet-doctor.sh` (modo warn-only), documentando la guía operativa paso a paso en `docs/runbooks/bane-deep-research-service.md`, implementando el nuevo **Check 38** en la suite de validación `tests/validate-control-plane.sh` y actualizando de forma explícita el denominador formal de la suite de **37/37 a 38/38**, cerrando el mini-sprint de Bane y consolidando las métricas de intervención del piloto Opción D.

## Contexto técnico
Toda nueva capacidad o herramienta introducida en el Tooling Hub de la flota requiere tres pilares obligatorios de control plane:
1. **Diagnóstico Determinista en Flota**: `fleet-doctor.sh` debe incorporar una sonda config-driven para `bane`: si está declarado en `fleet.yaml`, intenta contactar el endpoint con timeout estricto. Si responde, emite `OK`; si no responde o está degradado, emite `WARN` y sale con exit code 0 (modo advertencia, nunca rompe el pipeline de inspección de flota).
2. **Runbook Operativo**: Un documento en `docs/runbooks/bane-deep-research-service.md` que detalle la arquitectura, requisitos de hardware, procedimiento de despliegue en Coolify / Docker Compose, configuración con FreeLLMAPI y SearXNG, y guía de troubleshooting.
3. **Certificación en Suite de Control Plane (Check 38)**: `tests/validate-control-plane.sh` añade el Check 38 validando la sintaxis de `templates/bane/docker-compose.yml`, el comportamiento fail-soft de `bane-client.sh`, la ausencia de literales de infraestructura personal y la correcta respuesta de `fleet-doctor.sh`.
4. **Denominador Explícito Declarado**: El número total de comprobaciones de la suite pasa oficialmente de **37/37 a 38/38**, actualizando las variables y mensajes del arnés de pruebas.

Esta tarea es la última del mini-sprint y del Sprint 28, y consolida las métricas finales del piloto Opción D en `docs/sprints/sprint-28-autonomy-pilot-report.md`.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 28 / 2026-11-02
- **Diseño y arquitectura aprobados por**: Humano / Relé (Sprint Planning Sprint 28 - Enmienda Bane)
- **Decisiones e interfaces selladas**:
  - Incorporar sonda de Bane en `scripts/agent/fleet-doctor.sh` bajo la sección `services` en modo `warn-only` (exit code 0).
  - Redactar `docs/runbooks/bane-deep-research-service.md` respetando la frontera portable (sin IPs privadas ni credenciales reales).
  - Añadir Check 38 en `tests/validate-control-plane.sh`:
    - Valida que `templates/bane/docker-compose.yml` existe y no tiene variables rotas.
    - Valida que `bane-client.sh` responde a `--help`, emite por stdout y degrada a inactivo sin credenciales.
    - Valida que `fleet-doctor.sh` incluye la sonda en el digest JSON.
  - **Actualizar explícitamente el denominador de la suite a 38/38** (actualizando cabeceras `[38/38]`, variables de conteo y mensajes de éxito).
  - Consolidar las métricas de intervenciones del usuario del piloto Opción D en `docs/sprints/sprint-28-autonomy-pilot-report.md` (reportando reducción lograda frente a baseline ~3/tarea y 0 fallos de seguridad).
  - Suite de control plane pasando limpia en **38/38** (0 errores).
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `agent-os-scripts`: Mantenimiento de suite de validación y fleet doctor.
- `testing-flows`: Extensión de la suite de control plane y gestión del denominador.
- `doc-maintainer`: Redacción y verificación de runbooks técnicos.

## Caja de archivos
- `scripts/agent/fleet-doctor.sh`
- `docs/runbooks/bane-deep-research-service.md`
- `docs/sprints/sprint-28-autonomy-pilot-report.md`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-161.md`

## Criterios de done
- [ ] Sonda de Bane integrada en `scripts/agent/fleet-doctor.sh` operando en modo warn-only.
- [ ] Runbook `docs/runbooks/bane-deep-research-service.md` redactado y libre de literales privados.
- [ ] Check 38 implementado en `tests/validate-control-plane.sh`.
- [ ] Denominador formal de la suite actualizado a 38/38 en todos los checks y mensajes.
- [ ] Suite de pruebas pasando limpia al 100% (38/38) sin errores ni regresiones.
- [ ] Métricas finales del piloto Opción D consolidadas en `docs/sprints/sprint-28-autonomy-pilot-report.md`.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido
- [ ] Rama creada
- [ ] Cierre y merge autorizado por el relé
