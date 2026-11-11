# Executive Design Digest — T-138

## 🎯 Objetivo
Corregir los comandos obsoletos e inexactos introducidos en la documentación inicial de orquestación de Orca (`docs/runbooks/orca-multiagent-orchestration.md` y `docs/architecture/tools/llm-routing-selection.md`), alineándolos con la máquina de estados real y los comandos canónicos certificados en host (`orca orchestration worker-start`, `worker-stop`, `worker-release`, aislamiento `env -i`).

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan T-138 define adecuadamente la actualización
de los runbooks y guías de arquitectura para alinear la documentación viva
con la CLI real de Orca (ciclo de vida worker-start/stop/release, sonda
orca status --json y aislamiento env -i). La decisión de diferir el
archivado scout a backlog future mantiene el acotamiento S sin introducir
riesgos ni requerir modificaciones de código core.
- **Prospección Scout**: `CONFORME (sprint-24-research.md)`
  - Alternativas detectadas**:
  - `@ricsam/r5d-worker` (NPM): Ejecutor host duradero y gestor de adaptadores supervisados independientes.
  - `@deepseek-ai/dsh-tool-ralph` (v0.0.1-rc.1, NPM): Bucle Ralph Loop agéntico sobre interfaces de workflow y costuras de subagentes.
  - Show HN: Pizza Bot – An inbox for AI agents that work in the background* (Hacker News #49713894): Patrón de buzón asíncrono para agentes en background.
- **Mensaje de Cierre**: `merge: feat/T-138-orca-lifecycle-scout-doc into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-138.md`
- `.agents/tasks/task-138.md`
- `docs/architecture/tools/llm-routing-selection.md`
- `docs/runbooks/orca-multiagent-orchestration.md`
- `docs/sprints/sprint-24-core.md`

## 🧠 Skills Declaradas y Aplicadas
- `doc-maintainer`
- `orchestrator`
