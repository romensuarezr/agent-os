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
2. **Compuerta proactiva de arranque de sprint (Pregunta única de Régimen y Camino)**:
   Verificar la sección `## Régimen Operativo del Sprint` en el sprint file (`docs/sprints/sprint-XX.md`).
   - Si la sección está ausente, sin sellar o contiene `[PENDIENTE]` / `[PENDIENTE_ARRANQUE]` (típicamente al abrir la primera sesión del sprint):
     El flujo se detiene y formula **PROACTIVAMENTE** al usuario una única consulta antes de seleccionar tarea o abrir planes:
     ```
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     🚀 ARRANQUE DE SPRINT {{SPRINT_ACTIVE}} — CONFIGURACIÓN OPERATIVA
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

     Para este sprint, define el régimen operativo y el camino de ejecución:

     1️⃣ RÉGIMEN OPERATIVO:
        A) Desatendida (Opción D): Encadena tareas automáticamente en camino limpio sin volver al usuario entre ellas. Aborta de inmediato a humano ante cualquier anomalía técnica o si la verificación del relé falla.
        B) Tarea a tarea (Clásico): Pausa para revisión y aprobación humana explícita en cada puerta antes de proceder con la siguiente tarea.

     2️⃣ CAMINO DE CARRILES (derivado de la tabla de dependencias del acta):
        Propuesta de carriles según dependencias:
        - Carril 1: [T-XXX → T-YYY] (secuencial por dependencias)
        - Carril 2: [T-ZZZ] (independiente)
        ¿Confirmas este orden de carriles o prefieres un orden alternativo?

     Esperando tu respuesta (ej: "A, confirmo carriles" o "Opción D, carril 2 primero").
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     ```
   - Al recibir la respuesta del operador, el agente actualiza inmediatamente el sprint file sellando la sección:
     ```markdown
     ## Régimen Operativo del Sprint
     - **Régimen**: Desatendida (Opción D) [o Tarea a tarea (Clásico)]
     - **Orden de Carriles (DAG de dependencias)**:
       - Carril 1: [T-XXX → T-YYY]
       - Carril 2: [T-ZZZ]
     - **Sellado en**: YYYY-MM-DD HH:MM UTC
     ```
   - **Invariante**: Una vez sellado, el régimen es vinculante e inmutable durante todo el sprint. Las siguientes invocaciones de `/session-start` detectan el sellado y proceden directamente sin volver a preguntar.
3. **Comprobar tareas `🟡 En curso`:** si existe alguna, mostrar alerta y esperar confirmación:
   ```
   ⚠️ La tarea [T-XXX] quedó en estado 🟡 En curso en la sesión anterior.
   Opciones:
     A) Retomarla (marcarla como tarea activa)
     B) Marcarla como ✅ Hecho si ya está completada
     C) Marcarla como ⏸ Pausada y continuar con la siguiente pendiente
   ¿Qué hacemos?
   ```
   No continuar hasta recibir respuesta explícita.
4. Identificar la siguiente tarea activa:
   - Siguiendo el `Orden de Carriles` sellado en `## Régimen Operativo del Sprint`, seleccionar la primera tarea `⬜ Pendiente` o `⏸ Pausada` cuyas dependencias (declaradas en la columna `Dependencias` del acta) estén ya completadas (`✅ Hecho`). Mostrar: `"Tarea activa: [T-XXX] — [descripción]"`.

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
   - Existe → integrar en `## Contexto técnico` del task file. Si el research contiene una subsección `### T-XXX` bajo `## Descubrimientos Scout (por tarea)` correspondiente a la tarea activa, integrarla explícitamente en el Contexto técnico (alternativa adoptada con versión/licencia, o justificación de desarrollo a medida). Informar: `"📚 Research integrado."`
   - No existe → preguntar `"¿Tienes investigación previa de Perplexity? (S/N)"`. Si S → pegar y guardar en `sprint-{{SPRINT_ACTIVE}}-research.md`. Si N → continuar.

> ⚠️ Completar el task file **no autoriza la ejecución**. La única autorización es el APROBADO en Fase 3.5.

### FASE 3 — Declaración de la Caja y Cláusula de Skills

1. Leer `## Caja de archivos` del task file y mostrar archivos autorizados.
2. Identificar skills relevantes declaradas en el task file por nombre. No activarlas aún.
3. **Cláusula de Skills (obligatoria)**: El agente debe verificar que cada skill declarada en el task file tenga su regla aplicada explícitamente citada en el borrador del plan, o bien declarar `"no aplica"` con motivo fundado.

### FASE 3.4 — Generación del Borrador y Deliberación Autónoma

