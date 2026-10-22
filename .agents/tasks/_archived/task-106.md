# Task-106: Saneado de exposición de infraestructura en romensuarez-web

## Objetivo
Sanear las violaciones de frontera portable del satélite `romensuarezr/romensuarez-web` sobre la base
**`origin/main` (`339b029`)**, no sobre la rama stale `romensuarezr/limpet` (74 commits por detrás).
Alcance verificado en `main`: 36 líneas en 8 documentos (rutas personales `file://<ruta-personal>/…`
e IP pública `<ip-publica>`) + 4 ficheros de `.agents/tasks/_archived/` excluidos con motivo escrito.
En `main` **no hay violaciones en código** (`docs/adr/` singular no existe; no hay duplicidad de ADRs).

## Contexto técnico
El escáner del core ya soporta repo externo (`locator-hygiene.sh --path`, puro lector, sin escrituras).
El satélite expone `.agents/`, así que la exclusión vive en
`<worktree>/.agents/config/infra-literals.exceptions` — directorio que **no existe en `main`** y se crea.
Base fijada por el usuario: `origin/main` = `339b029`; el commit local sin pushear `9f20ad7` no se mezcla.
Transformación: `file://<ruta-personal>/<X>` → enlace relativo real; `<ip-publica>` → marcador `<ip-publica>`.
`_archived/` se excluye (no se reescribe historia).

## Caja de archivos
Archivos autorizados para modificación (en el worktree `limpet-T-106`, base `339b029`):
- `docs/adrs/ADR-001-estrategia-despliegue-hibrida-cloudflare-coolify.md`
- `docs/adrs/ADR-002-segmentacion-subdominios-cloudflare-access.md`
- `docs/adrs/ADR-003-configuracion-produccion-versionada.md`
- `docs/adrs/README.md`
- `docs/architecture-evaluation-cloudflare-coolify.md`
- `docs/coolify-deployment-guide.md`
- `docs/coolify-deployment-verification.md`
- `roadmap.md`
- `.agents/config/infra-literals.exceptions` (crear; `.agents/config/` no existe en `main`)
Ampliación aprobada (2026-10-22) — 8 ficheros `[hostname-nodo]`:
- Restaurar byte-idénticos desde el core (6; prohibición era editar código, no restaurar sync verificado):
  `.agents/profiles/coordinator.yaml`, `.agents/profiles/ops-auditor.yaml`,
  `.agents/skills/coolify-admin/SKILL.md`, `.agents/skills/remote-admin/scripts/audit-host.sh`,
  `.agents/skills/remote-admin/scripts/check-git-remote.sh`, `scripts/agent/audit-orca.sh`
- Saneado in situ, solo la línea marcada (2; exclusivos del satélite):
  `.agents/skills/twenty-crm-guidelines/SKILL.md:14`, `docs/runbooks/twenty-crm-operations.md:76`
Prohibido: editar el resto de `scripts/**`, historia (`_archived/**`), `docs/adr/` (no existe en `main`),
cualquier fichero fuera de esta lista.

## Criterios de done
- [x] `locator-hygiene.sh --path <worktree>` devuelve **0 violaciones** ANTES del commit
- [x] `_archived/task-005/006/007/038.md` excluidos con motivo escrito (no reescritos)
- [x] Los 6 assets restaurados: `diff` contra el core = 0 (byte-idénticos, evidencia reportada)
- [x] In situ solo las 2 líneas marcadas; nada más de esos ficheros tocado
- [x] Suite del core **27/27** (incluye el check 27 nuevo del fix `--path`)
- [x] 2 commits locales en el satélite `3300aa1`/`8fa413d` (rama `feat/T-106-…`); **sin push**
- [x] `limpet` y `Proyectos/romensuarez-web` intactos

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO — 2026-10-22 (A: base `origin/main` 339b029; B: worktree `limpet-T-106`; C: sin push)
- [x] Rama creada: `feat/T-106-saneado-frontera-portable` (worktree `limpet-T-106`, base 339b029)
- [x] Lock activo: `.agent-session.lock` (core → worktree satélite)
- [ ] Sesión cerrada correctamente
