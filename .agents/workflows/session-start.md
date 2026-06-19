---
description: Inicia una sesión de desarrollo. Detecta sesiones colgadas, selecciona la tarea activa, declara la Caja de archivos y activa el modo ejecución.
---

# session-start

> Ejecutar al inicio de cada sesión, antes de escribir cualquier línea de código en {{PROJECT_NAME}}.

## Objetivo

- Iniciar formalmente una sesión de desarrollo identificando la tarea activa.
- Declarar y configurar la Caja de archivos autorizados.
- Crear el archivo de lock `.agent-session.lock` y preparar el entorno de ejecución.

## Archivos y rutas a revisar

- `.agent-session.lock`
- `docs/sprints/`
- `.agents/tasks/`

## Protocolo

### FASE 0 — Detección de sesión anterior (Modo Rescate)

```bash
bash scripts/agent/check-session.sh
```

- `NO_ACTIVE_SESSION` → ir a Fase 1.
- **JSON devuelto** → sesión sin cerrar. Leer `task`, `sprint`, `opened`. Avisar: `"⚠️ Sesión anterior sin cerrar: [task] desde [opened]. Preparando cierre para aprobación."` No commitear aún. Reflejar rescate en el plan. Continuar a Fase 1.

### FASE 1 — Lectura de contexto

1. Leer sprint file más reciente en `docs/sprints/`.
2. **Comprobar tareas `🟡 En curso`:** si existe alguna, mostrar alerta y esperar confirmación:
   ```
   ⚠️ La tarea [T-XXX] quedó en estado 🟡 En curso en la sesión anterior.
   Opciones:
     A) Retomarla (marcarla como tarea activa)
     B) Marcarla como ✅ Hecho si ya está completada
     C) Marcarla como ⏸ Pausada y continuar con la siguiente pendiente
   ¿Qué hacemos?
   ```
   No continuar hasta recibir respuesta explícita.
3. Identificar primera tarea `⬜ Pendiente` o `⏸ Pausada`. Mostrar: `"Tarea activa: [T-XXX] — [descripción]"`.

> ⚠️ **Una sola tarea activa por sesión.** El task file identificado aquí (ej: `task-029.md`) es el **Único** que puede leerse durante las Fases 0–2. Cualquier otro task file del sprint está **prohibido** hasta después de la aprobación del plan. Leerlos antes constituye una **violación lazy-planning**.

**Sin tareas pendientes:** mostrar y detenerse:
```
✅ Sprint {{SPRINT_ACTIVE}} completado. Ejecuta /sprint-planning para continuar. Cambia el selector de modelos a uno superior (Opus, Sonnet, Gemini Pro) y luego vuelve al Flash.
```

**Petición nueva sin task file:** informar `"Requiere planificación."` Sugerir `/sprint-planning`. No leer archivos ni preparar planes.

### FASE 2 — Creación o carga del task file

1. Comprobar `.agents/tasks/task-XXX.md`.
2. **Si no existe**, buscar en `_archived/`:
   - Encontrado → preguntar: `"⚠️ [T-XXX] archivada. ¿Regresión, re-apertura o error?"` Esperar respuesta.
     - Regresión → restaurar, marcar `⏸ Pausada` en sprint file.
     - Re-apertura → restaurar, limpiar estado previo.
     - Error → volver a Fase 1.
   - No encontrado → crear con `doe-framework` desde `_template.md`.

> 🔒 **LÍMITE FASE 2**: Solo leer documentos de planificación del task activo. Ver lista completa de prohibiciones en FASE 3.5.

3. **Investigación previa:** buscar `docs/sprints/sprint-{{SPRINT_ACTIVE}}-research.md`.
   - Existe → integrar en `## Contexto técnico` del task file. Informar: `"📚 Research integrado."`
   - No existe → preguntar `"¿Tienes investigación previa de Perplexity? (S/N)"`. Si S → pegar y guardar en `sprint-{{SPRINT_ACTIVE}}-research.md`. Si N → continuar.

