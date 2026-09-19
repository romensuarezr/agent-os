# Task-029: Validación E2E del endpoint OpenAI /v1 y redacción de docs/freellmapi-vps-runbook.md

## Objetivo
Documentar en un runbook operativo exhaustivo (`docs/freellmapi-vps-runbook.md`) la arquitectura, puertos, red Docker, seguridad en Tailscale, obtención de claves unificadas y ejemplos de consumo E2E (`curl`) para FreeLLMAPI en el VPS `datamanager`.

## Contexto técnico
- Servidor: VPS `datamanager` (IP privada Tailscale `100.77.82.13`, IP pública `141.253.197.108`).
- Despliegue: `/home/ubuntu/freellmapi/` gestionado vía Docker Compose (`freellmapi` container).
- Puerto y Bind: `100.77.82.13:3001` (aislado en Tailscale para evitar exposición a internet público).
- Red Docker: Conectado a `datamanager_default` para resolver y comunicarse directamente con Ollama en `http://ollama:11434/v1`.
- Autenticación: Endpoint `/v1/chat/completions` y `/v1/models` protegidos por la Unified API Key (extraíble de SQLite `settings.unified_api_key`).
- Modelos locales en Ollama verificados: `llama3.1:8b`, `qwen2.5:7b`, `qwen2.5:3b`, `mistral-nemo:12b`.
- Modelos externos cloud enrutados automáticamente vía `model: "auto"` (Groq, HuggingFace, etc.).
- Investigación previa integrada desde `docs/sprints/sprint-04-core-research.md`.

## Caja de archivos
Archivos autorizados para modificación:
- `docs/freellmapi-vps-runbook.md`
- `docs/sprints/sprint-04-core.md`

## Criterios de done
- [x] Runbook operativo `docs/freellmapi-vps-runbook.md` redactado con secciones: Arquitectura y Topología de Red, Seguridad y Bind Tailscale, Gestión y Mantenimiento del Servicio (Docker Compose), Autenticación y Token Unificado, Modelos Disponibles (Locales y Cloud), y Ejemplos de Invocación E2E (`curl` / SDK OpenAI).
- [x] Validación E2E documentada y contrastada con resultados reales contra el endpoint de inferencia `/v1/chat/completions`.
- [x] Tarea T-029 marcada en `docs/sprints/sprint-04-core.md`.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-19T23:49:12+01:00
- [x] Rama creada: feat/T-029-e2e-validation-runbook-freellmapi
- [x] Lock activo: 2026-09-19T23:49:15+01:00
- [x] Sesión cerrada correctamente
