# Research Sprint 35
> Fuente: Scout Determinista ($0 tokens) + Bypass Autónomo SearXNG (Core Interno)
> Fecha: 2026-11-11
> Sprint: sprint-35

## Estado de Investigación Técnica (SearXNG)
SearXNG verificado activo (`HTTP 200` en endpoint de flota).
> *Investigación web externa no requerida: tareas de alcance puramente interno/core.*

---

## Descubrimientos Scout (por tarea)

### T-192: Homologación integral de actualización de tooling (glances, hermes, infisical, opencode, orca)
- **Alternativas detectadas**: Herramientas consolidadas upstream oficiales (OpenCode CLI v2.2.7, Hermes v0.23.1, Orca v1.4.256, Infisical v0.167.8, Glances v4.5.9).
- **Dictamen Scout**: Integración/adopción obligatoria. No se realiza desarrollo a medida.
- **Alcance vivo**: Actualización de `.agents/skills/<herramienta>/SKILL.md`, perfiles `.agents/profiles/` y sondas de diagnóstico en `scripts/agent/fleet-doctor.sh`.

### T-193: Actualización asistida de Agent OS en proyectos satélite
- **Alternativas detectadas**: `git-subrepo`, `git-subtree`, sincronización manual bash.
- **Dictamen Scout**: Mantener la arquitectura sovereign $0 tokens basada en `scripts/agent/sync.sh` enriquecida con `--dry-run`, extracción determinista de novedades de `changelog.md` y generación del plan de impacto estructurado previo a la aprobación.

### T-194: Estandarización de Changelog, GitHub Releases y archivo `VERSION` universal
- **Alternativas detectadas**: `dropseed/changerelease` (29⭐ MIT), `favware/cliff-jumper` (57⭐ MIT), `conventional-changelog`.
- **Dictamen Scout**: Desarrollo determinista nativo en `scripts/agent/promote-to-main.sh` mediante `gh release create` y enlaces de comparación en `scripts/agent/update-changelog.sh`, más inyección canónica de `VERSION` para aplicaciones satélite (Next.js, Node, Python, Docker).

### T-195: Desbloqueo y rotación de credenciales (Cloudflare API Token / Infisical)
- **Alternativas detectadas**: `casonk/auto-pass` (2⭐), `pi-multi-auth` (13⭐).
- **Dictamen Scout**: Gestión nativa mediante `scripts/agent/secrets.sh` e Infisical CLI oficial con inyección efímera en memoria.
