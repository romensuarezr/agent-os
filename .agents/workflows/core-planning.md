---
description: Planifica y abre el siguiente sprint de evolución del núcleo de Agent OS.
---

# core-planning

Este workflow define el ritual para planificar el siguiente sprint de evolución del núcleo de Agent OS (self-hosted). Úsalo al cerrar un sprint, al acumular mejoras pendientes de proyectos hijos, o al inicio de una sesión de desarrollo sobre el propio core.

## Objetivo

- Cerrar el sprint anterior del core y evaluar el spillover.
- Recolectar e incorporar mejoras o bugs provenientes de proyectos hijos.
- Inicializar de forma consistente el nuevo archivo de sprint del core.

## Archivos y rutas a revisar

- [last-sync.md](file:///.agents/context/last-sync.md) — Marca de estado actual y sprint activo.
- [docs/sprints/](file:///docs/sprints/) — Sprints históricos del core (`sprint-NN-core.md`).
- [docs/external-inbox/](file:///docs/external-inbox/) — Sugerencias promocionadas por proyectos hijos.
- [roadmap.md](file:///roadmap.md) — Hoja de ruta general del sistema.

## Protocolo

### 1. Revisar estado actual

```bash
bash scripts/agent/check-sprint.sh
```

Anota:
- Tareas completadas en el sprint anterior
- Tareas que quedaron pendientes
- Deuda técnica identificada

### 2. Revisar el inbox de mejoras

Fuentes a revisar en orden:
- `.agents/context/last-sync.md` — notas de contexto acumuladas
- `docs/external-inbox/` — ideas llegadas desde proyectos hijos via `contribute.sh`
- `changelog.md` — patrones recurrentes que piden una solución sistémica
- Issues abiertos en el repo de GitHub

### 3. Clasificar candidatos al sprint

Categorías del core (distintas a un producto):

| Categoría | Descripción | Ejemplo |
|---|---|---|
| **Universalización** | Hacer un script más agnóstico de stack | Sacar hardcodes de paths a `lib/` |
| **Nueva herramienta** | Script o workflow que falta | `self-check.sh`, workflow de ADR |
| **Bug del sistema** | Script que falla en ciertos repos | `audit-repo.sh` con repos sin git |
| **Documentación** | AGENTS.md, ADRs, ejemplos | Documentar una decisión de diseño |
| **DX del agente** | Mejorar la experiencia del agente al usar el sistema | Mensajes de error más claros |

### 4. Definir el sprint

Crea `docs/sprints/sprint-NN-core.md` usando esta estructura:

```markdown
# Sprint NN — Core

**Período**: YYYY-MM-DD → YYYY-MM-DD  
**Objetivo**: [una frase que describe el foco del sprint]

## Tareas

- [ ] T-XXX: [descripción] — [categoría]

## Criterio de éxito

[Cómo sabremos que el sprint fue exitoso]

## Notas
```

### 5. Actualizar last-sync.md

Actualiza `.agents/context/last-sync.md` con el sprint activo nuevo.

### 6. Commit de planificación

```bash
git add docs/sprints/ .agents/context/last-sync.md
git commit -m "chore(self): open sprint-NN-core"
```

---

## Diferencias con /sprint-planning de proyectos hijos

| Aspecto | Proyectos hijos | agent-os core |
|---|---|---|
| Foco | Features de producto | Mejoras al sistema de trabajo |
| Tracker | `docs/mvp-tracker.md` | No aplica — el "producto" son los propios scripts |
| Éxito | Funcionalidad entregada | Scripts más robustos, portables o documentados |
| Tareas | User stories | Mejoras técnicas / universalizaciones |

---

## Comandos útiles durante el sprint

```bash
# Estado del sprint
bash scripts/agent/check-sprint.sh

# Cerrar una tarea
bash scripts/agent/close-task.sh T-XXX

# Generar digest del estado
bash scripts/agent/generate-digest.sh

# Cerrar el sprint
bash scripts/agent/close-sprint.sh
```

## Reglas

- NUNCA planifiques un nuevo sprint del core si existen cambios locales sin commitear en Git.
- Asegúrate de que las tareas del core sigan el formato de identificador estándar `T-XXX`.
- Toda nueva herramienta o cambio estructural en los scripts del core debe planificar la redacción de su correspondiente ADR (Architecture Decision Record) en `docs/adrs/`.
- No alteres ni elimines scripts existentes en el sprint sin justificación técnica documentada previamente.
