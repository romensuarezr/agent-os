# Task-107: Consolidar el flujo de worktrees (el flujo que nunca se ejecutó)

## Objetivo
Que el flujo de worktrees sea tan claro, obligatorio y distribuido como
`session-start` o `sprint-planning`: una única ubicación canónica, un único
documento de flujo que viaja a los hijos, GC de huérfanos, gate de disco, y
reglas que resuelven las contradicciones actuales. Que lo de esta sesión
(tres esquemas documentados, cero usados, `main` en otro worktree, sin GC,
disco al 84% sin gate) no pueda repetirse en este repo ni en ningún hijo.

## Contexto técnico

### El hallazgo que da origen a la tarea (investigación 2026-10-15, con evidencia)

- El flujo **existe y nunca se ejecutó**: `.agents/workflows/parallel-orchestration.md`
  define el ciclo, pero no hay `.worktrees/` en ninguna copia del repo, no existe
  `.agents/context/dag-state.json`, y el workflow **no está en `assets-manifest.txt`**
  (0 entradas): ni siquiera viaja a los hijos.
- **Tres esquemas de ubicación documentados, ninguno real**: `.worktrees/<task-id>`
  (core), `~/.orca/workspaces/<repo>/tarea-1` (runbook; ese directorio no existe),
  `new-top-level`/`new-child` (runtime). Lo real es `~/orca/workspaces/<repo>/<nombre>`,
  que nadie documentó.
- **Sin GC**: `git-gardener` cubre ramas (0 menciones a worktree), `close-task.sh` y
  `close-sprint.sh` no mencionan worktrees. El único `prune` automático es el pre-flight
  de `worktree-dispatch.sh:127`, que solo corre al crear uno nuevo.
- **Disco al 84% sin enforcement**: ADR-004/005 y el runbook fijan umbrales (>20 GB,
  75%) que **ningún script comprueba**.
- **`worktree-merge.sh` no tiene ni un test funcional**: el check 9 solo verifica
  existencia, `+x` y `bash -n`. (El check 23 cubre `dispatch` vía T-104; de `merge`, nada.)
- **Contradicción regla↔script**: `agent-permissions.md:31` prohíbe `rm -rf` y borrado
  de ramas sin gate L3, pero `worktree-merge.sh:254,256` los ejecuta sin gate.
- **Contradicción de nombres**: `strict-workflow.md` dice `feat/nombre-descriptivo`;
  todo lo demás (ADR-005, dispatch, merge, perfiles, skill) dice `feat/<task-id>-<profile>`.

### La decisión central: ubicación canónica fuera del árbol

Recomendación con motivo: el worktree canónico del core vive **hermano al checkout**,
`<padre>/<repo>-<task-id>/` — fuera del árbol, como dice toda la práctica externa
y como ya hace Orca de facto. Motivos: un `git add -A` en el principal no puede
barrerlo ni por accidente (defensa en profundidad sobre la prohibición de `add -A`);
los linters y búsquedas del principal no lo recorren; `git status` del principal no
lo ve ni como ignorado.

Esto **revisa un default aprobado en T-104** (`worktree_base` default `.worktrees/`,
elegido entonces como "cero sorpresa" provisional). T-107 es exactamente la
consolidación que justifica el cambio: o el default cambia aquí, o el core publica
dos doctrinas contradictorias. Los tres scripts (`worktree-dispatch.sh`,
`worktree-merge.sh`, `dispatch-satellite.sh` + cabecera de `satellites.yaml`) pasan
al mismo default en la misma tarea para no romper la pareja dispatch/merge.

### Qué NO se toca
- **El layout vivo del operador no se migra.** Los 3 worktrees actuales
  (`Proyectos/agent-os`, `mahimahi`, `multi-agent`) y la rama del checkout principal
  se quedan como están: documentar la regla no es moverle la casa a nadie.
