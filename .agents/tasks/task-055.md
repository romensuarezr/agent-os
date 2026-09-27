# Task-055: Motor de Aislamiento y Ciclo de Vida de Git Worktrees (worktree-dispatch.sh, worktree-merge.sh)

## Objetivo
Desarrollar los scripts de ciclo de vida de Git Worktrees (`worktree-dispatch.sh` y `worktree-merge.sh`) para permitir a los agentes ejecutarse en directorios de trabajo paralelos, efímeros y completamente aislados en `.worktrees/<task-id>/`, garantizando merges seguros previa verificación de metas y limpieza sin fugas en disco (ADR 004).

## Contexto técnico
- Basado en los hallazgos de `docs/sprints/sprint-09-core-research.md`:
  - `.gitignore` y `templates/.gitignore-agent-os`: Excluir la carpeta `.worktrees/` para que los árboles de trabajo efímeros no contaminen el control de versiones.
  - `scripts/agent/worktree-dispatch.sh`:
    - Valida que el repositorio principal esté en un estado consistente.
    - Crea un worktree efímero en `.worktrees/<task-id>/` con rama aislada (`feat/<task-id>-<profile>`) derivada de la rama base o HEAD:
      `git worktree add -b feat/<task-id>-<profile> .worktrees/<task-id> HEAD`
    - Inyecta variables de entorno esenciales: `AGENT_OS_ROOT="$(git rev-parse --show-toplevel)"`.
    - Garantiza enlaces simbólicos o acceso hacia `.agents/`, scripts y contexto operativo.
    - Emite digest JSON con la ruta del worktree, la rama creada y el PID/estado.
  - `scripts/agent/worktree-merge.sh`:
    - Recibe el `<task-id>`.
    - Ejecuta de forma determinista `scripts/agent/verify-goal.sh` dentro del worktree para comprobar que cumple el contrato de meta y pasa los quality gates.
    - Si la verificación pasa: realiza merge controlado (o emite PR/commit) hacia la rama de integración.
    - Desmantela el worktree de forma atómica:
      `git worktree remove --force .worktrees/<task-id>`
      `git worktree prune`
    - Elimina cualquier residuo administrativo en `.git/worktrees/`, cumpliendo ADR 004.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `scripts/agent/worktree-dispatch.sh`
- `scripts/agent/worktree-merge.sh`
- `.gitignore`
- `templates/.gitignore-agent-os`
- `docs/sprints/sprint-09-core.md`
- `.agents/tasks/task-055.md`

## Criterios de done
- [ ] `.worktrees/` añadido a `.gitignore` del core y a `templates/.gitignore-agent-os`.
- [ ] Script `scripts/agent/worktree-dispatch.sh` implementado y ejecutable (`chmod +x`), provisionando worktrees en `.worktrees/<task-id>` con rama `feat/<task-id>-<profile>` e inyección de contexto.
- [ ] Script `scripts/agent/worktree-merge.sh` implementado y ejecutable (`chmod +x`), invocando `verify-goal.sh`, realizando merge seguro y ejecutando `git worktree remove --force` y `git worktree prune`.
- [ ] Validación de flags de ayuda (`--help`) y salida estructurada en modo `--json` para orquestadores.
- [ ] Prueba funcional de ciclo de vida completo (dispatch -> check -> merge/remove) sin dejar residuos en `.git/worktrees/`.
- [ ] Estado reflejado en `docs/sprints/sprint-09-core.md` y `.agents/tasks/task-055.md`.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
