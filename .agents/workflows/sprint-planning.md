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
- `CHANGELOG.md`

## Prerrequisitos
- `ROADMAP.md` en la raíz del proyecto (mayúsculas exactas).
- Antigravity en modelo **Flash** (es lectura y planificación, no código).

---

## Protocolo

### 1. Detección de sesión colgada y archivado de sprints completados

```bash
bash scripts/agent/check-session.sh
bash scripts/agent/close-sprint.sh --auto
```

- Si `check-session.sh` devuelve un JSON → hay una sesión anterior sin cerrar. Ejecutar el **Modo Rescate** de `/session-start` antes de continuar.
- `close-sprint.sh --auto` detecta y archiva en `docs/sprints/_archived/` cualquier sprint cuyo estado sea `✅ Completado`. Si no hay ninguno, continúa sin error.

### 1b. Verificación de actualización del core (offline)

1. Comprobar si existe `.agents/context/last-sync.md`.
2. Si **NO existe** o la fecha es de hace **más de 7 días**: recomendar al usuario ejecutar:
   ```bash
   bash scripts/agent/sync.sh .
   ```

### 2. Lectura de estado

```bash
bash scripts/agent/check-sprint.sh
```

**Usar exclusivamente el output de este script como fuente de verdad.** No ejecutar `find`, `ls` ni leer sprint files manualmente.

- `❌ CRÍTICO` en ROADMAP → detenerse e informar al usuario.
- **Alerta "SPRINT COMPLETADO SIN MARCAR"** → actualizar estado del sprint anterior a `✅ Completado` antes de continuar. Obligatorio.
- Entradas en `SPILLOVER` → ir al paso 2b.
- Sistema limpio → ir directamente al paso 3.

Leer `ROADMAP.md` completo tras ejecutar el script.

### 2b. Decisión sobre tareas incompletas (solo si hay sin ✅)

> No arrastrar por inercia — decisión explícita por cada una.

**Tabla maestra de decisión** (aplica tanto a spillover como a inventory check en 2c):

| Avance | En spillover (2b) | En inventory check (2c) |
|---|---|---|
| **>70%** | Arrastra al sprint nuevo como S con nota `↩ continuación sprint anterior` | Marcar `✅ Hecho` en roadmap; no entra al sprint |
| **30–70%** | Preguntar al usuario: ¿arrastra o vuelve al roadmap? | Preguntar al usuario si refinar la tarea para lo que falta |
| **<30%** | Vuelve al roadmap como ⬜ Pendiente | Proceder normalmente |

Al cerrar el sprint anterior:
- Cambiar su estado de `🟡 En curso` a `🔴 Cerrado con pendientes`.
- Añadir una línea en `## Notas de planning` explicando qué quedó sin hacer y por qué.

**El agente presenta la propuesta al usuario y espera confirmación antes de escribir nada.**

### 2c. Verificación de código — firewall anti-duplicación

> Ejecutar siempre que haya tareas `⬜ Pendiente` o `⏸ Pausada` candidatas al nuevo sprint.
> **Objetivo: evitar que llegue al sprint trabajo que ya está hecho.**

**Paso previo obligatorio — leer el registro de features:**

Antes de ejecutar `inventory-check.sh`, leer `CHANGELOG.md`.
Si la feature candidata ya aparece → **no entra al sprint, marcar `✅ Hecho` en roadmap directamente**.

Para cada tarea candidata que NO aparezca en `CHANGELOG.md`:

1. **Ejecutar inventory check:**
   ```bash
   bash scripts/agent/inventory-check.sh "keywords de la tarea"
   ```

2. **Leer los archivos marcados con ⚠️** (máx. 3–5). Comparar con criterios de done del task file si existe.

3. **Clasificar usando la tabla maestra del paso 2b** (columna “En inventory check”).

4. **Presentar tabla al usuario** con: tarea, fuente, archivos encontrados, % estimado, acción propuesta.

5. **Esperar confirmación antes de continuar al paso 3.**

> 💡 **Optimización de tokens:** El agente solo lee los archivos que devuelve el inventory check, no navega `src/` manualmente.

### 3. Vaciado de inboxes priorizando MVP

Todo lo gestionado en los inboxes debe clasificarse como MVP o post-MVP antes de introducirlo en `ROADMAP.md`.

```bash
bash scripts/agent/check-inbox.sh
```

#### 3a. external-inbox (si hay entradas)
Para cada manifiesto listado, leer Origen, ¿Qué hace?, Archivos que toca, Prioridad y Precauciones. Luego:
1. Buscar en `src/` los archivos del campo "Archivos que toca" — ¿ya implementado?
2. Cruzar contra `ROADMAP.md` — ¿existe tarea que lo cubra? ¿Invalida alguna?
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
   Si devuelve archivos con ⚠️ (>3 KB existentes): clasificar como `⚠️ Parcialmente implementada` y preguntar qué falta.

