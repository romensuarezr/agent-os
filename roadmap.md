# Roadmap — agent-os

## En curso
- Sprint 22 — Resiliencia de Orquestación Multi-Agente, Puentes de Estado y Flujos Autónomos (T-128 a T-131, planificación en curso). Ver `docs/sprints/sprint-22-core.md`.

## Próximo
- Rotar las 15 credenciales revocadas detectadas en la bóveda; requiere decidir si `CLOUDFLARE_API_TOKEN` es transversal o un token por zona. ⛔ BLOQUEADO hasta el veredicto del usuario — no entra a sprint sin acotación.
- **Sprint 21**: Arquitectura Multi-Agente, Orquestación y Workflows (T-124 a T-127). Formalizado como release `v1.17.0` en `multi-agent`. Ver `docs/sprints/_archived/sprint-21-core.md`.
- **Sprint 20**: Deliberación Cruzada Autónoma y Executive Design Digest (T-119 a T-123). Formalizado como release `v1.16.0` en `multi-agent`. Ver `docs/sprints/_archived/sprint-20-core.md`.
- **Sprint 19**: Versiones, Honestidad del Escáner y Seguridad de Secretos (T-113 a T-118). Formalizado como release `v1.15.0` en `multi-agent`. Ver `docs/sprints/_archived/sprint-19-core.md`.
- **Sprint 18**: Corrección de Versiones, Higiene de Convenciones y Consolidación (T-106, T-108, T-109, T-110, T-112). Publicado en `main` como `v1.14.0` (tag `v1.14.0` sobre `cdb1566`).
- **Sprint 17**: Despacho Multi-Repo, Flujo de Worktrees y Punto de Entrada del Coordinador (T-104, T-107, T-105). Publicado en `main` como `v1.13.0`.
- **Sprint 16**: Frontera Portable y Saneado de Exposición (T-103).
- **Sprint 15**: Publicación Remota y Honestidad de los Scripts de Cierre (T-100, T-101, T-102).
- **Sprint 14**: Automejora y Confianza (T-091 a T-098)
  - [T-091] Regla de destilación y automejora procedimental (Self-Improvement Distillation) (M).
  - [T-092] Fix consistencia de secciones en `roadmap.md` y `audit-repo.sh` (HIGH) (S).
  - [T-093] Port de patrones estáticos de SkillSpector adaptado a `.agents/skills/` (M).
  - [T-094] Unificación de firma CLI con soporte `--path` en `audit-repo.sh` (S).
  - [T-095] Ciclo de vida de secretos: localizador, auditoría de bóveda, taxonomía, catálogo y materialización (L).
  - [T-096] Guidance operativo del working tree post-instalación en `install.sh` (S).
  - [T-097] Remediación inmediata y desbloqueo de Hermes en <nodo-inferencia> y <nodo-orquestacion> (M).
  - [T-098] Pre-flight de pasarelas de inferencia y formalización de la remediación (S).
- Sprint 13: Escalado, Distribución Universal del Core & Ciclo de Vida de Satélites (T-085 a T-090).
- Sprint 12: Core Hardening, Gobernanza & Pilotaje Portable (T-080 a T-084).
- Sprint 11: Core Hardening, Fleet Doctor & Descubrimiento 0-contexto (T-067 a T-079).
- Sprint 10: Homepage Fleet Observability, Perimetral Security & AI Telemetry (T-060 a T-065).
- Sprint 09: Multi-Agent Parallel Orchestration & Deterministic Goals Engine (T-054 a T-059).

## Próximo
- ✅ Automatizar la publicación de ramas de tarea (T-101, Sprint 15): `promote-to-main.sh` ya tiene `--push-source`, `--merge-commit` y `--pr`.
- ✅ Mapa global de flujos de Agent OS con niveles de zoom C4 (T-102, Sprint 15): `scripts/agent/generate-flow-map.sh` genera `docs/flow-map.md` + digest.
- ✅ **FIXES de `close-*.sh`** (T-100, Sprint 15) — resueltos:
  - `close-task.sh` actualiza el enlace de su fila al archivar (antes roto en T-094, T-095, T-096 y T-098).
  - `close-sprint.sh` hace staging acotado a sus propios ficheros y avisa de lo ajeno (antes commit `0 insertions / 0 deletions` en sprint-14).
- Rotar las 15 credenciales revocadas detectadas en la bóveda; requiere decidir si `CLOUDFLARE_API_TOKEN` es transversal o un token por zona. ⛔ BLOQUEADO hasta el veredicto del usuario — no entra a sprint sin acotación.
- ✅ Wrapper portable de copias no destructivas (`cp -n` vs `--update=none`) en `lib/portable-fs.sh` (T-110, sprint-18).
- Estandarización de variables de entorno y endpoints en `coolify-admin` / MCPs (S).
- Impeccable critique: protocolo de auditoría y revisión de interfaces UI para satélites (M).
- [T-043] Prospección periódica automatizada de herramientas Freemium / OSS para `tool-inventory` (S).
- Auditorías automáticas del estado de salud de los scripts en proyectos hijos.
- Refinamiento de workflows globales y estandarización de logs de ejecución.

## Backlog
- Manifest de assets regenerable en `close-sprint.sh` (idea de 2026-06-18, especificación en `docs/idea-inbox/`). Diferido 4 sprints sin incidente; el manifest manual funciona. Se deja de arrastrar al sprint.
- Skill + CLI `bytebox-curator` para registrar snippets y comandos en ByteBox (idea de 2026-09-26, especificación en `docs/idea-inbox/`). Producto específico, no es core; puede conectar con trabajo futuro, no se archiva.

## Descartado
- (Sin líneas descartadas por el momento)

## Deuda observada

- **`docs/architecture/control-plane-topology.md` incumple la política de
  `docs/critical-flows.md`.** El primero abre con un `[!IMPORTANT]` que prohíbe literales de
  infraestructura; el segundo está versionado en git desde `8b335c1` y contiene cuatro hostnames
  reales (`<host-local>`, `<nodo-inferencia>`, `<nodo-web>`, `<nodo-datos>`). Verificado en
  `HEAD`, `origin/main`, `origin/multi-agent` y `feat/sprint-11-core-planning`.
  **Detectado en T-102** (2026-10-13) al modelar el mapa de flujos y **sanado en T-103**:
  sus literales están sustituidos por marcadores genéricos. El mapa ya no podía propagarlos
  porque se genera desde `critical-flows.md` y nunca leyó ese fichero.
  ~~Sanear el documento existente~~ → hecho.
