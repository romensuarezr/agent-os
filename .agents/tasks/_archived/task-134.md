# Task-134: Especificación Inyectable de Revisor Ejecutor Derivada de `qa-judge.md` y `reviewer.yaml`

## Objetivo
Implementar un generador determinista que compile la directiva y preámbulo de ejecución (`--spec`) para el Revisor Ejecutor a partir de la Única Fuente de Verdad contenida en `.agents/profiles/qa-judge.md` y `.agents/profiles/reviewer.yaml`, sin duplicar código ni textos estáticos de contrato.

## Contexto técnico
El Revisor Ejecutor en Orca no debe comportarse como un desarrollador generalista, sino como un árbitro técnico imparcial bajo el patrón **Ralph Loop**:
- **Prohibición estricta de generar o mutar código**: Tiene vetado `git commit`, `git push`, `git checkout -b` o editar código fuente.
- **Ejecución objetiva**: Debe auditar mediante herramientas deterministas de verificación (tales como `scripts/agent/verify-goal.sh`, `tests/validate-control-plane.sh`, `git diff`, `git status`).
- **Respuesta estructurada y delimitada**: Debe emitir exclusivamente un bloque JSON de veredicto interpretable por la máquina bajo delimitadores exactos (`<!-- VERDICT_JSON_START -->` ... `<!-- VERDICT_JSON_END -->`).
- **Circuit breaker y presupuestos temporales**:
  - Circuit breaker: Máximo **2 rondas totales** de deliberación (1 ronda de corrección automática; si en la ronda 2 no hay consenso → `ESCALADO_A_HUMANO`).
  - Presupuesto Orca ADE: **15 segundos** explícitos para el worker (el timeout de 5s en `reviewer.yaml` corresponde al tier de pasarela HTTP en `deliberate-plan.sh`, no al worker ejecutor).
- **Extracción SSOT robusta y fail-closed**:
  - Lee dinámicamente `.agents/profiles/qa-judge.md` y `.agents/profiles/reviewer.yaml` soportando PyYAML con fallback determinista en Python stdlib.
  - Fail-closed: si cualquier perfil fuente falta o está malformado, aborta con código 1 sin emitir especificaciones parciales.
  - Unión verbatim de prohibiciones de ambos perfiles (Zero Code Mutation).

Esta tarea implementa `scripts/agent/lib/generate-reviewer-spec.sh` que extrae los perfiles declarativos, ensambla el preámbulo hermético y ofrece interfaz para texto plano o JSON con las 4 claves canónicas (`spec`, `role`, `source_profiles`, `contract_version`).

## Skills relevantes
- `rule-creator`: Regla aplicada: formalización declarativa de comportamientos y límites operativos para agentes.
- `goal-evaluation`: Regla aplicada: protocolo desacoplado de validación Ralph Loop y contratos de evaluación de metas.

## Caja de archivos
- `scripts/agent/lib/generate-reviewer-spec.sh` (nuevo)
- `.agents/tasks/task-134.md`

## Criterios de done
- [ ] Script generador `scripts/agent/lib/generate-reviewer-spec.sh` implementado con permisos de ejecución (+x).
- [ ] Extracción SSOT dinámica sin PyYAML garantizado (fallback stdlib) con política fail-closed ante perfiles ausentes o malformados.
- [ ] Unión verbatim de prohibiciones de `qa-judge.md` y `reviewer.yaml` reflejada en la directiva compilada.
- [ ] Spec compilada contiene delimitadores exactos (`<!-- VERDICT_JSON_START -->` / `<!-- VERDICT_JSON_END -->`), presupuesto Orca 15s y circuit breaker de 2 rondas totales.
- [ ] Invocación con `--json` emite un objeto válido con las 4 claves canónicas: `spec`, `role`, `source_profiles`, `contract_version`.
- [ ] Sin duplicación manual de contratos y validado con tests automatizados.
