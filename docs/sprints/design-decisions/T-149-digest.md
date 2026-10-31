# Executive Design Digest — T-149

## 🎯 Objetivo
Implementar una compuerta determinista fail-closed en el motor de deliberación y pre-flight de planes (`scripts/agent/deliberate-plan.sh`) que verifique que toda skill declarada en el plan borrador existe efectivamente en el directorio `.agents/skills/` del repositorio. Si alguna skill declarada no existe en disco, abortar inmediatamente de forma fail-closed con mensaje explícito y código de error, impidiendo que planes con skills inexistentes o fantasma superen la compuerta técnica.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `SIN_REVISOR` (Rondas: 1)
- **Síntesis de Diseño**: Revisor no disponible (timeout o conexión rehusada). Se activa fallback seguro a aprobación manual clásica.
- **Prospección Scout**: `CONFORME (sprint-26-research.md)`
  - Alternativa detectada:** `ajv` (v8.20.0, NPM), `@deepseek-ai/dsh-sandbox` (v0.0.1-rc.1, NPM).
  - Recomendación del agente:** Desarrollo a medida justificado (validación estática fail-closed en Bash nativo).
  - Decisión del usuario:** Desarrollo a medida justificado — la verificación de skills debe ser determinista, instantánea y con $0 tokens, sin añadir dependencias del ecosistema Node/NPM. Una comprobación directa de la existencia del directorio `.agents/skills/<skill>` y su `SKILL.md` es completamente análoga a la comprobación de la caja de archivos.
  - Notas de integración:**
- **Mensaje de Cierre**: `merge: feat/T-149-skills-fail-closed-gate into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-149.md`
- `docs/sprints/sprint-26-core.md`
- `scripts/agent/deliberate-plan.sh`
- `tests/validate-control-plane.sh`

## 🧠 Skills Declaradas y Aplicadas
- `agent-os-scripts`
- `testing-flows`
