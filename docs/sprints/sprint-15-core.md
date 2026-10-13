# Sprint 15 — Publicación Remota y Honestidad de los Scripts de Cierre

## Estado
🟡 En curso

## Tareas
| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| T-100 | Fixes de `close-task.sh` y `close-sprint.sh`: que actualicen el enlace al archivar y no affirmen más de lo que hacen | Bug del sistema / DX | S | ✅ Completada | — | [.agents/tasks/_archived/task-100.md](.agents/tasks/_archived/task-100.md) |
| T-101 | Publicación remota de ramas de tarea: extender `promote-to-main.sh` con `--push-source`, `--merge-commit` y `--pr` | DX / Universalización | M | ✅ Completada | T-100 | [.agents/tasks/_archived/task-101.md](.agents/tasks/_archived/task-101.md) |
| T-102 | Mapa global de flujos de Agent OS con niveles C4, generado y versionado (humano + digest para agentes) | Documentación / DX | M | ⬜ Pendiente | T-100 | — |

## Notas de planning

- **Alcance por sprint-14 cerrado**: 8/8 tareas completadas. Este sprint abre con trabajo
  que ya estaba identificado y documentado, no con discovery.
- **T-100 va primero por decisión del usuario**, no por tamaño: los dos scripts de cierre
  son la capa sobre la que se apoya el resto del flujo (T-101 reutiliza el mismo patrón de
  "stagear lo que se afirma haber hecho"). Arreglarlos después significaría seguir parcheando
  a mano.
- **Verificado por el firewall 2c**: los tres candidatos **no** están implementados.
  `changelog.md` registra fixes de `close-task.sh` (mensajes de commit y guardia de sprint),
  pero ninguno toca la reescritura del enlace ni el staging del working tree.
- **Descartado por ya implementado (regla 2c)**: idea de namespacing
  `config/` → `.agents/config/` del 2026-09-28. Implementada en T-085 (sprint-13).
- **Idea reutilizada**: la tarea de auditoría de scripts en hijos queda **aparcada** hasta
  que T-100 esté mergeada. Ese era el acuerdo previo y este sprint lo respeta.
- **Riesgo de seguridad a vigilar en T-101**: `close-task.sh` usa `git add -A`, que se traga
  cambios ajenos del working tree. Es comportamiento preexistente y **no** se cambia en
  este sprint; queda documentado en el changelog cuando se toque `close-sprint.sh`.
- **Deuda visible detectada durante el planning**: `docs/sprints/_archived/sprint-06..13`
  contienen enlaces `file://***REMOVED-PATH***/...` con rutas personales. No entra en este sprint
  (fuera del foco), queda anotada en el roadmap para triaje.

### Decisiones del usuario en la apertura

1. Los fixes de `close-*.sh` se resuelven **antes** de abrir capacidad nueva.
2. La auditoría de scripts en hijos queda aparcada.
3. Ningún camino de `check-sprint.sh` puede proponer `sprint-01` (corregido en `main`).