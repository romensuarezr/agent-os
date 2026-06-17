# Sprint 01 — Core

**Período**: 2026-05 → 2026-06-16  
**Objetivo**: Establecer la infraestructura base de agent-os como sistema portable y funcional.

---

## Tareas completadas

- [x] CORE-01: `install.sh` — instalación de agent-os en proyectos hijos
- [x] CORE-02: `sync.sh` — sincronización de assets globales → proyectos hijos
- [x] CORE-03: `contribute.sh` — promoción de mejoras de hijos → core
- [x] CORE-04: `audit-repo.sh` — detección de incompatibilidades en repos con vida previa
- [x] CORE-05: `check-sprint.sh` — verificación de estado del sprint activo
- [x] CORE-06: `check-session.sh` — contexto de sesión para el agente
- [x] CORE-07: `close-sprint.sh` — cierre y archivo del sprint
- [x] CORE-08: `close-task.sh` — cierre de tareas individuales
- [x] CORE-09: `generate-digest.sh` — resumen del estado del proyecto
- [x] CORE-10: `update-changelog.sh` — actualización del changelog
- [x] CORE-11: `audit-mvp-tracker.sh` — auditoría del tracker de MVP
- [x] CORE-12: `check-inbox.sh` — revisión del inbox de ideas
- [x] CORE-13: `check-lazy-planning.sh` — detección de planificación insuficiente
- [x] CORE-14: `inventory-check.sh` — inventario del estado del repo
- [x] CORE-15: Estructura `.agents/` con rules, skills, workflows, templates
- [x] CORE-16: Onboarding de proyectos hijos (Kanarii, Polymarket, surf-app)
- [x] CORE-17: Bootstrap self-hosted — agent-os como ciudadano de primera clase de sí mismo

## Criterio de éxito

agent-os puede instalarse en cualquier repo nuevo y proporcionar inmediatamente un entorno operativo funcional para agentes. El core tiene su propia estructura operativa y puede ser gestionado por un agente igual que cualquier proyecto hijo.

## Notas

- Los scripts de este sprint fueron desarrollados y validados en proyectos reales (Kanarii, Polymarket)
- El modo self-hosted (CORE-17) cierra el bootstrap inicial del sistema
- Siguiente sprint: universalizaciones pendientes, mejoras de DX del agente, documentación de ADRs
