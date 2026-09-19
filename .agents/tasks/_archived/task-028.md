# Task-028: Configurar proveedores gratuitos y backend local Ollama en FreeLLMAPI

## Objetivo
Configurar los proveedores LLM gratuitos disponibles en el entorno y registrar la instancia local de Ollama como proveedor custom en FreeLLMAPI sobre `datamanager`, habilitando el catálogo unificado y el enrutamiento inteligente.

## Contexto técnico
- Servidor: VPS `datamanager` (IP Tailscale `100.77.82.13`).
- Contenedor FreeLLMAPI ya conectado a la red `datamanager_default`.
- Endpoint Ollama interno: `http://ollama:11434/v1`.
- Modelos locales en Ollama: `llama3.1:8b`, `qwen2.5:7b`, `qwen2.5:3b`, `mistral-nemo:12b`.
- Proveedores disponibles en el entorno: `groq`, `openrouter`, `huggingface`, `zhipu` (Z.ai), `google`.
- Archivo de configuración: `/home/ubuntu/freellmapi/config/freellmapi.config.json`.

## Caja de archivos
Archivos autorizados para modificación:
- `templates/freellmapi/config/freellmapi.config.json`
- `docs/sprints/sprint-04-core.md`

## Criterios de done
- [x] Plantilla `templates/freellmapi/config/freellmapi.config.json` actualizada con la estructura de Custom Provider para Ollama local (`http://ollama:11434/v1`) y estrategia de enrutamiento balanceado.
- [x] Configuración inyectada en `/home/ubuntu/freellmapi/config/freellmapi.config.json` con las claves de proveedores del entorno y el enlace a Ollama.
- [x] Contenedor FreeLLMAPI reiniciado y confirmada la aplicación de configuración en logs (`[config] applied`).
- [x] Validación de inferencia funcional con `curl` a través de FreeLLMAPI (`/v1/chat/completions`) enrutando hacia el backend local de Ollama.
- [x] Tarea T-028 marcada en `docs/sprints/sprint-04-core.md`.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-19T23:25:35+01:00
- [x] Rama creada: feat/T-028-config-providers-ollama-freellmapi
- [x] Lock activo: 2026-09-19T23:25:40+01:00
- [x] Sesión cerrada correctamente
