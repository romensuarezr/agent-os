# T-227 — Actualización del Runbook Operativo de Hermes VPS (`/reload-skills`, auto-sync y manual de conserjería)
Sprint: Sprint 42 | Estado: ⬜ Pendiente | Tamaño: S | Rama propuesta: feat/T-227-hermes-vps-runbook-update | Merge destino: multi-agent

## Diseño macro aprobado en planning
- **Sprint / Fecha**: Sprint 42 — 2026-11-14
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Actualizar `docs/runbooks/hermes-vps-runbook.md` incorporando:
    1. El uso y comportamiento del comando nativo `/reload-skills` para refrescar habilidades en caliente sin reiniciar el gateway.
    2. El protocolo de auto-sincronización del Core vía cronjob `no_agent: true`.
    3. El rol del contrato `/home/ubuntu/AGENTS.md` y la arquitectura del conserje bidireccional.
    4. Procedimientos de verificación y troubleshooting de WhatsApp / Telegram bridge ante cambios de skills.
- **Veredicto de diseño macro**: [APROBADO_EN_PLANNING]

---

## 1. Objetivo
Documentar exhaustivamente en el runbook canónico de Hermes la arquitectura consolidada de conserjería, el mantenimiento proactivo de skills y la recarga en caliente para que cualquier operador o agente de la flota pueda operarlo sin fricciones.

## 2. Contexto técnico
- Runbook objetivo: `docs/runbooks/hermes-vps-runbook.md`.
- Skills implicadas: `~/.hermes/skills/agent-os/`, `~/.hermes/skills/hermes-concierge/`.

## 3. Caja de archivos
- `.agents/tasks/task-227.md`
- `docs/runbooks/hermes-vps-runbook.md`
- `docs/sprints/sprint-42.md`

## 4. Plan de implementación
1. Incorporar la sección de recarga en caliente de skills con `/reload-skills`.
2. Detallar el flujo de sincronización del Core a través de `sync_agent_os_core.sh`.
3. Documentar la interacción entre `SOUL.md` y `AGENTS.md`.
4. Verificar que el runbook cumple las normas de control plane (cero literales privados).

## 5. Criterios de aceptación
- `docs/runbooks/hermes-vps-runbook.md` actualizado y conforme.
- `tests/validate-control-plane.sh` permanece 100% verde con 38/38 checks.
