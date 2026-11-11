# Executive Design Digest — T-197

## 🎯 Objetivo
Extender `scripts/agent/inspect-skills.sh` con un flag `--context` que mida líneas y peso estimado de tokens por `SKILL.md` y detecte skills huérfanas no referenciadas en workflows ni perfiles, para visibilizar el coste de memoria del catálogo.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan para T-197 respeta de manera estricta la caja de archivos autorizada (`scripts/agent/inspect-skills.sh` y `.agents/skills/skill-inspector/SKILL.md`), garantizando cero mutaciones fuera de alcance y manteniendo inmutable el denominador de la suite de control plane (38/38 verdes). La aproximación determinista de cálculo de tokens (`líneas × 10`) mediante bash/awk puro cumple con el principio de coste $0 y ausencia de dependencias externas. Asimismo, la arquitectura de cortocircuito temprano asegura la retrocompatibilidad total del gate de seguridad por defecto, y el protocolo de verificación con snapshots pre y post-cambio mitiga eficazmente cualquier riesgo de regresión funcional.
- **Prospección Scout**: `CONFORME (sprint-36-research.md)`
  - Consulta scout**: `token context weight audit orphan skills manifest lines tokens`
  - Alternativas detectadas**: paquetes npm ajenos al problema (`js-tokens`, `parse-statements`, `@sanity-labs/design-tokens`) — sin aplicabilidad.
  - Recomendación**: `Desarrollo a medida justificado` — extensión determinista de `scripts/agent/inspect-skills.sh` (script existente del core, señal⚠️ leído, no recreado). Se reutiliza la base de inspección estática existente.
- **Mensaje de Cierre**: `Merge branch 'feat/T-197-inspect-skills-context' into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/skills/skill-inspector/SKILL.md`
- `.agents/tasks/_archived/task-197.md`
- `docs/sprints/sprint-36.md`
- `scripts/agent/inspect-skills.sh`

## 🧠 Skills Declaradas y Aplicadas
- Ninguna skill adicional registrada.
