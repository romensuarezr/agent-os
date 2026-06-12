---
name: workflow-designer
description: Crea, revisa y refactoriza workflows de Antigravity (.agents/workflows/) siguiendo el estándar oficial y las convenciones del proyecto.
---

# Workflow Designer

Esta habilidad convierte al agente en experto en el ciclo de vida completo de los workflows de Antigravity: creación desde cero, revisión de calidad, refactorización y registro. Se activa cuando el usuario quiere crear un flujo nuevo, mejorar uno existente o auditar que los workflows actuales siguen el estándar.

## Diferencia clave: Workflow vs Skill vs Rule

| Tipo | Activación | Ubicación | Propósito |
|---|---|---|---|
| **Rule** | Siempre (`trigger: always_on`) | `.agents/rules/` | Comportamiento permanente y global |
| **Workflow** | Manual, slash command del usuario | `.agents/workflows/` | Protocolo multi-paso para una tarea concreta |
| **Skill** | Automática cuando el contexto es relevante | `.agents/skills/<nombre>/` | Conocimiento especializado cargado bajo demanda |

Un workflow es la respuesta a "¿cómo se hace X en este proyecto?".  
Una skill es la respuesta a "¿qué sé hacer cuando aparece X?".  
Una rule es la respuesta a "¿cómo me comporto siempre?"

## Prerrequisitos

- Tener claro el **disparo**: ¿qué comando o situación activa este workflow?
- Definir el **resultado esperado**: ¿qué queda hecho cuando el workflow termina?
- Revisar si ya existe un workflow similar en `.agents/workflows/` antes de crear uno nuevo.

## Flujo 1 — Crear un workflow nuevo

### Paso 1 — Analizar y proponer antes de crear
1. Pregunta (o infiere del contexto):
   - **Nombre del comando** (kebab-case, ej: `sprint-planning`, `session-close`)
   - **Disparador**: ¿cuándo lo invoca el usuario?
   - **Pasos principales**: ¿qué hace el agente paso a paso?
   - **Scripts involucrados**: ¿hay scripts bash en `scripts/agent/` que deba llamar?
2. Presenta una propuesta al usuario antes de escribir el archivo.

### Paso 2 — Estructura obligatoria del archivo

Cada workflow vive en `.agents/workflows/<nombre>.md`. El formato estándar:

```markdown
---
description: <Qué hace este workflow en una línea — aparece en el tooltip del slash command>
---

# <nombre-del-comando>

<Párrafo de contexto: cuándo usar este workflow y qué resuelve>

## Objetivo

- Punto 1 del objetivo
- Punto 2 del objetivo

## Archivos y rutas a revisar

<Lista de rutas relevantes para este workflow — ayuda al agente a orientarse>

## Protocolo



### 1. <Primer paso>
- Acción concreta.
- Verificación o guardia si aplica.

### 2. <Segundo paso>
...

## Reglas

- Reglas de oro que el agente NUNCA debe romper durante este workflow.
- Formato: frases cortas, imperativas, en negativo o positivo claro.
```

**Notas de formato:**
- El `description` del frontmatter es el único campo obligatorio.
- Los pasos del `## Protocolo` deben ser **deterministas**: el agente no debe necesitar inferir qué hacer a continuación.
- Cualquier paso que llame a un script bash debe incluir el comando exacto en un bloque de código.
- Separar claramente los pasos **manuales** (el agente edita archivos) de los pasos **automáticos** (el agente ejecuta scripts).
- Incluir siempre una sección `## Reglas` con las guardias más importantes.

### Paso 3 — Guardia antes de escribir

Antes de crear el archivo, verificar:
- [ ] ¿Ya existe `.agents/workflows/<nombre>.md`? Si existe, usar Flujo 2 (revisión).
- [ ] ¿El nombre está en kebab-case?
- [ ] ¿El frontmatter `description` tiene menos de 80 caracteres?
- [ ] ¿Hay al menos un paso con un comando o acción concreta?

### Paso 4 — Crear el archivo y registrar

