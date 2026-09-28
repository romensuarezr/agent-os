# Task-070: Regla global deterministic-execution.md + resolución de contradicciones

## Objetivo
Crear `.agents/rules/global/deterministic-execution.md` (prohibición de improvisar: nada de scripts ad-hoc sin versionar, nada de asumir servicios sin comprobación determinista, `install.sh` obligatorio) **y** resolver las contradicciones ya existentes entre reglas, porque una regla nueva sobre reglas contradictorias no gobierna nada.

## Contexto técnico
Auditoría 2026-09-28, revisada regla por regla:
- **C1 — Secretos**: `maximum-autonomy.md` ("guarda las API keys en `.env` y utilízalas automáticamente") vs `agent-permissions.md` L3 ("ningún agente puede leer/mostrar/transferir secretos"). Resolución requerida: uso vía inyección de entorno/referencias Infisical sin jamás imprimir valores; L3 sigue prohibiendo lectura/display/transferencia.
- **C2 — Captura de ideas**: `caveman.md` (protocolo silent → `docs/idea-inbox/`, sin confirmación) vs `mvp-focus-redirect.md` (5 pasos con confirmación → `roadmap.md`). Resolución requerida: un único protocolo con destino canónico (`docs/idea-inbox/`, ver T-071) y criterio explícito de cuándo aplica confirmación.
- **C3 — Coordinator duplicado**: `.agents/profiles/coordinator.md` (Swarm Orchestrator, worktrees) vs `coordinator.yaml` (bot Hermes/WhatsApp 24/7), mismo `id`, propósitos incompatibles. Resolución requerida: unificar o partir en dos perfiles con IDs distintos.
- `tool-decision-flow.md` paso 1 asume `config/fleet.yaml` como universal: hacerlo condicional ("si existe fleet local, consúltalo; si no, pasa al paso 2").
- Solo 2/15 reglas declaran `trigger` en frontmatter: añadirlo a todas para que el router sepa cuándo aplica cada una.

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/rules/global/deterministic-execution.md` (nuevo)
- `.agents/rules/global/maximum-autonomy.md`
- `.agents/rules/global/agent-permissions.md`
- `.agents/rules/global/caveman.md`
- `.agents/rules/global/mvp-focus-redirect.md`
- `.agents/rules/global/tool-decision-flow.md`
- `.agents/profiles/coordinator.md`
- `.agents/profiles/coordinator.yaml`

## Criterios de done
- [ ] `deterministic-execution.md` existe con las 3 prohibiciones y referencia a `fleet-doctor.sh` (T-067) como comprobación canónica.
- [ ] C1, C2 y C3 resueltas con texto explícito de precedencia en cada archivo afectado (no basta con la regla nueva).
- [ ] `tool-decision-flow.md` paso 1 condicionado a la existencia de fleet local.
- [ ] Las 15 reglas de `.agents/rules/global/` declaran `trigger` en frontmatter.
- [ ] `tests/validate-control-plane.sh` sigue en verde (12/12 tras T-067).

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
