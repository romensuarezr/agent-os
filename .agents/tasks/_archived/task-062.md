# Task-062: Telemetría de Inferencia IA ($0) (Widgets Ollama y Custom API)

## Objetivo
Configurar en `templates/homepage/config/services.yaml` la telemetría en tiempo real para los motores de inferencia IA ($0) de la flota. Integrar el widget oficial de Homepage para Ollama apuntando al nodo `datamanager` sobre Tailscale (`http://100.77.82.13:11434`), e incorporar el widget `customapi` para la monitorización de estado y catálogo dinámico de modelos de FreeLLMAPI y OmniRoute.

## Contexto técnico
- **Ollama Widget Oficial**: Homepage cuenta con integración nativa para Ollama (`widget: { type: "ollama", url: "http://100.77.82.13:11434" }`) que muestra dinámicamente el estado del servidor y el conteo/listado de modelos cargados en memoria.
- **Custom API Widget para Pasarelas**: FreeLLMAPI (puerto `3001`) y OmniRoute (puerto `20128`) exponen especificación compatible con OpenAI (`/v1/models`). Mediante el widget `customapi` de Homepage, se extrae el campo `data` mapeando el número de modelos disponibles y la latencia/salud del servicio.
- **Topología de Inferencia**: Todo el cómputo de inferencia corre en `datamanager` (`100.77.82.13` sobre Tailscale), garantizando 0 carga de CPU/GPU en el VPS `oracle`.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `templates/homepage/config/services.yaml`
- `.agents/tasks/task-062.md`
- `docs/sprints/sprint-10-core.md`

## Criterios de done
- [x] Configurado el servicio Ollama en `templates/homepage/config/services.yaml` con widget `customapi` consultando `http://100.77.82.13:11434/api/tags` y mapeando modelos instalados.
- [x] Configurados los servicios FreeLLMAPI y OmniRoute con widget `type: customapi` apuntando a sus respectivos endpoints de modelos en `datamanager` (`100.77.82.13`).
- [x] Verificación sintáctica estricta de `services.yaml` con parser YAML sin errores.
- [x] `tests/validate-control-plane.sh` pasa 10/10 checks.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-27T14:56:58+01:00
- [x] Rama creada: feat/T-062-ai-inference-widgets
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
