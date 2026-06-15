---
description: Ritual de inicio de semana. Lee el roadmap, vacía el idea-inbox, genera el sprint file semanal y produce el prompt listo para investigación en Perplexity.
---

# sprint-planning

> Duración estimada: 15 min. Ejecutar los lunes antes de abrir cualquier sesión de desarrollo en {{PROJECT_NAME}}.

## Objetivo

- Analizar el roadmap del proyecto, vaciar los inboxes priorizando MVP y preparar las tareas del nuevo sprint.
- Sincronizar el progreso real del producto en `docs/MVP-TRACKER.md`.
- Generar el prompt de investigación técnica para Perplexity.

## Archivos y rutas a revisar

- `ROADMAP.md`
- `docs/sprints/`
- `docs/idea-inbox/`
- `external-inbox/`
- `docs/MVP-TRACKER.md`
- `docs/IMPLEMENTED.md`

## Prerrequisitos
- `ROADMAP.md` en la raíz del proyecto (mayúsculas exactas).
- Antigravity en modelo **Flash** (es lectura y planificación, no código).

---

## Protocolo

### 1. Detección de sesión colgada y archivado de sprints completados

Antes de cualquier otra acción, ejecutar en secuencia:

```bash
bash scripts/agent/check-session.sh
bash scripts/agent/close-sprint.sh --auto
```

- Si `check-session.sh` devuelve un JSON → hay una sesión anterior sin cerrar. Ejecutar el **Modo Rescate** de `/session-start` antes de continuar.
- `close-sprint.sh --auto` detecta y archiva en `docs/sprints/_archived/` cualquier sprint cuyo estado sea `✅ Completado`. Si no hay ninguno, continúa sin error.

### 1b. Verificación de actualización del core (offline)

Antes de continuar con la lectura de estado:
1. Comprobar si existe el archivo `.agents/context/last-sync.md`.
2. Si el archivo **NO existe** o si la fecha registrada en él es de hace **más de 7 días** respecto a la fecha actual:
   * Recomendar explícitamente al usuario ejecutar la sincronización del core de Agent OS ejecutando:
     ```bash
     bash scripts/agent/sync.sh .
     ```
   * Esto garantiza que el agente trabaje con la última versión de los scripts, reglas y habilidades globales.

### 2. Lectura de estado (con script — no navegación manual)

Ejecutar:
```bash
bash scripts/agent/check-sprint.sh
```

**Usar exclusivamente el output de este script como fuente de verdad.** No ejecutar `find`, `ls` ni leer sprint files manualmente para localizar el roadmap o el estado del sprint. El script ya resuelve rutas, conteo de tareas y advertencias.

- Si el script devuelve `❌ CRÍTICO` en ROADMAP → detenerse. Informar al usuario y no continuar.
- **Si hay alerta "SPRINT COMPLETADO SIN MARCAR"** → actualizar el estado del sprint anterior a `✅ Completado` antes de continuar. Esto es obligatorio.
- Si hay entradas en `SPILLOVER` → ir al paso 2b.
- Si el sistema está limpio → ir directamente al paso 3.

Leer `ROADMAP.md` completo tras ejecutar el script (la ruta exacta la da el script).

### 2b. Decisión sobre tareas incompletas

> Este paso se ejecuta solo si el sprint anterior tiene tareas sin ✅.
> No arrastrar por inercia — cada tarea incompleta requiere una decisión explícita.

Para cada tarea sin ✅ del sprint anterior, estimar el porcentaje completado y aplicar esta regla:

| Avance estimado | Destino | Acción |
|---|---|---|
| **> 70%** | Arrastra al sprint nuevo | Añadir como primera tarea, tamaño S, con nota `↩ continuación sprint anterior` |
| **< 30%** | Vuelve al roadmap | Marcar como ⬜ Pendiente en `ROADMAP.md`; no entra al sprint nuevo |
| **30–70%** | Decisión del usuario | Preguntar: ¿arrastra o vuelve al roadmap? Esperar respuesta antes de continuar |

Al cerrar el sprint anterior:
- Cambiar su estado de `🟡 En curso` a `🔴 Cerrado con pendientes`.
- Añadir una línea en `## Notas de planning` del sprint anterior explicando qué quedó sin hacer y por qué.

