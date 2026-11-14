# Executive Design Digest — T-223

## 🎯 Objetivo
Objetivo no especificado.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico para T-153 se alinea estrictamente con el diseño macro aprobado en planning y el contrato operativo del core. Aborda de forma determinista y hermética los tres vectores de contención requeridos para el Revisor agy: centinela PRE fail-closed ante working tree sucio, aislamiento de entorno mediante 'env -i' con whitelist estricta, reversión post-ejecución acotada exclusivamente al diff diferencial pre/post con escalado a humano, e incorporación del nit de gobernanza para degradar limpiamente si portable_timeout no está presente.

La caja de archivos está acotada estrictamente a los componentes necesarios ('scripts/agent/deliberate-plan.sh', 'tests/validate-control-plane.sh' y '.agents/tasks/task-153.md') y la estrategia de verificación asegura el mantenimiento del invariante de 37/37 checks en la suite de control plane sin introducir mutaciones no controladas ni riesgos de regresión.
- **Prospección Scout**: `CONFORME (sprint-41-research.md)`
  - Alternativas evaluadas**:
  - Nixpacks nativo de Coolify (falla en monorepos complejos pnpm con dependencias de workspace como `@leaderboard/core`).
  - Dockerfile manual por cada proyecto satélite sin estándar.
  - Decisión**: Patrón estándar Next.js 15 Standalone Dockerfile Multi-Stage con Corepack + Pnpm.
- **Mensaje de Cierre**: `feat(T-222): cierre de tarea T-222`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/skills/coolify-nextjs-deploy/SKILL.md`
- `.agents/skills/coolify-nextjs-deploy/scripts/audit-next.sh`
- `.agents/skills/coolify-nextjs-deploy/templates/Dockerfile.flat.template`
- `.agents/skills/coolify-nextjs-deploy/templates/Dockerfile.monorepo.template`
- `.agents/skills/coolify-nextjs-deploy/templates/Dockerfile.template`
- `.agents/tasks/_archived/task-222.md`
- `.agents/tasks/_archived/task-223.md`
- `docs/runbooks/coolify-nextjs-deploy.md`
- `docs/sprints/design-decisions/T-222-digest.md`
- `docs/sprints/design-decisions/T-222-raw.json`
- `docs/sprints/sprint-41.md`
- `scripts/agent/assets-manifest.txt`
- `scripts/agent/install.sh`
- `scripts/agent/sync.sh`
- `tests/validate-control-plane.sh`

## 🧠 Skills Declaradas y Aplicadas
- Ninguna skill adicional registrada.
