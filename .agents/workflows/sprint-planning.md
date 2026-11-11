---
description: Workflow ejecutable de planificación de sprint. Si este archivo es invocado o referenciado, el agente DEBE asumir de inmediato el rol de planificador y ejecutar secuencialmente los pasos 1 al 7 en orden estricto sin pausas pasivas.
---

# sprint-planning

> ⚡ **DIRECTIVA DE EJECUCIÓN INMEDIATA (AGNOSTIC RUNTIME)**:
> Si el usuario menciona este archivo (ej. `@[.agents/workflows/sprint-planning.md]`) o lanza el comando `/sprint-planning`,
> el agente **debe comenzar a ejecutar de inmediato el protocolo en orden estricto (Paso 1 → 7)**.
> **PROHIBIDO** responder preguntando «¿qué deseas hacer con este archivo?» o quedarse esperando instrucciones. La invocación ES la orden de ejecución.

> Duración estimada: 15 min. Ejecutar los lunes antes de abrir cualquier sesión de desarrollo en {{PROJECT_NAME}}.

## Objetivo

- Analizar el roadmap del proyecto, vaciar los inboxes priorizando MVP y preparar las tareas del nuevo sprint.
- Sincronizar el progreso real del producto en `docs/MVP-TRACKER.md` (satélites).
- Generar el prompt de investigación técnica para Perplexity o ejecutar SearXNG de forma autónoma.

### Regla de Oro de Gobernanza: El agente propone, el usuario solo confirma
1. El agente **NUNCA** formula preguntas abiertas de definición al usuario («¿qué tareas quieres hacer?», «elige entre estas opciones»).
2. El agente es el responsable de analizar el estado del proyecto, cosechar las fuentes (spillover, inboxes, backlog del roadmap) y formular en el Paso 7 una **propuesta estructurada y cerrada de 3 a 5 tareas** (IDs, títulos, tamaños S/M/L y justificación técnica).
3. Si el roadmap no tiene tareas desglosadas con ID para el sprint entrante, el agente toma el siguiente tema prioritario del roadmap y lo descompone de forma autónoma en 3–5 tareas atómicas (S/M/L).
4. La única interacción requerida del operador humano es emitir su veredicto en el Paso 7: `APROBADO` (autorización macro para régimen Desatendido) o enmiendas concretas («quita T-X y mete Y»).

## Arquetipo de Repositorio (Core vs. Satélite)
- **Si el proyecto es el Core de agent-os**:
  - No existe ni se busca `docs/MVP-TRACKER.md` (omitir Paso 4b).
  - El producto son los scripts en `scripts/agent/`, workflows y skills.
  - Las categorías canónicas de tareas son: `Universalización`, `Bug del sistema`, `Nueva herramienta`, `DX`, `Documentación`, `Gobernanza`.
  - La fuente principal de backlog es `roadmap.md` y `docs/idea-inbox/`.
- **Si el proyecto es un Satélite (aplicación de usuario)**:
  - Aplica `docs/MVP-TRACKER.md` para medir % funcional del producto.
  - Las tareas responden a features, UI, APIs y casos de uso del producto.

## Archivos y rutas a revisar

- `roadmap.md`
- `docs/sprints/`
- `docs/idea-inbox/`
- `docs/external-inbox/`
- `docs/MVP-TRACKER.md` (solo si el proyecto es satélite; el core no lo tiene)
- `changelog.md`

## Prerrequisitos
- `roadmap.md` en la raíz del proyecto. **La convención del core es minúsculas**: `audit-repo.sh` migra de forma proactiva los `ROADMAP.md` a `roadmap.md`, así que el requisito en mayúsculas estaba desalineado con el estándar que el propio core impone.
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

### 1c. Sonda determinista de automejora del tooling ($0 tokens)

Ejecutar la sonda determinista de actualización de herramientas de la flota:
```bash
bash scripts/agent/check-tooling-updates.sh --generate-inbox
```
- Inspecciona los registros oficiales (npm, GitHub, PyPI) de herramientas de la flota (OpenCode, Hermes, Orca, Infisical, Glances) a coste $0 de tokens de inferencia.
- Si detecta versiones upstream nuevas, genera automáticamente un borrador estructurado en `docs/idea-inbox/YYYY-MM-DD-<tool>-v<version>.md` con el estado `💡 REGISTRADA, NO APROBADA`.
- **Cero auto-ejecución**: no muta ni actualiza paquetes en caliente. La propuesta se clasifica en el Paso 3 y se somete a veredicto soberano del operador en el Paso 7.

