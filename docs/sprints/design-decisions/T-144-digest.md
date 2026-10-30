# Executive Design Digest — T-144

## 🎯 Objetivo
Implementar mecanismos deterministas de recolección de procesos (process reaper) y limpieza garantizada de terminales en el host mediante traps de señales del sistema operativo (`EXIT`, `INT`, `TERM`, `HUP`), asegurando que tras cualquier ejecución concurrente (exitosa o interrumpida) el censo emitido por `orca orchestration worker-list` reporte exactamente 0 terminales huérfanas.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `SIN_REVISOR` (Rondas: 1)
- **Síntesis de Diseño**: Revisor no disponible (timeout o conexión rehusada). Se activa fallback seguro a aprobación manual clásica.
- **Prospección Scout**: `CONFORME (sprint-25-research.md)`
  - Alternativas detectadas**:
  - `node-cleanup` (v2.1.2, NPM): Instalador de handlers de limpieza en salida.
  - `focus-trap` (v8.2.4, NPM): Enfoque de UI (no aplicable a backend/CLI).
  - Recomendación del agente**: **Desarrollo a medida justificado**.
- **Mensaje de Cierre**: `merge: feat/T-144-terminal-stability-worker-census (T-144)`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-144.md`
- `docs/sprints/sprint-25-core.md`
- `scripts/agent/deliberate-plan.sh`
- `scripts/agent/lib/terminal-reaper.sh`

## 🧠 Skills Declaradas y Aplicadas
- `orchestrator`
- `agent-os-scripts`
