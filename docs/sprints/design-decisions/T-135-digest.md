# Executive Design Digest — T-135

## 🎯 Objetivo
Evolucionar `scripts/agent/deliberate-plan.sh` para implementar una jerarquía de arbitraje de 3 niveles: (1) Revisor Ejecutor en Orca ADE como primera opción cuando el runtime esté accesible; (2) Cascada de inferencia HTTP resiliente como fallback (T-130); y (3) Fallback seguro a `SIN_REVISOR` ($0 tokens), garantizando que el bucle de desarrollo nunca quede bloqueado y preservando el presupuesto de tiempos.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `SIN_REVISOR` (Rondas: 1)
- **Síntesis de Diseño**: Revisor no disponible (timeout o conexión rehusada). Se activa fallback seguro a aprobación manual clásica.
- **Prospección Scout**: `CONFORME (sprint-23-research.md)`
  - Alternativas detectadas**:
  - `@csstools/postcss-cascade-layers` (v6.0.2, NPM) y `@csstools/cascade-layer-name-parser` (v3.0.2, NPM): Paquetes CSS homónimos espurios.
  - Recomendación del agente**: Construir. Enriquecer `scripts/agent/deliberate-plan.sh` para adoptar una arquitectura de 3 niveles: (1) Revisor ejecutor autónomo vía Orca ADE (si runtime está activo y alcanzable); (2) Cascada HTTP resiliente (`freellmapi` → `omniroute` → `ollama-local`) como fallback; (3) Fallback seguro a `SIN_REVISOR` ($0).
  - Decisión vigente**: Construcción interna. Se define y justifica el modelo de timeout con latencia peor caso de ~21s (<1s sonda Orca + hasta 15s ejecución worker Orca + 5s cascada HTTP), garantizando degradación limpia y sin bloqueo a `SIN_REVISOR`. Se formaliza la inclusión de `.agents/config/routing-policy.yaml` en la caja de archivos para parametrizar `orca_revisor`.
- **Mensaje de Cierre**: `merge: feat/T-135-deliberate-orca-refactor into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/config/routing-policy.yaml`
- `.agents/tasks/_archived/task-135.md`
- `.agents/tasks/task-135.md`
- `docs/sprints/sprint-23-core.md`
- `scripts/agent/deliberate-plan.sh`

## 🧠 Skills Declaradas y Aplicadas
- `agent-os-scripts`
- `orchestrator`
