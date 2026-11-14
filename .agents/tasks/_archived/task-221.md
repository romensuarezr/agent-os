# T-221 — Auditoría Bidireccional de Drift Core ↔ Satélites (audit-satellites.sh --skills)
Sprint: Sprint 41 | Estado: ✅ Hecho | Tamaño: M | Rama propuesta: feat/T-221-bidirectional-satellite-skills-audit | Merge destino: multi-agent

## Diseño macro aprobado en planning
- **Sprint / Fecha**: Sprint 41 — 2026-11-14
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Incorporar la bandera `--skills` en `scripts/agent/audit-satellites.sh`.
  - Comparar el conjunto de habilidades en `.agents/skills/` del Core frente a cada satélite declarado en `.agents/config/satellites.yaml`.
  - Detección de tres estados de drift de habilidades:
    1. `ORPHAN_IN_SATELLITE`: Skill creada en el satélite que no existe en el Core (sugiere `contribute.sh`).
    2. `MODIFIED_IN_SATELLITE`: Skill modificada localmente en el satélite con respecto al Core (sugiere `contribute.sh` o `sync.sh`).
    3. `MISSING_IN_SATELLITE`: Skill global del Core no instalada en el satélite (sugiere `sync.sh`).
  - Preservar los principios: Solo Lectura ($0 tokens), salida formateada legible y soporte estructurado `--json`.
  - Extender la suite de validación `tests/validate-control-plane.sh` para verificar la nueva bandera `--skills`.
- **Veredicto de diseño macro**: [APROBADO_EN_PLANNING]

---

## 1. Objetivo
Detectar automáticamente cualquier divergencia en las habilidades entre el Core y los satélites para evitar la fragmentación del ecosistema y facilitar que las innovaciones de los satélites se incorporen de forma determinista al Core.

## 2. Contexto técnico
- Script de auditoría de satélites: `scripts/agent/audit-satellites.sh`.
- Configuración de satélites: `.agents/config/satellites.yaml`.
- Suite de control plane: `tests/validate-control-plane.sh`.

## 3. Caja de archivos
- `.agents/tasks/task-221.md`
- `scripts/agent/audit-satellites.sh`
- `tests/validate-control-plane.sh`
- `docs/sprints/sprint-41.md`

## 4. Plan de implementación
1. Añadir el flag `--skills` al analizador de argumentos y ayuda de `scripts/agent/audit-satellites.sh`.
2. Implementar la función de inspección de skills comparando las carpetas `.agents/skills/` del Core y del satélite.
3. Formatear la salida en modo texto y en el bloque JSON `skills_drift`.
4. Añadir prueba de validación en `tests/validate-control-plane.sh` verificando el comportamiento de `audit-satellites.sh --skills`.
5. Ejecutar la auditoría sobre los satélites reales de la máquina para comprobar su correcto funcionamiento.

## 5. Criterios de aceptación
- `audit-satellites.sh --help` documenta `--skills`.
- `audit-satellites.sh --skills` identifica correctamente skills modificadas o huérfanas en satélites.
- Salida JSON incluye el bloque `skills_drift` de manera estructurada.
- `tests/validate-control-plane.sh` pasa en verde con todas las verificaciones.
