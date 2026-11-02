# Executive Design Digest — T-155

## 🎯 Objetivo
Implementar los 3 tests unitarios y de integración pendientes en Check 34 de `tests/validate-control-plane.sh` para blindar la cascada y robustez del Revisor Dual (`agy` Tier 1 → `Orca ADE` Tier 2): salto instantáneo 0s ante binario de agy ausente, terminación forzosa con `SIGKILL` ante timeout real, y captura exitosa de veredicto en handoff hacia Orca, manteniendo el denominador de la suite estrictamente en 37/37.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico para T-155 cubre con precisión los tres casos de hueco identificados en T-154 para el Check 34: degradación instantánea ante binario no ejecutable o ausente, terminación forzosa con SIGKILL frente a procesos bloqueados que ignoran SIGTERM, y handoff limpio entre agy y Orca ADE. La caja de cambios está estrictamente acotada a los archivos requeridos, asegurando el determinismo de la suite en 37/37 sin efectos secundarios en el repositorio.
- **Prospección Scout**: `CONFORME (sprint-28-research.md)`
  - Alternativa detectada:** `jest-canvas-mock` (v2.5.8), `office-addin-mock` (v4.0.1), `jest-date-mock` (v1.0.10).
  - Recomendación del agente:** Desarrollo a medida justificado (scripts mock deterministas en Bash y aserciones en `tests/validate-control-plane.sh`).
  - Decisión del usuario:** Desarrollo a medida justificado — carry-over acordado en T-154 (Opción A de Gobernanza). Se trata de cubrir los 3 huecos de integración identificados en la suite de control plane para el Revisor Tier 1 (`agy`) y su cascada a Tier 2 (`Orca ADE`):
  - 1. *Binario ausente*: salto determinista inmediato (0s) hacia Orca cuando `agy` no está en PATH ni en ruta configurada (`evaluator_tier != agy`).
- **Mensaje de Cierre**: `feat(T-155): merge bateria de tests de hueco del revisor dual en check 34`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-155.md`
- `docs/sprints/sprint-28-core.md`
- `scripts/agent/deliberate-plan.sh`
- `scripts/agent/lib/portable-timeout.sh`
- `tests/validate-control-plane.sh`

## 🧠 Skills Declaradas y Aplicadas
- `agent-os-scripts`
- `testing-flows`