- **No se fusionan skills** (decisión heredada del veredicto de la spike).
- **Orca decide sus propias ubicaciones**: el core documenta el mapeo, no lucha contra el runtime.
- **`dag-state.json` no se resucita**: el estado emerge del dispatcher (T-104) y del
  registro de GC, no de un fichero de estado paralelo.

## Caja de archivos
- `.agents/workflows/parallel-orchestration.md` (reescribir: el flujo canónico —
  ubicación, hooks de sesión, merge vs promote, GC. Se mantiene el nombre: solo lo
  referencia el índice de ADRs)
- `.agents/workflows/session-start.md` (FASE 4: registrar identidad del worktree en el lock)
- `.agents/workflows/session-close.md` (sección: qué le pasa a tu worktree al cerrar;
  cuándo merge / cuándo promote / qué implica cada uno)
- `.agents/rules/global/agent-permissions.md` (exención L2 acotada para efímeros)
- `.agents/rules/global/strict-workflow.md` (alinear nombre de rama canónico)
- `scripts/agent/worktree-dispatch.sh` (default canónico + gate de disco)
- `scripts/agent/worktree-merge.sh` (mismo default; más 3 correcciones que la
  implementación demostró necesarias: suprimir stdout de `branch -d` en `--force`
  —rompía el JSON—, gate con `--strict` como `/judge` —sin él REJECT era código
  muerto—, y `verify-goal.sh` hermano al script —la copia del destino no existe
  en satélites sin agent-os y el gate se saltaba en silencio)
- `scripts/agent/dispatch-satellite.sh` (revisar default de `worktree_base`)
- `.agents/config/satellites.yaml` (cabecera: default revisado)
- `scripts/agent/worktree-gc.sh` (nuevo — huérfanos con `--dry-run`/`--apply`)
- `.agents/skills/orchestrator/SKILL.md` (alinear ejemplos a la ubicación canónica)
- `.agents/skills/goal-evaluation/SKILL.md` (alinear diagrama a la ubicación canónica)
- `.agents/profiles/coder.md` (alinear protocolo de worktree a la ubicación canónica)
- `.agents/profiles/coordinator.md` (alinear ejemplo de despacho a la ubicación canónica)
- `scripts/agent/assets-manifest.txt` (registrar workflow + gc.sh)
- `tests/validate-control-plane.sh` (check 24)
- `changelog.md`
- `.agents/tasks/task-107.md` (este contrato)
- `docs/sprints/sprint-17-core.md`
- `docs/sprints/sprint-17-core-research.md` (sección T-107 con la evidencia)

## Criterios de done
- [x] Ubicación canónica única documentada e implementada con el mismo default en los 3 scripts
- [x] `worktree-gc.sh` lista huérfanos (rama mergeada, metadata prunable); `--dry-run` por defecto, `--apply` purga; JSON
- [x] Gate de disco: refuse accionable bajo el umbral (`WORKTREE_MIN_FREE_GB`, default 5 GB)
- [x] `session-start` FASE 4 registra worktree (ruta + rama) en el lock y lo muestra
- [x] `session-close` incluye tabla cerrar-vs-merge-vs-promote con implicaciones para el worktree
- [x] Exención L2 acotada documentada: solo efímeros creados por dispatch y registrados; resto sigue L3
- [x] `parallel-orchestration.md` reescrito y en el manifest (viaja a los hijos)
- [x] Check 24: `merge.sh` funcional (estrategias, REJECT conserva, dismantle limpia) + GC básico
- [x] `strict-workflow.md` alineado al nombre canónico `feat/<task-id>-<profile>`
- [x] Skills (`orchestrator`, `goal-evaluation`) y perfiles (`coder`, `coordinator`) alineados a la ubicación canónica
- [x] Suite completa sin regresiones
- [x] `git diff --name-only` ⊆ Caja
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-10-16
- [x] Rama creada: feat/T-107-worktree-flow (desde multi-agent @ 5b7c61e)
- [x] Lock activo: task-107
- [ ] Sesión cerrada correctamente

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