### 2. Lectura de estado

```bash
bash scripts/agent/check-sprint.sh
```

**Usar exclusivamente el output de este script como fuente de verdad.** No ejecutar `find`, `ls` ni leer sprint files manualmente.

- `❌ CRÍTICO` en ROADMAP → detenerse e informar al usuario.
- **Alerta "SPRINT COMPLETADO SIN MARCAR"** → actualizar estado del sprint anterior a `✅ Completado` antes de continuar. Obligatorio.
- Entradas en `SPILLOVER` → ir al paso 2b.
- Sistema limpio → ir directamente al paso 3.

Leer `roadmap.md` completo tras ejecutar el script.

### 2b. Evaluación de spillover (tareas incompletas)

> No arrastrar por inercia — decisión técnica por cada una.

**Tabla maestra de decisión** (aplica tanto a spillover como a inventory check en 3c):

| Avance | En spillover (2b) | En inventory check (3c) |
|---|---|---|
| **>70%** | Proponer arrastrar al sprint nuevo como S con nota `↩ continuación sprint anterior` | Marcar `✅ Hecho` en roadmap; no entra al sprint |
| **30–70%** | Proponer arrastrar refinada o devolver al roadmap según criticidad | Proponer refinar la tarea para lo que falta |
| **<30%** | Proponer devolver al roadmap como ⬜ Pendiente | Proceder normalmente |

Al cerrar el sprint anterior:
- Si quedan tareas incompletas: cambiar su estado de `🟡 En curso` a `🔴 Cerrado con pendientes`.
- Añadir una línea en `## Notas de planning` explicando qué quedó sin hacer y por qué.
- Las tareas seleccionadas para arrastrar se incorporan como candidatas prioritarias en el Paso 3c.

---

### 3. Vaciado y clasificación de inboxes

Todo lo gestionado en los inboxes debe clasificarse como MVP o post-MVP antes de sintetizar las candidatas del sprint.

```bash
bash scripts/agent/check-inbox.sh
```

#### 3a. docs/external-inbox (si hay entradas)
Para cada manifiesto listado, leer Origen, ¿Qué hace?, Archivos que toca, Prioridad y Precauciones. Luego:
1. Buscar en `src/` o `scripts/` los archivos del campo "Archivos que toca" — ¿ya implementado?
2. Cruzar contra `roadmap.md` — ¿existe tarea que lo cubra? ¿Invalida alguna?
3. Clasificar:

| Resultado | Acción propuesta |
|---|---|
| Ya implementado | Marcar `✅ Hecho`, no planificar |
| Cubre tarea existente | Enriquecer descripción con contexto del manifiesto |
| Nuevo, prioridad Alta | Incorporar a candidatas prioritarias del sprint (Paso 3c) |
| Nuevo, prioridad Media/Baja | Añadir al backlog |
| Invalida tarea planificada | Marcar `⚠️ Revisar` en propuesta |

> Los archivos de `docs/external-inbox/` no se mueven ni borran hasta la aprobación en el Paso 7.

#### 3b. idea-inbox (si hay entradas)
1. Analizar las propuestas existentes en `docs/idea-inbox/`, incluyendo las recién capturadas por la sonda del Paso 1c (`check-tooling-updates.sh --generate-inbox`).
2. Evaluar pertinencia e impacto frente al hito actual del proyecto.
3. Clasificar cada idea en:
   - **candidata a sprint** → pasa a la cosecha del Paso 3c (proponer al operador formalizar como tarea técnica).
   - **backlog** → anotar en `## Backlog` del roadmap.
   - **descartar** → registrar motivo en el informe del Paso 7.

---

### 3c. Cosecha y Síntesis Determinista de Tareas Candidatas

> **Objetivo**: Formular autónomamente una propuesta cerrada de 3 a 5 tareas (S/M/L) listas para instanciación, aplicando salvaguardas anti-duplicación y prospección OSS antes de la investigación técnica.

