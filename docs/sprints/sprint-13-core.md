# Sprint 13 — Escalado, Distribución Universal del Core & Ciclo de Vida de Satélites

**Período**: 2026-10-01 → 2026-10-10  
**Objetivo**: Escalar la distribución del core de Agent OS a cualquier repositorio hijo mediante un mecanismo de instalación desatendido, universal e idempotente (one-liner / CLI), resolviendo el namespacing de configuración runtime (`.agents/config/`), blindando la detección defensiva de stacks ante repositorios desordenados (dualidad lockfile vs PATH), dotando a los proyectos satélite de auditoría de salud y drift (`audit-child.sh`), y cerrando con la prueba ciega 0-contexto obligatoria sobre un repositorio efímero.

---

## Estado
🟡 En curso

---

## Tareas del Sprint

| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| T-085 | Namespacing de configuración runtime (`config/` → `.agents/config/`) y blindaje de overlays | Arquitectura / Core Standard | M | 🟢 Completada | — | [.agents/tasks/_archived/task-085.md](file:///home/romen/orca/workspaces/agent-os/Core-Hardening/.agents/tasks/_archived/task-085.md) |
| T-086 | Detección defensiva de stack y runtimes en `detect-stack.sh` (resolución lockfile vs PATH) | Bug del sistema / DX | S | 🟢 Completada | — | [.agents/tasks/_archived/task-086.md](file:///home/romen/orca/workspaces/agent-os/Core-Hardening/.agents/tasks/_archived/task-086.md) |
| T-087 | Distribución universal del Core — One-Liner reejecutable e instalación idempotente pineada a release tag | Universalización / Core | M | 🟢 Completada | T-085 | [.agents/tasks/_archived/task-087.md](file:///home/romen/orca/workspaces/agent-os/Core-Hardening/.agents/tasks/_archived/task-087.md) |
| T-088 | Ledger de versiones del core y auditoría de salud en satélites (`audit-child.sh` con suite dedicada) | Gobernanza / DX | M | 🟢 Completada | T-087 | [.agents/tasks/_archived/task-088.md](file:///home/romen/orca/workspaces/agent-os/Core-Hardening/.agents/tasks/_archived/task-088.md) |
| T-089 | Setup guiado y generación determinista de perfiles adaptados al stack | DX / Universalización | S | ⬜ Pendiente | T-085, T-086 | `.agents/tasks/task-089.md` |
| T-090 | Prueba ciega 0-contexto de distribución e instalación desatendida en repo efímero | Validación Externa / QA | S | ⬜ Pendiente | T-087, T-088, T-089 | `.agents/tasks/task-090.md` |

---

## Requisitos de Implementación y Restricciones Arquitectónicas

1. **Caja Exhaustiva y Trazabilidad en T-085**:
   - Se migra `config/` a `.agents/config/`.
   - Se actualizan todos los scripts consumidores, skills, rules y docs vivos.
   - **Regla de Invarianza Histórica**: Task files históricos (`.agents/tasks/task-0*.md`) y documentación en `_archived/` NO se reescriben. Solo código y documentación viva.
2. **Pinchado de Versión en One-Liner (T-087)**:
   - El instalador remoto debe pinearse a un tag de release explícito (`https://raw.githubusercontent.com/romensuarezr/agent-os/<tag>/scripts/agent/install.sh`), nunca a `main`.
3. **Decisión Arquitectónica de Testing en T-088**:
   - `audit-child.sh` es una herramienta satélite y se valida fuera de `validate-control-plane.sh` mediante suite dedicada `tests/test-audit-child.sh`, preservando estrictamente el invariante 12/12 del control plane del core.
4. **Idempotencia (`mv-no-rm`)**:
   - Ninguna herramienta de sincronización o instalación debe sobreescribir o borrar silenciosamente personalizaciones locales en proyectos hijos.
5. **Validación Continua**:
   - Toda tarea debe superar `tests/validate-control-plane.sh` (12/12) y mantener working tree limpio.

---

## Criterios de cierre del sprint

- [ ] Las 6 tareas completadas con sus criterios verificados.
- [ ] `tests/validate-control-plane.sh` 12/12 sin regresiones.
- [ ] `git ls-files config/` devuelve 0 resultados (namespacing `.agents/config/` completado).
- [ ] Detección defensiva de stack validada contra lockfiles huérfanos.
- [ ] One-liner pineado a tag de release y validado en repo limpio.
- [ ] T-090 en verde: prueba ciega 0-contexto superada al 100% (5/5 hitos).
- [ ] `changelog.md` y `roadmap.md` actualizados atómicamente al cierre.
