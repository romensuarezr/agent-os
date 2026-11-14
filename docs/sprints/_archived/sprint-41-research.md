# Research Técnico — Sprint 41: Orquestación, Sincronización Bidireccional y Universalización de Despliegues

> Sprint: Sprint 41  
> Fecha: 2026-11-14  
> Motor de búsqueda: SearXNG Soberano (`<nodo-inferencia>`)  
> Coste de inferencia en prospección: $0 tokens  

---

## Descubrimientos Scout (por tarea)

### T-219: Integración Automática de Reporte de Orquestación en close-sprint.sh y session-close.md
- **Alternativas evaluadas**:
  - Scripts externos / frameworks de observabilidad pesados (ej. Langfuse, LangSmith).
- **Decisión**: Desarrollo a medida justificado.
- **Justificación**: Agent OS ya cuenta con `scripts/agent/orchestration-report.sh` (11KB), que agrega ejecuciones, calcula floor cost savings (~75k tokens por sprint), playbooks ejecutados y desglose por worker. Solo se requiere cablearlo deterministamente en el gancho de cierre de `close-sprint.sh` y en `.agents/workflows/session-close.md`.
- **Constraint clave**: $0 tokens, puramente determinista y ejecutable sin dañar el working tree limpio.

### T-220: Absorción de orca-cli (v1.4.258), actualización de infisical-secrets (v0.45.8) y fix de staging acotado en contribute.sh
- **Alternativas evaluadas**:
  - Re-implementación desde cero de la skill orca.
- **Decisión**: Adopción de la skill probada en satélite (`romensuarez-web` T-050) y desarrollo a medida para el fix de staging.
- **Justificación**: El satélite `romensuarez-web` ya homologó y testeó `orca-cli` evitando la colisión de PATH con `/usr/bin/orca` (screen reader de GNOME), resolviendo alias `~/.local/bin/orca-agent` y subcomandos `worktree`, `task`, `browser`. En `contribute.sh`, la línea 73 ejecutaba `git add .` indiscriminado, lo que rompía la compuerta de higiene si había archivos untracked; debe acotarse estrictamente a `git add "$DEST_DIR/$FILE_NAME"`.
- **Constraint clave**: Cero literales de host o rutas de usuario; compatibilidad con el control plane.

### T-221: Auditoría Bidireccional de Drift Core ↔ Satélites (audit-satellites.sh --skills)
- **Alternativas evaluadas**:
  - Herramientas de diffing complejas (git submodules, monorepo tooling).
- **Decisión**: Desarrollo a medida justificado en bash.
- **Justificación**: `audit-satellites.sh` ya audita scripts ejecutables en satélites. Añadir el flag `--skills` permite comparar `.agents/skills/` del core contra cada satélite configurado en `.agents/config/satellites.yaml`. Si un satélite crea o modifica una skill sin pasarla por `contribute.sh`, la auditoría lo señala explícitamente con semáforo y sugerencia de contribución.
- **Constraint clave**: Solo lectura (read-only), salida JSON estructurada y compatible con `fleet-doctor.sh`.

### T-222: Sincronización y Propagación de Herramientas Ops (scripts/ops/coolify.sh) en sync.sh
- **Alternativas evaluadas**:
  - Crear un repositorio separado para scripts de infraestructura.
- **Decisión**: Desarrollo a medida justificado integrando `scripts/ops/` en `sync.sh`.
- **Justificación**: `scripts/ops/coolify.sh` existe en el core (10.2 KB) pero los satélites (`leaderboard-platform`, `annascheer-web`) no lo recibían porque `sync.sh` solo copiaba `scripts/agent/`. Incluir la sincronización de `scripts/ops/` (respetando modo idempotente, flags `--dry-run` y `--cleanup`) resuelve la incoherencia detectada en la auditoría de Leaderboard.
- **Constraint clave**: Idempotencia, preservación de permisos de ejecución `chmod +x` y modo no-destructivo por defecto.

### T-223: Universalización y Recipe Determinista de Despliegue Coolify para Next.js (soporte monorepo + flat)
- **Alternativas evaluadas**:
  - Nixpacks nativo de Coolify (falla en monorepos complejos pnpm con dependencias de workspace como `@leaderboard/core`).
  - Dockerfile manual por cada proyecto satélite sin estándar.
- **Decisión**: Patrón estándar Next.js 15 Standalone Dockerfile Multi-Stage con Corepack + Pnpm.
- **Justificación**: Prospección en la comunidad oficial de Coolify y documentación de Next.js 15 valida que `output: 'standalone'` en Alpine multi-stage reduce el peso entre un 60% y un 80%, y resuelve de forma determinista tanto aplicaciones planas (ej. `annascheer-web`) como monorepos pnpm (ej. `leaderboard-platform`) mediante `turbo prune` o copias acotadas de workspaces. Se creará una recipe documentada y plantillas en `.agents/skills/coolify-nextjs-deploy/` y `docs/runbooks/coolify-nextjs-deploy.md`.
- **Constraint clave**: Compatibilidad con Coolify API / Webhooks y Cloudflare DNS sin acoplamiento a un satélite concreto.

---

## Síntesis de Búsqueda Soberana SearXNG

- **Consulta ejecutada**: `nextjs 15 standalone dockerfile pnpm coolify`
- **Hallazgos técnicos destacados**:
  1. Para monorepos pnpm, el runner debe recibir únicamente los artefactos generados en `.next/standalone` y `.next/static`, con ownership del usuario `nextjs:nodejs` (UID/GID 1001) para máxima seguridad (non-root).
  2. Variables de entorno obligatorias en runner: `ENV PORT=3000`, `ENV HOSTNAME="0.0.0.0"`, `ENV NODE_ENV=production`.
  3. Soporte dual: detección automática en el script de auditoría (`audit-next.sh`) de estructura monorepo (`pnpm-workspace.yaml` / `turbo.json`) vs estructura plana (`package.json` en raíz).