#### 1. Algoritmo de Selección de Candidatas
El agente selecciona entre 3 y 5 tareas respetando este orden de prelación:
1. **Prioridad 1**: Tareas de spillover aprobadas para arrastre (del Paso 2b).
2. **Prioridad 2**: Manifiestos de alta prioridad de inboxes (Paso 3a/3b).
3. **Prioridad 3**: Siguiente hito o temas del `roadmap.md` (`## Próximo`).
   - *Desglose autónomo*: Si el roadmap no tiene tareas desglosadas con ID, el agente toma el siguiente tema prioritario del roadmap y lo descompone autónomamente en tareas atómicas con tamaño S, M o L.

#### 2. Firewall Anti-Duplicación (Inventory Check)
Para cada candidata seleccionada que plantee nueva lógica o scripts:
1. Comprobar `changelog.md`. Si la funcionalidad ya aparece → descartar de la propuesta y marcar `✅ Hecho`.
2. Ejecutar:
   ```bash
   bash scripts/agent/inventory-check.sh "keywords de la tarea"
   ```
   Leer los archivos marcados con ⚠️ (máx. 3–5). Si la lógica ya existe, ajustar o descartar la tarea.

#### 3. Salvaguarda de Prospección Determinista OSS (Scout-First)
Para cada candidata técnica o de nuevas herramientas:
1. Ejecutar prospección a coste $0:
   ```bash
   bash scripts/agent/scout.sh "keywords de la tarea o módulo"
   ```
2. Si detecta librerías maduras (≥500⭐, licencias permisivas MIT/Apache), recomendar su integración en vez de desarrollo a medida.
3. **Persistencia obligatoria en research (Gate Scout-First, T-129)**:
   Escribir o inicializar `docs/sprints/sprint-{{SPRINT_SIGUIENTE}}-research.md` con la sección `## Descubrimientos Scout (por tarea)`, incluyendo una subsección `### T-XXX` para cada tarea planificada (declarando alternativa o `Desarrollo a medida justificado`).

#### 4. Salida del Paso 3c
Tabla consolidada de las 3–5 tareas candidatas definitivas con sus dependencias preliminares y tamaños.
- Aplicar cambios en `roadmap.md`.
- Archivar procesados de `docs/idea-inbox/` en `docs/idea-inbox/_archived/`.
- Archivar procesados de `docs/external-inbox/` en `docs/external-inbox/_archived/`.

### 4. Generación del sprint file
Crear `docs/sprints/sprint-{{SPRINT_SIGUIENTE}}.md` con esta estructura:

```markdown
# Sprint {{SPRINT_SIGUIENTE}} — [fecha lunes] → [fecha viernes]

## Estado
🟡 En curso

## Tareas
| ID | Descripción | Tamaño | Estado | Dependencias | Task file |
|---|---|---|---|---|---|
| T-001 | [descripción] | S/M/L | ⬜ Pendiente | — | — |

## Régimen Operativo del Sprint
> Se sella en la primera sesión de /session-start tras consulta proactiva única al operador.
- **Régimen**: [PENDIENTE_ARRANQUE — Desatendida | Tarea a tarea (Clásico)]
- **Orden de Carriles (DAG de dependencias)**:
  - Carril 1: [T-001 → ...]
- **Sellado en**: [PENDIENTE]

## Notas de planning
[Observaciones del sprint anterior, dependencias, riesgos, decisiones macro aprobadas]
```

### 4a. Formalización y Sellado de Diseño Macro por Tarea (Nivel Macro de Gobernanza)

El sprint planning es el ritual **exclusivo y vinculante** donde el usuario humano evalúa y aprueba el diseño arquitectónico, límites de interfaces y alcance de cada tarea.
Para cada tarea incorporada a la tabla del sprint:
1. **Artefacto de aprobación de diseño**: Toda tarea debe instanciarse con la sección canónica `## Diseño macro aprobado en planning` rellenada en su task file (`.agents/tasks/task-XXX.md`):
   - `Sprint / Fecha`: referencia temporal y sprint al que pertenece.
   - `Diseño y arquitectura aprobados por`: `[Humano / Relé]`.
   - `Decisiones e interfaces selladas`: descripción concreta de interfaces pactadas, contratos de tipos, dependencias admitidas y guardarraíles técnicos acordados.
   - `Veredicto de diseño macro`: `[APROBADO_EN_PLANNING]`.
