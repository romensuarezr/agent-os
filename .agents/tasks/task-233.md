# T-233 — Homologación y Actualización Integral del Stack de Flota (OpenCode, Hermes, Infisical, Orca)
Sprint: Sprint 44 | Estado: ⬜ Pendiente | Tamaño: S | Rama propuesta: feat/T-233-fleet-tooling-update | Merge destino: multi-agent

## Diseño macro aprobado en planning
- **Sprint / Fecha**: Sprint 44 — 2026-11-23
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Homologar y registrar las versiones upstream detectadas por la sonda determinista (`check-tooling-updates.sh`):
    - OpenCode: v2.3.2 (actualmente v2.2.6)
    - Hermes Agent: v0.23.3 (actualmente v0.21.2 en local, v0.21.1 en VPS)
    - Infisical CLI: v0.45.14 (actualmente v0.43.137)
    - Orca IDE: v1.4.268 (actualmente v1.4.264)
  - Actualizar `scripts/agent/fleet-version.sh`, `.agents/config/fleet.example.yaml`, `.agents/config/fleet.yaml` y la matriz de roles de herramientas de la flota.
  - Archivar los 4 borradores procesados de `docs/idea-inbox/` a `docs/idea-inbox/_archived/` manteniendo el inbox limpio.
  - Verificar que la sonda determinista refleja las versiones esperadas sin alertas falsas.
- **Veredicto de diseño macro**: [APROBADO_EN_PLANNING]

---

## 1. Objetivo
Actualizar formalmente el catálogo de versiones del tooling de la flota, sincronizando matrices de arquitectura y archivando los borradores de idea-inbox para dejar el stack homologado antes de evolucionar las skills e integraciones de bots.

## 2. Contexto técnico
- Sonda CLI: `scripts/agent/check-tooling-updates.sh`.
- Script de versiones: `scripts/agent/fleet-version.sh`.
- Borradores en: `docs/idea-inbox/2026-11-21-*.md`.

## 3. Caja de archivos
- `scripts/agent/fleet-version.sh`
- `.agents/config/fleet.example.yaml`
- `docs/architecture/tools/fleet-cli-roles-matrix.md`
- `docs/idea-inbox/`
- `.agents/tasks/task-233.md`
- `docs/sprints/sprint-44.md`

## 4. Plan de implementación
1. Actualizar las constantes y comprobaciones de versión en `scripts/agent/fleet-version.sh` para OpenCode (2.3.2), Hermes (0.23.3), Infisical (0.45.14) y Orca (1.4.268).
2. Reflejar las nuevas versiones en `docs/architecture/tools/fleet-cli-roles-matrix.md` y `.agents/config/fleet.example.yaml`.
3. Mover los 4 borradores `2026-11-21-*.md` a `docs/idea-inbox/_archived/`.
4. Ejecutar `scripts/agent/fleet-version.sh` y certificar que no hay desvíos.

## 5. Criterios de aceptación
- `docs/idea-inbox/` queda limpio sin archivos de tooling pendientes.
- `fleet-version.sh` reporta las versiones homologadas.
- La matriz de roles y catálogos de flota quedan 100% consistentes.