> **Arquitectura de Gobernanza de Dos Niveles**:
> - **Nivel Macro (Diseño y Arquitectura)**: El diseño conceptual, arquitectura, interfaces y alcance de la tarea ya fueron evaluados, pactados y sellados durante el sprint planning en la sección `## Diseño macro aprobado en planning` del task file.
> - **Nivel Micro (Compuerta Técnica por Tarea)**: La deliberación entre Coder y Reviewer mediante `deliberate-plan.sh` actúa estrictamente como compuerta técnica determinista (auditoría de caja de archivos, ausencia de duplicación, cobertura de pruebas, compatibilidad del stack y apego estricto al diseño macro ya aprobado). Queda prohibido reabrir o cuestionar decisiones conceptuales selladas en planning.
> - **Escalado Vinculante**: Ante cualquier desviación entre el plan y el diseño macro aprobado (fuga de alcance, alteración de contratos de interfaces o dependencias no pactadas), el revisor emite bloqueo técnico vinculante y escala al humano (`ESCALADO_A_HUMANO`), suspendiendo inmediatamente cualquier ejecución desatendida hasta resolución humana.
> - **Régimen Operativo Opción D (Autonomía Acotada Estándar)**: El diseño macro aprobado y sellado en el sprint planning constituye la única autorización previa vinculante. En el flujo `/session-start`, el proceso de deliberación técnica actúa como compuerta determinista. Si se satisfacen todas las condiciones de camino limpio, el agente ejecuta el ciclo de forma desatendida hasta el merge y cierre inclusive. Ante cualquier anomalía técnica o discordancia, el agente aplica contención inmediata fail-closed y escala al operador humano en el chat.

1. El Coder redacta el borrador del plan en `.agents/context/plan-draft.md` conteniendo objetivo, rama propuesta, archivos a modificar/crear, pasos secuenciales, riesgos, justificación de skills y verificación de conformidad con `## Diseño macro aprobado en planning`.
2. Ejecuta el motor determinista de arbitraje Coder-Reviewer:
   ```bash
   bash scripts/agent/deliberate-plan.sh --plan .agents/context/plan-draft.md --task-id T-XXX
   ```
3. El motor emite el veredicto en `.agents/context/plan-deliberation.json` con uno de los 4 estados canónicos: `CONSENSO`, `REVISADO_CON_CAMBIOS`, `ESCALADO_A_HUMANO` o `SIN_REVISOR`.

### FASE 3.5 — Decision Gate: Bifurcación Opción D y Executive Design Digest

Tras emitir el veredicto de deliberación, el agente evalúa la compuerta determinista de gobernanza según el régimen estándar de **Opción D**:

#### 1. Camino Limpio Desatendido (Happy Path)

Se activa si y solo si se satisfacen copulativamente las **5 condiciones inviolables**:
1. **Veredicto estricto**: El resultado de `deliberate-plan.sh` es estrictamente igual a `CONSENSO`.
2. **Suite en verde**: La suite de pruebas de control plane pasa al 100% (0 errores).
3. **Caja de archivos**: La lista de modificaciones se encuentra estrictamente dentro de `authorized_files` del task file.
4. **Fidelidad al Macro**: No existen alteraciones, expansiones de alcance ni desvíos frente a `## Diseño macro aprobado en planning`.
5. **Centinelas intactos**: Cero modificaciones en variables de entorno críticas, secretos, rutas personales o archivos fuera de alcance.

*Acción determinista*: El agente emite un resumen compacto acreditando el consenso y avanza automáticamente y sin pausas interactivas a la **FASE 4 (Apertura del lock)**, **FASE 5 (Ejecución controlada)** y **FASE 6 (Cierre de sesión)**, completando la condición pre-merge refinada, el merge `--no-ff` y `close-task.sh`.

#### 2. Compuertas de Aborto Inmediato Fail-Closed (Anomalías o Modo Interactivo)

Se activa ante CUALQUIERA de las siguientes anomalías:
- **Veredicto no consensual**: El veredicto es `REVISADO_CON_CAMBIOS`, `ESCALADO_A_HUMANO`, `SIN_REVISOR` o `RECHAZADO`. Queda prohibido re-etiquetar veredictos o auto-aplicar cambios del revisor sin mediación humana.
- **Fallo en suite**: Regresiones o errores en la ejecución de la suite de validación.
- **Fuera de caja**: Necesidad de alterar archivos no autorizados en el task file.
- **Desviación de diseño**: Discrepancias respecto a las decisiones selladas en planning.
- **Violación de centinelas o higiene**: Presencia de rutas absolutas personales o secretos.

*Acción determinista*: El avance autónomo se suspende de inmediato (fail-closed) y el agente DEBE presentar el bloque de decisión correspondiente antes de realizar cualquier acción operativa adicional:

