# Sprint 17 — Despacho Multi-Repo, Flujo de Worktrees y Punto de Entrada del Coordinador

## Estado
🟡 En curso

## Tareas
| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :--- | :--: | :--- | :--- |
| T-104 | Despacho multi-repo del core portable: declaración de satélites + dispatcher determinista con ruta Orca y fallback Git-nativo | Universalización | M | ✅ Completada | — | — |
| T-107 | Consolidar el flujo de worktrees: ubicación canónica fuera del árbol, GC, gate de disco, hooks de sesión y merge-vs-promote documentados | Universalización / DX | L | ✅ Completada | T-104 | — |
| T-105 | Punto de entrada del coordinador + runbook: run → DAG → workers → gates, cableando orchestrator → orchestration → runtime-o-fallback | DX / Documentación | M | ✅ Completada | T-104, T-107 | — |

## Notas de planning

- **Origen**: spike de inventario de capacidades de Orca ADE 1.4.216, con runtime **verificado en
  ejecución** (no por lectura). El sprint propuesto inicialmente ("registro de repos" + "coordinador
  autónomo") **muere reformulado**: ver `## Veredicto` del research.
- **Decisión que da forma al sprint**: el core **no puede asumir Orca**. `orca-orchestrate.sh:33`
  aborta si `command -v orca` falla, y por eso el chequeo falla en VMs limpias desde el Sprint 12.
  El fallback `git worktree add` **no es una degradación: es el diseño**, y por eso T-104 pone
  ambas rutas en el mismo plano.
- **Se mantiene la garantía de revisión**: el humano sigue en los decision gates, exactamente como
  hoy. Este sprint construye *mecánica*, no *autonomía*.
- **Lo que este sprint NO hace**: panel de estado (el estado emerge del dispatcher), y tampoco
  `control-mail`, federación ni consolidación asíncrona — están **aparcados** en el research con su
  evidencia (0 mensajes, 0 filas de federación, 0 environments).
- **Fuera de alcance**: T-106 (saneado de `romensuarez-web`), que es S y va aparte.
- **T-107 nace de una investigación, no de un plan**: al implementar T-104 se descubrió
  que el flujo de worktrees está definido y nunca ejecutado (sin `.worktrees/`, sin
  `dag-state.json`, fuera del manifest), con tres esquemas de ubicación y ninguno real,
  sin GC y sin gate de disco (84% usado). T-105 depende de T-107 porque el coordinador
  se apoya en ese flujo: construir encima de algo nunca ejecutado repetiría el error.
- **T-104 revisa su default en T-107**: `worktree_base` default `.worktrees/` fue
  provisional ("cero sorpresa"); la ubicación canónica fuera del árbol lo sustituye.

### Veredicto de la spike (resumen)

| Candidato | Veredicto |
|---|---|
| Registro de repos | **MUERE** — `orca repo list` + `worktree ps` ya lo dan, con estado vivo |
| Coordinador autónomo | **MUERE** — contradice la garantía de aprobación humana |
| Motor de orquestación propio | **MUERE** — el runtime tiene las primitivas ya probadas (4 runs, 6 dispatches, 1 gate) |