**El agente presenta la propuesta de decisión al usuario y espera confirmación antes de escribir nada.**

### 2c. Verificación de código — firewall anti-duplicación

> Este paso se ejecuta siempre que haya tareas con estado ⬜ Pendiente o ⏸ Pausada,
> tanto del sprint anterior como del roadmap candidatas al nuevo sprint.
> **Su objetivo: evitar que llegue al sprint trabajo que ya está hecho.**
> Es el firewall principal antes de que una tarea entre al sprint.

**Paso previo obligatorio — leer el registro de features:**

Antes de ejecutar `inventory-check.sh`, leer `docs/IMPLEMENTED.md`.  
Si la feature candidata ya aparece en ese archivo → **no entra al sprint, se marca directamente como `✅ Hecho` en el roadmap**. No hace falta ejecutar inventory-check para esa tarea.

Para cada tarea candidata que NO aparezca en `docs/IMPLEMENTED.md`:

1. **Ejecutar inventory check:**
   ```bash
   bash scripts/agent/inventory-check.sh "keywords de la tarea"
   ```
   Extraer 2-4 keywords de la descripción (ej: `"timeline propuesta respuesta modal"`).

2. **Leer los archivos marcados con ⚠️** que devuelva el script (máx. 3-5).
   - Si existe task file en `.agents/tasks/` o `_archived/`, leer sus criterios de done.
   - Comparar qué funcionalidad ya está cubierta vs. qué describe la tarea.

3. **Clasificar:**

| Resultado | Acción |
|---|---|
| ✅ en `docs/IMPLEMENTED.md` | Marcar `✅ Hecho` en roadmap; no entra al sprint. |
| ✅ >70% ya implementado (inventory) | Marcar `✅ Hecho` en el sprint anterior; no arrastrar. Informar al usuario con evidencia de archivo. |
| ⚠️ 30–70% implementado | Preguntar al usuario si refinar la tarea para lo que falta |
| ⬜ <30% o sin implementar | Proceder normalmente |

4. **Presentar tabla al usuario** con: tarea, fuente de verificación (IMPLEMENTED.md o inventory), archivos encontrados, % estimado, acción propuesta.

5. **Esperar confirmación del usuario antes de continuar al paso 3.**

> ⚠️ Especialmente importante cuando hay commits recientes sin task file asociado.
> El script `check-sprint.sh` incluye los últimos 10 commits — úsalos como punto de partida.

> 💡 **Optimización de tokens:** El agente solo lee los archivos que devuelve el inventory check,
> no navega `src/` manualmente. El script ya filtra por relevancia.

### 3. Vaciado de inboxes priorizando MVP
Todo lo que se gestione en los inboxes ha de ser primero clasificado como MVP o post-MVP antes de introducirlo en el ROADMAP.md.

Ejecutar:
```bash
bash scripts/agent/check-inbox.sh
```

El script reporta rutas exactas de manifiestos en `external-inbox/` y archivos en `docs/idea-inbox/`.

#### 3a. external-inbox (si hay entradas)
Para cada manifiesto listado, leer los campos Origen, ¿Qué hace?, Archivos que toca, Prioridad y Precauciones. Luego:
1. Buscar en `src/` los archivos del campo "Archivos que toca" — ¿ya implementado?
2. Cruzar contra `ROADMAP.md` — ¿existe tarea que lo cubra? ¿invalida alguna?
3. Clasificar:

| Resultado | Acción en roadmap |
|---|---|
| Ya implementado | Marcar `✅ Hecho`, no planificar |
| Cubre tarea existente | Enriquecer descripción con contexto del manifiesto |
| Nuevo, prioridad Alta | Añadir como tarea bloqueante |
| Nuevo, prioridad Media/Baja | Añadir al backlog |
| Invalida tarea planificada | Marcar `⚠️ Revisar`, preguntar al usuario |

> Los archivos de `external-inbox/` no se mueven ni borran hasta que el usuario lo apruebe.

#### 3b. idea-inbox (si hay entradas)

1. **Ejecutar inventory check ANTES de clasificar:**
   ```bash
   bash scripts/agent/inventory-check.sh "keywords de la idea"
   ```
   Si el script devuelve archivos con ⚠️ (>3 KB existentes):
   - La idea **no puede clasificarse como "nueva tarea de implementación"**.
   - Clasificar como `⚠️ Parcialmente implementada` y preguntar al usuario qué falta realmente.

