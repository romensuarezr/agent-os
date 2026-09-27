# Task-054: Contratos de Metas Persistentes (goal.schema.md), Motor Determinista (verify-goal.sh) y Skill de Evaluación Judge (goal-evaluation)

## Objetivo
Implementar los contratos formales para metas y submetas persistentes (`/goal`, `/subgoal`), el script determinista en Bash/POSIX `verify-goal.sh` que audita a coste 0 de tokens el working tree, la caja de archivos autorizados y las suites de pruebas, y la skill `.agents/skills/goal-evaluation/SKILL.md` para el protocolo del agente Judge (Ralph Loop).

## Contexto técnico
- Basado en los hallazgos de `docs/sprints/sprint-09-core-research.md`:
  - `templates/goals/goal.schema.md`: Esquema declarativo con metadatos del goal, End State Contract, allowlist de archivos autorizados, comandos de validación requeridos y compuertas binarias.
  - `scripts/agent/verify-goal.sh`:
    - Verifica que el working tree esté limpio (`test -z "$(git status --porcelain)"`).
    - Valida que `git diff --name-only <base>...HEAD` contenga única y exclusivamente archivos de la caja autorizada (allowlist). Si hay cualquier archivo no autorizado, falla inmediatamente con código 1.
    - Ejecuta de forma determinista la suite de pruebas del proyecto (ej: `tests/validate-control-plane.sh` o runner detectado) y exige retorno 0.
    - Soporta flags CLI: `--base <ref>`, `--allowlist <file>`, `--json` y `--strict`.
  - `.agents/skills/goal-evaluation/SKILL.md`:
    - Protocolo del Evaluador Independiente (Judge / Ralph Loop).
    - Desacoplamiento estricto: el Worker vuelca el estado y el Judge evalúa el resultado de `verify-goal.sh` y el diff sin re-ejecutar heurísticas subjetivas.
    - Circuito de parada (Circuit Breaker): máximo 3 intentos de corrección. Al tercer fallo consecutivo, emite `escalated_to_human` y activa una Decision Gate (`pending_approval`).

## Caja de archivos
Archivos autorizados para modificación / creación:
- `templates/goals/goal.schema.md`
- `scripts/agent/verify-goal.sh`
- `.agents/skills/goal-evaluation/SKILL.md`
- `docs/sprints/sprint-09-core.md`
- `.agents/tasks/task-054.md`

## Criterios de done
- [x] Esquema `templates/goals/goal.schema.md` creado con contrato declarativo de meta, allowlist y criterios binarios de verificación.
- [x] Script Bash `scripts/agent/verify-goal.sh` implementado y ejecutable (`chmod +x`), con validación de git status, allowlist de archivos y suite de pruebas a 0 tokens de inferencia.
- [x] Skill `.agents/skills/goal-evaluation/SKILL.md` documentada con el protocolo Judge (Ralph Loop), desacoplamiento de roles y límite de 3 reintentos antes de escalado humano.
- [x] Pruebas unitarias/funcionales de `verify-goal.sh` verificando salidas ante violaciones de allowlist y ramas limpias.
- [x] Estado reflejado en `docs/sprints/sprint-09-core.md` y `.agents/tasks/task-054.md`.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-27T11:51:42+01:00
- [x] Rama creada: feat/T-054-deterministic-goals-engine
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
