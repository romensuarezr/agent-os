# Executive Design Digest — T-201

## 🎯 Objetivo
Implementar el descubrimiento proactivo de Agent OS en repositorios satélite creando la plantilla canónica `templates/root/AGENTS.md` (distribuida vía `install.sh` y `sync.sh`) y la regla global `.agents/rules/global/coordinator-boot.md`, de modo que cuando un agente nuevo (Antigravity, Cursor, etc.) inicie sesión en cualquier proyecto satélite, se presente automáticamente como Coordinador, diagnostique el estado del sprint a coste $0 tokens y ofrezca el menú interactivo de opciones.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan para T-201 es 100% aditivo, agnóstico del stack y respeta estrictamente la Regla 22 (frontera portable) al evitar rutas absolutas y dependencias del entorno local. La preservación de archivos preexistentes en los scripts de instalación y sincronización previene sobreescrituras accidentales en proyectos satélite.

La delimitación de la caja de cambios es limpia y acotada, incorporando el registro en assets-manifest.txt y garantizando la compatibilidad con el control plane sin mutaciones de riesgo.
- **Prospección Scout**: `CONFORME (sprint-37-research.md)`
  - Keywords**: `agent onboarding greeting protocol`
  - Alternativas OSS evaluadas**:
  - `major-ai-skills` (v2.5.0): Contratos modulares de skills, pero no resuelve el boot inicial a nivel de repo.
  - Reglas nativas de Antigravity (`AGENTS.md`, `.agents/rules/*.md`): Soporte nativo de inyección jerárquica de reglas al abrir el workspace.
- **Mensaje de Cierre**: `docs(sprint): planificar sprint-37`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/rules/global/coordinator-boot.md`
- `.agents/tasks/_archived/task-201.md`
- `.agents/tasks/task-202.md`
- `.agents/tasks/task-203.md`
- `.agents/tasks/task-204.md`
- `docs/sprints/sprint-37-research.md`
- `docs/sprints/sprint-37.md`
- `roadmap.md`
- `scripts/agent/assets-manifest.txt`
- `scripts/agent/install.sh`
- `scripts/agent/sync.sh`
- `templates/root/AGENTS.md`

## 🧠 Skills Declaradas y Aplicadas
- Ninguna skill adicional registrada.
