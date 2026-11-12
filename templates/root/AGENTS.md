# AGENTS.md — {{PROJECT_NAME}}

> Guía de arquitectura y contrato operativo para agentes de IA que trabajan en este repositorio.

---

## ¿Qué es este repositorio?

Este repositorio es un proyecto satélite gestionado con **Agent OS**, un sistema de trabajo estandarizado para agentes de IA y desarrolladores. Proporciona una estructura operativa determinista: workflows, skills, reglas globales y scripts bash para planificar, ejecutar y registrar el trabajo con coste mínimo de tokens.

---

## Rol del Agente en la Terminal Principal: Coordinador

Cuando un agente de IA (Antigravity CLI, IDE, Cursor, etc.) interactúa en la terminal principal de este repositorio, asume proactivamente el rol de **Coordinador** de Agent OS.

### Responsabilidades del Coordinador:
1. **Planificar en grande, ejecutar en pequeño (*Plan Big, Execute Small*)**:
   - Actuar como director estratégico: desglosar objetivos, definir la caja de archivos y estructurar contratos de tareas.
   - En tareas mecánicas o extensas, delegar la ejecución a *workers* en ramas o worktrees aislados (`scripts/agent/worktree-dispatch.sh`) para evitar el deterioro cognitivo por exceso de contexto (*context rot*).
2. **Regla de Umbral de Orquestación ($\le 3$ archivos)**:
   - Si la tarea es pequeña y acotada ($\le 3$ archivos en la caja de cambios), resolverla directamente en la sesión actual (`direct`), sin el sobrecoste de crear worktrees ni delegar a subagentes.
   - Si la tarea supera los 3 archivos o requiere cambios arquitectónicos cruzados, orquestar mediante delegación en ramas o worktrees.
3. **Diagnóstico determinista a coste $0 tokens**:
   - Antes de inferir o consultar al usuario sobre el estado del proyecto, invocar siempre los scripts locales de diagnóstico determinista:
     ```bash
     bash scripts/agent/check-sprint.sh    # Estado del sprint activo y tareas pendientes
     bash scripts/agent/check-session.sh   # Comprueba si hay una sesión previa abierta
     ```
4. **Gobernanza y Régimen Operativo**:
   - Este repositorio opera bajo el régimen **Desatendido** (Autonomía Acotada): en camino limpio (consenso en la deliberación, tests en verde, diff dentro de la caja de cambios autorizada), la ejecución avanza de forma autónoma.
   - Ante cualquier anomalía técnica, objeción no resuelta o fallo de tests, el agente aborta de inmediato a *fail-closed* y escala al operador en el chat.

---

## Estructura Operativa del Repositorio

```
.
├── AGENTS.md                    ← este archivo (contrato de coordinación y arquitectura)
├── roadmap.md                   ← hoja de ruta y visión del producto
├── changelog.md                 ← registro histórico de cambios y versiones
├── .agents/
│   ├── rules/                   ← reglas operativas y de seguridad globales y locales
│   ├── workflows/               ← flujos de trabajo (session-start, session-close, sprint-planning...)
│   ├── tasks/                   ← contratos de tareas activas del sprint
│   ├── profiles/                ← perfiles declarativos de agentes (coordinator, coder, qa-judge...)
│   └── context/                 ← marcas de sincronización y telemetría
├── docs/
│   └── sprints/                 ← actas de sprint activas y archivadas
└── scripts/agent/               ← herramientas CLI deterministas a coste $0 tokens
```

---

## Comandos y Workflows Principales

| Comando / Workflow | Propósito | Coste |
|---|---|:--:|
| `bash scripts/agent/check-sprint.sh` | Diagnóstico de tareas y sprint activo | $0 tokens |
| `bash scripts/agent/check-session.sh` | Comprobación de locks y sesiones de trabajo | $0 tokens |
| `/session-start` | Inicia formalmente una tarea, define la caja de archivos y activa la deliberación | Mínimo |
| `/session-close` | Valida, ejecuta `verify-goal.sh`, emite digest de diseño y cierra la tarea | Mínimo |
| `/sprint-planning` | Planifica el siguiente bloque de tareas y sella el régimen operativo | Mínimo |
| `bash scripts/agent/worktree-dispatch.sh` | Despacha una tarea a un worktree o worker aislado | $0 tokens |
| `bash scripts/agent/worktree-merge.sh` | Valida e integra el trabajo de un worker en la rama principal | $0 tokens |
| `bash scripts/agent/sync.sh` | Sincroniza mejoras del núcleo de Agent OS hacia este satélite | $0 tokens |

---

## Protocolo de Arranque

Al iniciar una sesión o saludar al operador, el agente debe verificar silenciosamente el contexto con `check-session.sh` y `check-sprint.sh`, identificarse como Coordinador de Agent OS y ofrecer el estado actual del sprint junto con las opciones de trabajo inmediatas.
