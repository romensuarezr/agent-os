# Task-183: Estandarización de variables, endpoints y pre-flights en coolify.sh y coolify-admin

## Objetivo
Estandarizar el script `scripts/ops/coolify.sh` y la skill `.agents/skills/coolify-admin/SKILL.md` para integrar la ayuda estándar determinista (`scripts/agent/lib/cli-help.sh`), eliminar literales de ejemplo hardcodeados (`coolify.example.com`), y habilitar la resolución de endpoints desde `.agents/config/fleet.yaml` con precedencia estricta sobre variables de entorno (`COOLIFY_BASE_URL` e Infisical).

## Contexto técnico
El script actual `scripts/ops/coolify.sh` contiene un fallback rígido `https://coolify.example.com/api/v1` y no implementa la ayuda estándar con `lib/cli-help.sh`. Con la estandarización de Fleet y la frontera portable, el script debe resolver dinámicamente el host de Coolify desde `fleet.yaml` (nodo PaaS) si no está definido en variables de entorno, verificando dependencias deterministas (`curl`, `jq`) con pre-flight limpio.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 33 / 2026-11-10
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Incorporar `scripts/agent/lib/cli-help.sh` para soporte de `-h` y `--help`.
  - Sustituir fallback estático por resolución dinámica: `$COOLIFY_BASE_URL` -> bloque PaaS en `.agents/config/fleet.yaml` -> error determinista si no está configurado (sin URLs hardcodeadas).
  - Preservar inyección efímera de tokens (Infisical / `$COOLIFY_TOKEN`).
  - Actualizar `.agents/skills/coolify-admin/SKILL.md` documentando la resolución de endpoints.
  - El denominador de la suite permanece rígidamente inmutable en 38/38 (0 errores).
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/ops/coolify.sh`
- `.agents/skills/coolify-admin/SKILL.md`
- `.agents/tasks/task-183.md`

## Criterios de done
- [x] `scripts/ops/coolify.sh` expone ayuda determinista mediante `lib/cli-help.sh`.
- [x] Eliminado el fallback hardcodeado `coolify.example.com`.
- [x] Resolución de endpoint vía variable de entorno o `fleet.yaml`.
- [x] `.agents/skills/coolify-admin/SKILL.md` sincronizado.
- [x] `locator-hygiene.sh` 100% limpio.
- [x] Suite de validación `tests/validate-control-plane.sh` 38/38 en verde.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `CONSENSO`
  - **Rol del revisor**: Compuerta técnica determinista (qa-judge).
- [x] Plan presentado al usuario (Fase 3.5 — Opción D sellada en planning)
- [x] APROBADO recibido — fecha/hora: 2026-11-10 21:19 UTC (camino limpio Opción D)
- [x] Rama creada: feat/T-183-estandarizacion-coolify-ops-fleet
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