> ⚠️ Completar el task file **no autoriza la ejecución**. La única autorización es el APROBADO en Fase 3.5.

### FASE 3 — Declaración de la Caja

1. Leer `## Caja de archivos` del task file y mostrar archivos autorizados.
2. Identificar skill relevante. No activarla aún.

### FASE 3.5 — Plan para aprobación (OBLIGATORIA Y BLOQUEANTE)

El agente DEBE generar y mostrar el siguiente bloque completo **antes de realizar cualquier acción operativa**. Este bloque es obligatorio. No hay excepción posible.

El bloque debe aparecer exactamente con esta estructura y el token `⏳ ESPERANDO` al final:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔐 PLAN PENDIENTE DE APROBACIÓN — T-XXX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 TAREA: [nombre de la tarea]
🌿 RAMA PROPUESTA: feat/T-XXX-descripcion-corta

📁 ARCHIVOS QUE SE VAN A MODIFICAR:
  - src/ruta/archivo1.ts  → [qué se cambia y por qué]
  - src/ruta/archivo2.tsx → [qué se cambia y por qué]

🆕 ARCHIVOS NUEVOS: verificar existencia con `test -f` antes de crear.
⛔ Si >500 bytes: cambiar "crear" por "extender/revisar" y presentar plan corregido.

📌 PASOS DEL PLAN (en orden):
  1. [paso concreto]
  2. [paso concreto]
  3. [paso concreto]

⚠️  RIESGOS DETECTADOS:
  - [riesgo real con impacto estimado — omitir si no hay ninguno genuino]

⏳ ESPERANDO: responde APROBADO, APROBADO CON CAMBIOS: [...] o CANCELAR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### Prohibiciones absolutas hasta recibir APROBADO

- ❌ Crear `.agent-session.lock`
- ❌ Crear o cambiar de rama (`git checkout`, `git branch`)
- ❌ Editar, crear o borrar cualquier archivo del proyecto
- ❌ Ejecutar `git add`, `git commit`, `git push`
- ❌ Ejecutar `npm`, `yarn`, `pnpm` o cualquier comando que modifique estado
- ❌ `Searched for`, `Listed directory` o `Viewed` en código fuente (`src/`, `lib/`)
- ❌ `Listed directory` en `.agents/tasks/` o `.agents/tasks/_archived/`
- ❌ Leer `task-YYY.md` donde `YYY ≠ XXX` (tarea activa)
- ❌ Leer `SKILL.md`, `_template.md` u otros documentos de referencia estáticos

✅ Permitido: leer **exclusivamente** el task file activo (`task-XXX.md`), el sprint file y el research file.

Si el agente detecta que ha ejecutado cualquier acción operativa sin haber recibido `APROBADO`:
1. Detenerse inmediatamente.
2. Informar al usuario de qué ejecutó.
3. Proponer el rollback correspondiente.
4. Presentar el plan de nuevo y esperar aprobación.

#### Respuestas válidas del usuario
- `APROBADO` → ejecutar el plan tal cual
- `APROBADO CON CAMBIOS: [descripción]` → ajustar el plan y confirmar los cambios antes de ejecutar
- `CANCELAR` → cerrar la sesión sin ninguna acción

### FASE 4 — Apertura del lock

**Solo tras aprobación explícita.** Crear rama aprobada. Si está en `main`/`master` sin poder crearla: detenerse y avisar.

Crear `.agent-session.lock` con campos: `task`, `sprint`, `branch`, `opened` (ISO 8601), `status: open`, `approved_plan: true`, `authorized_files: [...]`.

El `branch` del lock debe coincidir con la rama de trabajo. Si no: detenerse hasta corregirlo.

Mostrar: `"🔒 Sesión abierta. Ejecución autorizada para [T-XXX]."`

### FASE 5 — Ejecución controlada

