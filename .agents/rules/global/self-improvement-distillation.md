---
trigger: session-close
---

# Rule: Self-Improvement Distillation & Procedural Knowledge Governance

> **Invariante de Automejora**: El conocimiento procedimental, los gotchas resueltos y los trucos descubiertos por primera vez **nunca mueren en el transcript**. Se destilan a artefactos vivos, duraderos y versionados bajo un filtro anti-ruido estricto y con validación humana explícita.

---

## 🎯 1. El Principio de Destilación

Cuando un agente ejecuta un procedimiento técnico multi-paso sin documentación previa, tropieza con una trampa técnica no documentada o crea una secuencia operativa reutilizable:
- **Prohibido**: Cerrar la sesión dejando la solución únicamente en el historial de la conversación o en logs efímeros.
- **Obligatorio**: Capturar la lección y destilarla a su destino canónico en el repositorio antes de liberar la sesión.

---

## 🔍 2. Protocolo de Self-Reflection Obligatorio

En la fase final de cada sesión (integrado en `session-close.md`), el agente debe evaluar de forma reflexiva las 3 preguntas clave antes de solicitar el cierre:

1. **¿Sufrí por alguna convención, truco o dependencia no documentada?**
2. **¿Encontré un gotcha o trampa técnica que el siguiente agente inevitablemente volverá a pisar?**
3. **¿Desarrollé una secuencia operativa o herramienta multi-paso reutilizable?**

Si la respuesta a cualquiera de ellas es **AFIRMATIVA**, el agente debe formular una propuesta concreta de destilación clasificándola según la matriz de destino.

---

## 🧭 3. Matriz de Destino Canónico

El agente selecciona el destino del hallazgo según su naturaleza:

| Naturaleza del Hallazgo | Destino Canónico en Agent OS | Mecanismo Operativo |
| :--- | :--- | :--- |
| **Capacidad procedimental / herramienta multi-paso** | `.agents/skills/<nombre>/SKILL.md` | Delegar en la skill `creador-habilidades` |
| **Invariante de comportamiento / directiva universal** | `.agents/rules/global/<regla>.md` | Delegar en la skill `rule-creator` |
| **Paso a paso operativo / infra / comandos CLI** | `docs/runbooks/<procedimiento>.md` | Plantilla canónica de runbook |
| **Patrón incipiente / idea que no alcanza umbral** | `docs/idea-inbox/YYYY-MM-DD-<idea>.md` | Entrada fechada en idea-inbox |
| **Aclaración a un contrato o regla preexistente** | Edición in-situ del archivo correspondiente | Disciplina *retrospective* en documentos vivos |

---

## 🛡️ 4. Los Tres Filtros de Calidad

### A. Umbral de Repetición 3x (Anti-Ruido)
- *"Un candidato a skill es un workflow ocurrido 3+ veces con la misma forma; las heroicidades puntuales hacen malas skills."*
- Si el procedimiento es específico de una única tarea o no se prevé recurrencia inmediata, **no se crea una skill**: se anota como runbook operativo o se deposita como idea en `docs/idea-inbox/`.

### B. Retrospective sobre Documentos Vivos (Prohibición de Silos Muertos)
- **Queda terminantemente prohibido** crear ficheros huérfanos o silos estáticos de "lecciones aprendidas" (ej. `docs/lessons.md`, `LECCIONES.txt`) que ningún agente lee en el onboarding.
- Las lecciones aprendidas se integran como ediciones atómicas sobre los documentos que rigen la ejecución: reglas, workflows, contratos de arquitectura o READMEs vivos.

### C. Live-Capture vs. Reconstrucción de Memoria
- Los comandos exitosos, banderas exactas y secuencias de entorno deben registrarse **en caliente durante la ejecución** apoyándose en la evidencia de los comandos ejecutados, nunca reconstruidos de memoria al final de la sesión donde se omiten variables o flags críticos.

---

## 👤 5. Protocolo Draft → Aprobación Humana

1. **Estado Borrador**: Todo nuevo artefacto generado mediante automejora (skill, regla, runbook o propuesta) nace en estado *draft* o propuesta dentro del plan de cierre.
2. **Confirmación Explícita**: El agente presenta la propuesta al usuario con formato conciso (QUÉ, POR QUÉ y DESTINO).
3. **Activación**: Solo la confirmación explícita del usuario autoriza la incorporación formal del artefacto al repositorio y su commit asociado.

---

## 🌐 6. Herencia y Versionado en el Core

- Esta regla reside en el core versionado de Agent OS (`.agents/rules/global/self-improvement-distillation.md`).
- Está cableada en `scripts/agent/assets-manifest.txt` para garantizar que `install.sh` y `sync.sh` la distribuyan automáticamente a cualquier proyecto satélite.
- Los agentes en proyectos satélite operan bajo esta misma disciplina y pueden promover mejoras al core mediante `scripts/agent/contribute.sh`.
