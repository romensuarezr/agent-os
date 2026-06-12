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
- Actualizar CHANGELOG.md al cerrar un sprint.
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
- `CHANGELOG.md`

Si existen otros artefactos temporales o de validación, deben quedar:
- archivados en una ruta oficial,
- documentados,
- o eliminados antes del cierre.

## Protocolo

### 1. Confirmar el cierre
- Verifica que la tarea está terminada.
- Confirma que no quedan cambios funcionales pendientes.
- Si hay dudas abiertas, no cierres todavía.

### 2. Preparar documentación (antes del script)
Antes de llamar al script de cierre, edita manualmente:
1. **`docs/sprints/sprint-{{SPRINT_ACTIVE}}.md`** — marca la tarea como `✅ Completada` en la tabla.
2. **`.agents/tasks/task-XXX.md`** — marca el criterio `- [ ] Sesión cerrada correctamente` como `- [x]`.
3. **Si el sprint queda completado al 100%** — actualiza la sección `## Estado` del sprint a `✅ Completado`.

> **⚠️ Importante:** El script `close-task.sh` verifica que la tarea esté marcada como `✅ Completada`
> en el sprint antes de permitir el commit. Si no está marcada, el script bloqueará con error.
> Para saltarte la guardia en casos excepcionales: `SKIP_SPRINT_CHECK=1 bash scripts/agent/close-task.sh`

**Verificación lazy-planning:** Antes de ejecutar el script, confirma que el campo
`📂 ARCHIVOS LEÍDOS` del plan aprobado (Fase 3.5) coincide con el checkpoint
lazy-planning declarado en Fase 2.5. Si hubo una violación no resuelta, añádela
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

### 4. Archivar el sprint + actualizar CHANGELOG (si sprint completado al 100%)

Después del commit de cierre de tarea, verifica si el sprint activo quedó completado al 100%.
Si es así, ejecuta **en este orden**:

```bash
# 1. Genera la entrada de changelog (NO commitea — solo modifica CHANGELOG.md)
bash scripts/agent/update-changelog.sh sprint-{{SPRINT_ACTIVE}}

# 2. Archiva el sprint e incluye CHANGELOG.md en el mismo commit
bash scripts/agent/close-sprint.sh sprint-{{SPRINT_ACTIVE}}
```

El flujo completo es:
- `update-changelog.sh` lee los commits del sprint, clasifica por tipo (Conventional Commits),
  inserta una nueva sección `## [vX.Y.Z] — sprint-{{SPRINT_ACTIVE}} — YYYY-MM-DD` en `CHANGELOG.md`
  y sugiere el bump de versión semver (major si hay breaking, minor si hay feat, patch si solo fix).
- `close-sprint.sh` verifica que todas las tareas están `✅ Completada`, mueve el sprint a
  `docs/sprints/_archived/` con `git mv`, hace `git add CHANGELOG.md` y commitea todo junto:

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