1. Activar skill relevante.
2. Ejecutar plan aprobado paso a paso.
3. Si hay que salir de la Caja o cambiar enfoque: detener, presentar mini-plan (mismo formato Fase 3.5), esperar nueva aprobación.

> Si completas todos los criterios de done antes de que el usuario lo indique: ver **Fase 5b** en Casos especiales.

### FASE 6 — Cierre de sesión

#### C1. Verificación de la Caja
`git diff --name-only` → comparar con `authorized_files`. Si hay archivos fuera: informar y esperar instrucción.

Durante el cierre: prohibido leer fuera de la Caja, preparar planes nuevos o analizar trabajo futuro. Si el usuario lanza una petición nueva, confirmar que está capturada en idea-inbox y proceder al cierre sin desviarse.

#### C2. Commit atómico
Usar siempre el script de cierre:
```bash
bash scripts/agent/close-task.sh T-XXX "tipo(scope): descripción del cambio"
```
El script hace `git add -A`, archiva el task file, realiza el commit atómico y elimina el lock. **No ejecutes `git add`, `git mv` ni `git commit` por separado.**

Prerequisito: edita `docs/sprints/sprint-{{SPRINT_ACTIVE}}.md` y `task-XXX.md` marcando la tarea como completada **antes** de llamar al script.

#### C3. Actualización del sprint file
- Completa → `✅ Hecho` | Incompleta → `⏸ Pausada` con nota.
- Editar **antes** de ejecutar `close-task.sh`.

#### C4. Actualización del task file
1. Marcar `- [x] Sesión cerrada correctamente` en `## Estado de aprobación`.
2. Guardar.
3. `close-task.sh` se encarga del `git mv` a `_archived/`. No lo hagas manualmente.

#### C5. Limpieza del idea-inbox
Mover ideas al sprint file solo si pertenecen a la tarea cerrada. Si la tarea se completó en Fase 5b, las ideas permanecen en `idea-inbox/` hasta el próximo `/sprint-planning`.

#### C5b. Archivado del research
Solo si **todas** las tareas del sprint quedan `✅ Hecho`:
```bash
bash scripts/agent/close-sprint.sh sprint-{{SPRINT_ACTIVE}}
```
El script archiva el sprint file y su research asociado en `docs/sprints/_archived/`.

#### C6. Borrar el lock
El script `close-task.sh` lo elimina automáticamente. Si por alguna razón persiste:
```bash
rm .agent-session.lock
```
Mostrar: `"✅ Sesión cerrada. Hasta la próxima."`

## Casos especiales

### Fase 5b — 🔴 BLOQUEADO (tarea completada)

Al completar todos los criterios de done:

1. Detener ejecución. No leer más archivos ni preparar planes.
2. Mostrar: `"✅ Tarea completada. ¿Confirmas commit y cierre?"`
3. Respuestas válidas: `sí, commitea` / `cierra` → Fase 6. `no, primero…` → escuchar sin actuar.
4. Petición nueva en el mismo mensaje: capturar en `docs/idea-inbox/YYYY-MM-DD.md`. Responder: `"💡 Capturada. Primero cierro. ¿Confirmas?"` No leer ni preparar nada nuevo.
5. Solo tras cerrar la sesión (Fase 6 completa) se puede `/session-start` para la petición nueva.

> ❌ **VIOLACIÓN CRÍTICA**: actuar sobre petición nueva antes de cerrar → detener, informar, proponer rollback.

## Reglas

### Contrato de trazabilidad de flujos (flow-bug-traceability)
Antes de cerrar cualquier tarea que corrija un bug en producción o modifique permisos/listeners/modelos de datos:
- Consultar `docs/critical-flows.md`
- Añadir el caso de borde detectado al flujo correspondiente
- Actualizar el estado de cobertura (⬜ / 🟡 / ✅)
- Incluir `docs/critical-flows.md` en el commit de cierre

### Protocolo de comunicación por fase
Durante Fases 4–6 aplica `silent-execution`. Ver `.agents/rules/global/silent-execution.md`.
