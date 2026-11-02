# Task-156: Experimento empírico de enrutamiento por dificultad: evaluación comparada Orca vs. agy

## Objetivo
Ejecutar un experimento empírico comparativo sistemático evaluando la capacidad de resolución de Orca ADE frente a Antigravity CLI (`agy`) sobre los planes de desarrollo fuertemente discordantes identificados en la calibración de T-154 (C-04: omisión de tests, C-06: fuga a main/tags, C-07: alteración de contratos), midiendo si una pasarela con presupuesto temporal amplio (60s - 120s) es capaz de emitir veredictos estructurados limpios de rechazo o si también agota el tiempo, documentando el informe formal y dictamen de viabilidad del enrutamiento por dificultad en `docs/sprints/sprint-28-difficulty-routing-report.md`.

## Contexto técnico
En la calibración empírica de T-154 (`docs/sprints/sprint-27-parity-report.md`), se constató que cuando los planes técnicos son conformes con el diseño macro (C-01, C-02, C-03), `agy` resuelve con consenso en ~16-20s. Sin embargo, cuando los planes contienen desviaciones complejas de arquitectura o fuga de alcance severa (C-04, C-06, C-07), el proceso de `agy` agotó la cota de 30s sin emitir respuesta delimitada, delegando la contención en la cascada a Orca y degradando finalmente a `SIN_REVISOR` (~93s).
Para decidir si se implementa un enrutador inteligente basado en dificultad léxica o heurística de complejidad, es imperativo contar con evidencia empírica cuantitativa:
- Si Orca ADE, operando con presupuesto extendido (60s a 120s), logra emitir veredictos estructurados limpios (`ESCALADO_A_HUMANO` o `REVISADO_CON_CAMBIOS`), la hipótesis de "enrutamiento por dificultad hacia Orca" queda confirmada.
- Si Orca ADE también agota el tiempo o emite respuestas corruptas/ANSI fragmentadas ante estos planes discordantes, se valida que los planes difíciles deben saltar directamente a supervisión humana por diseño ($0 cómputo desperdiciado en inferencias redundantes).

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 28 / 2026-11-02
- **Diseño y arquitectura aprobados por**: Humano / Relé (Sprint Planning Sprint 28)
- **Decisiones e interfaces selladas**:
  - Batería focalizada con los 3 casos discordantes de T-154 (C-04, C-06, C-07) ejecutados contra Orca ADE (`scripts/agent/lib/orca-client.sh`).
  - Presupuesto temporal asignado para Orca: 60s base con observación hasta 120s.
  - Registro comparativo cuantitativo: tiempo de respuesta, veredicto delimitado, legibilidad de objeciones y consumo estimado de tokens.
  - Generación de informe formal en `docs/sprints/sprint-28-difficulty-routing-report.md` con dictamen técnico vinculante: `ENRUTADO_DIFICIL_VIABLE` o `ENRUTADO_DIFICIL_DESCARTADO`.
  - Aserción de integridad del informe en Check 34 de `tests/validate-control-plane.sh`.
  - Cero modificaciones a `scripts/agent/deliberate-plan.sh` sin datos concluyentes que justifiquen el enrutador.
  - Denominador de la suite estrictamente en **37/37** (0 errores).
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `agent-os-scripts`: Invocación del cliente Orca y herramientas de deliberación.
- `testing-flows`: Metodología de análisis comparativo empírico y aserciones en suite.

## Caja de archivos
- `docs/sprints/sprint-28-difficulty-routing-report.md`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-156.md`

## Criterios de done
- [ ] Batería de casos discordantes (C-04, C-06, C-07) ejecutada contra Orca ADE con medición de latencia y veredictos.
- [ ] Comparativa empírica tabular detallada agy vs. Orca documentada.
- [ ] Dictamen vinculante emitido (`ENRUTADO_DIFICIL_VIABLE` o `ENRUTADO_DIFICIL_DESCARTADO`).
- [ ] Informe formal documentado en `docs/sprints/sprint-28-difficulty-routing-report.md`.
- [ ] Aserción en Check 34 de `tests/validate-control-plane.sh` verificando el informe.
- [ ] Suite pasando limpia en 37/37 (0 errores).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido
- [ ] Rama creada
- [ ] Cierre y merge autorizado por el relé
