# Task-076: Instalación selectiva de skills por stack

## Objetivo
`install.sh` deja de copiar a ciegas el 100% de `.agents/skills/`: manifiesto con etiquetas por skill y modos `--minimal` / `--full`; `--check` informa qué se instalaría y por qué.

## Contexto técnico
Auditoría 2026-09-28: `install.sh` y `sync.sh` copian todas las skills sin filtro — `coolify-nextjs-deploy`, `infisical-secrets`, plantillas freellmapi, etc. se instalan igual en un proyecto Java que en uno Next.js. Viola el principio #4 de AGENTS.md ("Global pequeño, local fino": lo específico vive en el proyecto hijo). Depende de T-074: con el stack detectado, el instalador puede sugerir las skills relevantes.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/install.sh` (flags `--minimal`/`--full`; coordinar con T-069)
- `scripts/agent/sync.sh` (respeta las etiquetas al sincronizar)
- `.agents/skills/skills-manifest.yaml` (nuevo — etiquetas por skill) o frontmatter en cada `SKILL.md`
- `README.md` (documentar los modos)

## Criterios de done
- [x] Manifiesto con etiquetas por skill: `scope: universal | stack | infra` y, cuando aplique, `stack: [nextjs, …]`, `infra: [coolify, …]`, `optional: true`.
- [x] `--minimal` instala solo skills `universal`; `--full` instala todo con aviso explícito de lo específico que incluye.
- [x] Sin flags, el instalador usa `detect-stack.sh` (T-074) y propone el conjunto recomendado, pidiendo confirmación (no instala a ciegas).
- [x] `--check` lista qué skills se instalarían, con su etiqueta y motivo.
- [x] `sync.sh` no reintroduce en el hijo skills que el proyecto descartó deliberadamente.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-28T17:34:59+01:00
- [x] Rama creada: feat/T-076-selective-skills-install
- [x] Lock activo: .agent-session.lock
- [ ] Sesión cerrada correctamente
