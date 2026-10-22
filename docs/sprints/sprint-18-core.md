# Sprint 18 — Versiones, Convenciones y Consolidación de Lotes

## Estado
🟡 En curso

## Tareas
| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :--- | :--: | :--- | :--- |
| T-106 | Saneado de frontera portable en `romensuarez-web` sobre `origin/main` (339b029): 26 hallazgos — 12 en docs (enlaces relativos + `<ip-publica>`), 6 en `_archived/` excluidos con motivo, 8 `[hostname-nodo]` (6 assets restaurados del core + 2 saneados in situ); incluye fix de `locator-hygiene.sh --path` + check 27 | Bug del sistema | S | ✅ Completada | — | [.agents/tasks/task-106.md](.agents/tasks/_archived/task-106.md) |
| T-108 | Semver real en el cierre de sprint: `update-changelog.sh` ignora `## [Unreleased]` al leer la versión actual + check 26 de regresión en la suite | Bug del sistema | M | ✅ Completada | — | [.agents/tasks/task-108.md](.agents/tasks/_archived/task-108.md) |
| T-109 | Unificar el literal `CHANGELOG.md` → `changelog.md`: invertir la preferencia en `update-changelog.sh`/`close-sprint.sh` y corregir los mensajes y workflows que apuntan a un fichero inexistente | Bug del sistema / DX | S | ✅ Completada | T-108 | [.agents/tasks/task-109.md](.agents/tasks/_archived/task-109.md) |
| T-110 | Wrapper portable de copias no destructivas: `lib/portable-fs.sh` con `agent_cp_n` (patrón `portable-timeout.sh`), aplicado en `install.sh` (8 usos de `cp -n`) | Universalización | S | ⬜ Pendiente | — | [.agents/tasks/task-110.md](.agents/tasks/task-110.md) |
| T-112 | Informe consolidado de lote read-only: nuevo subcomando de `orca-orchestrate.sh` que agrega run → tareas → worktrees → gates → diffstat en una sola pantalla para el humano | DX | L | ⬜ Pendiente | — | [.agents/tasks/task-112.md](.agents/tasks/task-112.md) |

## Notas de planning

- **Origen**: `/sprint-planning` 2026-10-16 sobre `main` recién publicado (`v1.13.0`). Sin spillover: sprint-17 cerró 3/3.
- **Higiene previa ejecutada**: 3 líneas del roadmap marcadas `✅ Hecho` (T-100/101/102, sprints 15-16 registrados como completados); T-111 + ByteBox a `## Backlog`; archivadas 2 ideas caducas (ver `## Ideas archivadas` del research); `last-sync.md` corregido.
- **Dependencias**: T-109 es secuencial tras T-108 (comparten `update-changelog.sh`/`close-sprint.sh`: el fix de versión toca la línea que T-109 renombra). T-106, T-110 y T-112 son independientes.
- **Lo que este sprint NO hace**: ejecución desatendida de lotes (el modelo de seguridad — la manualidad es la garantía — no se toca); consolidación de los ADRs duplicados de `romensuarez-web` (otra tarea); rotación de credenciales revocadas (⛔ bloqueada hasta el veredicto sobre `CLOUDFLARE_API_TOKEN`).
- **Workflow**: se propone condensar los pasos 4b (MVP tracker) y 5 (Perplexity) de `sprint-planning.md` con cláusulas condicionales para el core — entra como parte de T-109 (misma clase: el workflow exige artefactos que el core no tiene).
