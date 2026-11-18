# T-232 — Homologación de Tooling de Flota (OpenCode, Hermes, Orca, Infisical)
Sprint: Sprint 43 | Estado: ✅ Hecho | Tamaño: S | Rama propuesta: feat/T-232-fleet-tooling-homologation | Merge destino: multi-agent

## Diseño macro aprobado en planning
- **Sprint / Fecha**: Sprint 43 — 2026-11-18
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Homologar las versiones detectadas por la sonda determinista (`check-tooling-updates.sh`):
    - OpenCode: v2.3.2 (actualmente v2.2.6)
    - Orca: v1.4.262 (actualmente v1.4.261)
    - Hermes: v0.23.2 (actualmente v0.21.2)
    - Infisical: v0.45.11 (actualmente v0.43.137)
  - Actualizar `scripts/agent/fleet-version.sh`, perfiles de agentes en `.agents/profiles/` y matrices de tooling según aplique.
  - Archivar los borradores procesados de `docs/idea-inbox/` a `docs/idea-inbox/_archived/` para mantener limpio el inbox.
  - Verificar que la sonda `check-tooling-updates.sh` reporta estado consistente tras la homologación.
- **Veredicto de diseño macro**: [APROBADO_EN_PLANNING]

---

## 1. Objetivo
Mantener la trazabilidad, catálogos y perfiles de agentes alineados con las versiones upstream de las herramientas esenciales de la flota sin deuda técnica pasiva.

## 2. Contexto técnico
- Sonda CLI: `scripts/agent/check-tooling-updates.sh`.
- Script de versiones: `scripts/agent/fleet-version.sh`.
- Borradores en: `docs/idea-inbox/`.

## 3. Caja de archivos
- `scripts/agent/fleet-version.sh`
- `.agents/profiles/` (si referencian versiones concretas)
- `docs/idea-inbox/`
- `.agents/tasks/task-232.md`
- `docs/sprints/sprint-43.md`

## 4. Plan de implementación
1. Revisar los cambios introducidos en OpenCode v2.3.2, Orca v1.4.262, Hermes v0.23.2 e Infisical v0.45.11 a partir de las notas de release capturadas.
2. Actualizar las referencias de versión en `fleet-version.sh` y documentación relevante de la flota.
3. Mover los 4 archivos de borrador de `docs/idea-inbox/` a `docs/idea-inbox/_archived/`.
4. Ejecutar `scripts/agent/fleet-version.sh` y validar que los checks de control plane se mantienen verdes.

## 5. Criterios de aceptación
- `docs/idea-inbox/` queda limpio sin borradores pendientes.
- `fleet-version.sh` y la suite de validación pasan limpiamente.
