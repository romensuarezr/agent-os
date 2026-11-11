# Task-193: Actualización asistida de Agent OS en proyectos satélite

## Objetivo
Transformar el mecanismo de actualización y sincronización de Agent OS en proyectos satélite (hijos), eliminando el bloqueo del timeout interactivo de 10s en `check-session.sh` y la directiva pasiva en `sprint-planning.md`. El sistema debe pre-visualizar cambios con `sync.sh --dry-run`, extraer automáticamente las novedades de `changelog.md` frente a la versión local y generar un Plan de Impacto estructurado que se someta a aprobación en la ventana de decisión macro.

## Contexto técnico
- En proyectos satélite, `check-session.sh` hace un prompt interactivo bash con timeout de 10s (`read -t 10 response`). Si corre un agente LLM no interactivo, el timeout salta a `skip` y la actualización se pospone indefinidamente.
- En `sprint-planning.md` Paso 1b solo se sugiere pasivamente `sync.sh .` sin explicar qué cambia, qué nuevas skills se incorporan ni cómo impactará en el flujo del usuario.
- Se requiere que el agente en el satélite actúe como un consultor proactivo de plataforma, analizando las novedades del core y proponiendo su adopción de forma asistida.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 35 / 2026-11-11
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - `check-session.sh` en modo no interactivo o invocado por agentes no se bloquea en timeout: emite estado JSON/texto limpio `CORE_UPDATE_AVAILABLE: vX.Y.Z`.
  - Paso 1b de `sprint-planning.md` en satélites ejecuta `sync.sh --dry-run` para auditar diferencias exactas de assets sin escribir en disco.
  - El agente sintetiza un Plan de Impacto estructurado con 3 secciones: Novedades de la versión, Activos vivos modificados y Cambios en el flujo de trabajo.
  - La sincronización se integra formalmente en la ventana de decisión del Paso 7 de forma opcional y explícita.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/sync.sh`
- `scripts/agent/check-session.sh`
- `.agents/workflows/sprint-planning.md`
- `.agents/workflows/session-start.md`
- `docs/sprints/sprint-35.md`

## Criterios de done
- [x] `check-session.sh` reporta disponibilidad de nueva versión de forma determinista y sin bloqueos de timeout no interactivos.
- [x] `sync.sh --dry-run` emite un digest estructurado de archivos nuevos, modificados y deprecados.
- [x] Paso 1b en `sprint-planning.md` documenta la generación del Plan de Impacto a partir de `changelog.md`.
- [x] Ventana de decisión del planning en satélites incluye la compuerta de sincronización opcional.
- [x] Suite `tests/validate-control-plane.sh` pasa 38/38 checks verdes.

## Estado de aprobación y deliberación
- [x] Deliberación técnica completada (`deliberate-plan.sh`)
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido en planning
- [x] Rama de trabajo activa
- [x] Lock activo: —
- [x] Tarea cerrada y verificada
