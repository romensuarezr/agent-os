# Task-064: Motor Declarativo Agnóstico (generate-homepage-config.sh), fleet.example.yaml y Control Plane Tests

## Objetivo
Actualizar `scripts/agent/generate-homepage-config.sh` para que genere de forma 100% agnóstica y determinista las configuraciones de Homepage (`widgets.yaml`, `services.yaml`, `settings.yaml`), leyendo bloques modulares de `monitoring` y servicios desde `config/fleet.yaml` (o `fleet.example.yaml`) sin IPs hardcodeadas. Extender `config/fleet.example.yaml` con la nueva sección declarativa y agregar verificación en `tests/validate-control-plane.sh`.

## Contexto técnico
- **Generación Declarativa Agnóstica**: El script no debe asumir direcciones IP fijas (como `192.0.2.10`), sino extraerlas dinámicamente de `node_data.get("host")` o `s.get("endpoint")` para cada servicio (`ollama`, `freellmapi`, `omniroute`, `glances`).
- **Soporte Modular de Monitoring**:
  - `monitoring.search`: Configuración declarativa del buscador de cabecera (`duckduckgo`, `google` o `searxng`).
  - `monitoring.github`: Configuración del repositorio y widget oficial.
  - `services.glances`: Detección en nodos remotos para instanciar automáticamente el widget `glances` en `widgets.yaml`.
- **Integración con Control Plane Tests**: Incorporar en `tests/validate-control-plane.sh` un check determinista que valide la ejecución en modo dry-run (`--check`) de `generate-homepage-config.sh`.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `scripts/agent/generate-homepage-config.sh`
- `config/fleet.example.yaml`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-064.md`
- `docs/sprints/sprint-10-core.md`

## Criterios de done
- [x] `scripts/agent/generate-homepage-config.sh` genera widgets de telemetría de inferencia (`customapi` para Ollama, FreeLLMAPI, OmniRoute) y `glances` sin IPs hardcodeadas.
- [x] Soporte para bloques modulares de `monitoring` (buscador y GitHub) en el generador.
- [x] `config/fleet.example.yaml` actualizado documentando la sección `monitoring` y el servicio `glances`.
- [x] Agregado check de validación determinista en `tests/validate-control-plane.sh`.
- [x] `tests/validate-control-plane.sh` pasa 100% de checks (0 errores).

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-27T15:45:42+01:00
- [x] Rama creada: feat/T-064-agnostic-homepage-generator
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
