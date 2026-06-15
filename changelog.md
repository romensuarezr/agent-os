# Changelog — Agent OS Core

Historial de cambios y releases del núcleo de Agent OS.

## [1.1.0] — 2026-06-15
### Añadido
- **Flujo de Onboarding Inteligente (`sprint-inicial.md`)**: Creado como ritual exclusivo de una sola ejecución para auditar y adaptar repositorios preexistentes.
- **Marca de Onboarding (`onboarding-complete.md`)**: Implementada la generación automática de un archivo de marca al aplicar con éxito la auditoría, garantizando la idempotencia del proceso.
- **Sincronización de Workflows**: Modificado `sync.sh` para propagar de manera segura nuevos flujos y rituales globales al proyecto destino.
- **Detección Desacoplada de Actualizaciones**: Añadido aviso de commits remotos en `sync.sh` y registro de fecha de sincronización local en `.agents/context/last-sync.md`.
- **Integración en Sprint Planning**: Añadida una instrucción en `sprint-planning.md` para recomendar la sincronización si la marca local tiene más de 7 días o si no existe.

### Modificado
- `scripts/agent/audit-repo.sh`: Implementada la salvaguarda de working tree limpio, control de ambigüedad en apply, y generación del archivo de marca.
- `scripts/agent/sync.sh`: Modificado para copiar el changelog del core, escribir la fecha del último sync y comprobar silenciosamente actualizaciones en GitHub.

---

## [1.0.0] — 2026-06-12
### Añadido
- **Estructura Base de Agentes**: Directorios `.agents/rules/`, `.agents/workflows/`, `.agents/skills/`.
- **Scripts del Ciclo de Vida**:
  - `check-session.sh` y `check-sprint.sh`.
  - `close-task.sh` y `close-sprint.sh`.
  - `install.sh` y `sync.sh`.
  - `inventory-check.sh` y `update-mvp-tracker.sh`.
- **Workflows Base**: `session-start.md`, `session-close.md`, `sprint-planning.md`, `changelog.md`, `honesto.md`.
