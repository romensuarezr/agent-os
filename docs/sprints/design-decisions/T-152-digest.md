# Executive Design Digest — T-152

## 🎯 Objetivo
Integrar la herramienta de inferencia nativa Antigravity CLI (`agy`) como Tier 1 prioritario dentro del motor determinista de arbitraje Coder-Reviewer (`scripts/agent/deliberate-plan.sh`), estableciendo una cascada de degradación resiliente: `agy` → `Orca ADE` → `HTTP Cascade` → `SIN_REVISOR`. Implementar el wrapper de timeout portátil, validación del delimitador ante el comportamiento de `exit 0` en timeout de `agy`, y sonda previa de autenticación y flags disponibles.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `SIN_REVISOR` (Rondas: 1)
- **Síntesis de Diseño**: Revisor no disponible (timeout o conexión rehusada). Se activa fallback seguro a aprobación manual clásica.
- **Prospección Scout**: `CONFORME (sprint-27-research.md)`
  - Alternativa detectada:** `node-llama-cpp` (v3.22.2, NPM), `json-schema-to-zod` (v2.8.1, NPM), `json-schema-traverse` (v1.0.0, NPM).
  - Recomendación del agente:** Desarrollo a medida justificado (cableado CLI directo sobre `agy` en PATH o `~/.local/bin/agy`).
  - Decisión del usuario:** Desarrollo a medida justificado — `agy` es un CLI local nativo disponible en el entorno (`agy --version 1.4.12`, accesible en PATH o `~/.local/bin/agy`), con soporte para `--print`, `--output-format json`, `--json-schema` y `--mode plan`. Debe integrarse como primer tier prioritario en `deliberate-plan.sh`, con degradación en cascada a Orca → HTTP → `SIN_REVISOR`.
  - Notas de integración:**
- **Mensaje de Cierre**: `merge: feat/T-152-agy-reviewer-tier1 a multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-152.md`
- `.agents/tasks/task-153.md`
- `docs/sprints/sprint-27-core.md`
- `scripts/agent/deliberate-plan.sh`
- `tests/validate-control-plane.sh`

## 🧠 Skills Declaradas y Aplicadas
- `agent-os-scripts`
- `antigravity-guide`
- `testing-flows`
