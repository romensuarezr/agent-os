# Sprint 43 — 2026-11-18 → 2026-11-22

## Estado
✅ Completado

## Tareas
| ID | Descripción | Tamaño | Estado | Dependencias | Task file |
|---|---|:---:|:---:|:---:|:---:|
| T-228 | Declaración Integral del Stack Auditado en `fleet.yaml` | S | ✅ Hecho | — | [.agents/tasks/task-228.md](file:///.agents/tasks/task-228.md) |
| T-229 | Despliegue de Glances Web en VPS DataManager vía Tailscale | S | ✅ Hecho | — | [.agents/tasks/task-229.md](file:///.agents/tasks/task-229.md) |
| T-230 | Adaptación de `generate-homepage-config.sh` para Stack Completo y Multi-Host | M | ✅ Hecho | T-228, T-229 | [.agents/tasks/task-230.md](file:///.agents/tasks/task-230.md) |
| T-231 | Despliegue en Vivo y Validación en Homepage (`http://g8o4sgwsw8k4c0cscoskkks8...`) | S | ✅ Hecho | T-230 | [.agents/tasks/task-231.md](file:///.agents/tasks/task-231.md) |
| T-232 | Homologación de Tooling de Flota (OpenCode, Hermes, Orca, Infisical) | S | ✅ Hecho | — | [.agents/tasks/task-232.md](file:///.agents/tasks/task-232.md) |

## Régimen Operativo del Sprint
> Sellado en arranque tras confirmación explícita del operador: A, aprobado (Régimen Desatendido).
- **Régimen**: Desatendida
- **Orden de Carriles (DAG de dependencias)**:
  - Carril 1 (Dashboard, Telemetría & Stack Completo): [T-228 → T-229 → T-230 → T-231]
  - Carril 2 (Tooling de Flota): [T-232]
- **Sellado en**: 2026-11-18 (Arranque de Sprint 43)

## Notas de planning
- Sprint centrado en la operatividad total del panel de control de la flota (Homepage) en `http://g8o4sgwsw8k4c0cscoskkks8.<nodo-orquestacion-ip>.sslip.io/`.
- T-228 actualiza `.agents/config/fleet.yaml` con el inventario 100% auditado directamente de la base de datos de Coolify (`coolify-db`) y Traefik, eliminando placeholders y asociando las URLs operativas reales (Coolify `https://coolify.romensuarez.com`, SearXNG, n8n, Umami, ByteBox, Twenty CRM, Ghost, WhatsApp Bridge, Outbid, Kanarii, Finca Adama, etc.).
- T-229 resuelve la ausencia de telemetría del nodo de inferencia desplegando Glances Web en DataManager VPS amarrado estrictamente a Tailscale IP `<TAILSCALE_IP_DATAMANAGER>:61208` sin exposición pública WAN (ADR 004).
- T-230 evoluciona el generador determinista `scripts/agent/generate-homepage-config.sh` para soportar widgets de recursos multi-host (Oracle VPS local + DataManager Glances remoto) y categorizar los 4 grupos de servicios del stack.
- T-231 sincroniza remotamente los archivos generados con el volumen persistente de Homepage en Oracle VPS creando un backup fechado obligatorio antes de reiniciar el contenedor y validar accesibilidad.
- T-232 homologa y archiva las actualizaciones de versiones de herramientas reportadas por la sonda determinista (OpenCode v2.3.2, Orca v1.4.262, Hermes v0.23.2, Infisical v0.45.11).
