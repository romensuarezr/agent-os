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

```bash
# 1. Run y vinculación del coordinador a esta terminal
orca orchestration run-create --objective "<objetivo del lote>"

# 2. Tareas con dependencias (DAG)
orca orchestration task-create --title "<tarea>" --spec "<qué hacer>"

# 3. Despacho: un worker por tarea, en el repo destino
orca orchestration worker-start --task <task_id> \
      --repo <selector> --worktree new-child --agent <id>

# 4. Seguimiento
orca orchestration worker-list      # contabilidad y estado
orca orchestration worker-read      # salida acotada del worker

# 5. Gate: el humano aprueba. AQUÍ SE PARA.
orca orchestration gate-create --task <task_id> --question "<qué se decide>"
orca orchestration gate-resolve --gate <gate_id> --decision approve
```

Los pasos 1-5 están verificados contra `--help` del runtime 1.4.216 instalado en esta máquina.

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
- `scripts/agent/coordinator-run.sh` (nuevo — el punto de entrada, paso a paso)
- `.agents/config/routing-policy.yaml` (extender solo si el DAG necesita reglas nuevas)
- `docs/architecture/orchestration-layers.md` (nuevo — la jerarquía de las tres capas)
- `tests/validate-control-plane.sh` (check N+1)
- `changelog.md`
- `.agents/tasks/task-105.md` (este contrato)
- `docs/sprints/sprint-17-core.md`

## Criterios de done
- [ ] `coordinator-run.sh` recorre los 5 pasos y **se detiene en el gate** sin continuarlo solo
- [ ] Con runtime: invoca los comandos de Orca con los flags verificados
- [ ] Sin runtime: dice explícitamente que cae a T-104 y **no simula éxito**
- [ ] El runbook deja de descrever el runbook y pasa a citar `orca orchestration` real
- [ ] El runbook documenta el **fallback Git-nativo** con el mismo peso
- [ ] `orchestration-layers.md` documenta la jerarquía y **por qué no se fusionan** las skills
- [ ] Los aparcados (control-mail, federación, consolidación) quedan listados con su estado real
- [ ] Ningún gate se resuelve automáticamente
- [ ] Check N+1: el script se detiene en el gate (no lo resuelve)
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

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente