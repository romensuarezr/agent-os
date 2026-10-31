# Task-154: Batería de calibración, medición de cuota/coste y paridad Revisor-vs-Relé (T-147)

## Objetivo
Ejecutar una batería estructurada de calibración y evaluación de paridad empírica entre el Revisor automático (`agy`) y el Relé humano sobre un conjunto representativo de planes de desarrollo, operando bajo el nuevo flujo de gobernanza de dos niveles formalizado en T-147 (macro en planning, micro en tarea). Medir la tasa de concordancia de veredictos, la precisión ante desviaciones de alcance (`ESCALADO_A_HUMANO`) y el consumo de cuota y coste de tokens por deliberación, documentando el informe formal de paridad en el core.

## Contexto técnico
En el Sprint 26 se pospuso la medición cuantitativa de paridad Revisor-vs-Relé hasta estabilizar las pasarelas y formalizar la gobernanza de dos niveles (T-147).
Bajo la gobernanza de dos niveles:
1. El usuario humano evalúa y sella el diseño macro en sprint planning (`## Diseño macro aprobado en planning`).
2. El Revisor actúa exclusivamente como compuerta técnica determinista durante `/session-start`, vigilando:
   - Que los archivos a tocar correspondan a la caja autorizada.
   - Que existan pruebas y no haya duplicación de código.
   - Que el plan técnico no se desvíe ni amplíe el diseño macro sellado (fuga de alcance). Si se desvía, debe emitir `ESCALADO_A_HUMANO`.
Con el cableado de `agy` (T-152) y sus guardas (T-153), procede ejecutar la batería de calibración para evaluar si el revisor automático alcanza paridad estadística con el criterio del relé humano y cuánto cómputo consume.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 27 / 2026-10-31
- **Diseño y arquitectura aprobados por**: Humano / Relé (Sprint Planning Sprint 27)
- **Decisiones e interfaces selladas**:
  - Batería de evaluación con un mínimo de 10 casos de prueba representativos:
    1. Planes conformes con diseño macro (deben recibir `CONSENSO`).
    2. Planes con objeciones menores de pruebas o cobertura (deben recibir `REVISADO_CON_CAMBIOS`).
    3. Planes con desviación de arquitectura, alteración de contratos o fuga de alcance respecto a `## Diseño macro aprobado en planning` (deben recibir estrictamente `ESCALADO_A_HUMANO`).
    4. Planes con skills inexistentes o fuera de inventario (deben ser rechazados por el gate fail-closed T-149).
  - Medición cuantitativa:
    - % de concordancia global Revisor-vs-Relé.
    - Tasa de falsos positivos y falsos negativos en escalado a humano.
    - Latencia promedio por deliberación y métrica de coste / consumo de cuota de tokens.
  - Generación de informe formal en `docs/sprints/sprint-27-parity-report.md`.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `agent-os-scripts`: Invocación del motor de deliberación y scripts de métricas.
- `testing-flows`: Diseño de conjuntos de datos de prueba y análisis estadístico de concordancia.

## Caja de archivos
- `docs/sprints/sprint-27-parity-report.md`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-154.md`

## Criterios de done
- [ ] Batería de al menos 10 casos de prueba ejecutada contra la configuración cableada de `agy`.
- [ ] Tasa de concordancia cuantitativa (%) calculada y comparada con el veredicto del relé.
- [ ] Comprobación de que ante desviaciones de diseño macro pactado, el Revisor emite `ESCALADO_A_HUMANO` sin excepciones.
- [ ] Métricas de coste de tokens, cuota y latencia documentadas por deliberación.
- [ ] Informe formal documentado en `docs/sprints/sprint-27-parity-report.md`.
- [ ] Suite completa de control plane `tests/validate-control-plane.sh` pasando limpia sin regresiones (37/37).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido
- [ ] Rama creada
- [ ] Cierre y merge autorizado por el relé
