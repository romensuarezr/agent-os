# Executive Design Digest — T-193

## 🎯 Objetivo
Transformar el mecanismo de actualización y sincronización de Agent OS en proyectos satélite (hijos), eliminando el bloqueo del timeout interactivo de 10s en `check-session.sh` y la directiva pasiva en `sprint-planning.md`. El sistema debe pre-visualizar cambios con `sync.sh --dry-run`, extraer automáticamente las novedades de `changelog.md` frente a la versión local y generar un Plan de Impacto estructurado que se someta a aprobación en la ventana de decisión macro.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico para T-193 se adhiere de forma estricta a los principios de diseño de Agent OS: determinismo, $0 coste de tokens y no destructividad. La eliminación del bloqueo por timeout en check-session.sh mediante detección de stdin no interactivo ([ ! -t 0 ]) erradica fricciones de latencia en invocaciones desatendidas, al tiempo que la formalización de CORE_UPDATE_AVAILABLE y el enriquecimiento de sync.sh --dry-run proporcionan telemetría estructurada sin efectos secundarios.

La incorporación del Plan de Impacto de Actualización en los workflows canónicos (sprint-planning.md y session-start.md) garantiza una gobernanza robusta en satélites antes de la ejecución de sprints. La allowlist de archivos se encuentra estrictamente delimitada y la estrategia de verificación asegura la integridad del control plane sin riesgo de regresiones arquitectónicas.
- **Prospección Scout**: `CONFORME (sprint-35-research.md)`
  - Alternativas detectadas**: `git-subrepo`, `git-subtree`, sincronización manual bash.
  - Dictamen Scout**: Mantener la arquitectura sovereign $0 tokens basada en `scripts/agent/sync.sh` enriquecida con `--dry-run`, extracción determinista de novedades de `changelog.md` y generación del plan de impacto estructurado previo a la aprobación.
- **Mensaje de Cierre**: `feat(tooling): homologación integral de tooling upstream y detección remota en VPS (T-192)`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/config/fleet.example.yaml`
- `.agents/skills/infisical-secrets/SKILL.md`
- `.agents/skills/orchestrator/SKILL.md`
- `.agents/skills/tooling-advisor/SKILL.md`
- `.agents/tasks/_archived/task-192.md`
- `.agents/tasks/_archived/task-193.md`
- `.agents/workflows/session-start.md`
- `.agents/workflows/sprint-planning.md`
- `docs/runbooks/hermes-vps-runbook.md`
- `docs/sprints/design-decisions/T-192-digest.md`
- `docs/sprints/design-decisions/T-192-raw.json`
- `docs/sprints/sprint-35.md`
- `scripts/agent/check-session.sh`
- `scripts/agent/check-tooling-updates.sh`
- `scripts/agent/fleet-doctor.sh`
- `scripts/agent/sync.sh`

## 🧠 Skills Declaradas y Aplicadas
- Ninguna skill adicional registrada.