##### Caso A: Revisor activo (`REVISADO_CON_CAMBIOS`, `ESCALADO_A_HUMANO` o revisión manual solicitada)
Se presenta el **Executive Design Digest** estructurado para que el operador decida sobre la visión estratégica y buenas prácticas sin necesidad de ser un intermediario de mensajes manuales:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏛️ EXECUTIVE DESIGN DIGEST — T-XXX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 1. OBJETIVO ESTRATÉGICO:
   [Resumen de alto nivel del propósito de la tarea y qué problema resuelve]

🛠️ 2. CORRECCIONES ACORDADAS ENTRE IA:
   - [Objeción/Ajuste detectado por el Revisor y cómo fue subsanado, o "Consenso inicial sin objeciones de inventario"]

📁 3. ARCHIVOS A MODIFICAR / NUEVOS:
   - src/ruta/archivo1.ts → [qué se cambia]
   - scripts/nuevo.sh → [nuevo: verificado test -f]

⚡ 4. ACCIONES IRREVERSIBLES O DE IMPACTO:
   - [Migraciones, reinicio de servicios o comandos críticos, o "Ninguna irreversible"]

🧠 5. SKILLS APLICADAS:
   - [skill-1]: Regla [nombre/número] aplicada para [propósito]
   - [skill-2]: no aplica ([motivo])

📚 6. REFERENCIA A ARTEFACTOS COMPLETOS:
   - Borrador del plan: .agents/context/plan-draft.md
   - Deliberación estructurada: .agents/context/plan-deliberation.json

🚦 7. ESTADO DEL VEREDICTO:
   [CONSENSO | REVISADO_CON_CAMBIOS | ESCALADO_A_HUMANO (en caso de desacuerdo)]

⏳ ESPERANDO: responde APROBADO (o Y), APROBADO CON CAMBIOS: [...] o CANCELAR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

##### Caso B: Revisor no disponible (`SIN_REVISOR`)
Si el Revisor no responde tras 5s de timeout o no hay conectividad a la pasarela, se emite un aviso visible y se activa el fallback al formato de plan crudo clásico de Fase 3.5 para aprobación manual directa sin bloquear la sesión:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ REVISOR OFFLINE — FALLBACK A PLAN CLÁSICO — T-XXX
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

#### Prohibiciones absolutas ante compuerta de aborto hasta recibir APROBADO (o Y)

En caso de compuerta de aborto o modo interactivo, queda terminantemente prohibido hasta recibir `APROBADO` (o `Y`):
- ❌ Crear `.agent-session.lock`
- ❌ Crear o cambiar de rama (`git checkout`, `git branch`)
- ❌ Editar, crear o borrar cualquier archivo del proyecto
- ❌ Ejecutar `git add`, `git commit`, `git push`
- ❌ Ejecutar `npm`, `yarn`, `pnpm` o cualquier comando que modifique estado
- ❌ `Searched for`, `Listed directory` o `Viewed` en código fuente (`src/`, `lib/`)
- ❌ `Listed directory` en `.agents/tasks/` o `.agents/tasks/_archived/`
- ❌ Leer `task-YYY.md` donde `YYY ≠ XXX` (tarea activa)
- ❌ Leer `SKILL.md`, `_template.md` u otros documentos de referencia estáticos

✅ Permitido: leer **exclusivamente** el task file activo (`task-XXX.md`), el sprint file y el research file, y ejecutar `deliberate-plan.sh`.

Si el agente detecta que ha ejecutado cualquier acción operativa sin la debida autorización (camino limpio Opción D o `APROBADO` explícito):
1. Detenerse inmediatamente.
2. Informar al usuario de qué ejecutó.
3. Proponer el rollback correspondiente.
4. Presentar el plan de nuevo y esperar aprobación.

#### Respuestas válidas del usuario en modo escalado
- `APROBADO` o `Y` → autoriza abrir la sesión y ejecutar el plan consensuado
- `APROBADO CON CAMBIOS: [descripción]` → ajustar el plan y confirmar los cambios antes de ejecutar
- `CANCELAR` → cerrar la sesión sin ninguna acción

### FASE 4 — Apertura del lock

**Solo tras aprobación explícita.** Crear rama aprobada. Si está en `main`/`master` sin poder crearla: detenerse y avisar.

Crear `.agent-session.lock` con campos: `task`, `sprint`, `branch`, `worktree`, `opened` (ISO 8601), `status: open`, `approved_plan: true`, `authorized_files: [...]`.

El campo `worktree` registra dónde se trabaja (T-107): salida de `git rev-parse --show-toplevel` más la rama activa. El `branch` del lock debe coincidir con la rama de trabajo. Si no: detenerse hasta corregirlo.

Mostrar: `"🔒 Sesión abierta. Ejecución autorizada para [T-XXX] en [worktree] ([branch])."`

### FASE 5 — Ejecución controlada

