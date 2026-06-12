---
name: doe-framework
description: Crea un task file (contrato escrito) antes de abrir Antigravity para cualquier tarea de desarrollo. Activa cuando la tarea dure más de 30 min estimados o afecte a más de 2 archivos.
---

# DOE Framework — Directive → Orchestration → Execution

## Cuándo activar
Siempre que se cumpla **cualquiera** de estas condiciones:
- Duración estimada **superior a 30 minutos**, o
- Tarea que modifica o crea **más de 2 archivos** (nuevos o existentes).

Si ambas condiciones son falsas (tarea corta en 1–2 archivos), trabaja
directamente sin task file.

## Los tres pasos

### D — Directive
1. Crear `.agents/tasks/task-XXX.md` usando la plantilla en `.agents/tasks/_template.md`.
2. Rellenar: objetivo, Caja de archivos (lista explícita), criterios de done, dependencias.
3. El número XXX es el siguiente disponible en `.agents/tasks/`.

### O — Orchestration
1. Abrir Antigravity.
2. Primer mensaje = contenido completo del task file. Sin añadir contexto extra.
3. Activar `implementar-feature-dry` para que el agente mapee antes de actuar.

### E — Execution
1. El agente trabaja exclusivamente contra el task file.
2. Si surge un desvío → `idea-capture` lo anota en `docs/idea-inbox/`, no en el chat.
3. Al terminar: estado `DONE` en el task file → mover a `.agents/tasks/_archived/task-XXX.md`.

## Instrucciones para el agente
- Plan compacto: máx. 10 líneas antes de actuar.
- Sin Walkthrough Artifact al final — resumen de 3 líneas máximo.
- Espera aprobación entre fases cuando hay más de una fase.
- No escanees el workspace completo — el task file tiene el contexto suficiente.
