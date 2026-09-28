# Task-061: Telemetría Multi-Nodo y Hardware (Glances en DataManager y Widgets Multi-Host)

## Objetivo
Implementar la infraestructura de telemetría remota de hardware configurando Glances Web (`glances -w`) para ejecutarse exclusivamente en el nodo `datamanager` (`192.0.2.10:61208` vía Tailscale), respetando la restricción de recursos en `oracle` (ADR 004). Extender `templates/homepage/config/widgets.yaml` para renderizar una cabecera multi-host con los estados combinados de `Oracle VPS` y `DataManager Node`.

## Contexto técnico
- **ADR 004 (Restricción de Carga en `oracle`)**: En el VPS `oracle`, Homepage no levantará demonios adicionales de telemetría ni Prometheus/NodeExporter. Solo consumirá las métricas locales ya provistas o las métricas servidas por el daemon Glances remoto en `datamanager`.
- **Topología de Red Tailscale**: `datamanager` está conectado a la malla con la IP fija `192.0.2.10`. El servicio web de Glances (`glances -w`) escuchará en el puerto estándar `61208`.
- **Homepage Widget Nativo `glances`**: Homepage incluye soporte directo para Glances mediante el widget:
  ```yaml
  - glances:
      url: http://192.0.2.10:61208
      cpu: true
      mem: true
      disk: "/"
      label: "DataManager Node"
  ```
- **Plantilla Compose Desacoplada**: Se crea `templates/homepage/glances-compose.yml` para facilitar el despliegue mediante Docker en `datamanager` o servicio systemd.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `templates/homepage/glances-compose.yml`
- `templates/homepage/config/widgets.yaml`
- `docs/runbooks/glances-setup.md`
- `.agents/tasks/task-061.md`
- `docs/sprints/sprint-10-core.md`

## Criterios de done
- [x] Creada la plantilla `templates/homepage/glances-compose.yml` con imagen oficial de Glances en modo web server.
- [x] Actualizado `templates/homepage/config/widgets.yaml` con cabecera multi-host (Oracle VPS + DataManager Node vía Tailscale).
- [x] Redactado `docs/runbooks/glances-setup.md` con instrucciones de puesta en marcha en `datamanager`, opciones de systemd/docker y comandos de comprobación curl (`/api/3/all`).
- [x] Validaciones de sintaxis YAML aprobadas.
- [x] `tests/validate-control-plane.sh` pasa 10/10 checks.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-27T14:43:03+01:00
- [x] Rama creada: feat/T-061-multi-node-glances-telemetry
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
