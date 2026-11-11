# Executive Design Digest — T-128

## 🎯 Objetivo
Implementar en `scripts/agent/worktree-merge.sh` el mecanismo de rescate determinista que copie el artefacto de deliberación `.agents/context/deliberation-${TASK_ID}.json` desde el worktree efímero hacia el checkout principal antes de ejecutar el desmontaje (`git worktree remove --force`), garantizando que la deliberación real del worker sobreviva para el cierre de tarea y generación del Executive Design Digest en `close-task.sh`.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `SIN_REVISOR` (Rondas: 1)
- **Síntesis de Diseño**: Revisor de inferencia no disponible (timeout 5s o conexión rehusada). Se activa fallback seguro a aprobación manual clásica.
- **Mensaje de Cierre**: `merge: integrate feat/T-128-worktree-deliberation-bridge into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-128.md`
- `docs/sprints/sprint-22-core.md`
- `scripts/agent/worktree-merge.sh`

## 🧠 Skills Declaradas y Aplicadas
- `orchestrator`
- `agent-os-scripts`
