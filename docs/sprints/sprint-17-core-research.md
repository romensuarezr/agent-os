# Research Sprint 17

> Fuentes: spike de inventario de capacidades de Orca ADE (2026-10-14, runtime **verificado en
> ejecución**, no por lectura) + `scout.sh` determinista + inventario de assets del core.
> Tareas: T-104' despacho multi-repo · T-105' punto de entrada del coordinador

## Veredicto de la spike: qué muere

| Candidato | Veredicto | Motivo (con evidencia) |
|---|---|---|
| Registro de repos | **MUERE** | `orca repo list` ya devuelve 9 repos; `orca worktree ps` añade rama, terminales vivos y preview en vivo. Duplicarlo es trabajo inútil. |
| Coordinador autónomo | **MUERE** | Contradice el modelo de seguridad del workflow: aprobación del plan + revisión antes del merge. La manualidad **es** la garantía. |
| Motor de orquestación propio | **MUERE** | El runtime tiene las primitivas probadas: `runs` 4, `worker_dispatches` 6, `decision_gates` 1 en `orchestration.db`. |

## Runtime verificado (no supuesto)

- `orca` CLI **1.4.216**. `orca status` → `appRunning: true`, `runtimeReachable: true`,
  `graphState: ready`.
- `orca` es un **shim** que ejecuta `/opt/Orca/resources/bin/orca-ide`. **No es auto-instalable**:
  no existe `orca install` ni descarga en el CLI. En una VM limpia sin la distribución, no hay CLI.
  *No verificado*: el procedimiento de instalación (no se instaló nada).

## Primitivas disponibles (con su flag)

| Necesidad | Comando | Nota |
|---|---|---|
| Registrar repo | `orca repo add <path>` / `repo list` | Ya existe, 9 repos |
| Crear worktree en repo destino | `worker-start --repo <selector>` | selector: `id:<id>`, `name:<name>`, `path:<path>` |
| Worktree hijo nuevo | `--worktree new-child` / `new-top-level` | |
| Lanzar agente conocido | `--agent <id>` | |
| Lanzar en servidor remoto | `--on <saved-environment>` | **`environment list` → vacío hoy** |
| Run del coordinador | `run-create --objective <text>` | vincula la terminal al Run |
| Tareas con DAG | `task-create` (`--deps`, `--parent`) | |
| Supervisar | `worker-read`, `worker-show`, `worker-list` | |
| Gate de decisión | `gate-create` / `gate-resolve` | 1 gate registrado en la DB |

## Lo que NO se pudo verificar (y por tanto no se planifica)

| Elemento | Estado real | Decisión |
|---|---|---|
| `control-mail` | **0 menciones** en `orca --help` y `orca agent-context`. No es superficie de CLI. | **APARCADO** |
| `orchestration.federation.v1` | Tabla `federated_dispatches` **existe** con `protocol_version`, `peer_fingerprint`, `remote_runtime_epoch` y secuencias. **0 filas**. Sin environments no es ejercitable. | **APARCADO** |
| Mensajería inter-agente | `send`/`check`/`ask`/`reply`/`inbox` existen. **`messages` = 0 filas**. | **APARCADO**: existe pero no está probado |
| Consolidación auto-asíncrona | Sin superficie de CLI que la exprese. | **APARCADO** |

> Regla aplicada: no se planifica sobre algo con 0 filas y 0 environments. Cuando el operador
> parsee un environment y se envíe el primer mensaje, se reabre con evidencia.

## Jerarquía de skills: `orchestrator` vs `orchestration`

**No se fusionan. Son capas distintas** (decisión explícita del usuario):

```
orchestrator  (repo, agnóstico)   → contrato COGNITIVO
  gramática /goal /subgoal /dispatch /judge /gate /merge
  se apoya en verify-goal.sh, worktree-dispatch.sh, plantillas goals/
        │ razona, decide, define el contrato verificable
        ▼
orchestration  (global, Orca 1.4.216)  → BACKEND DE EJECUCIÓN
  run-create, task-create, worker-start, worker-read, gate-*, send/inbox
        │ opera el runtime
        ▼
RUNTIME (Orca)  ···o···  FALLBACK GIT-NATIVO
```

| | `orchestrator` | `orchestration` |
|---|---|---|
| Respaldo | Scripts del core | Runtime de Orca |
| Alcance | Agnóstico: Orca, Hermes, CLI | **Solo Orca** |
| Aporta | Contrato verificable de la meta | Mecánica del despacho y supervisión |
| Si no hay runtime | Funciona (cae a git worktree) | No aplica |

