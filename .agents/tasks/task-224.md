# T-224 — Script Determinista de Sincronización del Core y Regeneración Atómica de Symlinks de Skills en VPS
Sprint: Sprint 42 | Estado: ⬜ Pendiente | Tamaño: S | Rama propuesta: feat/T-224-hermes-core-sync-script | Merge destino: multi-agent

## Diseño macro aprobado en planning
- **Sprint / Fecha**: Sprint 42 — 2026-11-14
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Implementar un script bash determinista `/home/ubuntu/scripts/sync_agent_os_core.sh` en `<nodo-inferencia>`.
  - El script realiza `git fetch` y `git pull --ff-only origin multi-agent` sobre `/home/ubuntu/projects/agent-os`.
  - Itera sobre `.agents/skills/` y asegura que cada subcarpeta tenga su symlink correspondiente en `~/.hermes/skills/agent-os/` (enlazando de inmediato skills nuevas como `orca-cli`).
  - Aplica permisos `chmod +x` a `scripts/agent/*.sh` y `scripts/ops/*.sh`.
  - Registra el timestamp y la versión actual en `~/.hermes/runtime/last_core_update.json`.
- **Veredicto de diseño macro**: [APROBADO_EN_PLANNING]

---

## 1. Objetivo
Permitir que el entorno de Hermes en el VPS actualice el Core de Agent OS y sus habilidades asociadas de forma idempotente y determinista a coste $0 tokens.

## 2. Contexto técnico
- Nodo: `<nodo-inferencia>` (VPS de inferencia).
- Repositorio del Core en VPS: `/home/ubuntu/projects/agent-os`.
- Directorio de skills en Hermes: `~/.hermes/skills/agent-os/`.
- Rama rastreada: `multi-agent`.

## 3. Caja de archivos
- `.agents/tasks/task-224.md`
- `docs/sprints/sprint-42.md`
- `/home/ubuntu/scripts/sync_agent_os_core.sh` (en `<nodo-inferencia>`)

## 4. Plan de implementación
1. Diseñar el script `sync_agent_os_core.sh` con manejo de errores `set -euo pipefail`.
2. Probar la ejecución sobre `/home/ubuntu/projects/agent-os` llevando el repo a `v1.37.0`.
3. Validar que el symlink para `orca-cli` y cualquier otra skill nueva queda creado y activo.
4. Confirmar que no hay residuos ni mutaciones en el working tree del VPS.

## 5. Criterios de aceptación
- `/home/ubuntu/projects/agent-os` avanza a `v1.37.0` limpiamente.
- `~/.hermes/skills/agent-os/orca-cli` queda enlazado y accesible.
- El script retorna exit code 0 y emite resumen determinista.
