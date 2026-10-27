# Sprint 19 — Versiones y Honestidad de la Flota

## Estado
🟡 En curso

## Tareas
| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :--- | :--: | :--- | :--- |
| T-113 | El cierre de sprint escribe `VERSION` con la versión del changelog en el mismo commit de archivado (hoy quedó `1.12.0` con release `v1.14.0`) + check 30 de alineación | Bug del sistema | M | ⬜ Pendiente | — | [.agents/tasks/task-113.md](.agents/tasks/task-113.md) |
| T-114 | `PREV_TAG` por versión: `update-changelog.sh:49` ordena por `-creatordate` y elige una base equivocada si los tags no se crean en orden; pasar a `git describe`/`sort -V` y extender el check 26 | Bug del sistema | S | ⬜ Pendiente | — | [.agents/tasks/task-114.md](.agents/tasks/task-114.md) |
| T-115 | Versión del core en los satélites: el ledger `.agents/context/last-sync.md` y `audit-child.sh` ya existen; falta la vista agregada de desfase de la flota (read-only, sin dashboards) — caso real `ops-hub` con el core del 5-6 oct | Nueva herramienta | M | ⬜ Pendiente | T-113 (reserva check 31) | [.agents/tasks/task-115.md](.agents/tasks/task-115.md) |
| T-116 | Honestidad del escáner: `locator-hygiene.sh` devuelve "limpio" sobre un directorio que no es repo (`git ls-files` falla → lista vacía) y no ve ficheros sin trackear; cerrar ambos huecos + ampliar el check 22 | Bug del sistema | S | ⬜ Pendiente | — | [.agents/tasks/task-116.md](.agents/tasks/task-116.md) |

## Notas de planning

- **Origen**: `/sprint-planning` 2026-10-27 sobre `main` en `v1.14.0` recién publicado (`cdb1566`, tag `v1.14.0`). Sin spillover: sprint-18 cerró 5/5.
- **Tema**: versiones. Los cuatro frentes comparten una sola clase de fallo: una cifra de versión (o un veredicto de "limpio") que se afirma sin haberla verificado.
- **Higiene previa ejecutada**: 3 ideas archivadas con `git mv` cuyas tareas ya cerraron (T-108, T-109, T-110 — se escaparon en sus cierres); línea del wrapper portable marcada `✅` en el roadmap; `last-sync.md` del core actualizado (seguía diciendo sprint-18).
- **Caso real que origina T-113**: al promover el sprint-18, `VERSION` seguía en `1.12.0` dos releases después. `close-sprint.sh` ya extrae la versión del changelog (`VERSION_TAG`, líneas 112-122) y la usa en el mensaje del commit, pero nunca escribe `VERSION`.
- **Dependencias**: T-113 y T-115 son secuenciales solo por el número de check (T-115 reserva el 31). T-114 y T-116 son independientes y tocan ficheros distintos (`update-changelog.sh` / `locator-hygiene.sh`).
- **Lo que este sprint NO hace**: T-111 (manifest regenerable) y `bytebox-curator` siguen en `## Backlog`; REA/MCP queda capturada para evaluación aparte; credenciales revocadas sigue ⛔ BLOQUEADO hasta el veredicto sobre `CLOUDFLARE_API_TOKEN`; ningún dashboard ni consulta de red en la vista de flota.
- **Ritual**: planning + research + contratos primero; cada plan de tarea espera `APROBADO` explícito antes de tocar código.
