# T-225 — Integración del Cronjob `no_agent: true` de Auto-Sincronización en Hermes y Telemetría Matutina
Sprint: Sprint 42 | Estado: ⬜ Pendiente | Tamaño: S | Rama propuesta: feat/T-225-hermes-cron-core-sync | Merge destino: multi-agent

## Diseño macro aprobado en planning
- **Sprint / Fecha**: Sprint 42 — 2026-11-14
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Registrar el job `Agent OS Core Sync` en `~/.hermes/cron/jobs.json` con `"no_agent": true` y `"script": "sync_agent_os_core.sh"`.
  - Horario programado: diario a las 06:00 AM (o cada 12 horas `0 6,18 * * *`).
  - Integrar la telemetría en `fleet_morning_briefing.py`: leer `last_core_update.json` y, si hubo actualización en las últimas 24 horas, incluir una línea destacada en el resumen matutino de WhatsApp de las 08:30 AM.
- **Veredicto de diseño macro**: [APROBADO_EN_PLANNING]

---

## 1. Objetivo
Automatizar la ejecución periódica y desatendida de la sincronización del Core en el VPS sin consumo de tokens de inferencia, notificando al operador en su briefing diario de WhatsApp.

## 2. Contexto técnico
- Archivo de cron de Hermes: `~/.hermes/cron/jobs.json`.
- Script de briefing matutino: `/home/ubuntu/fleet_morning_briefing.py`.
- Canal de entrega: WhatsApp (`deliver: "whatsapp:<USER_PHONE>@lid"`).

## 3. Caja de archivos
- `.agents/tasks/task-225.md`
- `docs/sprints/sprint-42.md`
- `~/.hermes/cron/jobs.json` (en `<nodo-inferencia>`)
- `/home/ubuntu/fleet_morning_briefing.py` (en `<nodo-inferencia>`)

## 4. Plan de implementación
1. Validar el formato JSON de `jobs.json` respetando el esquema oficial de Hermes Agent.
2. Inyectar la entrada de job con ID único y `no_agent: true`.
3. Actualizar `fleet_morning_briefing.py` para consultar si hubo release nueva y reportarla.
4. Validar ejecución simulada sin errores.

## 5. Criterios de aceptación
- `jobs.json` es sintácticamente válido y Hermes cron lo carga sin warnings.
- `fleet_morning_briefing.py` reporta la versión del Core correctamente.
- Cero consumo de tokens en la ejecución del cron.
