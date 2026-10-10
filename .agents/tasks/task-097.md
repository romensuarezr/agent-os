# Task-097: Remediación inmediata y desbloqueo de Hermes en datamanager y oracle

## Objetivo
Sanear y restaurar la operatividad de Hermes Agent en los VPS datamanager y oracle, enrutando su inferencia hacia la malla de pasarelas gratuitas ($0) sobre Tailscale (OmniRoute y FreeLLMAPI), reactivando el dashboard y eliminando procesos huérfanos dinámicamente con inyección segura de secretos vía Infisical.

## Contexto técnico
- `datamanager` aloja `omniroute` (puerto 20128) y `freellmapi` (puerto 3001) expuestos en la IP Tailscale `<TAILSCALE_IP>` (definida en el overlay local gitignored `.agents/config/fleet.yaml`).
- Hermes en `datamanager` fallaba por intentar conectar a `localhost:20128` (rechazado por el bind de Docker a la IP Tailscale) y un túnel temporal expirado de Cloudflare. El servicio `hermes-dashboard.service` (9119) estaba detenido (`inactive`) desde una actualización.
- Hermes en `oracle` fallaba por error HTTP 403 (cuota agotada de OpenRouter al solicitar modelos comerciales como `claude-opus-4.6`). Requiere enrutamiento a la malla gratuita y restricción estricta a modelos `:free`.
- Manejo de secretos: las credenciales de OpenRouter y FreeLLMAPI se gestionan en Infisical y se inyectan en memoria (`infisical run` o evaluación en subshell efímero), sin persistir contraseñas en claro en disco, logs o comandos.

## Caja de archivos
Archivos autorizados para modificación:
- `docs/sprints/sprint-14-core.md`
- `docs/sprints/sprint-14-core-research.md`
- `docs/runbooks/hermes-vps-runbook.md`

## Criterios de done
- [x] `datamanager`: `~/.hermes/config.yaml` corregido para usar `base_url: http://<TAILSCALE_IP>:20128/v1` (OmniRoute en Tailscale), registrar `FreeLLMAPI` (`http://<TAILSCALE_IP>:3001/v1`) como proveedor alternativo y eliminar referencias al subdominio muerto de Cloudflare.
- [x] `datamanager`: `hermes-dashboard.service` reactivado y comprobado escuchando en `<TAILSCALE_IP>:9119`.
- [x] `datamanager`: `hermes-gateway.service` reiniciado para aplicar nueva configuración y resolver drift en scheduler de cron.
- [x] `oracle`: Detección en vivo por comando (`pgrep`/`ps aux | grep hermes`) de procesos huérfanos de Hermes, mostrando evidencia antes de terminarlos de forma segura.
- [x] `oracle`: `~/.hermes/config.yaml` configurado hacia la pasarela Tailscale (`http://<TAILSCALE_IP>:20128/v1` con `auto/best-coding` / FreeLLMAPI) y fallback de OpenRouter limitado estrictamente a modelos con sufijo `:free`.
- [x] Verificación de inferencia interactiva ($0 coste) confirmada en ambos nodos mediante test funcional no interactivo (`hermes -z "ping" --yolo` respondiendo `pong`).
- [x] Secretos gestionados e inyectados exclusivamente en memoria vía Infisical sin exposición de claves.
- [x] `docs/runbooks/hermes-vps-runbook.md` actualizado con la topología real y mitigaciones.
- [x] `docs/sprints/sprint-14-core.md` y `docs/sprints/sprint-14-core-research.md` actualizados.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-10-10 09:03 (con cambios de placeholder portable)
- [x] Rama creada: feat/T-097-remediacion-hermes-vps
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente

