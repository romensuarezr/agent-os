# Task-175: Saneamiento integral del fantasma Bane: purga de residuos, migración a SearXNG y adaptación del control plane

## Objetivo
Desmantelar y purgar de forma integral todos los residuos del motor fantasma Bane en el repositorio (wrapper obsoleto, plantillas Docker y runbook), migrar workflows y sondas de flota hacia el cliente soberano existente `searxng-client.sh` y adaptar las validaciones de los Checks 34 y 38 en `tests/validate-control-plane.sh` preservando rígidamente el denominador en **38/38** (0 errores), sin duplicar código de búsqueda ya implementado.

## Contexto técnico
En T-169 se consolidó la integración del motor soberano de búsqueda profunda reactivando la instancia de SearXNG e implementando el cliente determinista `scripts/agent/lib/searxng-client.sh` (283 líneas). Sin embargo, persistieron artefactos deprecados de Bane (`bane-client.sh`, `templates/bane/`, runbook de Bane) y comprobaciones en `sprint-planning.md`, `fleet-doctor.sh` y `validate-control-plane.sh` que seguían requiriendo o invocando el binario deprecado.
Esta tarea limpia definitivamente la deuda técnica erradicando el motor fantasma y unificando el stack sobre SearXNG.
Esta tarea fue formalmente **APROBADA por el usuario** con su alcance verificado y se ejecuta bajo el régimen estándar de **Opción D**.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 31 / 2026-11-08
- **Diseño y arquitectura aprobados por**: Humano / Relé (Aprobación Formal con Alcance Verificado)
- **Decisiones e interfaces selladas**:
  - **Cero duplicación de `searxng-client.sh`**: Reconocimiento expreso de que el cliente soberano de SearXNG ya existe, está probado y operativo; queda prohibido recrearlo o duplicarlo.
  - **Purga física de artefactos de Bane**:
    - Borrado de `scripts/agent/lib/bane-client.sh`.
    - Borrado de `templates/bane/` (`docker-compose.yml`, `.env.example`).
    - Borrado de `docs/runbooks/bane-deep-research-service.md`.
  - **Saneamiento de workflows y sondas**:
    - En `.agents/workflows/sprint-planning.md`: sustituir la comprobación de `bane-client.sh --check` por `searxng-client.sh --check`.
    - En `.agents/workflows/deep-research.md`: purgar referencias al wrapper compatible de Bane, dejando exclusivamente SearXNG.
    - En `scripts/agent/fleet-doctor.sh`: migrar sonda de Bane hacia SearXNG (`searxng_probe`).
  - **Adaptación en `tests/validate-control-plane.sh`**:
    - Check 34: Desmantelar la validación que exigía templates de Bane y `bane-client.sh`, auditando en su lugar que el stack y workflows apunten a SearXNG sin cadenas fantasma.
    - Check 38: Sustituir la sub-verificación de Bane por la validación de la suite soberana SearXNG (`templates/searxng/`, `searxng-client.sh`, runbook de SearXNG y Nango).
    - **Denominador inmutable**: Rígidamente **38/38** (0 errores).
- **Veredicto de diseño macro**: `APROBADO_EN_PLANNING`

## Skills relevantes
- `agent-os-scripts`: Manipulación y validación de utilidades del core.
- `tool-inventory`: Actualización del inventario de servicios de búsqueda profunda.

## Caja de archivos
Archivos autorizados para modificación / eliminación:
- `scripts/agent/lib/bane-client.sh` (eliminación)
- `templates/bane/` (eliminación)
- `docs/runbooks/bane-deep-research-service.md` (eliminación)
- `.agents/workflows/sprint-planning.md`
- `.agents/workflows/deep-research.md`
- `scripts/agent/fleet-doctor.sh`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-175.md`

## Criterios de done
- [x] Artefactos de Bane (`bane-client.sh`, `templates/bane/`, `docs/runbooks/bane-deep-research-service.md`) eliminados del árbol de git.
- [x] Workflows `sprint-planning.md` y `deep-research.md` migrados para usar exclusivamente `searxng-client.sh`.
- [x] `fleet-doctor.sh` saneado con sonda de búsqueda profunda unificada sobre SearXNG.
- [x] Checks 34 y 38 de `tests/validate-control-plane.sh` adaptados a SearXNG sin rastro de dependencias de Bane.
- [x] Suite de control plane pasando limpia con denominador inmutable en **38/38** (0 errores).
- [x] Ejecutada y registrada bajo las reglas de Opción D.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `CONSENSO`
  - **Rol del revisor**: qa-judge (Antigravity CLI Tier 1, $0 inferencia, 0 objeciones)
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-11-10T13:34:52Z (Piloto Camino B Aprobado por Humano en Planning)
- [x] Rama creada: `feat/T-175-purge-bane-searxng-migration`
- [x] Lock activo: `.agent-session.lock`
- [ ] Sesión cerrada correctamente