2. **Modelado de dependencias y carriles de ejecución**: En la tabla de tareas, la columna `Dependencias` explicita las precondiciones técnicas (IDs de tareas precedentes obligatorias o `—` si es independiente). A partir de la tabla, se deriva el grafo acíclico dirigido (DAG) y se proyecta la distribución en carriles de ejecución en la sección `## Régimen Operativo del Sprint` (ej. Carril 1: T-172 → T-173 → T-174; Carril 2: T-175; Carril 3: T-176).
3. **Reflejo en notas de planning**: Las decisiones arquitectónicas transversales del conjunto de tareas se resumen en `## Notas de planning` del sprint file.
4. **Invariante de desacoplamiento y handoff al arranque del sprint**: Una vez aprobado el sprint, el diseño macro de las tareas queda sellado. El planning prepara la propuesta de orden de carriles, dejando el régimen en `[PENDIENTE_ARRANQUE]`. Al arrancar el sprint en la primera sesión de `/session-start`, el flujo formula una **consulta proactiva única** al operador para sellar (1) el régimen operativo (`A) Desatendida` vs. `B) Tarea a tarea (Clásico)`) y (2) el camino de carriles. Si se sella el régimen **Desatendido** (anteriormente conocido por su alias histórico «Opción D»), el diseño macro actúa como la **única autorización habilitante** para que el agente encadene autónomamente las tareas en camino limpio sin volver al usuario entre ellas. En la posterior ejecución por tarea, el Revisor Ejecutor opera como compuerta técnica determinista (Nivel Micro) mediante `deliberate-plan.sh` y no reabre diseño; si se alcanzan las 5 condiciones del camino limpio (`CONSENSO`), la tarea se ejecuta, integra y cierra de forma 100% desatendida. Ante cualquier discrepancia técnica frente a esta sección, fallo en la verificación del relé de la tarea cerrada o veredicto no consensual, el sistema aborta de inmediato a fail-closed (`ESCALADO_A_HUMANO`) suspendiendo la autonomía y devolviendo el control al operador humano en el chat.

### 4b. Actualización del MVP Tracker

> Condicional: solo si el proyecto tiene `docs/MVP-TRACKER.md`. Si no existe (el core),
> omitir este paso — `update-mvp-tracker.sh` falla sin tracker (`exit 1`) y el core se
> versiona con `changelog.md`.

```bash
bash scripts/agent/update-mvp-tracker.sh
```

El script recalcula el **% global** leyendo los valores de `% cap.` de `docs/MVP-TRACKER.md`.

Revisar manualmente si alguna capacidad requiere actualizar su `% cap.`:
- Leer `changelog.md` y el sprint recién cerrado.
- Actualizar valores en la tabla si el trabajo completado mueve el %.
- Ejecutar de nuevo `update-mvp-tracker.sh` para recalcular.
- Añadir fila en `## Historial de actualizaciones` con fecha, sprint y % global.

### 5. Investigación técnica: bifurcación autónoma (SearXNG) / asistida (Perplexity)

> Protocolo unificado de investigación técnica profunda. Si SearXNG está disponible en la flota,
> ejecuta la investigación de forma 100% desatendida; si no, activa el fallback asistido con Perplexity.
> **Regla de oro: El fallback nunca es silencioso. Si se recurre a Perplexity, se declara explícitamente el motivo.**

1. **Comprobar disponibilidad de SearXNG:**
   ```bash
   bash scripts/agent/lib/searxng-client.sh --check
   ```
   Capturar el código de salida y la salida de diagnóstico (`exit 0` = activo; `exit 2` o error = inactivo/degradado).