1. Activar skill relevante.
2. Ejecutar plan aprobado paso a paso.
3. Si hay que salir de la Caja o cambiar enfoque: detener, presentar mini-plan (mismo formato Fase 3.5), esperar nueva aprobación.

> Si completas todos los criterios de done antes de que el usuario lo indique: ver **Fase 5b** en Casos especiales.

### FASE 6 — Cierre de sesión

#### C1. Verificación de la Caja
`git diff --name-only` → comparar con `authorized_files`. Si hay archivos fuera: informar y esperar instrucción.

Durante el cierre: prohibido leer fuera de la Caja, preparar planes nuevos o analizar trabajo futuro. Si el usuario lanza una petición nueva, confirmar que está capturada en idea-inbox y proceder al cierre sin desviarse.

#### C1b. Protocolo Pre-Merge Refinado y Cierre Atómico (Opción D)
Bajo el régimen Opción D, la integración y cierre se completan desatendidamente en camino limpio siguiendo esta secuencia determinista:
1. **Ejecución y pruebas**: Verificar suite de control plane completa y linters en verde.
2. **Publicación remota previa**: Publicar la rama de feature en remoto (`git push origin feat/T-XXX-...`).
3. **Acreditación del recibo**: El informe y notas de la tarea acreditan el recibo de deliberación (referenciando el veredicto `CONSENSO` y el identificador/SHA del recibo generado en `.agents/context/deliberation-T-XXX.json`).
4. **Integración controlada**: Cambiar a la rama base (ej. `git checkout multi-agent`), ejecutar merge `--no-ff` (`git merge --no-ff feat/T-XXX-... -m "Merge branch 'feat/T-XXX-...' into multi-agent"`), empujar a origin (`git push origin multi-agent`) y eliminar la rama feature remota y local.
5. **Cierre y Digest atómico**: Ejecutar `bash scripts/agent/close-task.sh T-XXX "tipo(scope): descripción"`. El script ejecuta internamente `design-digest.sh`, el cual redacta secretos y rutas de forma determinista, persistiendo `T-XXX-digest.md` y `T-XXX-raw.json` en `docs/sprints/design-decisions/` y commiteando atómicamente. La persistencia definitiva del digest y raw ocurre en el cierre, sin requerir la publicación manual previa del archivo JSON crudo en origin antes del merge.
6. **Encadenamiento desatendido a la siguiente tarea**:
   Bajo el régimen Opción D (Desatendida), tras completarse el commit atómico con `close-task.sh`:
   - El agente ejecuta la verificación del relé de la tarea recién cerrada: suite de pruebas `tests/validate-control-plane.sh` y `verify-goal.sh` (si la tarea cuenta con contrato de meta).
   - **Compuerta Fail-Closed Crítica**: **El encadenamiento en Opción D aborta inmediatamente a humano si la verificación del relé de la tarea recién cerrada falla** (fallo en suite, error en meta, archivos fuera de caja o anomalías en git). Ante cualquier fallo, el agente NO inicia la siguiente tarea, suspende la autonomía y notifica la anomalía al operador en el chat con la evidencia del error.
   - **Camino Limpio**: Si la verificación del relé es 100% verde (0 errores), el agente evalúa si restan tareas pendientes en el sprint según el `Orden de Carriles` sellado en el acta. De haberlas, encadena automáticamente iniciando de inmediato el ciclo de la siguiente tarea disponible (Fases 1–6) sin pausar para pedir confirmación interactiva. Si no restan tareas pendientes, procede al archivado del sprint con `close-sprint.sh`.

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

### Fase 5b — Tarea completada

En modo interactivo clásico (`Tarea a tarea`) o si se aborta a humano:
1. Detener ejecución. No leer más archivos ni preparar planes.
2. Mostrar: `"✅ Tarea completada. ¿Confirmas commit y cierre?"`
3. Respuestas válidas: `sí, commitea` / `cierra` → Fase 6. `no, primero…` → escuchar sin actuar.
4. Petición nueva en el mismo mensaje: capturar en `docs/idea-inbox/YYYY-MM-DD.md`. Responder: `"💡 Capturada. Primero cierro. ¿Confirmas?"` No leer ni preparar nada nuevo.
5. Solo tras cerrar la sesión (Fase 6 completa) se puede abrir `/session-start` para la petición nueva o siguiente tarea.

En camino limpio bajo el régimen `Desatendida (Opción D)`:
El cumplimiento de todos los criterios de done desencadena directamente el Protocolo Pre-Merge Refinado y la ejecución de `close-task.sh` sin requerir pausas interactivas en esta compuerta. A continuación, si la verificación del relé post-cierre pasa al 100%, encadena automáticamente con la siguiente tarea del carril según el orden sellado en el acta; si la verificación del relé falla, aborta inmediatamente a humano (fail-closed).

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
