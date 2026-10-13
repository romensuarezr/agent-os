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

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/close-task.sh`
- `scripts/agent/close-sprint.sh`
- `tests/validate-control-plane.sh`
- `changelog.md`
- `docs/sprints/sprint-15-core.md`
- `.agents/tasks/task-100.md`

## Criterios de done
- [ ] Reproducidos ambos fallos antes del fix, con evidencia registrada en este task file.
- [ ] `close-task.sh` actualiza el enlace de la fila al archivar, de forma idempotente y verificable.
- [ ] `close-task.sh` conserva la búsqueda de tres niveles (activo, `_archived/`, fallback).
- [ ] `close-sprint.sh` stagea solo sus propios ficheros y avisa de los ajenos.
- [ ] Ambos validan el commit con `git diff-tree` **antes** de mover el ref.
- [ ] Si la validación falla, no queda ref nuevo creado ni estado a medias.
- [ ] Documentado que `update-ref` no dispara los hooks de git.
- [ ] Suite de control plane sin regresiones, con los nuevos checks de regresión añadidos.
- [ ] `git diff --name-only` ⊆ Caja.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente