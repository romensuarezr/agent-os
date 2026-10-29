# Executive Design Digest — T-133

## 🎯 Objetivo
Implementar una biblioteca compartida y universal `scripts/agent/lib/orca-client.sh` que centralice la detección determinista de Orca ADE, la resolución de su ejecutable sin ambigüedad (`orca-ide` por PATH, sin colisionar con el lector de pantalla `/usr/bin/orca` y sin rutas personales hardcodeadas como `<home-usuario>`), y abstraiga las operaciones fundamentales del ciclo de vida de workers (`status`, `worker-start`, `worker-read`, `worker-release`).

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `SIN_REVISOR` (Rondas: 1)
- **Síntesis de Diseño**: Revisor de inferencia no disponible (timeout 5s o conexión rehusada). Se activa fallback seguro a aprobación manual clásica.
- **Prospección Scout**: `CONFORME (sprint-23-research.md)`
  - Alternativas detectadas**:
  - `@orca-so/whirlpools-client` (v7.0.0, NPM): Cliente TypeScript para protocolos DeFi (resultado homónimo sin relación con el runtime ADE).
  - `@orca-so/whirlpools` (v8.0.1, NPM): SDK de alto nivel homónimo ajeno a la orquestación.
  - Recomendación del agente**: Construir. Desarrollar una biblioteca POSIX modular `scripts/agent/lib/orca-client.sh` que centralice la detección determinista del ejecutable `orca-ide` (priorizando `PATH`, descartando binarios conflictivos como `/usr/bin/orca` de GNOME y prohibiendo rutas hardcodeadas personales como `<home-usuario>`), unificando la lógica duplicada en `orca-orchestrate.sh` y `dispatch-satellite.sh`.
- **Mensaje de Cierre**: `merge: feat(orchestration) cliente unificado lib/orca-client.sh y resolucion portable (T-133)`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-133.md`
- `docs/sprints/sprint-23-core.md`
- `scripts/agent/dispatch-satellite.sh`
- `scripts/agent/lib/orca-client.sh`
- `scripts/agent/orca-orchestrate.sh`

## 🧠 Skills Declaradas y Aplicadas
- `agent-os-scripts`
- `orchestrator`
