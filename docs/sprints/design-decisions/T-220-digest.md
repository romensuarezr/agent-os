# Executive Design Digest — T-220

## 🎯 Objetivo
Objetivo no especificado.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico para T-153 se alinea estrictamente con el diseño macro aprobado en planning y el contrato operativo del core. Aborda de forma determinista y hermética los tres vectores de contención requeridos para el Revisor agy: centinela PRE fail-closed ante working tree sucio, aislamiento de entorno mediante 'env -i' con whitelist estricta, reversión post-ejecución acotada exclusivamente al diff diferencial pre/post con escalado a humano, e incorporación del nit de gobernanza para degradar limpiamente si portable_timeout no está presente.

La caja de archivos está acotada estrictamente a los componentes necesarios ('scripts/agent/deliberate-plan.sh', 'tests/validate-control-plane.sh' y '.agents/tasks/task-153.md') y la estrategia de verificación asegura el mantenimiento del invariante de 37/37 checks en la suite de control plane sin introducir mutaciones no controladas ni riesgos de regresión.
- **Prospección Scout**: `CONFORME (sprint-41-research.md)`
  - Alternativas evaluadas**:
  - Re-implementación desde cero de la skill orca.
  - Decisión**: Adopción de la skill probada en satélite (`romensuarez-web` T-050) y desarrollo a medida para el fix de staging.
  - Justificación**: El satélite `romensuarez-web` ya homologó y testeó `orca-cli` evitando la colisión de PATH con `/usr/bin/orca` (screen reader de GNOME), resolviendo alias `~/.local/bin/orca-agent` y subcomandos `worktree`, `task`, `browser`. En `contribute.sh`, la línea 73 ejecutaba `git add .` indiscriminado, lo que rompía la compuerta de higiene si había archivos untracked; debe acotarse estrictamente a `git add "$DEST_DIR/$FILE_NAME"`.
- **Mensaje de Cierre**: `feat(T-219): cierre de tarea T-219`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/config/skills-manifest.yaml`
- `.agents/skills/orca-cli/SKILL.md`
- `.agents/tasks/_archived/task-219.md`
- `.agents/tasks/_archived/task-220.md`
- `.agents/workflows/session-close.md`
- `docs/sprints/design-decisions/T-219-digest.md`
- `docs/sprints/design-decisions/T-219-raw.json`
- `docs/sprints/sprint-41.md`
- `scripts/agent/close-sprint.sh`
- `scripts/agent/contribute.sh`

## 🧠 Skills Declaradas y Aplicadas
- Ninguna skill adicional registrada.
