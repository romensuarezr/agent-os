# Task-083: Estandarización de Interfaz CLI (`--help` en 15 scripts) y Normalización de Skills

## Objetivo
Implementar la biblioteca reutilizable `scripts/agent/lib/cli-help.sh` con la función `show_help` estandarizada e integrarla en los 15 scripts de `scripts/agent/` evaluando `-h|--help` en la primera línea ejecutable. Convertir `.agents/skills/external-inbox.md` a carpeta de skill canónica `.agents/skills/external-inbox/SKILL.md`, añadir secciones "Cuándo usar" a las 7 skills sin disparador explícito, alinear rutas e invocaciones de scripts, incorporar notas de equivalencia runtime agnósticas (Antigravity-isms) y subsanar referencias documentales.

## Contexto técnico
La auditoría del Sprint 11 identificó deuda en la interfaz de línea de comandos y en la uniformidad de skills:
- **SCR-M13 / SCR-B1**: 15 scripts en `scripts/agent/` carecen de gestión interactiva de `-h|--help`. Se requiere un helper modular `scripts/agent/lib/cli-help.sh` con la función `show_help <nombre> <sinopsis> <descripcion> [opciones...]` que emita la ayuda formateada y finalice con `exit 0`. Los scripts deben invocarla en su primera línea ejecutable, antes de guardias de argumentos o git.
- **SKL-MEDIA-8**: `.agents/skills/external-inbox.md` es el único archivo suelto que rompe la convención de carpetas con `SKILL.md`. Se migra a `external-inbox/SKILL.md` y se actualiza `.agents/context/skills-inventory.md`.
- **SKL-H-19**: 7 skills (`coolify-admin`, `coolify-nextjs-deploy`, `goal-evaluation`, `infisical-secrets`, `orchestrator`, `remote-admin`, `tool-inventory`) carecen de sección "Cuándo usar" explícita.
- **SKL-MEDIA-6**: `coolify-nextjs-deploy/SKILL.md` línea 71 utiliza invocación sin prefijo de ruta (`cloudflare-dns.sh`), mientras la L73 usa `./scripts/cloudflare-dns.sh`.
- **SKL-BAJA-2**: `implementar-feature-dry/SKILL.md` cita `.agents/rules/naming-convention.md`, que no existe en el core. Se sustituye por directiva agnóstica de convenciones del proyecto.
- **SKL-H-16**: Skills que asumen primitivas propietarias de Antigravity (`run_command` en `creador-habilidades`, `notify_user` con `BlockedOnUser` en `rule-creator`, "abrir Antigravity" en `doe-framework`) incorporan aclaración de equivalencias agnósticas para otros runtimes (Claude Code, OpenCode, Hermes, terminal shell).
- **SKL-MEDIA-4**: `session-close.md` verifica contra "Fase 2.5", la cual no existe en `session-start.md`. Se corrige la cita hacia el pre-flight de Fase 2 / 3.5.
- **SKL-R-5**: Numeración de títulos en `docs/runbooks/orca-read-only-audit.md` homogeneizada.
- **SKL-E-2**: `CONTRIBUTING.md` enlaza formalmente los términos de workflow operativo a `.agents/workflows/session-start.md`.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/lib/cli-help.sh` (nuevo)
- `scripts/agent/audit-mvp-tracker.sh`
- `scripts/agent/audit-orca.sh`
- `scripts/agent/audit-repo.sh`
- `scripts/agent/check-inbox.sh`
- `scripts/agent/check-lazy-planning.sh`
- `scripts/agent/check-session.sh`
- `scripts/agent/check-sprint.sh`
- `scripts/agent/close-sprint.sh`
- `scripts/agent/close-task.sh`
- `scripts/agent/contribute.sh`
- `scripts/agent/generate-digest.sh`
- `scripts/agent/inventory-check.sh`
- `scripts/agent/scout.sh`
- `scripts/agent/update-changelog.sh`
- `scripts/agent/update-mvp-tracker.sh`
- `.agents/skills/external-inbox.md` (renombrado)
- `.agents/skills/external-inbox/SKILL.md` (nuevo)
- `.agents/context/skills-inventory.md`
- `.agents/skills/coolify-admin/SKILL.md`
- `.agents/skills/coolify-nextjs-deploy/SKILL.md`
- `.agents/skills/goal-evaluation/SKILL.md`
- `.agents/skills/infisical-secrets/SKILL.md`
- `.agents/skills/orchestrator/SKILL.md`
- `.agents/skills/remote-admin/SKILL.md`
- `.agents/skills/tool-inventory/SKILL.md`
- `.agents/skills/creador-habilidades/SKILL.md`
- `.agents/skills/rule-creator/SKILL.md`
- `.agents/skills/doe-framework/SKILL.md`
- `.agents/skills/implementar-feature-dry/SKILL.md`
- `.agents/workflows/session-close.md`
- `docs/runbooks/orca-read-only-audit.md`
- `CONTRIBUTING.md`
- `docs/sprints/sprint-12-core.md`
- `.agents/tasks/task-083.md`

## Criterios de done
- [x] `scripts/agent/lib/cli-help.sh`: creado con la función `show_help` estandarizada (sinopsis, descripción, parámetros/opciones, ejemplos, exit 0).
- [x] 15 scripts actualizados con `source` a `cli-help.sh` y evaluación de `-h|--help` en su primera línea ejecutable:
  - [x] `audit-mvp-tracker.sh`
  - [x] `audit-orca.sh`
  - [x] `audit-repo.sh`
  - [x] `check-inbox.sh`
  - [x] `check-lazy-planning.sh`
  - [x] `check-session.sh`
  - [x] `check-sprint.sh`
  - [x] `close-sprint.sh`
  - [x] `close-task.sh`
  - [x] `contribute.sh`
  - [x] `generate-digest.sh`
  - [x] `inventory-check.sh`
  - [x] `scout.sh`
  - [x] `update-changelog.sh`
  - [x] `update-mvp-tracker.sh` (añadida cabecera `Uso:` según SCR-B1)
- [x] `.agents/skills/external-inbox.md` renombrado a `.agents/skills/external-inbox/SKILL.md` y actualizado `.agents/context/skills-inventory.md:20`.
- [x] Secciones "Cuándo usar" añadidas a las 7 skills (`coolify-admin`, `coolify-nextjs-deploy`, `goal-evaluation`, `infisical-secrets`, `orchestrator`, `remote-admin`, `tool-inventory`).
- [x] Invocación corregida en `coolify-nextjs-deploy/SKILL.md:71` (`./scripts/cloudflare-dns.sh`).
- [x] Referencia en `implementar-feature-dry/SKILL.md:22` actualizada a convenciones de arquitectura/proyecto.
- [x] Equivalencias de runtime agnósticas documentadas en `creador-habilidades`, `rule-creator` y `doe-framework`.
- [x] Referencia a "Fase 2.5" corregida en `.agents/workflows/session-close.md`.
- [x] Numeración de títulos homogeneizada en `docs/runbooks/orca-read-only-audit.md`.
- [x] Enlaces canónicos añadidos en `CONTRIBUTING.md`.
- [x] Pruebas unitarias de `--help` en los 15 scripts devuelven salida clara y código 0.
- [x] `tests/validate-control-plane.sh` pasa 12/12 sin regresiones.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-29T21:43:41+01:00 (APROBADO CON CAMBIOS)
- [x] Rama creada: feat/T-083-estandarizacion-cli-skills
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
