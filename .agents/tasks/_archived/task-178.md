# Task-178: Purga definitiva de residuos Bane (fleet.example.yaml, searxng-client.sh, Check 34 §18)

## Objetivo
Erradicar por completo los residuos de configuración y código del motor fantasma Bane que permanecen en el repositorio, concretamente el bloque de servicio `bane:` en `.agents/config/fleet.example.yaml` y las referencias de fallback `BANE_API_URL` y `svcs['bane']` en `scripts/agent/lib/searxng-client.sh`, blindando su ausencia definitiva en el Check 34 (§18) de `tests/validate-control-plane.sh`.

## Contexto técnico
En T-175 se llevó a cabo el saneamiento primario de Bane (purga de plantillas, cliente y runbooks; migración a SearXNG como motor activo). Sin embargo, se identificaron residuos residuales en `fleet.example.yaml` y en el cliente `searxng-client.sh` que todavía mantenían fallbacks hacia Bane. En el planning de Sprint 32 se acordó purgar estos remanentes y blindar su control estático en la suite de control plane en el Check 34 (§18).

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 32 / 2026-11-10
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Purgar el bloque de servicio `bane:` en `.agents/config/fleet.example.yaml`.
  - Purgar el fallback de entorno `BANE_API_URL` y el bloque condicional `if 'bane' in svcs:` en `scripts/agent/lib/searxng-client.sh`.
  - Extender la sección §18 del Check 34 en `tests/validate-control-plane.sh` para verificar de forma determinista que ni `fleet.example.yaml` ni `searxng-client.sh` contienen referencias a `bane`.
  - El denominador de la suite permanece rígidamente inmutable en 38/38 (0 errores).
  - No romper ninguna funcionalidad existente de búsqueda vía SearXNG.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/config/fleet.example.yaml`
- `scripts/agent/lib/searxng-client.sh`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-178.md`

## Criterios de done
- [x] Bloque `bane:` purgado de `.agents/config/fleet.example.yaml`.
- [x] Fallbacks `BANE_API_URL` y `svcs['bane']` eliminados de `scripts/agent/lib/searxng-client.sh`.
- [x] Check 34 (§18) de `tests/validate-control-plane.sh` extiende la verificación cubriendo `fleet.example.yaml` y `searxng-client.sh`.
- [x] Suite de validación `tests/validate-control-plane.sh` 38/38 en verde sin regresiones.
- [x] `locator-hygiene.sh` 100% limpio.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `CONSENSO`
  - **Rol del revisor**: Compuerta técnica determinista (caja de archivos, tests, realidad repo, fidelidad a diseño macro).
- [x] Plan presentado al usuario (Fase 3.5 — Opción D sellada en planning)
- [x] APROBADO recibido — fecha/hora: 2026-11-10 18:56 UTC (camino limpio Opción D)
- [x] Rama creada: feat/T-178-purga-residuos-bane-fleet-searxng
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
