# Idea: Regla de automejora: destilar procedimientos primerizos en skills/reglas/runbooks

> **Fecha**: 2026-09-30  
> **Origen**: Conversación con el usuario el 2026-09-30, a raíz de la pregunta: *"cuando se hace un paso a paso por primera vez porque no existía ese proceso documentado, ¿se documenta de alguna manera?"*  
> **Estado**: 💡 Capturada para Sprint 14 (no entra en Sprint 13)  
> **Área**: Gobernanza / Metacognición de Agentes / Automejora Continua del Core e Hijos  
> **Rama**: `docs/idea-self-improvement-distillation`  

---

## 1. Concepto y Justificación

Actualmente, cuando un agente se enfrenta a una tarea o procedimiento técnico sin documentación previa (un setup nuevo, resolución de un gotcha inesperado, orquestación de herramientas no contemplada), resuelve los obstáculos mediante razonamiento en el transcript. Una vez completada la tarea y finalizada la sesión, ese conocimiento procedimental queda sepultado en los logs de la conversación o en el histórico efímero, obligando a futuros agentes a redescubrir y deducir la solución desde cero (quemando tokens, tiempo y arriesgando inconsistencias).

**La Regla Disparadora de Automejora**:
Cuando un agente ejecuta un procedimiento multi-paso por primera vez porque no existía documentado en el repositorio, **no debe dejarlo morir en el transcript**. Debe destilarlo a un artefacto durable y versionado (skill, regla, runbook o idea en inbox) según su naturaleza y con validación explícita del usuario.

---

## 2. Patrones de la Comunidad que la Respaldan

Esta propuesta se fundamenta en patrones probados en el ecosistema abierto de ingeniería de contexto y agentes autónomos:

1. **Self-Reflection Obligatoria** ([rolandbrecht/agent-skills](https://github.com/rolandbrecht/agent-skills/blob/HEAD/self-reflection/SKILL.md)):
   - Protocolo obligatorio antes de declarar *done*.
   - Plantea 3 preguntas de reflexión al agente:
     1. *¿Sufrí por alguna convención, truco o dependencia no documentada?*
     2. *¿Encontré un gotcha o trampa técnica que el siguiente agente inevitablemente volverá a pisar?*
     3. *¿Desarrollé una secuencia o herramienta multi-paso reutilizable?*

2. **Workflow Distiller & Umbral de Repetición** ([abdulaibah479/farmer-marketplace_232](https://github.com/abdulaibah479/farmer-marketplace_232/blob/HEAD/./.agents/skills/workflow-distiller/SKILL.md)):
   - Principio anti-ruido: *"Un candidato a skill es un workflow ocurrido 3+ veces con la misma forma; las heroicidades puntuales hacen malas skills"*.
   - Evita la proliferación de skills innecesarias o hiper-específicas para excepciones de una sola vez.

3. **Retrospective y Edición sobre Documentos Vivos** ([shiftynick/agent-foundry](https://github.com/shiftynick/agent-foundry/blob/HEAD/./starter/.claude/skills/retrospective/SKILL.md)):
   - Las correcciones y lecciones aprendidas deben integrarse como ediciones a documentos y contratos existentes (reglas, runbooks, READMEs), **nunca crear un nuevo fichero o silo muerto de "lecciones aprendidas"** que nadie leerá en el boot.

4. **Runbook Live-Capture** ([hess0ul/ai-workspace-template](https://github.com/hess0ul/ai-workspace-template/blob/HEAD/.claude/skills/runbook/SKILL.md)):
   - Cada comando y paso exitoso se escribe en el runbook en caliente, **DURANTE la ejecución**, no reconstruido retrospectivamente de memoria al final de la sesión donde se omiten banderas, órdenes o variables críticas.

5. **Draft → Promoción Humana**:
   - Todo artefacto nuevo generado por automejora nace en estado *draft* o propuesta. Solo la revisión y confirmación humana explícita lo activa en el árbol principal.

---

## 3. Puntos Clave de Diseño y Encaje en Agent OS

El sistema operativo de agentes ya cuenta con las piezas modulares necesarias; esta idea las articula en un bucle cerrado de retroalimentación:

### A. Paso de Reflexión en `session-close.md`
- Integrar en la fase final de cierre de sesión (`session-close.md`) la evaluación determinista de las 3 preguntas de reflexión de `self-reflection`.
- Si la respuesta a alguna es afirmativa, el agente debe formular una propuesta concreta de destilación antes de liberar el lock.

### B. Matriz de Decisión de Destino
El agente clasifica el procedimiento según su naturaleza:

| Naturaleza del Hallazgo | Destino Canónico en Agent OS | Mecanismo de Creación |
| :--- | :--- | :--- |
| **Capacidad procedimental / herramienta multi-paso** | `.agents/skills/<nombre>/SKILL.md` | Delegar en la skill `creador-habilidades` |
| **Invariante de comportamiento / directiva universal** | `.agents/rules/<regla>.md` | Delegar en la skill `rule-creator` |
| **Paso a paso operativo / infra / comandos CLI** | `docs/runbooks/<procedimiento>.md` | Plantilla canónica de runbook |
| **Patrón incipiente / idea que no alcanza umbral** | `docs/idea-inbox/<fecha>-<idea>.md` | Entrada fechada en idea-inbox |
| **Aclaración a un contrato o regla preexistente** | Edición in-situ del archivo correspondiente | Principio `retrospective` (sin silos nuevos) |

### C. Captura en Vivo vs. Reconstrucción
- Aprovechar la disciplina ya implantada en Agent OS de *evidencia por criterio* y registro de comandos (`run_command` con logs deterministas).
- Durante la ejecución de tareas complejas, el agente anota comandos verificados para que la destilación al cerrar la tarea sea un volcado limpio y validado.

### D. Umbral de Repetición y Filtro Anti-Ruido
- Si el procedimiento es específico de una única tarea o no se prevé recurrencia (umbral < 3), no se crea una skill: se documenta en el runbook o se anota como idea en `idea-inbox/`.

---

## 4. Requisito Arquitectónico Clave: Herencia en Proyectos Hijos

Para que esta automejora no sea un mecanismo aislado del repositorio core:

1. **Ubicación en el Core Versionado**:
   - La regla formal residirá en `.agents/rules/global/` (ej. `self-improvement-distillation.md`).
   - El gatillo operativo se integrará en el workflow global `.agents/workflows/session-close.md`.
2. **Propagación determinista a Satélites**:
   - Al estar en `rules/global/` y `workflows/`, cualquier proyecto hijo nuevo o preexistente recibirá el comportamiento de forma automática vía `install.sh` y `sync.sh`.
   - Los agentes que trabajen en cualquier repositorio satélite del ecosistema operarán bajo la misma disciplina: auto-descubrir, resolver, destilar con validación humana y enriquecer su base local o promover al core vía `contribute.sh`.

---

## 5. Planificación y Próximos Pasos

- **Sprint Asignado**: Sprint 14 (fuera del alcance del Sprint 13 activo).
- **Entregables previstos para Sprint 14**:
  1. Redacción de la regla global `.agents/rules/global/self-improvement-distillation.md`.
  2. Actualización de `.agents/workflows/session-close.md` con la sección de autoevaluación / reflexión previa al cierre.
  3. Verificación de herencia en satélite mediante `sync.sh` y validación de pre-flights.
