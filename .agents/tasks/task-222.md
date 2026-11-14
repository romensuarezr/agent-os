# T-222 — Sincronización y Propagación de Herramientas Ops (scripts/ops/coolify.sh) en sync.sh e install.sh
Sprint: Sprint 41 | Estado: ⬜ Pendiente | Tamaño: S | Rama propuesta: feat/T-222-propagate-ops-tools-in-sync | Merge destino: multi-agent

## Diseño macro aprobado en planning
- **Sprint / Fecha**: Sprint 41 — 2026-11-14
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Incorporar la sincronización determinista de `scripts/ops/` en `scripts/agent/sync.sh` y en `scripts/agent/install.sh`.
  - Asegurar que `scripts/ops/coolify.sh` se replique en los satélites con permisos de ejecución `chmod +x`.
  - Respetar los modos de `sync.sh`: `--dry-run` (simula sin escribir), `--cleanup` y exclusión en `--self`.
  - Actualizar `tests/validate-control-plane.sh` para verificar que `scripts/ops/` se incluye en la distribución estándar.
- **Veredicto de diseño macro**: [APROBADO_EN_PLANNING]

---

## 1. Objetivo
Resolver la discrepancia donde la habilidad `coolify-admin` hace referencia a `scripts/ops/coolify.sh` pero los satélites no reciben dicho script al ejecutar `install.sh` o `sync.sh`.

## 2. Contexto técnico
- Herramienta de operaciones: `scripts/ops/coolify.sh` (10.2 KB).
- Script de instalación: `scripts/agent/install.sh`.
- Script de sincronización: `scripts/agent/sync.sh`.
- Skill dependiente: `.agents/skills/coolify-admin/SKILL.md`.

## 3. Caja de archivos
- `.agents/tasks/task-222.md`
- `scripts/agent/sync.sh`
- `scripts/agent/install.sh`
- `tests/validate-control-plane.sh`
- `docs/sprints/sprint-41.md`

## 4. Plan de implementación
1. Analizar el bloque de sincronización de scripts en `scripts/agent/sync.sh`.
2. Añadir la copia e inspección de `scripts/ops/` hacia `$TARGET_PROJECT/scripts/ops/`, aplicando `chmod +x` a los ejecutables en destino y respetando `--dry-run`.
3. Actualizar `scripts/agent/install.sh` para crear `$TARGET/scripts/ops/` y copiar los scripts de operaciones en instalaciones nuevas.
4. Validar en `tests/validate-control-plane.sh` la presencia y permisos de `scripts/ops/coolify.sh`.

## 5. Criterios de aceptación
- `bash scripts/agent/sync.sh --dry-run .` detecta `scripts/ops/` si corresponde sin errores.
- Al ejecutar `sync.sh` sobre un satélite, `scripts/ops/coolify.sh` queda instalado y ejecutable.
- `tests/validate-control-plane.sh` pasa en verde sin regresiones.
