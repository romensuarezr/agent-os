# Task-038: Prospección determinista pre-código: script scout.sh e integración con tech-scout y tool-decision-flow

## Objetivo
Implementar un script CLI determinista (`scripts/agent/scout.sh`) que consulte APIs públicas rápidas (GitHub REST API, NPM Registry API, Hacker News Algolia) para prospección tecnológica con coste 0 tokens de inferencia, integrándolo como paso previo obligatorio en la skill `tech-scout` y en la regla `tool-decision-flow.md`.

## Contexto técnico
- El uso de búsquedas web abiertas (`search_web`) o scraping por LLM consume miles de tokens y genera alucinaciones sobre librerías desactualizadas.
- Se detectó que `gh` CLI no está autenticado localmente y que Reddit bloquea peticiones de `curl` (HTTP 403). Por tanto, `scout.sh` debe usar APIs públicas deterministas que no requieran credenciales ni dependencias pesadas (`curl` + `jq`):
  1. GitHub REST API (`https://api.github.com/search/repositories`) con fallback opcional a `gh`.
  2. NPM Registry Search API (`https://registry.npmjs.org/-/v1/search`) para paquetes del ecosistema JS/TS.
  3. Hacker News Algolia Search API (`https://hn.algolia.com/api/v1/search`) para debates de arquitectura sin bloqueos.
- La salida debe ser un digest ultracompacto (10-15 líneas) apto para que el agente lo consuma en menos de 100 tokens.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `scripts/agent/scout.sh` (nuevo script determinista)
- `.agents/skills/tech-scout/SKILL.md` (actualización de protocolo pre-código)
- `.agents/rules/global/tool-decision-flow.md` (actualización de regla de prospección previa)
- `.agents/tasks/task-038.md` (task file activo)
- `docs/sprints/sprint-06-core.md` (registro de estado y enlace a task file)

## Criterios de done
- [x] Creación de `scripts/agent/scout.sh` robusto, sin dependencias externas pesadas, que consulte GitHub, NPM y Hacker News en paralelo o secuencial rápido devolviendo un digest plano de 10-15 líneas.
- [x] Permisos de ejecución en `scripts/agent/scout.sh` y verificación empírica local con consultas de prueba.
- [x] Actualización de `.agents/skills/tech-scout/SKILL.md` incorporando la prospección determinista como paso 1 prioritario.
- [x] Actualización de `.agents/rules/global/tool-decision-flow.md` formalizando la regla de pre-code scouting determinista.
- [x] Suite de validación local `bash tests/validate-control-plane.sh` pasando con 0 errores.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-24T17:28:20+01:00
- [x] Rama creada: feat/T-038-deterministic-scout
- [x] Lock activo: 2026-09-24T17:28:30+01:00
- [x] Sesión cerrada correctamente
