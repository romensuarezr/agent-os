# Task-098: Trazabilidad y pre-flight determinista de la inferencia local resiliente

## Objetivo
Formalizar el trabajo de remediación de inferencia en agentes locales ya implementado en `69eff74`: registrar su contrato, la evidencia en vivo que refuta dos diagnósticos previos, y su cobertura en la suite de control plane, para que ningún agente vuelva a aproximarse a ciegas a estos fallos.

## Contexto técnico
**Estado previo**: la implementación (script de pre-flight, runbook, test 13/13 y entrada de changelog) ya está commiteada en `69eff74` sobre `multi-agent`. Esta tarea **no implementa código**: sella la trazabilidad del trabajo ya hecho.

**Research de sprint** (`docs/sprints/sprint-14-core-research.md` §4, mapeado a T-097) propose como causa del fallo local: (a) túneles efímeros `*.trycloudflare.com` y (b) obligación de enlazar los servicios del VPS a `0.0.0.0` o a la IP de Tailscale, nunca a `127.0.0.1`. **La evidencia en vivo refuta ambas**:

1. **No había túnel de Cloudflare.** El 503 era interno de OmniRoute: `Maximum combo retry limit reached`, 24 reintentos sobre un pool de 1437 modelos. El 502 era `tailscale serve` proxyando a `127.0.0.1:20128` mientras el contenedor publicaba el puerto **solo** en la IP de Tailscale (`100.x.x.13:20128->20128/tcp`). El requisito de bind del research ya se cumplía; lo que faltaba era que el destino del proxy inverso coincidiera con el bind real. La regla correcta es bidireccional: *el proxy debe apuntar a la dirección donde el servicio realmente escucha*.
2. **Las dos pasarelas usan credenciales distintas.** La `api_key` de OmniRoute devuelve `401 Invalid API key` contra FreeLLMAPI. La clave correcta de FreeLLMAPI es `settings.unified_api_key` en su SQLite (`/app/server/data/freeapi.db`). Dicha clave **no existía** en `~/.hermes/.env`, por lo que la configuración previa no podía funcionar.

**Estado real de los proveedores** (medido): FreeLLMAPI `auto` rota de verdad — en la misma tarde sirvió `google/gemini-3.5-flash` (2.8 s) y `openrouter/dots-studio/dots-3-note-preview:free` (1.5 s), con un `groq → HTTP 413` intermedio. 6 credenciales sanas: `google`, `groq`, `openrouter`, `huggingface`, `zhipu` y `custom` (Ollama en el nodo). OmniRoute `auto/best-coding` es **inservible** (>60 s, 503); `auto/best-free` (0.67 s) y `auto/cheap` (7.5 s) sí sirven.

**Trampa de diagnóstico**: con `max_tokens` bajo, un modelo con razonamiento consume el presupuesto en `reasoning_content` y devuelve `content` vacío. Parece un gateway roto y no lo es. Todo sondeo debe usar ≥256 tokens.

**Convención de core aplicada**: el runbook versiona `<GATEWAY_HOST>` como placeholder, nunca literales de infraestructura; el script enmascara el host y jamás imprime la credencial.

**Deuda registrada**: la regla `flow-bug-traceability` de `session-start.md` exige consultar y actualizar `docs/critical-flows.md`, pero ese archivo **no existe** en el repositorio. Se deja constancia aquí y su creación se aborda en T-094; el caso de borde (proxy inverso hacia un bind inexistente) ya está documentado en el runbook §2.

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/tasks/task-098.md`
- `docs/sprints/sprint-14-core.md`
- `changelog.md`

## Criterios de done
- [x] `task-098.md` existe con Contexto técnico, Caja y criterios verificables.
- [x] `sprint-14-core.md` incluye la fila T-098 como Completada y refleja que la suite de control plane pasó de 12/12 a 13/13 (requisito 4 y criterio de cierre).
- [x] `changelog.md` etiqueta la entrada de pre-flight de inferencia como T-098.
- [x] `bash tests/validate-control-plane.sh` devuelve 13/13 sin regresiones.
- [x] `git diff --name-only` ⊆ Caja de archivos.
- [x] Cero literales de IP de Tailscale y cero secretos en los archivos versionados.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-10-12T12:38:59+01:00
- [x] Rama creada: feat/T-098-preflight-inferencia-local
- [x] Lock activo: sí (`.agent-session.lock`)
- [x] Sesión cerrada correctamente