# Task-126: Integración del Bucle de Deliberación en Workflows de Despacho y Worktrees

## Objetivo
Conectar el flujo de despacho paralelo en Git Worktrees (`parallel-orchestration.md` y `worktree-dispatch.sh`) con el motor de deliberación determinista (`deliberate-plan.sh`), permitiendo que el Coordinator despache tareas a ramas/worktrees efímeros garantizando que el Coder genere su plan y ejecute la deliberación antes de modificar código en su entorno aislado.

## Contexto técnico
Actualmente:
- `worktree-dispatch.sh` aprovisiona el directorio hermano `<repo>-<task-id>/` con su rama efímera.
- `session-start.md` cuenta con la deliberación integrada, pero `parallel-orchestration.md` no especificaba cómo se realiza la deliberación cuando un worker opera dentro de un worktree independiente.
En esta tarea:
1. `parallel-orchestration.md` se actualiza para documentar el ciclo completo:
   `worktree-dispatch` → `deliberate-plan` en worktree → aprobación humana/consenso → ejecución → `verify-goal` → `worktree-merge` → `close-task`.
2. `worktree-dispatch.sh` inicializa la estructura de contexto necesaria para que el worker pueda deliberar en su entorno aislado sin colisionar con el checkout principal.
3. Asegurar que `.agents/context/dispatched.jsonl` mantenga la trazabilidad del estado de deliberación de cada worktree.

## Skills relevantes
- `orchestrator`: Gestión del ciclo de vida de worktrees efímeros y orquestación paralela.
- `agent-os-scripts`: Robustez en bash y CLI conventions en `worktree-dispatch.sh`.
- `workflow-designer`: Diseño de flujos operativos en Antigravity.

## Caja de archivos
- `.agents/workflows/parallel-orchestration.md`
- `scripts/agent/worktree-dispatch.sh`
- `.agents/tasks/task-126.md`

## Criterios de done
- [ ] `parallel-orchestration.md` actualizado con el diagrama y fases que integran deliberación y compuertas de calidad.
- [ ] `worktree-dispatch.sh` prepara el entorno de deliberación del worker sin alterar el checkout principal.
- [ ] Trazabilidad de estados en `dispatched.jsonl` conforme a los estándares de orquestación.
- [ ] Verificación de despacho y aislamiento sin fugas de infraestructura (Check 23 y 24 de la suite).
