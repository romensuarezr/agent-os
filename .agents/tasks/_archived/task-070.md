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

## Vocabulario trigger controlado (Lista cerrada — kebab-case)

| Trigger | Propósito / Ámbito | Reglas asignadas |
| :--- | :--- | :--- |
| `always-on` | Ejecución transversal continua en todo momento | `language-protocol.md`, `caveman.md`, `response-checklist.md`, `analysis-principles.md` |
| `session-start` | Flujo de arranque, ramas y control estricto | `strict-workflow.md` |
| `pre-flight` | Verificación determinista antes de actuar | `deterministic-execution.md` |
| `task-execution` | Ejecución de tareas operativas y fases activas | `maximum-autonomy.md`, `silent-execution.md` |
| `security-and-permissions` | Fronteras de seguridad y gestión de secretos | `agent-permissions.md` |
| `code-architecture` | Diseño de código, capas, modularidad y no duplicación | `dry-architecture.md`, `audit-before-refactor.md` |
| `code-quality` | Calidad balanceada de entrega, testing y refactors | `mvp-code-quality.md` |
| `destructive-action` | Prevención de borrados o acciones destructivas | `no-destructive-without-audit.md` |
| `deployment-safety` | Inicializaciones, runtime y estabilidad de despliegue | `deployment-safety.md` |
| `idea-capture` | Redirección de ideas fuera de MVP hacia inboxes | `mvp-focus-redirect.md` |
| `tool-selection` | Selección jerárquica de herramientas y scouting | `tool-decision-flow.md` |

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/rules/global/deterministic-execution.md` (nuevo)
- `.agents/rules/global/*.md`
- `.agents/profiles/coordinator.md`
- `.agents/profiles/coordinator.yaml`
- `.agents/AGENT_ONBOARDING.md`
- `.agents/tasks/task-070.md`
- `docs/sprints/sprint-11-core.md`

## Criterios de done
- [x] `deterministic-execution.md` existe con las 3 prohibiciones y referencia a `fleet-doctor.sh` (T-067) como comprobación canónica.
- [x] C1, C2 y C3 resueltas con texto explícito de precedencia y citas por nombre a la regla canónica (CAMBIO 1).
- [x] `tool-decision-flow.md` paso 1 condicionado a la existencia de `config/fleet.yaml` local.
- [x] Las 16 reglas de `.agents/rules/global/` declaran `trigger` utilizando exclusivamente el vocabulario controlado (CAMBIO 2).
- [x] `.agents/AGENT_ONBOARDING.md` registra `deterministic-execution.md` en su inventario de reglas globales (CAMBIO 3).
- [x] `tests/validate-control-plane.sh` sigue en verde (12/12 tras T-067).

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-28T16:20:54+01:00 (APROBADO CON CAMBIOS)
- [x] Rama creada: feat/T-070-deterministic-execution
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
