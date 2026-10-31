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

## Skills relevantes
- `agent-os-scripts`: Mantenimiento y estándares de calidad de scripts del core.
- `testing-flows`: Diseño de aserciones de regresión no destructivas en el control plane.

## Caja de archivos
- `scripts/agent/audit-repo.sh`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-148.md`

## Criterios de done
- [ ] Literal en `scripts/agent/audit-repo.sh` actualizado a `- [ ] Actualizar changelog.md con los hitos históricos identificados en el Sprint 00`.
- [ ] Verificado que el bloque de migración de nombres de archivo en `audit-repo.sh` (líneas 195-201) permanece funcional e idéntico en su detección.
- [ ] Test de regresión incorporado o extendido en `tests/validate-control-plane.sh` validando que la propuesta emitida usa `changelog.md` y no `CHANGELOG.md`.
- [ ] Plan legible previo en `.agents/context/plan-draft.md` deliberado formalmente mediante `deliberate-plan.sh` (timeout default 60s).
- [ ] Suite completa de control plane `tests/validate-control-plane.sh` ejecutada y pasando 100% limpia sin regresiones.