2. Clasificar cada idea en:
   - **roadmap** → añadir al ítem correspondiente en `ROADMAP.md` o crear ítem nuevo.
   - **backlog** → anotar en sección `## Backlog` del roadmap.
   - **descartar** → registrar como descartada con motivo en una línea.

#### Confirmación y escritura (una sola ronda)
Presentar al usuario una tabla consolidada con todas las entradas de ambos inboxes y las acciones propuestas.

**Esperar confirmación antes de escribir o archivar nada.**

Una vez confirmado:
- Aplicar todos los cambios en `ROADMAP.md`.
- Archivar archivos procesados de `docs/idea-inbox/` en `docs/idea-inbox/_archived/`.
- Archivar archivos procesados de `external-inbox/` en `external-inbox/_archived/`.

### 4. Generación del sprint file
Crear `docs/sprints/sprint-{{SPRINT_SIGUIENTE}}.md` (incrementar número respecto al último existente — usar el valor `SPRINT_SIGUIENTE` del script) con esta estructura:

```markdown
# Sprint {{SPRINT_SIGUIENTE}} — [fecha lunes] → [fecha viernes]

## Estado
🟡 En curso

## Tareas
| ID | Descripción | Tamaño | Estado | Task file |
|---|---|---|---|---|
| T-001 | [descripción] | S/M/L | ⬜ Pendiente | — |

## Notas de planning
[Observaciones del sprint anterior, dependencias, riesgos]
```

### 4b. Actualización del MVP Tracker

> Este paso se ejecuta siempre, justo después de generar el sprint file.
> Su objetivo: mantener el progreso hacia MVP sincronizado con el estado real del producto.

Ejecutar:
```bash
bash scripts/agent/update-mvp-tracker.sh
```

El script recalcula el **% global** leyendo los valores de `% cap.` de la tabla en `docs/MVP-TRACKER.md` y actualiza la fila `TOTAL` y el historial automáticamente.

**A continuación, revisar manualmente si alguna capacidad requiere actualizar su `% cap.`:**

- Leer `docs/IMPLEMENTED.md` y el sprint recién cerrado.
- Para cada capacidad, evaluar si el trabajo completado desde el último planning mueve el % de esa capacidad.
- Actualizar los valores en la tabla de `docs/MVP-TRACKER.md` si procede.
- Ejecutar de nuevo `update-mvp-tracker.sh` para recalcular el total con los valores actualizados.
- Añadir una fila en la tabla `## Historial de actualizaciones` con fecha, sprint y % global resultante.

### 5. Generación del prompt para Perplexity

Antes de redactar el prompt, usar como fuente primaria el digest generado por `inventory-check.sh` si la señal de complejidad fue ≥2 (el script lo genera automáticamente). Si la señal fue baja, leer directamente los archivos más relevantes del código relacionado con la tarea principal (máx. 3 archivos).
Objetivo: identificar qué ya está implementado o parcialmente resuelto para no investigar desde cero. El resultado de esta lectura alimenta la sección `SITUACIÓN ACTUAL` del prompt.

Producir un bloque de texto listo para pegar en Perplexity con este formato:

```
CONTEXTO: Estoy desarrollando [descripción de {{PROJECT_NAME}} en 2 líneas].
STACK: [Describe el stack tecnológico principal].
SITUACIÓN ACTUAL: [qué ya existe en el código relacionado con la tarea:
helpers implementados, patrones ya en uso, deuda técnica conocida].
TAREA DE ESTA SEMANA: [descripción de la tarea principal del sprint]
NECESITO INVESTIGAR: [pregunta específica de investigación]
FORMATO DE RESPUESTA ESPERADO: [lo que necesitas: comparativa, ejemplo
de código, decisión de arquitectura, etc.]
```

### 6. Pausa y handoff a /session-start

Mostrar al usuario el siguiente mensaje y **no continuar hasta recibir respuesta**:

