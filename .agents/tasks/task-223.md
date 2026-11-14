# T-223 — Universalización y Recipe Determinista de Despliegue Coolify para Next.js (soporte monorepo + flat)
Sprint: Sprint 41 | Estado: ⬜ Pendiente | Tamaño: M | Rama propuesta: feat/T-223-coolify-nextjs-universal-deploy | Merge destino: multi-agent

## Diseño macro aprobado en planning
- **Sprint / Fecha**: Sprint 41 — 2026-11-14
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Universalizar `.agents/skills/coolify-nextjs-deploy/`:
    1. Actualizar `audit-next.sh` para detectar dinámicamente el gestor de paquetes (`npm`, `pnpm`, `yarn`, `bun`) y la tipología de repositorio (plano vs monorepo `apps/web`).
    2. Proveer dos plantillas estándar de Dockerfile:
       - `Dockerfile.flat.template`: para Next.js plano (ej. `annascheer-web`) con detección agnóstica de lockfile (`pnpm-lock.yaml` / `package-lock.json`).
       - `Dockerfile.monorepo.template`: para monorepos pnpm (ej. `leaderboard-platform` con `apps/web` y packages internos).
    3. Eliminar variables hardcodeadas de proyectos anteriores (como `NEXT_PUBLIC_WHATSAPP_NUMBER`) sustituyéndolas por bloque configurable de Build Args.
    4. Integrar la invocación determinista de `scripts/ops/coolify.sh` (subcomandos `deploy`, `get`, `list`) disponible tras T-222.
    5. Crear el runbook canónico `docs/runbooks/coolify-nextjs-deploy.md` con la recipe paso a paso utilizable por cualquier agente satélite.
- **Veredicto de diseño macro**: [APROBADO_EN_PLANNING]

---

## 1. Objetivo
Proporcionar una guía y utilidades deterministas para que cualquier agente satélite pueda auditar, preparar, dockerizar y desplegar aplicaciones Next.js 14/15 en Coolify de forma autónoma y sin errores, tanto en proyectos planos como en monorepos pnpm.

## 2. Contexto técnico
- Skill actual: `.agents/skills/coolify-nextjs-deploy/`.
- Auditoría previa: Informe de `leaderboard-platform` identificando falta de soporte monorepo pnpm y referencias rotas a scripts de ops.
- Sondas y utilidades: `audit-next.sh`, `cloudflare-dns.sh`, `scripts/ops/coolify.sh`.
- Runbook objetivo: `docs/runbooks/coolify-nextjs-deploy.md`.

## 3. Caja de archivos
- `.agents/tasks/task-223.md`
- `.agents/skills/coolify-nextjs-deploy/SKILL.md`
- `.agents/skills/coolify-nextjs-deploy/scripts/audit-next.sh`
- `.agents/skills/coolify-nextjs-deploy/templates/Dockerfile.flat.template`
- `.agents/skills/coolify-nextjs-deploy/templates/Dockerfile.monorepo.template`
- `.agents/skills/coolify-nextjs-deploy/templates/Dockerfile.template`
- `docs/runbooks/coolify-nextjs-deploy.md`
- `docs/sprints/sprint-41.md`

## 4. Plan de implementación
1. Refactorizar `audit-next.sh` para diagnosticar gestor de paquetes (`pnpm`, `npm`), tipo de estructura (`flat` vs `monorepo`), y coherencia de `output: 'standalone'`.
2. Actualizar `Dockerfile.template` y crear `Dockerfile.flat.template` con soporte `corepack enable pnpm` y multi-stage Alpine seguro non-root.
3. Crear `Dockerfile.monorepo.template` con soporte para pnpm workspaces aislando `apps/web`.
4. Escribir `docs/runbooks/coolify-nextjs-deploy.md` con el flujo operativo determinista (auditoría pre-build, dockerización, variables públicas vs runtime, DNS Cloudflare y despliegue Coolify vía API/webhook).
5. Actualizar `.agents/skills/coolify-nextjs-deploy/SKILL.md` documentando la nueva recipe universal.
6. Validar compatibilidad de scripts en el control plane.

## 5. Criterios de aceptación
- `audit-next.sh` detecta correctamente `annascheer-web` como plano y `leaderboard-platform` como monorepo pnpm.
- Las plantillas Dockerfile son válidas y libres de variables específicas de proyectos pasados.
- El runbook `docs/runbooks/coolify-nextjs-deploy.md` es completo, agnóstico y referenciado en la skill.
- `tests/validate-control-plane.sh` permanece 100% verde.