**Consecuencia de diseño**: el core no puede asumir Orca. `orca-orchestrate.sh:33` hace
`command -v orca` y aborta si no está; por eso el fallo en VMs limpias desde el Sprint 12. **El
fallback Git-nativo no es una degradación: es el diseño**, y T-104' lo pone en el mismo plano que
la ruta Orca en lugar de tratarlo como excepción.

## Estado del core que condiciona el diseño

| Pieza | Estado | Rol en el diseño nuevo |
|---|---|---|
`scripts/agent/orca-orchestrate.sh` | ✅ existe | Se convierte en **una de las dos rutas**, no en la única |
`scripts/agent/worktree-dispatch.sh` / `-merge.sh` | ✅ existen | **Ya son el fallback Git-nativo** |
`scripts/agent/verify-goal.sh` | ✅ existe | Gate verificable, agnóstico |
`.agents/config/agent-registry.yaml` | ✅ 14 agentes | A quién se delega |
`.agents/config/routing-policy.yaml` | ✅ 7 reglas | Qué tarea va a qué perfil |
`ADR-005` | ✅ Accepted | Worktrees + Ralph Loop + evaluador-trabajador |
`docs/runbooks/orca-multiagent-orchestration.md` | ⚠️ **16 refs a scripts del core, 0 comandos `orca orchestration`** | Está escrito contra la capa antigua |

## Prospección OSS (scout.sh, 0 tokens de inferencia)

| Candidata | Alternativa | ★ / Licencia | Veredicto |
|---|---|---|---|
| Motor de orquestación | `@langchain/langgraph-supervisor` | MIT | **Descartada**: dependencia Node rompe la portabilidad; además el runtime ya existe |
| Patrón supervisor-worker | `Modular-Earth-LLC/multi-agent-ai-development-framework` | 9⭐ MIT | Descartada: taller, no pieza adoptable |
| Estado multi-repo | *(sin viable)* | — | **A medida justificado**: no hay equivalente para el estado de sprints de un core bash |

> **Aclaración sobre "digest"**: no es una pieza aparte.
> El **digest es la salida del dispatcher** de T-104: el dispatcher sabe qué despachó porque
> él mismo lo hizo. **No hay componente de digest que construir**, ni tarea para él.

## Restricciones heredadas del veredicto

- **Nada de dashboards.** El estado multi-repo **emerge del dispatcher** (sabe qué despachó).
  No existe tarea de "panel de estado".
- **T-106** (`romensuarez-web`) va **aparte**: es S y no pertenece a este sprint.

## Research T-107 — el flujo de worktrees nunca se ejecutó (2026-10-15)

> Origen: implementar T-104 obligó a mirar dónde aterrizan los worktrees, y no había
> dónde mirar. Inventario verificado contra código y disco, no por lectura.

| Hallazgo | Evidencia |
|---|---|
| Flujo definido, nunca ejecutado | `parallel-orchestration.md` existe; `.worktrees/` no existe en ninguna copia; `dag-state.json` no existe; workflow con 0 entradas en el manifest |
| Tres ubicaciones documentadas, ninguna real | `.worktrees/<task-id>` (core) / `~/.orca/workspaces/` (runbook, inexistente; lo real es `~/orca/workspaces/`) / `new-top-level` (runtime) |
| Sin GC | `git-gardener` 0 menciones a worktree; `close-task.sh`/`close-sprint.sh` 0 menciones; único `prune` = pre-flight de `dispatch` |
| Disco 84% sin gate | umbrales ADR-004/005 (>20 GB, 75%) sin comprobación en ningún script |
| `worktree-merge.sh` sin tests | check 9 = existencia + `+x` + `bash -n`; check 23 cubre `dispatch` vía T-104 |
| Regla ↔ script en contradicción | `agent-permissions.md:31` (L3 para `rm -rf`) vs `worktree-merge.sh:254,256` (sin gate) |
| Nombres en contradicción | `strict-workflow.md` (`feat/nombre-descriptivo`) vs resto (`feat/<task-id>-<profile>`) |

Práctica externa convergente (todas las fuentes coinciden): una rama por worktree,
worktree hermano fuera del repo, base limpia conocida, prohibido `git add -A`,
diff con tres puntos dos veces, limpiar al integrar, nunca borrar sucios sin permiso,
`git -C` explícito. El core incumple hoy: ubicación dentro, base = HEAD actual,
`add -A` barrió un transcript en esta misma sesión, y `merge.sh` borra sin gate.