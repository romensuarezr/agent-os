# last-sync.md — Estado operativo del core

> Este archivo es la marca de estado del propio agent-os como proyecto self-hosted.

---

## Estado actual

- **Modo**: self-hosted (agent-os operando sobre sí mismo)
- **Sprint activo**: sprint-19-core (planificado 2026-10-27; T-113, T-114, T-115, T-116)
- **Último sprint cerrado**: sprint-18-core (publicado en `main` como `v1.14.0`)
- **Último bootstrap**: 2026-06-16
- **Versión del core**: `v1.14.0` (`changelog.md` es la fuente de verdad; `VERSION` debe coincidir)

---

## Notas de contexto

- Los scripts en `scripts/agent/` son los mismos que se instalan en proyectos hijos
- `install.sh --self` está disponible para re-crear carpetas operativas si se borran
- Para sincronizar proyectos hijos: `bash scripts/agent/sync.sh <ruta-proyecto-hijo>`
- Para recibir mejoras de proyectos hijos: revisar PRs creados con `contribute.sh`

---

## Proyectos hijos conocidos

| Proyecto | Stack | Última sync |
|---|---|---|
| Kanarii | React / TypeScript / Firebase | — |
| Polymarket | Python | — |
| surf-app | — | — |