1. Crear `.agents/workflows/<nombre>.md` con el contenido validado.
2. **No existe inventario separado para workflows** — los workflows son autodescriptivos vía el frontmatter. Sin embargo, si el workflow usa scripts nuevos, mencionarlos en `scripts/agent/` o documentarlos en el README correspondiente.
3. Commit: `docs(workflows): add <nombre> workflow`

## Flujo 2 — Revisar un workflow existente

Usar cuando el usuario dice: "revisa el workflow X", "¿está bien escrito?", "¿sigue el estándar?"

### Checklist de revisión

**Estructura**
- [ ] Tiene frontmatter con `description`
- [ ] El título H1 coincide con el nombre del archivo
- [ ] Tiene sección `## Objetivo` o equivalente
- [ ] Tiene sección `## Protocolo` con pasos numerados
- [ ] Tiene sección `## Reglas` al final

**Calidad de los pasos**
- [ ] Cada paso es **determinista**: describe una acción concreta, no una intención vaga
- [ ] Los pasos que llaman scripts incluyen el comando exacto en bloque de código
- [ ] Se distingue claramente qué hace el agente manualmente vs qué ejecuta el script
- [ ] No hay pasos que digan "decide si..." sin criterio claro — las decisiones deben tener una regla explícita

**Integración con el repo**
- [ ] Las rutas mencionadas existen en el repo (`.agents/tasks/`, `docs/sprints/`, etc.)
- [ ] Los scripts invocados existen en `scripts/agent/`
- [ ] Las convenciones de naming de ramas, tasks y sprints son consistentes con el resto del sistema

**Guardrails**
- [ ] Incluye advertencias explícitas para los errores más comunes del workflow
- [ ] Los pasos irreversibles (archivar, commitear, merge) tienen verificación previa
- [ ] Los pasos que pueden bloquearse tienen instrucción de salida (`SKIP_*=1` o similar)

**Advertencia de rango:** si el workflow menciona roles (admin, miembro, visitante),
verifica que la lógica de acceso sea consistente con la gobernanza y la matriz de permisos del proyecto.
Los workflows no deben crear jerarquías invisibles de permisos.

### Entrega de la revisión

Presenta el resultado de la revisión como:
1. Lista de ✅ checks que pasan
2. Lista de ⚠️ items que mejorar (con sugerencia concreta)
3. Lista de ❌ bloqueantes (el workflow no es fiable sin corregirlos)

Pregunta al usuario si quiere que apliques las mejoras.

## Flujo 3 — Refactorizar un workflow

Usar cuando la revisión detectó ❌ bloqueantes o cuando el workflow ha crecido demasiado.

1. **Lee el archivo actual completo** antes de proponer cambios.
2. **Propón el diff** (secciones que cambian) antes de escribir — no reescritas completas sin confirmación.
3. Aplica solo los cambios aprobados por el usuario.
4. Commit: `docs(workflows): refactor <nombre> workflow`

## Señales de que un workflow necesita dividirse

Un workflow es demasiado grande si:
- Tiene más de 8 pasos en el Protocolo
- Cubre dos momentos temporales distintos (ej: inicio Y cierre de sesión en el mismo archivo)
- Los pasos tienen bifurcaciones complejas con más de 2 caminos

En ese caso, propón dividirlo en dos workflows con nombres distintos.

## Ejemplos de workflows bien formados en este repo
(Revisar en `.agents/workflows/` si existen):
- `session-close.md` — protocolo de cierre con scripts, guardrails y reglas claras
- `session-start.md` — activación de contexto con verificaciones de estado
- `sprint-planning.md` — planning con llamada a `check-sprint.sh`

Estos tres son la referencia de calidad del proyecto.

## Verificación final

Antes de cerrar el trabajo, confirma:
- El archivo existe en `.agents/workflows/<nombre>.md`
- El frontmatter es YAML válido
- El workflow fue testeado mentalmente: ¿un agente sin contexto previo podría ejecutarlo paso a paso sin ambigüedad?
- Si el workflow llama scripts, esos scripts existen y tienen el comportamiento descrito
