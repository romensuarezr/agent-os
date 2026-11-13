# Executive Design Digest — T-211

## 🎯 Objetivo
Actualizar los contratos del Coordinador en `.agents/profiles/coordinator.md`, `.agents/rules/global/coordinator-boot.md`, `.agents/skills/orchestrator/SKILL.md` y `.agents/config/orchestration-playbooks.yaml` para incorporar el protocolo de **Latidos Proactivos (*Progress Heartbeats*)**. Cuando se despachan tareas a subagentes en paralelo y la ejecución supera un umbral de tiempo (ej. 3–5 minutos), el Coordinador o monitor debe emitir periódicamente un resumen conciso del estado de cada worker y una estimación de tiempo, eliminando la "ansiedad de la caja negra" y el silencio de radio hacia el operador.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan para T-211 aborda la telemetría de latidos proactivos (Progress Heartbeats) de forma modular y estandarizada, respetando la separación de responsabilidades entre perfil (`coordinator.md`), regla canónica (`coordinator-boot.md`), skill operativa (`orchestrator/SKILL.md`) y configuración declarativa (`orchestration-playbooks.yaml`). No se detecta acoplamiento indebido, mutación de código ejecutable ni riesgo de fuga de credenciales. La caja de archivos autorizados está acotada al ámbito de orquestación y trazabilidad del sprint-39.
- **Prospección Scout**: `CONFORME (sprint-39-research.md)`
  - Scout OSS**: Modelos de heartbeat en orquestadores concurrentes.
  - Veredicto**: `Desarrollo a medida justificado` en `coordinator.md`, `coordinator-boot.md` y `orchestration-playbooks.yaml`.
- **Mensaje de Cierre**: `merge(task): integrar T-210 script audit-web-compliance en multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/config/orchestration-playbooks.yaml`
- `.agents/profiles/coordinator.md`
- `.agents/rules/global/coordinator-boot.md`
- `.agents/skills/orchestrator/SKILL.md`
- `.agents/tasks/_archived/task-210.md`
- `.agents/tasks/_archived/task-211.md`
- `docs/sprints/design-decisions/T-210-digest.md`
- `docs/sprints/design-decisions/T-210-raw.json`
- `docs/sprints/sprint-39.md`
- `scripts/agent/assets-manifest.txt`
- `scripts/agent/audit-satellites.sh`
- `scripts/agent/audit-web-compliance.sh`

## 🧠 Skills Declaradas y Aplicadas
- Ninguna skill adicional registrada.
