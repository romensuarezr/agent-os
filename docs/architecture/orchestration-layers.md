# Capas de orquestación (T-105)

> Tres capas, tres responsabilidades. No se fusionan porque responden a
> preguntas distintas. Si dudas dónde va algo nuevo, este documento decide.

```
┌─────────────────────────────────────────────────────────────┐
│ CAPA 1 · orchestrator — contrato cognitivo (agnóstico)       │
│ .agents/skills/orchestrator/SKILL.md                         │
│ Pregunta: ¿QUÉ hay que hacer y cómo se verifica?            │
│ Gramática /goal /dispatch /judge /gate + verify-goal.sh.    │
│ Funciona con Orca, Hermes o CLI: no sabe qué runtime hay.   │
└───────────────────────────────┬─────────────────────────────┘
                                │ delega la mecánica en
┌───────────────────────────────▼─────────────────────────────┐
│ CAPA 2 · orchestration — backend de ejecución (Orca)        │
│ scripts/agent/orca-orchestrate.sh (+ skill orchestration)    │
│ Pregunta: ¿CÓMO se ejecuta aquí y ahora?                     │
│ run-flow: create-run → task-create (con --deps) →            │
│ dispatch-worker → check-events → create-gate. PARA en el    │
│ gate; solo un humano invoca resolve-gate. Sin runtime usable │
│ cae al fallback Git-nativo con ruta explícita.              │
└───────────────────────────────┬─────────────────────────────┘
                                │ usa
┌───────────────────────────────▼─────────────────────────────┐
│ CAPA 3 · runtime-o-fallback — el metal                      │
│ Orca ADE (worker-start --repo/--worktree) O                  │
│ Git-nativo (dispatch-satellite.sh → worktree-dispatch.sh).  │
│ Pregunta: ¿DÓNDE corre el worker?                           │
│ El core nunca asume Orca: la ausencia de runtime es una     │
│ ruta, no un error (falla en VMs limpias desde el Sprint 12).│
└─────────────────────────────────────────────────────────────┘
```

## Por qué no se fusionan

| Si fusionas… | …pierdes |
|---|---|
| orchestrator + orchestration | La portabilidad: el contrato dejaría de funcionar sin Orca |
| orchestration + runtime | El punto de entrada único: cada usuario reconstruiría la secuencia a mano |
| Las tres en una | Todo a la vez, y el fallback Git-nativo no tendría dónde vivir |

La regla: la capa 1 no nombra binarios; la capa 2 no decide objetivos; la capa 3
no sabe de gates. Cada capa se testea por separado (checks 9, 23 y 25).

## El DAG es real

`create-task` expone `--deps`/`--parent` del runtime y `run-flow` resuelve
`títulos → ids` en orden de creación (solo hacia atrás; forward-ref es error
accionable). No hay DAG fingido: lo que el CLI no expone, no se promete.

## Aparcados, con su estado real (no se planifica sobre ellos)

| Pieza | Estado verificado | Condición de reapertura |
|---|---|---|
| `control-mail` | 0 menciones en el CLI 1.4.216 | que aparezca como superficie |
| `orchestration.federation.v1` | tabla `federated_dispatches` existe, 0 filas, 0 environments | primer environment pareado + primer dispatch |
| Mensajería (`send`/`check`/`inbox`) | comandos existen, 0 mensajes en la DB | primer mensaje real entre workers |
| Consolidación asíncrona | sin superficie de CLI | propuesta con evidencia |

## Dónde vive cada decisión humana

Los gates son el único sitio donde el flujo se detiene y espera: `create-gate`
los crea, `resolve-gate` solo lo invoca un humano. Ningún script, subcomando ni
flag resuelve un gate solo — el check 25 lo verifica por log de invocaciones.
La manualidad es la garantía, no el problema.
