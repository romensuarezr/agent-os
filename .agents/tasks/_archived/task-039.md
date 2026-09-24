# Task-039: Validación y configuración local de OpenCode con FreeLLMAPI

## Objetivo
Configurar el cliente local de OpenCode CLI (`/usr/bin/opencode`) para interactuar con el endpoint OpenAI-compatible de FreeLLMAPI (`http://100.77.82.13:3001/v1`), validar la generación de código y capacidades de tool-calling de forma aislada en un directorio de pruebas efímero (`scratch/opencode-test/`), certificar que el coste de inferencia sea $0, y documentar el procedimiento y mitigaciones en `docs/runbooks/opencode-freellmapi-setup.md`.

## Contexto técnico
- FreeLLMAPI corre en el VPS `datamanager` atado a la interfaz de Tailscale (`100.77.82.13:3001`) con autenticación Bearer (`unified_api_key`).
- OpenCode CLI versión 1.3.9 está instalado en `/usr/bin/opencode`.
- Basado en la investigación técnica (`docs/sprints/sprint-07-research.md`), OpenCode se integra con endpoints OpenAI-compatibles vía variables de entorno (`OPENAI_BASE_URL`, `OPENAI_API_KEY`, `OPENCODE_MODEL`) o configuración en `~/.config/opencode/`.
- Mitigaciones técnicas para modelos locales: Read timeouts extendidos (180s-300s), delimitación de contexto a 8k-16k tokens, estructuración y control de reintentos máximos (max 2) para evitar bucles.
- La ejecución de prueba debe realizarse estrictamente en `scratch/opencode-test/`, garantizando aislamiento absoluto respecto a los repositorios reales y coste $0.

## Caja de archivos
Archivos autorizados para modificación:
- `docs/sprints/sprint-07-core.md`
- `.agents/tasks/task-039.md`
- `docs/runbooks/opencode-freellmapi-setup.md`
- `scratch/opencode-test/*` (espacio efímero de prueba)

## Criterios de done
- [x] Conectividad verificada con el endpoint OpenAI-compatible de FreeLLMAPI en `datamanager` (`100.77.82.13:3001/v1/models`).
- [x] Configuración de proveedor y modelo en OpenCode CLI para operar contra FreeLLMAPI con `unified_api_key`.
- [x] Ejecución exitosa de una tarea de prueba de codificación/testing aislada en `scratch/opencode-test/` verificando coste $0.
- [x] Creación del runbook operativo `docs/runbooks/opencode-freellmapi-setup.md` con arquitectura, configuración, mitigaciones y comandos.
- [x] Verificación y actualización de estado en `docs/sprints/sprint-07-core.md`.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-24 22:08:14
- [x] Rama creada: feat/T-039-opencode-freellmapi-validation
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