2. **Bifurcación:**
   - **Si SearXNG está activo (`exit 0`):**
     - **Formulación de queries deterministas**: Para cada tarea del sprint que presente incertidumbre arquitectónica, integración de nueva librería o protocolo externo:
       ```bash
       bash scripts/agent/lib/searxng-client.sh --query "<stack> <tecnología/librería> <problema concreto>" --output "docs/sprints/sprint-{{SPRINT_SIGUIENTE}}-research.md"
       ```
     - **Bypass determinista para tareas puramente internas**: Si **todas** las tareas del sprint son de alcance interno (refactorización de scripts locales, workflows, reglas o documentación, con cero incertidumbre externa o de red):
       Declarar explícitamente en `docs/sprints/sprint-{{SPRINT_SIGUIENTE}}-research.md`:
       > *Investigación web externa no requerida: tareas de alcance puramente interno/core.*
       y avanzar directamente al Paso 7 sin llamadas superfluas a la red.
     - **Sin prompt de Perplexity ni bloqueo en pausa:** pasar directamente al **Paso 7 (Entrega y Aprobación del Sprint)**.
   - **Si SearXNG está inactivo (`exit 2` o fallo de red/configuración):**
     **Anuncio obligatorio y ruidoso**: El agente DEBE emitir en el chat el aviso explícito:
     ```
     ⚠️ AVISO DE FALLBACK: SearXNG inactivo o no disponible en la flota (código de salida: <RC>, diagnóstico: <salida de searxng-client.sh>).
     El fallback a investigación asistida nunca es silencioso: activando preparación de prompt de Perplexity Pro.
     ```
     Usar como fuente primaria el digest de `inventory-check.sh` si la señal de complejidad fue ≥2. Si fue baja, leer directamente los archivos más relevantes del código relacionado (máx. 3 archivos).
     Producir el bloque listo para pegar en Perplexity Pro:

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
     Continuar al Paso 6 (Pausa asistida).

### 6. Pausa asistida y handoff a /session-start (Solo si SearXNG estaba inactivo)

> **Condición**: Este paso se ejecuta **ÚNICAMENTE** si SearXNG estaba inactivo y se recurrió al fallback de Perplexity en el Paso 5.
> Si la investigación fue autónoma (SearXNG activo), este paso se omite por completo y el flujo avanza sin pausas.

Mostrar al usuario el siguiente mensaje y **no continuar hasta recibir respuesta**:

```
⚠️ Sprint {{SPRINT_SIGUIENTE}} preparado con fallback a Perplexity (SearXNG no disponible). Prompt generado.

👉 Próximos pasos:
   1. Copia el prompt del paso anterior y pégalo en Perplexity.
   2. Cuando tengas los hallazgos, vuelve con la investigación, cambia el selector de modelo a Gemini Flash y ejecuta /session-start
      pegando los hallazgos — el agente los guardará en docs/sprints/sprint-{{SPRINT_SIGUIENTE}}-research.md
      y los integrará en el task file antes de empezar a codear.

⏸ Este workflow queda en pausa asistida. Hasta luego.
```

> **Nota para el agente:** No ejecutes `/session-start` automáticamente cuando estés en pausa asistida. El usuario necesita realizar la investigación en Perplexity antes de continuar.

### 6b. Recepción de hallazgos de Perplexity (cuando el usuario vuelve de la pausa asistida)

1. Recibir el output de Perplexity del usuario.
2. Si `docs/sprints/sprint-{{SPRINT_SIGUIENTE}}-research.md` ya existe (creado por el paso 2e), **NO sobrescribirlo**: añadir las secciones de Perplexity (`## Hallazgos clave`, `## Decisiones tomadas`, `## Descartado`) sin tocar `## Descubrimientos Scout (por tarea)`. Si no existe, crearlo con esta estructura:

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
- Invocar la skill `buscar-codigo-en-github` pasando esas URLs y la pregunta de investigación.
- El resultado enriquece el research.md añadiendo una sección `## Patrones de repos analizados`.
- Listar los repos detectados e indicar los hallazgos analizados.

3. Confirmar: `"💾 Investigación guardada en docs/sprints/sprint-{{SPRINT_SIGUIENTE}}-research.md. Listo para /session-start."`

### 7. Entrega y Solicitud de Aprobación Macro del Sprint

