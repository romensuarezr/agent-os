# Sprint 40 — 2026-11-14 → 2026-11-18

## Estado
🟢 Completado (100%)

## Tareas
| ID | Descripción | Tamaño | Estado | Dependencias | Task file |
|---|---|---|---|---|---|
| T-214 | Sincronización del Core de Agent OS en <nodo-inferencia> (v1.35.0 y 31 skills) | M | ✅ Hecho | — | `.agents/tasks/task-214.md` |
| T-215 | Despliegue de Harness y Autenticación Dual Google Pro en el VPS (agy + agy2) | M | ✅ Hecho | T-214 | `.agents/tasks/task-215.md` |
| T-216 | Hermes Concierge Bridge y Failover de Cuentas | L | ✅ Hecho | T-215 | `.agents/tasks/task-216.md` |
| T-217 | Cronjobs de Monitoreo Proactivo y Briefing Matutino en WhatsApp | S | ✅ Hecho | T-214 | `.agents/tasks/task-217.md` |
| T-218 | Validación E2E del Conserje y Ensayo de Flota | M | ✅ Hecho | T-214, T-215, T-216, T-217 | `.agents/tasks/task-218.md` |

## Régimen Operativo del Sprint
> Se sella en el sprint planning bajo la gobernanza de Autonomía Acotada (Régimen Desatendido).
- **Régimen**: Desatendido (camino limpio avanza de forma 100% desatendida tras autorización macro del operador; aborta fail-closed ante anomalías técnicas o falta de consenso).
- **Orden de Carriles (DAG de dependencias)**:
  - **Carril 1 (Base Operativa del Core en VPS)**: `T-214` (sincronización `v1.35.0` y 31 skills) → `T-215` (harness nativo y autenticación dual Google Pro en VPS).
  - **Carril 2 (Orquestación & Observabilidad)**: `T-216` (Hermes Concierge Bridge y failover) en paralelo con `T-217` (cronjobs de salud y briefing WhatsApp).
  - **Carril 3 (Validación E2E)**: `T-218` (ensayo completo del conserje WhatsApp -> Antigravity -> retorno de resultados).
- **Sellado en**: 2026-11-14

## Notas de planning
- **T-214**: Llevar `/home/ubuntu/projects/agent-os` en `<nodo-inferencia>` a `v1.35.0` (commit `8751e50`), respaldar notas huérfanas de la antigua rama experimental de julio, enlazar atómicamente las 31 skills en `~/.hermes/skills/agent-os/` y validar permisos `+x`.
- **T-215**: Configurar `/home/ubuntu/.antigravity_pro1` y `/home/ubuntu/.antigravity_pro2` en `<nodo-inferencia>`. Transferir de forma segura los tokens OAuth desde local vía Tailscale (Método Inmediato Cero Fricción), aprovisionar wrappers de ejecución y verificar que ambas cuentas responden sin errores de autenticación.
- **T-216**: Implementar la skill/herramienta de conserje para Hermes en `~/.hermes/skills/hermes-concierge/`, permitiendo que un mensaje en WhatsApp lance una sesión de Antigravity en el VPS, gestione consultas/compuertas interactivas retransmitiéndolas a WhatsApp, e implemente la conmutación automática de cuenta (`agy` -> `agy2`) si se alcanza el límite de cuota.
- **T-217**: Corregir el snapshot erróneo en `~/.hermes/cron/jobs.json` (`llama3.1:8b` -> OmniRoute), programar el briefing matutino a las 08:30 AM en WhatsApp con la telemetría de Coolify en `<nodo-orquestacion>` y recursos de los VPS, y activar la política por excepción (alerta inmediata solo si algo cae).
- **T-218**: Ejecutar un ensayo E2E enviando una orden a través del gateway de WhatsApp de Hermes, validando la interacción con Antigravity en worktree efímero en el VPS y recibiendo el reporte final en WhatsApp.

## Estado de Research y Prospección
- **Diagnóstico Empírico en Vivo**: Realizado y documentado en `docs/sprints/sprint-40-research.md`.
- **Hallazgos Clave**:
  - `<nodo-inferencia>` (ARM64 Ubuntu 22.04 LTS) tiene 17 GB de RAM libre, 131 GB de disco, Node v22.23.1 y Python 3.10/3.11.
  - El wheel `google-antigravity` v0.1.23 en PyPI proporciona binario nativo `localharness` para Linux ARM64.
  - La transferencia de tokens OAuth replica la configuración dual de Google Pro (`agy` y `agy2`) en el VPS.
  - Orca Remote Relay ya está activo en `<nodo-inferencia>` en segundo plano.

## ✅ Completado (Sprints previos)
- Sprint 39: Web Compliance (RGPD/Cookies v3), Telemetría de Latidos (Heartbeats) y Desacoplamiento de Builds en Worktrees (T-209 a T-213, v1.35.0).
