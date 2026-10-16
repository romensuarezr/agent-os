# Task-105: Punto de entrada del coordinador y runbook del flujo

## Objetivo
Un flujo único y documentado que haga, en este orden y sin microsgestión: crear el run, descomponer
en un DAG de tareas, despachar un worker por tarea, seguir su estado y detenerse en un gate a la
espera de aprobación humana.

**No se construye autonomía. Se construye mecánica.**

## Contexto técnico

### El punto de partida: por qué hoy no hay "un coordinador"
`orca orchestration coordinator-start` y `coordinator-stop` están **retirados** en 1.4.216: el
runtime dice literalmente *"Retired: load the current orchestration skill"*. Es decir, el
coordinador **no es un comando**: es el agente que sigue la skill `orchestration` y está vinculado
a un Run mediante `run-create`.

Eso significa que el flujo existe como capacidad pero **no como punto de entrada**, y cada usuario
tiene que reconstruirlo a mano.

### La secuencia, con los flags verificados contra el runtime

`run-flow` (subcomando de `orca-orchestrate.sh`) ejecuta, en este orden, los
subcomandos ya existentes —no los duplica— con los flags verificados contra el
runtime 1.4.216:

```bash
# 1. Run y vinculación del coordinador a esta terminal
orca-orchestrate.sh create-run --objective "<objetivo del lote>"

# 2. Tareas (descomposición; orden de ejecución, ver limitación DAG abajo)
orca-orchestrate.sh create-task --run <id> --title "<tarea>" --spec "<qué hacer>"

# 3. Despacho: un worker por tarea, en el repo destino
orca-orchestrate.sh dispatch-worker --run <id> --title "<t>" --spec "<s>" \
      --agent <id> --role <rol> --repo path:<repo> --worktree new-top-level

# 4. Seguimiento
orca-orchestrate.sh check-events --run <id> [--wait]

# 5. Gate: el humano aprueba. AQUÍ SE PARA.
orca-orchestrate.sh create-gate --task <task_id> --question "<qué se decide>"
# resolve-gate SOLO lo invoca el humano, nunca el flujo.
```

### Limitación documentada: sin edges de DAG

El runtime tiene `--deps`/`--parent`, pero este CLI no los parsea ni `create-task`
los pasa: las "dependencias" de T-105 son **descomposición + orden de ejecución**
(según el spec-file), no aristas del runtime. No se finge un DAG que no se cablea;
exponer `--deps` queda como follow-up.

### Lo que este sprint NO construye
- **Nada de autonomía en la decisión.** El humano sigue en los gates. La manualidad es la garantía:
  este sprint automatiza el despacho, no la aprobación.
- **Nada de panel de estado**: el estado emerge del dispatcher de T-104.
- **`control-mail`, federación y consolidación asíncrona: aparcados.** Hay tabla
  `federated_dispatches` con `protocol_version` pero **0 filas**, y **0 environments** guardados.
  `control-mail` tiene **0 menciones** en el CLI. No se planifica sobre algo inoperable.

### Jerarquía documentada (no se fusionan)
`orchestrator` (contrato cognitivo, agnóstico) → `orchestration` (backend de ejecución, Orca) →
runtime **o** fallback Git-nativo. Ver research §"Jerarquía de skills".

### El hueco documental concreto
`docs/runbooks/orca-multiagent-orchestration.md` describe el patrón B del coordinador con un
diagrama correcto, pero contiene **16 referencias a scripts del core y 0 comandos
`orca orchestration`**: está escrito contra la capa de abstracción anterior al runtime. Es la
fuente de confusión más probable para quien intente usar esto hoy.

## Caja de archivos
- `docs/runbooks/orca-multiagent-orchestration.md` (reescribir contra el runtime + fallback)
- `scripts/agent/orca-orchestrate.sh` (sonda_runtime sin abortar + check_orca fail-hard
  para los 10 subcomandos directos + subcomando run-flow con parada en gate y fail-soft;
  NO se crea coordinator-run.sh: duplicaría los 10 subcomandos existentes)
- `docs/architecture/orchestration-layers.md` (nuevo — la jerarquía de las tres capas)
- `tests/validate-control-plane.sh` (check N+1)
- `changelog.md`
- `.agents/tasks/task-105.md` (este contrato)
- `docs/sprints/sprint-17-core.md`

## Criterios de done
- [ ] `run-flow` recorre los 5 pasos y **se detiene en el gate** sin continuarlo solo
- [ ] Con runtime: invoca los subcomandos existentes con los flags verificados
- [ ] Sin runtime: delega en `dispatch-satellite.sh` (T-104) con `route:"git-fallback"`
  explícito y **no simula éxito**; sin satélite declarado, error accionable
- [ ] Los 10 subcomandos directos mantienen fail-hard (sonda clasifica, check_orca
  aborta con mensaje accionable); **solo** `run-flow` usa el clasificador para fail-soft
- [ ] El runbook deja de describir el patrón en abstracto y pasa a citar `orca orchestration` real
- [ ] El runbook documenta el **fallback Git-nativo** con el mismo peso
- [ ] `orchestration-layers.md` documenta la jerarquía y **por qué no se fusionan** las skills
- [ ] Los aparcados (control-mail, federación, consolidación) quedan listados con su estado real
- [ ] Ningún gate se resuelve automáticamente (verificado por log de invocaciones en el check)
- [ ] Check N+1: run-flow se detiene en el gate (no lo resuelve) + fallback sin runtime
- [ ] Suite completa sin regresiones
- [ ] `git diff --name-only` ⊆ Caja
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5) — 2026-10-16
- [x] APROBADO CON CAMBIOS recibido — 2026-10-16 (opción A + contrato check_orca/sonda por subcomando + batch a deprecated)
- [x] Rama creada: feat/T-105-coordinator-entry (desde multi-agent @ 52cf7aa)
- [x] Lock activo: task-105
- [ ] Sesión cerrada correctamente