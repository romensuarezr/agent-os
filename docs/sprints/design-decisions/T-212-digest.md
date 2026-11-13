# Executive Design Digest — T-212

## 🎯 Objetivo
Optimizar la estrategia de verificación de metas en worktrees efímeros mediante `scripts/agent/verify-goal.sh` y las directivas del perfil `.agents/profiles/coder.md` y `.agents/skills/orchestrator/SKILL.md`. En el entorno aislado del worker, `verify-goal.sh` prioriza la verificación estricta pero rápida (comprobación de tipos `tsc --noEmit`, linters y tests unitarios / integración rápidos), desacoplando la prerenderización estática masiva (`next build` de decenas de páginas estáticas), la cual se delega a la compuerta final del Coordinador previa a la consolidación en `main`.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan para T-212 aborda con precisión el cuello de botella de contención de I/O y CPU derivado del prerenderizado estático en worktrees concurrentes. La estrategia de desacoplamiento en dos fases (validación ligera '--fast' con type-checking/tests unitarios en el worktree del worker, reservando el 'next build' exhaustivo para la compuerta de merge en el árbol principal) respeta el principio de determinismo, optimiza drásticamente los tiempos de ciclo y mantiene intacta la integridad del control plane.

La delimitación de la caja de archivos autorizados es quirúrgica y coherente con las responsabilidades del core, actualizando simultáneamente el script ejecutor, el perfil del worker, la documentación de la skill de orquestación y el sprint tracking sin introducir mutaciones o acoplamientos indeseados.
- **Prospección Scout**: `CONFORME (sprint-39-research.md)`
  - Scout OSS**: Prácticas de CI/CD para monorrepos y ramas efímeras.
  - Veredicto**: `Desarrollo a medida justificado` en `verify-goal.sh` y directivas del Coder.
- **Mensaje de Cierre**: `merge(task): integrar T-211 protocolo de heartbeat en multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/config/orchestration-playbooks.yaml`
- `.agents/profiles/coder.md`
- `.agents/profiles/coordinator.md`
- `.agents/rules/global/coordinator-boot.md`
- `.agents/skills/orchestrator/SKILL.md`
- `.agents/tasks/_archived/task-211.md`
- `.agents/tasks/_archived/task-212.md`
- `docs/sprints/design-decisions/T-211-digest.md`
- `docs/sprints/design-decisions/T-211-raw.json`
- `docs/sprints/sprint-39.md`
- `scripts/agent/verify-goal.sh`

## 🧠 Skills Declaradas y Aplicadas
- Ninguna skill adicional registrada.
