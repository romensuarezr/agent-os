---
description: Este flujo se usa cuando la tarea está terminada, validada y lista para archivarse o integrarse.
---

# session-close

Cierre formal de una sesión de trabajo en {{PROJECT_NAME}}.

Este flujo se usa cuando la tarea está terminada, validada y lista para archivarse o integrarse.
No se usa para seguir implementando cambios nuevos.

## Objetivo

- Cerrar el trabajo activo de forma limpia.
- Dejar registrado lo que cambió y lo que queda pendiente.
- Archivar la tarea activa.
- Actualizar el sprint activo y archivarlo si está completado.
- Actualizar changelog.md al cerrar un sprint.
- Eliminar locks y temporales de sesión.
- Dejar el repositorio listo para revisión, PR o integración según la política del proyecto.

## Archivos y rutas a revisar

Revisa solo las rutas genéricas o configurables que existan en el proyecto:

- `.agent-session.lock`
- `docs/sprints/`
- `docs/sprints/_archived/`
- `.agents/tasks/`
- `.agents/tasks/_archived/`
- `docs/adrs/`
- `scripts/`
- `changelog.md`

Si existen otros artefactos temporales o de validación, deben quedar:
- archivados en una ruta oficial,
- documentados,
- o eliminados antes del cierre.

## Protocolo

### 1. Confirmar el cierre
- Verifica que la tarea está terminada.
- Confirma que no quedan cambios funcionales pendientes.
- Si hay dudas abiertas, no cierres todavía.

### 1b. Automejora y Destilación Procedimental (Self-Reflection)
> Conforme a la regla global `.agents/rules/global/self-improvement-distillation.md`. El conocimiento procedimental, los gotchas resueltos y las secuencias operativas novedosas nunca mueren en el transcript.

Antes de preparar la documentación de cierre, evalúa reflexivamente las 3 preguntas:
1. **¿Sufrí por alguna convención, truco o dependencia no documentada?**
2. **¿Encontré un gotcha o trampa técnica que el siguiente agente inevitablemente volverá a pisar?**
3. **¿Desarrollé una secuencia operativa o herramienta multi-paso reutilizable?**

**Si la respuesta a alguna es SÍ:**
- **Clasificar el hallazgo** según la Matriz de Destino Canónico:
  - Procedimiento multi-paso/tool recurrente (≥ 3x) → Propuesta de Skill (`.agents/skills/<nombre>/SKILL.md`) vía `creador-habilidades`.
  - Invariante o directiva universal → Propuesta de Regla (`.agents/rules/global/<regla>.md`) vía `rule-creator`.
  - Paso a paso operativo/infraestructura → Runbook (`docs/runbooks/<procedimiento>.md`).
  - Patrón incipiente (< 3x) → Entrada fechada en `docs/idea-inbox/YYYY-MM-DD-<nombre>.md`.
  - Corrección o aclaración a contrato existente → Edición in-situ directa del documento vivo (*retrospective* sin crear silos muertos de lecciones aprendidas).
- **Presentar propuesta al usuario** (QUÉ, POR QUÉ y DESTINO) y esperar confirmación antes de consolidar.

### 2. Preparar documentación (antes del script)
Antes de llamar al script de cierre, edita manualmente:
1. **`docs/sprints/sprint-{{SPRINT_ACTIVE}}.md`** — marca la tarea como `✅ Completada` en la tabla.
2. **`.agents/tasks/task-XXX.md`** — marca el criterio `- [ ] Sesión cerrada correctamente` como `- [x]`.
3. **Si el sprint queda completado al 100%** — actualiza la sección `## Estado` del sprint a `✅ Completado`.

> **⚠️ Importante:** El script `close-task.sh` verifica que la tarea esté marcada como `✅ Completada`
> en el sprint antes de permitir el commit. Si no está marcada, el script bloqueará con error.
> Para saltarte la guardia en casos excepcionales: `SKIP_SPRINT_CHECK=1 bash scripts/agent/close-task.sh`

**Verificación lazy-planning:** Antes de ejecutar el script, confirma que el campo
`📂 ARCHIVOS LEÍDOS` del plan aprobado (Fase 3.5) coincide con el límite
declarado en el pre-flight de Fase 2 / Fase 3.5. Si hubo una violación no resuelta, añádela
como nota en el task file bajo `## Notas de sesión` antes de archivar:

```markdown
## Notas de sesión
- ⚠️ VIOLACIÓN LAZY-PLANNING: se leyeron [archivos] sin autorización previa.
  Continuó con autorización del usuario en [fecha].
```

No ejecutes `git add` ni `git status` manualmente. El script lo gestiona.

### 3. Cierre atómico con script
Ejecuta **un único comando**:

```bash
bash scripts/agent/close-task.sh
```

El script lee la rama activa, deriva automáticamente el TASK_ID y el mensaje de commit desde el nombre de la rama (formato esperado: `feat/T-026-descripcion`), verifica que la tarea está marcada como completada en el sprint, archiva el task file en `.agents/tasks/_archived/` con `git mv`, realiza un único commit atómico y elimina `.agent-session.lock` si existe.

**No ejecutes `git status`, `git add` ni `git commit` por separado.** Todo va en el mismo commit atómico.

Si el script falla:
- `❌ No se puede derivar el TASK_ID` → la rama no sigue el formato `feat/T-XXX-descripcion`.
- `❌ No encontrado: task-XXX.md` → el task file ya fue archivado o el ID es incorrecto.
- `❌ Nada en stage` → todos los cambios ya estaban commitados; revisa con `git log --oneline -3`.
- `⚠️ GUARDIA SPRINT` → la tarea no está marcada como `✅ Completada` en el sprint activo; edita el sprint primero.

