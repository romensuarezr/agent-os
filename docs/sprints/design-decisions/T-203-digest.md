# Executive Design Digest — T-203

## 🎯 Objetivo
Establecer en los contratos de agentes que los workers entreguen únicamente digests estructurados y evidencia determinista al Coordinador (evitando el vertido de transcripciones crudas que saturan la ventana de contexto), e implementar el script determinista `scripts/agent/orchestration-report.sh` para telemetría de ejecución, métricas de playbook empleado y estimación de ahorro de tokens/tiempo a coste $0.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan para T-203 satisface plenamente los principios de diseño y aislamiento cognitivo de Agent OS. La formalización del 'Retorno Compacto' (<= 30 líneas, diffstat y verify-goal.sh) en coder.md y coordinator.md neutraliza el riesgo de context rot en el agente orquestador, alineándose con las directrices de autonomía acotada y determinismo. Asimismo, la especificación de scripts/agent/orchestration-report.sh respeta la Regla 22 (cero credenciales/rutas personales), garantiza degradación limpia con exit code 0 ante inboxes vacíos y mantiene un alcance 100% de solo lectura sin mutaciones destructivas.
- **Prospección Scout**: `CONFORME (sprint-37-research.md)`
  - Keywords**: `agent telemetry cost report`
  - Alternativas OSS evaluadas**:
  - `Lowfat` (Show HN, 156 pts): Filtro CLI de tokens en pipelines.
  - `Aireceipts`: Facturación desglosada por tarea.
- **Mensaje de Cierre**: `Merge branch 'feat/T-202-orchestration-playbooks-threshold' into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/config/orchestration-playbooks.yaml`
- `.agents/profiles/coder.md`
- `.agents/profiles/coordinator.md`
- `.agents/skills/orchestrator/SKILL.md`
- `.agents/tasks/_archived/task-202.md`
- `.agents/tasks/_archived/task-203.md`
- `.agents/workflows/session-start.md`
- `docs/sprints/design-decisions/T-202-digest.md`
- `docs/sprints/design-decisions/T-202-raw.json`
- `docs/sprints/sprint-37.md`
- `scripts/agent/assets-manifest.txt`
- `scripts/agent/orchestration-report.sh`

## 🧠 Skills Declaradas y Aplicadas
- Ninguna skill adicional registrada.
