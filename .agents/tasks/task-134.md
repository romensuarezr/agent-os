# Task-134: Especificación Inyectable de Revisor Ejecutor Derivada de `qa-judge.md` y `reviewer.yaml`

## Objetivo
Implementar un generador determinista que compile la directiva y preámbulo de ejecución (`--spec`) para el Revisor Ejecutor a partir de la Única Fuente de Verdad contenida en `.agents/profiles/qa-judge.md` y `.agents/profiles/reviewer.yaml`, sin duplicar código ni textos estáticos de contrato.

## Contexto técnico
El Revisor Ejecutor en Orca no debe comportarse como un desarrollador generalista, sino como un árbitro técnico imparcial bajo el patrón **Ralph Loop**:
- **Prohibición estricta de generar o mutar código**: Tiene vetado `git commit`, `git push` o editar código fuente.
- **Ejecución objetiva**: Debe ejecutar herramientas deterministas de verificación (tales como `scripts/agent/verify-goal.sh --json` y `tests/validate-control-plane.sh`).
- **Respuesta estructurada**: Debe emitir exclusivamente un bloque JSON de veredicto interpretable por la máquina (`verdict`: `CONSENSO` | `REVISADO_CON_CAMBIOS` | `ESCALADO_A_HUMANO` | `RECHAZADO`).

Esta tarea crea una utilidad que extrae de los perfiles declarativos existentes los límites y las herramientas autorizadas, ensamblando un preámbulo hermético que se inyecta al despachar el worker en Orca.

## Skills relevantes
- `rule-creator`: Regla aplicada: formalización declarativa de comportamientos y límites operativos para agentes.
- `goal-evaluation`: Regla aplicada: protocolo desacoplado de validación Ralph Loop y contratos de evaluación de metas.

## Caja de archivos
- `scripts/agent/lib/generate-reviewer-spec.sh` (nuevo)
- `.agents/tasks/task-134.md`

## Criterios de done
- [ ] Script generador determinista implementado que lee `.agents/profiles/qa-judge.md` y `.agents/profiles/reviewer.yaml`.
- [ ] Spec compilada contiene explícitamente las prohibiciones de mutación de código y la exigencia de salida JSON de veredicto.
- [ ] Sin duplicación manual de contratos en múltiples scripts.
- [ ] Validación observable: ejecución del generador emitiendo el preámbulo formateado para `--spec`.
