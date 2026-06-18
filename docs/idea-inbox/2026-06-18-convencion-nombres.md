# Idea: Convención de nombres en agent-os
**Fecha**: 2026-06-18

## Contexto
A medida que agent-os crece, los nombres de archivos, carpetas y assets siguen patrones implícitos que no están documentados ni enforced. Esto genera inconsistencias (ej: `CHANGELOG.md` vs `changelog.md`, `assets-manifest.txt` vs `agent-os-assets-manifest.txt`) que hay que resolver caso a caso.

## Decisiones de diseño acordadas (Patrones por tipo de asset)

| Tipo de Asset | Patrón de Nombres | Ejemplos Correctos | Ejemplos Incorrectos |
|---|---|---|---|
| **Archivos raíz de proyecto (para humanos)** | MAYÚSCULAS | `CHANGELOG.md`, `README.md`, `LICENSE`, `AGENTS.md` | `changelog.md`, `agents.md` |
| **Workflows operativos del agente** | minúsculas con guiones en `.agents/workflows/` | `changelog.md`, `session-close.md`, `session-start.md` | `Changelog.md`, `SessionClose.md` |
| **Assets del core que viajan a hijos** | Prefijo `agent-os-` | `agent-os-assets-manifest.txt`, `agent-os-changelog.md` | `assets-manifest.txt` |
| **Assets locales del proyecto hijo** | Sin prefijo | `assets-manifest.txt`, `changelog.md` | `agent-os-assets-manifest.txt` |
| **Scripts** | minúsculas con guiones, verbo-sustantivo en `scripts/agent/` | `close-sprint.sh`, `update-changelog.sh`, `detect-stack.sh` | `closeSprint.sh`, `sprint-close.sh` |
| **Tasks** | `task-NNN.md` (número de 3 dígitos) en `.agents/tasks/` | `task-025.md`, `task-001.md` | `task-25.md`, `task_025.md` |
| **Sprints** | `sprint-NN-nombre.md` (número de 2 dígitos) en `docs/sprints/` | `sprint-03-core.md`, `sprint-04-polymarket.md` | `sprint-3.md`, `sprint_03.md` |
| **Ramas de trabajo** | `feat/T-NNN-descripcion-corta` | `feat/T-025-sync-assets-manifest-cleanup` | `feat/T25_sync`, `cleanup-assets` |

---

## Plan de Acción Propuesto

1.  **Nueva Rule Global: `naming-conventions.md`**
    *   Crear `.agents/rules/global/naming-conventions.md` (o integrar en una regla existente) que el agente deba consultar al crear cualquier archivo o directorio.
    *   Debe contener la tabla de convenciones y ejemplos claros.
2.  **Registro Histórico: `ADR-00X-naming-conventions.md`**
    *   Registrar un Architecture Decision Record (ADR) en `docs/adrs/` detallando el razonamiento de diseño detrás de cada uno de estos patrones para garantizar la coherencia futura del sistema.

## Criterio de éxito
*   El agente nunca pregunta "¿cómo lo llamo?". Consulta la rule y lo sabe de forma autónoma.
