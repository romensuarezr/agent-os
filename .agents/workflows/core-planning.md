# Workflow: /core-planning

> Equivalente a `/sprint-planning` pero para el propio core de agent-os.
> Úsalo cuando vayas a planificar el siguiente sprint de evolución del sistema.

---

## Cuándo usar este workflow

- Al cerrar un sprint del core y arrancar el siguiente
- Cuando hay acumulación de mejoras pendientes (ideas de proyectos hijos, bugs reportados, universalizaciones)
- Al inicio de una sesión de trabajo sobre agent-os

---

## Pasos

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

- [ ] CORE-NN: [descripción] — [categoría]

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
bash scripts/agent/close-task.sh CORE-NN

# Generar digest del estado
bash scripts/agent/generate-digest.sh

# Cerrar el sprint
bash scripts/agent/close-sprint.sh
```
