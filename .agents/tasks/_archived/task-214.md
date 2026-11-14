# Task-214: Sincronización del Core de Agent OS en <nodo-inferencia> (v1.35.0 y 31 skills)

## Objetivo
Actualizar el repositorio `/home/ubuntu/projects/agent-os` en el nodo VPS `<nodo-inferencia>` desde la rama desactualizada de julio (`experiment/hermes-integration`) hasta la versión `v1.35.0`, y reconstruir los enlaces simbólicos de `~/.hermes/skills/agent-os/` para que Hermes herede las 31 skills completas del core con permisos de ejecución correctos.

## Contexto técnico
- En la auditoría de `<nodo-inferencia>`, se detectó que `/home/ubuntu/projects/agent-os` estaba congelado en julio de 2026 (commit `1d8bd23`), en la rama `experiment/hermes-integration`, con solo 16 skills vinculadas en `~/.hermes/skills/agent-os/`.
- Faltan 15 skills críticas del core moderno: `remote-admin`, `coolify-admin`, `orchestrator`, `infisical-secrets`, `web-compliance`, `goal-evaluation`, etc.
- No hay cambios sensibles que preservar en esa rama experimental antigua; se debe respaldar cualquier nota huérfana y sincronizar limpiamente con `origin/main` / tag `v1.35.0`.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 40 / 2026-11-14
- **Diseño y arquitectura aprobados por**: Humano (Romén)
- **Decisiones e interfaces selladas**:
  - Respaldo de archivos no rastreados en `<nodo-inferencia>` antes de sincronizar.
  - Checkout limpio de `v1.35.0` en `/home/ubuntu/projects/agent-os`.
  - Actualización atómica de `~/.hermes/skills/agent-os/` con symlinks hacia `.agents/skills/*` (31 skills).
  - Verificación de permisos de ejecución en `scripts/agent/*.sh`.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `docs/sprints/sprint-40.md`
- `scripts/agent/audit-satellites.sh` (si requiere ajuste de verificación remota)

## Criterios de done
- [x] `/home/ubuntu/projects/agent-os` en `<nodo-inferencia>` en versión `v1.35.0` (commit `8751e50`).
- [x] `~/.hermes/skills/agent-os/` contiene las 31 skills completas enlazadas y accesibles por Hermes.
- [x] Scripts en `scripts/agent/` con permisos `+x` y validados sin errores de sintaxis en `<nodo-inferencia>`.
- [x] Suite de pruebas de integridad remota en verde ($0 tokens).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `CONSENSO`
  - **Rol del revisor**: Compuerta técnica determinista (caja de archivos, tests, realidad repo, fidelidad a diseño macro).
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-11-14T09:17:53Z
- [x] Sesión cerrada correctamente
