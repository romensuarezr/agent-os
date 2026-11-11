# Idea: PREV_TAG de update-changelog.sh ordena por fecha, no por versión — 2026-10-16

**Prioridad:** Baja (bug latente, sin incidente observado) — candidata a backlog

**Problema:**
`update-changelog.sh:49` elige el tag del sprint anterior con
`git tag --sort=-creatordate | head -1`. Si un tag posterior se crea sobre un commit anterior
(o se re-taggea), el rango `${PREV_TAG}..HEAD` no es el esperado y el sprint se clasifica con
commits de otro rango. Detectado al planificar T-108 (2026-10-16); explícitamente fuera de su
alcance (es otro bug, otro alcance).

**Propuesta:**
Ordenar por versión semver (`--sort=-v:refname`) o por el tag alcanzable más cercano al HEAD
(`git describe --tags --abbrev=0`), con fallback al comportamiento actual si no hay tags.

**Archivos que toca:**
- `scripts/agent/update-changelog.sh` (línea 49)
- `tests/validate-control-plane.sh` (extender el check 26 de T-108 con el caso)
