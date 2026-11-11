# Executive Design Digest — T-130

## 🎯 Objetivo
Implementar un mecanismo de enrutamiento escalonado (cascada de inferencia) en `.agents/config/routing-policy.yaml` y `scripts/agent/deliberate-plan.sh`, permitiendo que el motor de arbitraje pruebe de forma determinista una lista ordenada de endpoints o tiers de inferencia antes de degradar al veredicto offline `SIN_REVISOR`.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `SIN_REVISOR` (Rondas: 1)
- **Síntesis de Diseño**: Revisor de inferencia no disponible (timeout 5s o conexión rehusada). Se activa fallback seguro a aprobación manual clásica.
- **Prospección Scout**: `CONFORME (sprint-22-research.md)`
  - Alternativas detectadas**:
  - `crzyc0d3r/llm-router-ranking-engine` (0⭐, No lic, GitHub): Enrutador de inferencia con resolución de intenciones y ranking de latencia/coste (`https://github.com/crzyc0d3r/llm-router-ranking-engine`).
  - `@kortix/llm-catalog` (v0.14.8, NPM): Catálogo de modelos y pasarelas Kortix (`https://www.npmjs.com/package/@kortix/llm-catalog`).
  - `@oh-my-pi/pi-catalog` (v18.13.3, NPM): Base de datos de modelos y descriptores de proveedores (`https://www.npmjs.com/package/@oh-my-pi/pi-catalog`).
- **Mensaje de Cierre**: `merge: feat/T-130-inference-fallback-cascade (cascada de inferencia y fallback resiliente)`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/config/routing-policy.yaml`
- `.agents/tasks/_archived/task-130.md`
- `docs/sprints/sprint-22-core.md`
- `scripts/agent/deliberate-plan.sh`

## 🧠 Skills Declaradas y Aplicadas
- `agent-os-scripts`
- `orchestrator`