2. Clasificar cada idea en:
   - **roadmap** → añadir al ítem correspondiente o crear ítem nuevo.
   - **backlog** → anotar en `## Backlog` del roadmap.
   - **descartar** → registrar como descartada con motivo.

#### Confirmación y escritura (una sola ronda)
Presentar tabla consolidada con todas las entradas y acciones propuestas. **Esperar confirmación antes de escribir o archivar nada.**

Una vez confirmado:
- Aplicar cambios en `ROADMAP.md`.
- Archivar procesados de `docs/idea-inbox/` en `docs/idea-inbox/_archived/`.
- Archivar procesados de `external-inbox/` en `external-inbox/_archived/`.

### 4. Generación del sprint file
Crear `docs/sprints/sprint-{{SPRINT_SIGUIENTE}}.md` con esta estructura:

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

```bash
bash scripts/agent/update-mvp-tracker.sh
```

El script recalcula el **% global** leyendo los valores de `% cap.` de `docs/MVP-TRACKER.md`.

Revisar manualmente si alguna capacidad requiere actualizar su `% cap.`:
- Leer `CHANGELOG.md` y el sprint recién cerrado.
- Actualizar valores en la tabla si el trabajo completado mueve el %.
- Ejecutar de nuevo `update-mvp-tracker.sh` para recalcular.
- Añadir fila en `## Historial de actualizaciones` con fecha, sprint y % global.

### 5. Generación del prompt para Perplexity

Antes de redactar, usar como fuente primaria el digest de `inventory-check.sh` si la señal de complejidad fue ≥2. Si fue baja, leer directamente los archivos más relevantes del código relacionado (máx. 3 archivos).

Producir un bloque listo para pegar en Perplexity:

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

> **Nota para el agente:** No ejecutes `/session-start` automáticamente. El usuario necesita hacer la investigación en Perplexity antes de continuar.

### 6b. Recepción de hallazgos de Perplexity (cuando el usuario vuelve)

1. Recibir el output de Perplexity del usuario.
2. Crear `docs/sprints/sprint-{{SPRINT_SIGUIENTE}}-research.md`:

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

2b. **Detección de repos de referencia**
Si el research incluye URLs de repositorios GitHub:
- Extraer cada URL y subcarpeta relevante si el usuario la especificó.
- Invocar la skill `investigar-repos-referencia` pasando esas URLs y la pregunta de investigación.
- El resultado enriquece el research.md añadiendo una sección `## Patrones de repos analizados`.
- Si `HF_API_TOKEN` no está configurado: listar los repos detectados e indicar al usuario que puede invocar la skill manualmente.

3. Confirmar: `"💾 Investigación guardada en docs/sprints/sprint-{{SPRINT_SIGUIENTE}}-research.md. Listo para /session-start."`

### 7. Entrega (resumen previo a la pausa)

Justo antes del mensaje de pausa del paso 6:
1. Resumen del estado del roadmap (3 líneas máximo).
2. Decisiones tomadas sobre tareas incompletas del sprint anterior (si las hubo).
3. Resultado de la verificación de código del paso 2c (tabla con evidencias).
4. Las tareas del sprint seleccionadas con su tamaño.
5. **Progreso MVP actualizado:**
   ```
   📊 Progreso MVP: XX%
      Capacidad 1                  ██████████ 100%
      Capacidad 2                  ████████░░  80%
      ...
   ```
6. El prompt para Perplexity listo para copiar.
7. Ruta del sprint file creado.

## Reglas

### Selección de Tareas
- **3 a 5 tareas** por sprint.
- Equilibrio de tamaños: no más de 1 tarea L por sprint.
- Prioridad: tareas arrastradas primero, luego bloqueantes, luego por orden del roadmap.
- Tamaños: **S** = < 1h, **M** = 1-3h, **L** = 3h+.
- **Solo entran tareas verificadas como no implementadas** (resultado del paso 2c).

### Escala de Progreso del MVP
- **0%**: Sin implementación.
- **25%**: Base iniciada, flujo principal no funcional.
- **50%**: Flujo principal funcional, casos edge pendientes.
- **75%**: Funcional y probado, falta pulido o un criterio menor.
- **100%**: Todos los criterios "Done para MVP" cumplidos y validados.

### Guardias de Flujo y Verificación
- **Limpieza previa**: Obligatorio ejecutar `check-session.sh` y resolver sesiones colgadas antes de iniciar.
- **Auditoría de completado**: Si `check-sprint.sh` alerta de un "sprint completado sin marcar", actualizar estado antes de generar el nuevo sprint.
- **Restricción de lectura**: Solo leer archivos devueltos por `inventory-check.sh`. Prohibido navegar `src/` manualmente.
