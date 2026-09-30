# Idea: Unificación de firma CLI con soporte `--path` en audit-repo.sh — 2026-09-30

**Prioridad:** Media (Candidata Sprint 14 / DX / Universalización)

**Problema:**
Existe asimetría en la interfaz CLI entre los scripts de auditoría:
- `scripts/agent/audit-child.sh` soporta `--path <ruta>` para auditar cualquier repositorio destino sin necesidad de cambiar el directorio de trabajo del shell.
- `scripts/agent/audit-repo.sh` no dispone de flag `--path` y resuelve la raíz mediante `git rev-parse --show-toplevel 2>/dev/null || pwd`.

Cuando un agente orquestador o herramienta externa invoca `audit-repo.sh` apuntando a un proyecto satélite desde un directorio superior o ajeno, el script evalúa por error el repositorio padre o falla.

**Propuesta:**
1. Añadir el flag `--path <dir>` (y `-p <dir>`) a `scripts/agent/audit-repo.sh` de forma coherente con `audit-child.sh` y `setup-profiles.sh`.
2. Extender esta convención a cualquier otra herramienta de diagnóstico satélite.

**Origen:**
Hallazgo empírico durante la prueba ciega de T-090 con sujeto real en `/tmp/agent-os-blind-subject`.
