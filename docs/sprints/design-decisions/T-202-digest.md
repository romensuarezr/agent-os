# Executive Design Digest — T-202

## 🎯 Objetivo
Formalizar el catálogo declarativo de estrategias de orquestación en `.agents/config/orchestration-playbooks.yaml` e implementar la regla de umbral determinista de $\le 3$ archivos en el flujo de trabajo (`session-start.md` y `orchestrator`), evitando el sobrecoste (*overhead*) de tokens y tiempo que supone coordinar subagentes o worktrees para tareas mecánicas o acotadas.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan de trabajo para T-202 aborda de manera precisa la formalización declarativa de las 5 estrategias de orquestación canónicas y la regla dura de umbral (<= 3 archivos en la caja de cambios -> forzar modo `direct`). La delimitación de archivos es estrictamente acotada, contempla el registro preventivo en `assets-manifest.txt` y asegura la preservación del floor cost de tokens sin introducir acoplamiento innecesario ni mutaciones fuera del ámbito acordado.
- **Prospección Scout**: `CONFORME (sprint-37-research.md)`
  - Keywords**: `orchestration playbooks multi agent`
  - Alternativas OSS evaluadas**:
  - `jjanczur/tyran` (79⭐, Apache-2.0): Gestor de tareas para Claude Code, pero acoplado a un único CLI.
  - `sammyjason39/agent-build-playbook` (11⭐): Playbooks estáticos en Markdown.
- **Mensaje de Cierre**: `Merge branch 'feat/T-201-satellite-agents-md-boot' into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/config/orchestration-playbooks.yaml`
- `.agents/rules/global/coordinator-boot.md`
- `.agents/skills/orchestrator/SKILL.md`
- `.agents/tasks/_archived/task-201.md`
- `.agents/tasks/_archived/task-202.md`
- `.agents/workflows/session-start.md`
- `docs/sprints/design-decisions/T-201-digest.md`
- `docs/sprints/design-decisions/T-201-raw.json`
- `docs/sprints/sprint-37.md`
- `scripts/agent/assets-manifest.txt`
- `scripts/agent/install.sh`
- `scripts/agent/sync.sh`
- `templates/root/AGENTS.md`

## 🧠 Skills Declaradas y Aplicadas
- Ninguna skill adicional registrada.