Justo al finalizar la planificación (antes de la pausa si hubo fallback, o como entrega final para aprobación si SearXNG fue autónomo):
1. Resumen del estado del roadmap (3 líneas máximo).
2. Decisiones tomadas sobre tareas incompletas del sprint anterior (si las hubo).
3. Resultado de la verificación de código del paso 2c (tabla con evidencias).
4. **Resultado de la prospección determinista OSS del paso 2d** (tabla con alternativas detectadas por `scout.sh` y recomendación de adopción vs construcción).
5. Las tareas del sprint seleccionadas con su tamaño.
6. **Progreso MVP actualizado (omitir si el proyecto no tiene `docs/MVP-TRACKER.md`):**
   ```
   📊 Progreso MVP: XX%
      Capacidad 1                  ██████████ 100%
      Capacidad 2                  ████████░░  80%
      ...
   ```
7. El prompt para Perplexity listo para copiar (**exclusivamente si SearXNG estuvo inactivo**). Si SearXNG estuvo activo, indicar: `"✅ Investigación técnica completada autónomamente con SearXNG e integrada en el research file."`
8. Ruta del sprint file creado.
9. **Verificación de compuerta Scout-First (T-129):** Confirmar explícitamente la presencia de `docs/sprints/sprint-{{SPRINT_SIGUIENTE}}-research.md` con su sección `## Descubrimientos Scout (por tarea)` completa para todas las tareas del sprint. Si falta el research estructurado, detenerse inmediatamente: *"Sin research scout estructurado no hay plan de sprint admisible"*.

## Reglas

### Selección de Tareas (Regla de Oro: El agente propone, el usuario confirma)
- El agente **propone siempre una lista cerrada** de 3 a 5 tareas derivadas autónomamente de spillover, inboxes y roadmap.
- Prohibido hacer preguntas abiertas al operador sobre qué tareas incluir.
- Equilibrio de tamaños: no más de 1 tarea L por sprint.
- Prioridad: tareas arrastradas primero, luego bloqueantes, luego por orden del roadmap.
- Tamaños: **S** = < 1h, **M** = 1-3h, **L** = 3h+.
- **Solo entran tareas verificadas como no implementadas** (resultado del firewall anti-duplicación del Paso 3c).

### Salvaguarda de Prospección Determinista (scout-first)
- **Obligatorio para tareas técnicas y nuevas herramientas**: Toda tarea candidata que introduzca conectores, integraciones, agentes, scrapers o utilidades debe evaluarse previamente con `scout.sh`.
- Si existe una alternativa consolidada (≥500⭐, licencia permisiva MIT/Apache), la recomendación por defecto es la integración/adopción frente al desarrollo a medida.
- **Coste cero**: El agente solo consume el digest estructurado producido por el script CLI, garantizando 0 tokens en la fase de búsqueda.
- **Compuerta estricta de completitud (T-129)**: *"Sin research scout estructurado no hay plan de sprint admisible"*. El documento `sprint-{{SPRINT_SIGUIENTE}}-research.md` es condición de entrega previa a la pausa o solicitud de aprobación humana. Debe incluir subsecciones para cada tarea planificada, documentando alternativas detectadas, recomendaciones, decisiones y opciones rechazadas con su motivo explícito.

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

### Gobernanza Desacoplada en Dos Niveles (Macro en Planning, Micro por Tarea)
- **Aprobación de Diseño en Planning**: El usuario humano evalúa y aprueba formalmente la arquitectura, dependencias, interfaces y alcance funcional de cada tarea durante el sprint planning. Ninguna tarea entra al sprint con diseño o contratos abiertos.
- **Artefacto Concreto Requerido**: Toda tarea activa debe formalizarse con la sección canónica `## Diseño macro aprobado en planning` conteniendo el veredicto `[APROBADO_EN_PLANNING]` y el desglose de interfaces y decisiones acordadas.
- **Compuerta Técnica y Escalado Vinculante**: Durante `/session-start`, el Revisor Ejecutor (o relé) audita estrictamente la caja de archivos, pruebas y apego al diseño macro ya sellado. Ante cualquier desviación o fuga de alcance, emite bloqueo técnico inmediato con `ESCALADO_A_HUMANO`, suspendiendo la ejecución desatendida.
- **Papel del Relé en Transición**: El operador humano / relé se mantiene como fallback operativo ante indisponibilidad de pasarela (`SIN_REVISOR`) y sigue frenando de forma obligatoria y manual los merges hasta verificar paridad estadística empírica en el Sprint 27.
