# AGENTS.md — agent-os

> Guía de arquitectura y operación para agentes que trabajan sobre el propio core de agent-os.

---

## ¿Qué es agent-os?

Sistema de trabajo portable para agentes de IA. Se instala en cualquier repositorio de código y proporciona una estructura operativa estándar: workflows, skills, rules y scripts bash que el agente usa para planificar, ejecutar y registrar su trabajo.

agent-os es ciudadano de primera clase de sí mismo — tiene su propio sprint, sus propias tareas, y usa sus propias herramientas para evolucionar.

---

## Estructura del repositorio

```
agent-os/
├── AGENTS.md                    ← este archivo
├── README.md                    ← intro pública
├── changelog.md                 ← historial de cambios del core
├── .agents/
│   ├── rules/                   ← reglas globales (agnósticas de stack)
│   ├── skills/                  ← skills globales instalables en proyectos hijos
│   ├── workflows/               ← workflows globales + core-planning.md
│   ├── templates/               ← plantillas de tareas y sprints
│   └── context/
│       └── last-sync.md         ← marca de estado del core
├── scripts/agent/
│   ├── install.sh               ← instalación en proyectos hijos (--self para bootstrapping)
│   ├── sync.sh                  ← sincroniza assets globales → proyectos hijos
│   ├── contribute.sh            ← promueve mejoras de hijos → core
│   ├── check-sprint.sh          ← verifica estado del sprint activo
│   ├── check-session.sh         ← contexto de sesión para el agente
│   ├── close-sprint.sh          ← cierra y archiva el sprint
│   ├── close-task.sh            ← cierra una tarea individual
│   ├── audit-repo.sh            ← detecta incompatibilidades en repos con vida previa
│   ├── generate-digest.sh       ← genera resumen del estado del proyecto
│   └── lib/                     ← utilidades compartidas (detect-stack.sh, etc.)
├── docs/
│   ├── sprints/                 ← sprints del core (sprint-01-core.md, ...)
│   └── adrs/                    ← Architecture Decision Records
└── templates/
    ├── docs/                    ← plantillas de mvp-tracker, implemented, etc.
    └── root/                    ← plantillas de changelog, roadmap
```

---

## Principios de diseño

1. **Scripts universales** — ningún script asume un stack concreto. Detección de stack en `lib/detect-stack.sh`.
2. **No destructivo por defecto** — modo detección siempre seguro. Modificaciones requieren `--apply` y working tree limpio.
3. **SRP estricto** — cada script, skill y workflow tiene una única responsabilidad.
4. **Global pequeño, local fino** — skills y rules globales son agnósticas. Lo específico vive en el proyecto hijo.
5. **Trazabilidad** — operaciones importantes generan marcas (`last-sync.md`, commits atómicos).

---

## Flujo de datos

```
agent-os (core)
    │
    ├──sync.sh──────────────────▶  proyecto hijo (Kanarii, Polymarket, surf-app...)
    │                               assets globales → .agents/ del hijo
    │
    └──◀──contribute.sh──────────  proyecto hijo
                                    mejoras locales → PR al core
```

**Invariante**: `sync.sh` nunca va en dirección inversa. Para promover mejoras de un hijo al core se usa `contribute.sh`, que crea un PR.

---

## Trabajar sobre el propio core

Para operar agent-os sobre sí mismo, el agente usa el mismo flujo que en cualquier proyecto hijo:

```bash
# Ver estado del sprint activo
bash scripts/agent/check-sprint.sh

# Iniciar sesión de trabajo
bash scripts/agent/check-session.sh

# Planificar el próximo sprint del core
# → usar workflow: .agents/workflows/core-planning.md
```

### Bootstrapping inicial (una sola vez)

Si la estructura operativa del core no existe aún:

```bash
bash scripts/agent/install.sh . --self
```

El flag `--self` omite la copia de scripts (ya están) y solo crea las carpetas operativas que faltan.

---

## Política de breaking changes

Un cambio en el core es **breaking** si:
- Renombra o elimina un script que los proyectos hijos ya tienen instalado
- Cambia la firma de argumentos de un script existente
- Modifica la estructura de carpetas que los scripts esperan encontrar

Ante un breaking change:
1. Documenta el cambio en `docs/adrs/` con fecha y razonamiento
2. Actualiza `changelog.md`
3. Notifica en el commit con `BREAKING:` en el subject
4. Los proyectos hijos deberán re-ejecutar `sync.sh` para recibir la actualización

---

## Cuándo editar directamente vs. usar contribute.sh

| Situación | Acción |
|---|---|
| Eres el mantenedor del core y trabajas en el repo agent-os | Edita directamente, commit atómico |
| Encontraste una mejora trabajando en un proyecto hijo | Usa `contribute.sh` para crear PR al core |
| El cambio afecta solo al proyecto hijo | No lo subas al core |
| Tienes duda | Abre issue en agent-os con el contexto |

---

## Convenciones de commits

```
feat(scope): descripción
fix(scope): descripción  
refactor(scope): descripción
docs(scope): descripción
BREAKING: descripción
```

Scopes habituales: `install`, `sync`, `audit`, `self`, `workflows`, `skills`, `rules`, `lib`
