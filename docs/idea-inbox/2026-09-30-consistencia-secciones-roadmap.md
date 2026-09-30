# Idea: Consistencia de secciones en roadmap.md y audit-repo.sh — 2026-09-30

**Prioridad:** Alta (Candidata Sprint 14 / Bug del sistema / DX)

**Problema:**
La plantilla base de `roadmap.md` (`templates/root/roadmap.md`) distribuida por `install.sh` genera encabezados estándar:
- `## En curso`
- `## Próximo`
- `## Descartado`

Sin embargo, `scripts/agent/audit-repo.sh` valida y exige estrictamente la presencia de las secciones legacy:
- `## En progreso`
- `## Completado`
- `## Backlog`

Esto provoca que cualquier proyecto satélite virgen recién instalado con Agent OS emita advertencias inmediatas de incompatibilidad estructural al ejecutar `audit-repo.sh`.

**Propuesta:**
1. Armonizar la validación de `audit-repo.sh` para aceptar como equivalentes canónicos:
   - `## En curso` / `## En progreso`
   - `## Completado` / `## Completado recientemente`
   - `## Próximo` / `## Backlog`
2. Garantizar que la plantilla distribuida cumpla al 100% las expectativas de todos los scripts de auditoría sin generar advertencias espurias.

**Origen:**
Hallazgo empírico durante la prueba ciega de T-090 con sujeto real en `/tmp/agent-os-blind-subject`.
