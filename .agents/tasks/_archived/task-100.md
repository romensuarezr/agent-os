# Task-100: Verificación post-condición en los scripts de cierre

## Objetivo
Que `close-task.sh` y `close-sprint.sh` no puedan afirmar una acción sin haberla verificado: `close-task.sh` actualizará el enlace de la fila del sprint al archivar el task file, y ambos validarán el commit **antes** de crear el ref, revirtiendo sin dejar estado a medias si el resultado no es el esperado.

## Contexto técnico
Ambos scripts comparten un modo de fallo: ejecutan la acción y reportan éxito sin comprobar que el efecto se materializó. Concreto, ya observado en producción:

- **close-task.sh**: hace `git mv` del task file a `_archived/` pero la fila del sprint
  sigue apuntando a `.agents/tasks/task-XXX.md`, dejando un enlace roto. Ocurrió en T-094,
  T-095, T-096 y T-098, parcheado a mano cuatro veces.
- **close-sprint.sh**: usa `git mv`, que mueve la versión **del índice**, no la del working
  tree, así que las modificaciones sin stagear quedan fuera del commit. En el cierre de
  sprint-14 el commit salió `0 insertions / 0 deletions` y las ediciones quedaron colgando.

**Asimetría que hay que corregir** (verificada en el código): `close-task.sh:149` usa
`git add -A`; `close-sprint.sh:128/140` usa `git mv` + `add "$CHANGELOG"` condicional. Solo el
primero recoge el working tree.

**Búsqueda del sprint file — preservar el fallback ya existente.** `close-task.sh:111-118`
implementa una búsqueda de tres niveles: activo (`docs/sprints/sprint-*.md`) → **archivado**
(`docs/sprints/_archived/sprint-*.md`) → fallback al sprint activo más reciente. El nivel 2
**no se elimina**: permite cerrar tareas cuyo sprint ya se archivó, y el research de Perplexity
recomienda buscar solo en el nivel superior, lo que reintroduciría ese bug. Se conserva la
estructura actual y solo se le añade idempotencia y post-verificación.

**Investigación de Perplexity (integrada, 2026-10-13)** — `docs/sprints/sprint-15-core-research.md`:
- *Validar antes, no revertir después*: construir el commit en un índice temporal con
  `git write-tree` + `git commit-tree`, validarlo con
  `git diff-tree -r --no-commit-id --name-status <sha>` y solo entonces mover el ref con
  `git update-ref`. Evita por completo `git reset --soft` y nunca deja el repo a medias.
- **Reescritura portable del enlace**: `awk` POSIX con `index()`/`substr()` (nunca
  `sed -i`, que difiere entre BSD y GNU) → temporal en el mismo directorio → `mv`.
  Idempotencia por `grep -q` previo y **post-verificación obligatoria** posterior al `mv`.
- **Casos límite asumidos**: `core.quotePath` entrecomilla rutas con espacios o no-ASCII;
  hooks `pre-commit` que alteran el árbol entre stage y commit; CRLF en Git Bash; tareas
  listadas como elemento de lista en vez de celda de tabla, que la búsqueda no encuentra.

**Staging acotado**: `close-sprint.sh` debe stagear **solo sus propios ficheros** (sprint,
research y changelog si cambió) y **avisar** de cualquier modificación ajena colgando.
Prohibido un `git add -A` del working tree en ese script.

## Evidencia de reproducción

Ambos fallos se reprodujeron antes de tocar el código, en repos desechables:

**(a) close-task.sh** — con la fila del sprint enlazada a `.agents/tasks/task-100.md`:
task file archivado correctamente pero el enlace seguía apuntando al directorio activo.

**(b) close-sprint.sh** — con una modificación sin stagear en el sprint file:
el commit resultó `1 file changed, 0 insertions(+), 0 deletions(-)` (rename puro) y la
modificación quedó colgando en el working tree.

Tras los fixes: el enlace resuelve a `_archived/` y el commit de cierre pasó a
`1 file changed, 3 insertions(+)`, con el árbol limpio.

**Falso positivo encontrado y corregido durante la verificación**: el aviso de cambios ajenos
de `close-sprint.sh` usaba un ancla `$` que solo excluía el directorio `docs/sprints/`
exacto, de modo que cualquier fichero dentro se anunciaba como ajeno en cada cierre.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/close-task.sh`
- `scripts/agent/close-sprint.sh`
- `tests/validate-control-plane.sh`
- `changelog.md`
- `docs/sprints/sprint-15-core.md`
- `.agents/tasks/task-100.md`

## Criterios de done
- [x] Reproducidos ambos fallos antes del fix, con evidencia registrada en este task file.
- [x] `close-task.sh` actualiza el enlace de la fila al archivar, de forma idempotente y verificable.
- [x] `close-task.sh` conserva la búsqueda de tres niveles (activo, `_archived/`, fallback).
- [x] `close-sprint.sh` stagea solo sus propios ficheros y avisa de los ajenos.
- [x] Ambos validan el commit con `git diff-tree` **antes** de mover el ref.
- [x] Si la validación falla, no queda ref nuevo creado ni estado a medias.
- [x] Documentado que `update-ref` no dispara los hooks de git.
- [x] Suite de control plane sin regresiones (19/19), con los nuevos checks de regresión añadidos.
- [x] `git diff --name-only` ⊆ Caja.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5) — APROBADO CON CAMBIOS: base de rama declarada + validar-antes + staging acotado + fallback _archived preservado
- [x] APROBADO recibido — fecha/hora: 2026-10-13T21:29:01+01:00
- [x] Rama creada: fix/T-100-close-scripts-honestos (desde main @ ae323e1)
- [x] Lock activo: `.agent-session.lock`
- [x] Sesión cerrada correctamente