### 3b. Qué le pasa a tu worktree (T-107)

**Cerrar la sesión no toca tu worktree.** El commit y el archivado no integran nada
ni borran nada: tu rama y tu checkout siguen exactamente donde estaban. Integrar
y limpiar son pasos separados y explícitos:

| Acción | Qué hace con tu trabajo | Cuándo usarla | Qué implica |
|---|---|---|---|
| Cerrar sesión (`close-task.sh`) | Commit + archiva el task. No integra, no borra | Siempre, al terminar | Tu rama sigue existiendo; el worktree sigue en disco |
| `worktree-merge.sh --task-id <ID> --target <BASE>` | Verifica (`verify-goal.sh`), integra en la base y **desmonta** el worktree (remove + prune + borra la rama efímera) | El worker terminó y el judge dio PASS | La rama efímera desaparece; el trabajo vive en la base |
| `promote-to-main.sh --source <RAMA>` | Integra una rama en `main` (`--ff-only` por defecto) con push opcional. **No desmonta worktrees** | La rama ya está en la base y debe publicarse en `main` | Requiere gate humano para `--push`; el worktree se purga después con `worktree-gc.sh --apply` |
| `worktree-gc.sh --apply` | Purga huérfanos (rama ya mergeada, metadata colgada). Nunca toca el checkout principal, bloqueados ni sucios | Limpieza periódica o al ver `git worktree list` con restos | Solo efímeros (exención L2 acotada); lo sucio se queda |

Regla mnemotécnica: **cerrar archiva, merge integra, promote publica, gc limpia.** Si al cerrar tu `git worktree list` muestra restos de tareas ya integradas, purgarlos con `worktree-gc.sh --apply` forma parte del cierre.

### 4. Archivar el sprint + actualizar CHANGELOG (si sprint completado al 100%)

Después del commit de cierre de tarea, verifica si el sprint activo quedó completado al 100%.
Si es así, ejecuta **en este orden**:

```bash
# 1. Genera la entrada de changelog (NO commitea — solo modifica changelog.md)
bash scripts/agent/update-changelog.sh sprint-{{SPRINT_ACTIVE}}

# 2. Archiva el sprint e incluye changelog.md en el mismo commit
bash scripts/agent/close-sprint.sh sprint-{{SPRINT_ACTIVE}}
```

El flujo completo es:
- `update-changelog.sh` lee los commits del sprint, clasifica por tipo (Conventional Commits),
  inserta una nueva sección `## [vX.Y.Z] — sprint-{{SPRINT_ACTIVE}} — YYYY-MM-DD` en `changelog.md`
  y sugiere el bump de versión semver (major si hay breaking, minor si hay feat, patch si solo fix).
- `close-sprint.sh` verifica que todas las tareas están `✅ Completada`, mueve el sprint a
  `docs/sprints/_archived/` con `git mv`, sincroniza `VERSION` con la release del changelog
  (T-113: la primera cabecera **con semver**, aunque haya `## [Unreleased]` delante; si el
  changelog no cambió en este cierre, avisa y no toca `VERSION`), hace `git add changelog.md
  VERSION` y commitea todo junto:

```bash
git commit -m "chore: archive sprint-{{SPRINT_ACTIVE}} [vX.Y.Z]"
```

> **✔️ Regla:** Los sprints en `docs/sprints/` son activos o en curso.
> Los sprints completados deben vivir en `docs/sprints/_archived/`.
> Nunca archives un sprint parcialmente completado.

### 5. Auditar el MVP-TRACKER (si la sesión tocó capacidades MVP)

Este paso es obligatorio si la tarea cerrada implementó o modificó alguna capacidad
listada en `docs/MVP-TRACKER.md`.

**¿Cuándo ejecutarlo?**
- Si el task file de la sesión menciona alguna capacidad del tracker.
- Si vas a ejecutar `update-mvp-tracker.sh` a continuación.

**Paso obligatorio antes de `update-mvp-tracker.sh`:**

```bash
# Modo rápido: solo greps (~3 segundos)
bash scripts/agent/audit-mvp-tracker.sh --fast
```

Revisar la salida:
- `✅ VERIFICADO` — el símbolo existe en el scope esperado.
- `⚠️ FALSO POSITIVO` — el símbolo no está en el código. **No actualices el porcentaje
  de esa capacidad hasta implementarlo.** Corrige el criterio en el tracker primero.

Solo tras resolver todas las advertencias `⚠️`, ejecuta:

```bash
bash scripts/agent/update-mvp-tracker.sh
```

### 6. Detectar qué documentación adicional debe cerrarse
- Si la sesión generó ADRs, revísalos en `docs/adrs/`.
- Si generó scripts reutilizables, revísalos en `scripts/`.
- Si hay documentación adicional que commitear, hacer un commit separado con `git add <archivo> && git commit -m "docs: ..."`.

### 7. Verificación final
- Ejecuta `git status` una sola vez para confirmar que el árbol está limpio.
- Resume el cierre en una nota breve.

## Reglas

- No abrir trabajo nuevo durante el cierre.
- No dejar locks, temporales o scratch sin clasificar.
- **No ejecutar `git add` ni `git commit` manualmente durante el cierre de tarea — usar siempre `close-task.sh`.**
- **El archivado del sprint (`close-sprint.sh`) va en un commit separado tras el commit de tarea.**
- **`update-changelog.sh` siempre antes de `close-sprint.sh` si el sprint tiene feat: o fix:.**
- **`audit-mvp-tracker.sh --fast` siempre antes de `update-mvp-tracker.sh` si la sesión tocó capacidades MVP.**
