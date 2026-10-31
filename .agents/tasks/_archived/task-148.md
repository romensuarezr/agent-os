# Task-148: Corrección de literal CHANGELOG.md a changelog.md en propuesta de audit-repo.sh y test de regresión

## Objetivo
Corregir la propuesta generada en `scripts/agent/audit-repo.sh:664` para que utilice `changelog.md` en minúsculas en lugar de `CHANGELOG.md`, alineándola con la convención estándar del core y la lógica de migración del propio script (líneas 195-201). Incorporar además un test de regresión en `tests/validate-control-plane.sh` que verifique deterministamente que las propuestas generadas por `audit-repo.sh` usan la convención `changelog.md`.

## Contexto técnico
Al auditar repositorios existentes, `audit-repo.sh` detecta si existen archivos en mayúsculas (`CHANGELOG.md`, `ROADMAP.md`) y propone o aplica su renombrado a minúsculas (`changelog.md`, `roadmap.md`).
Sin embargo, en la línea 664, al sugerir la consolidación del historial git en un sprint histórico inicial, emitía:
`- [ ] Actualizar CHANGELOG.md con los hitos históricos identificados en el Sprint 00`
Esto generaba un literal engañoso e inconsistente con el resto del core y con las reglas de detección del propio script.
La corrección requiere:
1. Ajustar el literal en `scripts/agent/audit-repo.sh` a minúsculas (`changelog.md`).
2. Añadir aserción de regresión en `tests/validate-control-plane.sh` comprobando que `audit-repo.sh` genera `changelog.md` en sus propuestas.

## Diseño macro aprobado en planning
> Registro vinculante de diseño acordado entre el humano y el agente durante el sprint planning del Sprint 26 (triaje de inboxes del Paso 3).

- **Sprint / Fecha**: Sprint 26 / 2026-10-31
- **Diseño y arquitectura aprobados por**: Relé humano (Aprobación con cambios de Fase 3.5)
- **Decisiones e interfaces selladas**:
  - Fix literal in-place en `scripts/agent/audit-repo.sh:664`: propuesta pasa de `CHANGELOG.md` a `changelog.md`.
  - Preservar byte-idéntico el bloque de migración de nombres de archivo en `audit-repo.sh` (líneas 195-201).
  - Desarrollo a medida justificado sin dependencias externas (sin linters ni herramientas de terceros).
  - Test de regresión acotado a la propuesta de la línea 664 (Sprint 00) dentro de un check existente de `tests/validate-control-plane.sh` manteniendo el denominador 37/37.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `agent-os-scripts`: Mantenimiento y estándares de calidad de scripts del core.
- `testing-flows`: Diseño de aserciones de regresión no destructivas en el control plane.

## Caja de archivos
- `scripts/agent/audit-repo.sh`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-148.md`

## Criterios de done
- [x] Literal en `scripts/agent/audit-repo.sh` actualizado a `- [ ] Actualizar changelog.md con los hitos históricos identificados en el Sprint 00`.
- [x] Verificado que el bloque de migración de nombres de archivo en `audit-repo.sh` (líneas 195-201) permanece funcional e idéntico en su detección.
- [x] Test de regresión incorporado o extendido en `tests/validate-control-plane.sh` validando que la propuesta emitida usa `changelog.md` y no `CHANGELOG.md`.
- [x] Plan previo legible presentado en `.agents/context/plan-draft.md` deliberado formalmente mediante `deliberate-plan.sh` (timeout default 60s).
- [x] Suite completa de control plane `tests/validate-control-plane.sh` ejecutada y pasando 100% limpia sin regresiones (37/37).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `SIN_REVISOR` (degradación segura por timeout en pasarela).
  - **Rol del revisor**: Compuerta técnica determinista (caja de archivos, tests, realidad repo, fidelidad a diseño macro).
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO CON CAMBIOS recibido — fecha/hora: 2026-10-31 14:33 UTC
- [x] Rama creada: `feat/T-148-audit-repo-changelog-lowercase`
- [x] Cierre y merge autorizado por el relé
