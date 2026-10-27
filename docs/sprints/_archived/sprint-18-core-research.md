# Research Sprint 18

> Fuentes: verificación contra el código en ejecución (2026-10-16) + `scout.sh` determinista
> (0 tokens de inferencia) + escaneo real de `locator-hygiene.sh --path` contra el satélite.
> Tareas: T-106 saneado romensuarez-web · T-108 semver · T-109 convención changelog ·
> T-110 wrapper cp · T-112 informe de lote

## Descubrimientos Scout (por tarea)

### T-108 — Semver en el cierre de sprint
- **Alternativa detectada:** `semantic-release` (24.1k⭐ MIT), `release-it` (9.1k⭐ MIT), `standard-version` (npm)
- **Recomendación del agente:** desarrollo a medida
- **Decisión del usuario:** pendiente (se registra al aprobar el contrato)
- **Notas de integración:** las tres son del ecosistema Node/npm; el core es bash agnóstico de stack (principio 1 de AGENTS.md). El fix son ~3 líneas sobre `update-changelog.sh:110` + check 26 de regresión. N/A integración externa.

### T-111 — Manifest regenerable (→ Backlog, no entra)
- **Alternativa detectada:** `@architect/inventory` (Node), `webpack-assets-manifest`
- **Recomendación del agente:** desarrollo a medida justificado cuando se retome
- **Decisión del usuario:** diferir a `## Backlog` (4 sprints sin incidente; el manifest manual funciona)
- **Notas de integración:** ninguna resuelve un inventario bash con sección `[deprecated]` manual. N/A.

### T-106 / T-109 / T-110
- Sin funcionalidad nueva que prospectar: aplicación de herramientas existentes (T-106, escáner del core), corrección de literales (T-109) y wrapper portable sobre primitiva POSIX (T-110). No se ejecutó `scout.sh`: nada que adoptar.

### T-112 — Informe consolidado de lote
- Sin prospección externa: las fuentes son las primitivas ya verificadas del runtime (`list-runs`, `list-tasks --run`, `list-gates --run`, `status`, 23 flags `--json` en `orca-orchestrate.sh`). El informe es agregación read-only, no integración.

## Ideas archivadas (con evidencia)

| Idea | Veredicto | Evidencia |
|---|---|---|
| `2026-10-12-publicacion-remota-y-mapa-de-flujos.md` | **Implementada al 100%** → archivada | Parte 1 (publicación): `promote-to-main.sh:63,67,71` (`--push-source`, `--merge-commit`, `--pr`) — T-101. Parte 2 (mapa): `scripts/agent/generate-flow-map.sh` + `docs/flow-map.md` + digest versionados — T-102. |
| `2026-09-28.md` (namespacing `config/` → `.agents/config/`) | **Implementada** → archivada | `discover-fleet.sh:332` escribe en `.agents/config/fleet.yaml` y migra el legacy; `audit-child.sh:163` limpia rutas `config/` heredadas. |

## Evidencia de alcance por tarea

- **T-106**: base correcta = `origin/main` de `romensuarezr/romensuarez-web` (`339b029`).
  El worktree `~/orca/workspaces/romensuarez-web/limpet` estaba en `romensuarezr/limpet` (`c20e9b2`),
  **74 commits por detrás**: su escaneo (21 violaciones, incl. 4 en `scripts/agent/*.sh` y `docs/adr/`
  duplicado) **no es representativo** y queda descartado. Sobre `main`: 36 líneas en 8 docs
  (`docs/adrs/ADR-001/002/003`, `README.md`, `architecture-evaluation`, 2 guías de despliegue, `roadmap.md`)
  + 6 líneas en 4 `_archived/` (005/006/007/038). **Cero violaciones en código**; `docs/adr/` singular
  **Bug del escáner detectado y corregido en T-106**: `EXCEPTIONS` se calculaba antes de parsear
  argumentos, así que `--path` leía las excepciones del core y no las del repo destino (los 6
  `_archived/` se reportaban igual). Se movió la asignación tras el parseo + check 27 (fixture git
  aislado). Resultado con el escáner publicado sobre `limpet-T-106`: **0 violaciones**.
  Sigue abierto (otro bug, no T-106): el escáner afirma "limpio" sobre un directorio que no es repo.
- **T-108**: `update-changelog.sh:110` — `grep -m1 '^## \['` cae en `## [Unreleased]` (línea 119 del
  changelog) sin semver → fallback `0.0.0` → genera `0.1.0`. Reproducido y parcheado a mano en el
  cierre de sprint-17. La suite no valida el changelog (0 matches): el fix añade el check 26.
- **T-109**: 41 literales `CHANGELOG.md` en 7 ficheros. `update-changelog.sh:36-37` y
  `close-sprint.sh:42-43` ya tienen fallback a minúsculas (no rompen hoy), pero **prefieren** mayúsculas
  mientras `audit-repo.sh:196-197` migra a minúsculas. Único literal a conservar: `audit-repo.sh:196`
  (detecta el nombre viejo para migrarlo).
- **T-110**: `grep -c "cp -n" install.sh` = 8. Precedente: `lib/portable-timeout.sh` → `lib/portable-fs.sh`.
- **T-112**: `run-flow` emite JSON con tareas y gates y se detiene (`orca-orchestrate.sh:700`); no existe
  agregación de lectura. Fuentes: `list-runs`, `list-tasks --run`, `list-gates --run`, `status`.

## Follow-ups registrados (no entran al sprint)

- **Falso positivo del escáner**: `locator-hygiene.sh` devolvió "✅ limpio" sobre
  `~/orca/workspaces/romensuarez-web/` — un contenedor **sin repo git**. La herramienta debe negarse a
  dar "limpio" sobre un no-repo, no afirmarlo.
- **ADRs duplicados** en `romensuarez-web` (`docs/adr/` vs `docs/adrs/`): consolidar es otra tarea
  (decide ubicación canónica y referencias).
- **Credenciales revocadas**: ⛔ bloqueadas hasta el veredicto sobre `CLOUDFLARE_API_TOKEN`
  (transversal vs por zona).
