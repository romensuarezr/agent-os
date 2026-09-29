# Task-085: Namespacing de configuración runtime (`config/` → `.agents/config/`) y blindaje de overlays

## Objetivo
Trasladar todo el catálogo de configuración runtime desde `config/` a `.agents/config/` de forma canónica y uniforme para el core y proyectos hijos, eliminando clutter en la raíz y evitando colisiones con directorios nativos (`config/` en Rails, Laravel, NestJS, etc.), mientras se garantiza en `install.sh` y `sync.sh` que los overlays privados (`fleet.yaml`) nunca fuguen a los repositorios hijos.

## Contexto técnico
- **Problema**: `discover-fleet.sh --apply` y el diseño original ubicaban `config/` en la raíz del repositorio. Al instalarse en proyectos satélite que ya poseen su propio `config/`, se produce mezcla de archivos de la aplicación anfitriona con la configuración de Agent OS. Además, unificar bajo `.agents/config/` dota a cualquier agente sin contexto de una convención única.
- **Riesgo de fuga**: Previamente, la distinción física `.agents/` (instalable) vs `config/` (no instalable) impedía que `fleet.yaml` fuese copiado al hijo. Al unificar bajo `.agents/config/`, `install.sh` y `sync.sh` deben excluir explícitamente `.agents/config/fleet.yaml` y `.agents/config/fleet.local.yaml`.
- **Fallback retrocompatible con advertencia ruidosa**: En caso de encontrar `config/fleet.yaml` en proyectos hijos desactualizados, los scripts consumidores mantendrán fallback pero emitirán obligatoriamente una advertencia de deprecación a `stderr`: `⚠️ DEPRECATED: config/fleet.yaml es una ruta obsoleta. Migrar a .agents/config/fleet.yaml`. Silencioso no es opción para permitir visibilidad en `audit-child.sh` (T-088).
- **Invarianza Histórica**: Task files históricos (`.agents/tasks/task-0*.md`) y documentos en `_archived/` NO se reescriben para preservar la fidelidad de auditorías pasadas; la migración aplica exclusivamente a código vivo y documentación viva.

## Caja de archivos
Archivos autorizados para modificación / creación:
- **Sprint Setup**:
  - `docs/sprints/sprint-13-core.md` (CREADO siguiendo `.agents/workflows/sprint-planning.md`)
  - `roadmap.md` (actualizado con Sprint 13)
  - `.agents/tasks/task-085.md`
- **Scripts y Core**:
  - `scripts/agent/fleet-doctor.sh`
  - `scripts/agent/discover-fleet.sh`
  - `scripts/agent/import-secrets.sh`
  - `scripts/agent/generate-homepage-config.sh`
  - `scripts/agent/install.sh`
  - `scripts/agent/sync.sh`
  - `tests/validate-control-plane.sh`
  - `.gitignore`
- **Ficheros de configuración (`config/*` trasladados a `.agents/config/*`)**:
  - `.agents/config/routing-policy.yaml`
  - `.agents/config/skills-manifest.yaml`
  - `.agents/config/known-web-tools.yaml`
  - `.agents/config/fleet.example.yaml`
  - `.agents/config/agent-registry.yaml`
- **Onboarding, Skills, Reglas, Workflows y Perfiles vivos**:
  - `.agents/AGENT_ONBOARDING.md` (línea 39 y mapa de navegación)
  - `.agents/skills/tool-inventory/SKILL.md`
  - `.agents/skills/infisical-secrets/SKILL.md`
  - `.agents/skills/coolify-admin/SKILL.md`
  - `.agents/rules/global/tool-decision-flow.md`
  - `.agents/workflows/parallel-orchestration.md`
  - `.agents/profiles/README.md`
- **Documentación viva y seguimiento**:
  - `AGENTS.md`
  - `docs/architecture/tools/llm-routing-selection.md`
  - `docs/architecture/tools/candidate-gateways.md`
  - `docs/adrs/adr-004-agent-control-plane-architecture.md`
  - `docs/runbooks/prueba-ciega.md`
  - `docs/runbooks/fleet-doctor.md`
  - `docs/architecture/tool-inventory.md`
  - `docs/runbooks/orca-read-only-audit.md`
  - `docs/runbooks/orca-multiagent-orchestration.md`
  - `docs/runbooks/github-ssh-setup-remote.md`
  - `docs/runbooks/hermes-vps-runbook.md`
  - `docs/runbooks/glances-setup.md`
  - `docs/runbooks/freellmapi-vps-runbook.md`
  - `docs/runbooks/opencode-freellmapi-setup.md`
  - `docs/runbooks/oracle-disk-and-ports-audit.md`
  - `docs/runbooks/oracle-disk-recovery-plan.md`
  - `README.md`

## Criterios de done
- [x] Carpeta raíz `config/` eliminada; todos sus ficheros versionados viven en `.agents/config/` (`git ls-files config/` devuelve 0).
- [x] `install.sh` y `sync.sh` resuelven la ruta `$AGENT_OS_PATH/.agents/config/` y excluyen explícitamente `fleet.yaml` de ser instalado en el satélite.
- [x] Scripts consumidores (`fleet-doctor.sh`, `discover-fleet.sh`, `import-secrets.sh`, `generate-homepage-config.sh`) actualizados a `.agents/config/`.
- [x] Fallback retrocompatible en scripts consumidores ante `config/fleet.yaml` con emisión obligatoria de advertencia en `stderr`.
- [x] 0 referencias a `config/fleet` como ruta canónica en `scripts/` y `.agents/`, permitiendo únicamente las líneas de fallback marcadas explícitamente como retrocompatibles.
- [x] `.agents/AGENT_ONBOARDING.md` actualizado apuntando a `.agents/config/fleet.yaml` e incorporando `.agents/config/` a su mapa de navegación.
- [x] Skills, rules, workflows, profiles y docs vivos actualizados sin enlaces rotos a la ruta obsoleta.
- [x] `.gitignore` actualizado con reglas para `.agents/config/fleet.yaml` y `.agents/config/fleet.local.yaml`.
- [x] Decisión explícita respetada: task files históricos (`task-0*.md`) y docs archivados (`_archived/`) no han sido modificados.
- [x] `tests/validate-control-plane.sh` pasa 12/12 sin fallos de rutas ni sintaxis YAML.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-29T23:23:02+01:00 (APROBADO CON CAMBIOS)
- [x] Rama creada: feat/T-085-namespacing-config
- [x] Lock activo: .agent-session.lock
- [ ] Sesión cerrada correctamente
