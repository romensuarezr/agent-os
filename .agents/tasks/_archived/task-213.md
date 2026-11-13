# Task-213: Ensayo E2E y despliegue real en satélite annascheer-web (Sprint 04 Piloto)

## Objetivo
Sincronizar las nuevas habilidades y herramientas de Sprint 39 (`web-compliance`, `audit-web-compliance.sh`, directivas de latido y verificación ágil) al satélite real `annascheer-web` mediante `sync.sh --force --cleanup --commit`. Ejecutar una auditoría con `audit-web-compliance.sh` para diagnosticar la necesidad de cookies/legal derivada de la integración previa de Calendly (T-013), e implementar el piloto de `vanilla-cookieconsent` y páginas legales para validar en producción satélite la eficacia de la nueva skill.

## Contexto técnico
- Tras la finalización del Sprint 03 en `annascheer-web` (Homepage, Calendly, Schema.org), la web requiere urgentemente el banner de cookies y las páginas legales para no incurrir en infracción legal en producción.
- La validación sobre un satélite real garantiza que las plantillas y el script de auditoría funcionan sin fricción en Next.js 15.

### Research integrado (`docs/sprints/sprint-39-research.md` → `### T-213`)
- **Scout OSS**: N/A (validación empírica en satélite real de la flota).
- **Veredicto**: `Aprovechar utilidades del core` para el despliegue y auditoría.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 39 / 2026-11-13
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - Propagar activos a `annascheer-web` vía `sync.sh --force --cleanup --commit`.
  - Auditar la web con `audit-web-compliance.sh` comprobando que detecta la necesidad de CMP por Calendly.
  - Implementar el banner `vanilla-cookieconsent` v3 y las páginas `/aviso-legal`, `/politica-privacidad`, `/politica-cookies`.
  - Re-auditar con `audit-web-compliance.sh` confirmando estado VERDE / LIMPIO.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/audit-web-compliance.sh`
- `docs/sprints/sprint-39.md`
- `.agents/tasks/task-213.md`
- Referencia externa: `<satelites>/annascheer-web` (vía `sync.sh` e implementación de piloto)

## Criterios de done
- [x] Activos sincronizados al satélite `annascheer-web` con `audit-satellites.sh` limpio.
- [x] Diagnóstico inicial con `audit-web-compliance.sh` ejecutado.
- [x] Banner de cookies y páginas legales operativas en el satélite.
- [x] Auditoría final en satélite reporta cumplimiento conforme.
- [x] Suite `tests/validate-control-plane.sh` pasando limpia sin regresiones (38/38 checks verdes).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
- [x] Plan presentado al usuario (Fase 3.5)
- [x] Rama de trabajo creada
- [x] Verificación con verify-goal.sh
- [x] Cierre y merge formalizado
