# Executive Design Digest — T-156

## 🎯 Objetivo
Ejecutar un experimento empírico comparativo sistemático evaluando la capacidad de resolución de Orca ADE frente a Antigravity CLI (`agy`) sobre los planes de desarrollo fuertemente discordantes identificados en la calibración de T-154 (C-04: omisión de tests, C-06: fuga a main/tags, C-07: alteración de contratos), midiendo si una pasarela con presupuesto temporal amplio (60s - 120s) es capaz de emitir veredictos estructurados limpios de rechazo o si también agota el tiempo, documentando el informe formal y dictamen de viabilidad del enrutamiento por dificultad en `docs/sprints/sprint-28-difficulty-routing-report.md`.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico para T-156 se adhiere plenamente a los principios de arquitectura y contención del core. Focaliza la batería experimental en los 3 casos discordantes empíricos de T-154 (C-04, C-06, C-07), acota la caja de archivos a la documentación del dictamen vinculante, el task file y la aserción no destructiva en el Check 34 de validate-control-plane.sh, preservando intacto el denominador estricto de la suite en 37/37 y la inmutabilidad de deliberate-plan.sh.
- **Prospección Scout**: `CONFORME (sprint-28-research.md)`
  - Alternativa detectada:** `@monoes/routing` (v2.24.0, NPM), `@csstools/postcss-cascade-layers` (v6.0.2).
  - Recomendación del agente:** Desarrollo a medida justificado (batería empírica comparativa directa con telemetría local).
  - Decisión del usuario:** Desarrollo a medida justificado — en T-154 se constató que ante planes fuertemente discordantes con el diseño macro (C-04: omisión de tests, C-06: fuga a main/tags, C-07: alteración de contratos), `agy` agotó su ventana de 30s provocando degradación por timeout a `SIN_REVISOR`. El experimento somete estos mismos casos discordantes al worker de inferencia de Orca ADE con presupuesto temporal amplio (60s a 120s) para determinar empíricamente si:
  - Hipótesis A (Orca resuelve)*: Orca emite veredictos estructurados limpios de rechazo (`ESCALADO_A_HUMANO` o `REVISADO_CON_CAMBIOS`), demostrando que un enrutador por complejidad aporta valor real.
- **Mensaje de Cierre**: `Merge branch 'feat/T-156-difficulty-routing-eval' into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-156.md`
- `docs/sprints/sprint-28-core.md`
- `docs/sprints/sprint-28-difficulty-routing-report.md`
- `tests/validate-control-plane.sh`

## 🧠 Skills Declaradas y Aplicadas
- `agent-os-scripts`
- `testing-flows`