```
✅ Sprint {{SPRINT_SIGUIENTE}} listo. Prompt de Perplexity generado.

👉 Próximos pasos:
   1. Copia el prompt del paso anterior y pégalo en Perplexity.
   2. Cuando tengas los hallazgos, vuelve con la investigación, cambia el selector de modelo a Gemini Flash y ejecuta /session-start
      pegando los hallazgos — el agente los guardará en docs/sprints/sprint-{{SPRINT_SIGUIENTE}}-research.md
      y los integrará en el task file antes de empezar a codear.

⏸ Este workflow queda en pausa. Hasta luego.
```

> **Nota para el agente:** No ejecutes `/session-start` automáticamente. El usuario necesita hacer la investigación en Perplexity antes de continuar. El handoff es intencional.

### 6b. Recepción de hallazgos de Perplexity (cuando el usuario vuelve)

> Este paso se ejecuta cuando el usuario regresa con los hallazgos de Perplexity, antes de lanzar `/session-start`.

1. Recibir el output de Perplexity del usuario.
2. Crear `docs/sprints/sprint-{{SPRINT_SIGUIENTE}}-research.md` con este formato:

```markdown
# Research Sprint {{SPRINT_SIGUIENTE}}
> Fuente: Perplexity — [fecha]
> Tarea principal: [descripción de la tarea del sprint]

## Hallazgos clave
[Decisiones técnicas, patrones elegidos, referencias]

## Decisiones tomadas
- **Decisión:** [patrón o solución elegida]
- **Por qué:** [razón en 1 línea]
- **Constraint clave:** [limitación técnica relevante]
- **Referencia:** [URL o doc si existe]

## Descartado
[Opciones exploradas y descartadas con motivo]
```

3. Confirmar al usuario: `"💾 Investigación guardada en docs/sprints/sprint-{{SPRINT_SIGUIENTE}}-research.md. Listo para /session-start."`

### 7. Entrega (resumen previo a la pausa)
Justo antes del mensaje de pausa del paso 6, mostrar al usuario:
1. Resumen del estado del roadmap (3 líneas máximo).
2. Decisiones tomadas sobre tareas incompletas del sprint anterior (si las hubo).
3. Resultado de la verificación de código del paso 2c (tabla con evidencias).
4. Las tareas del sprint seleccionadas con su tamaño.
5. **Progreso MVP actualizado** — mostrar en este formato exacto:
   ```
   📊 Progreso MVP: XX%
      Capacidad 1                  ██████████ 100%
      Capacidad 2                  ████████░░  80%
      ...
   ```
   Donde cada barra tiene 10 bloques (█ lleno, ░ vacío) proporcionales al % de la capacidad.
   Si alguna capacidad bajó desde el planning anterior, añadir ⚠️ junto a esa línea.
6. El prompt para Perplexity listo para copiar.
7. Ruta del sprint file creado: `docs/sprints/sprint-{{SPRINT_SIGUIENTE}}.md`.

## Reglas

### Selección de Tareas
- **3 a 5 tareas** por sprint.
- Equilibrio de tamaños: no más de 1 tarea L por sprint.
- Prioridad: tareas arrastradas del sprint anterior primero, luego ítems bloqueantes, luego por orden del roadmap.
- Tamaños: **S** = < 1h, **M** = 1-3h, **L** = 3h+.
- **Solo entran tareas verificadas como no implementadas** (resultado del paso 2c — ni en `docs/IMPLEMENTED.md` ni en inventory check).

### Escala de Progreso del MVP
Para la actualización manual de las capacidades en `docs/MVP-TRACKER.md`, aplicar esta escala:
- **0%**: Sin implementación.
- **25%**: Base iniciada, flujo principal no funcional.
- **50%**: Flujo principal funcional, casos edge pendientes.
- **75%**: Funcional y probado, falta pulido o un criterio menor.
- **100%**: Todos los criterios "Done para MVP" cumplidos y validados.

### Guardias de Flujo y Verificación
- **Limpieza previa**: Es obligatorio ejecutar `check-session.sh` y resolver sesiones colgadas antes de iniciar la planificación.
- **Auditoría de completado**: Si `check-sprint.sh` alerta de un "sprint completado sin marcar", es obligatorio actualizar el estado del sprint anterior a `✅ Completado` antes de generar el nuevo sprint.
- **Restricción de lectura**: El agente solo leerá los archivos devueltos por el script de `inventory-check.sh`. Está prohibido navegar o realizar búsquedas manuales sobre el directorio de código fuente `src/` para evitar consumos de tokens y asegurar la neutralidad.
