# Executive Design Digest — T-209

## 🎯 Objetivo
Crear la nueva habilidad global `.agents/skills/web-compliance/SKILL.md` y sus plantillas declarativas en `.agents/skills/web-compliance/templates/`. Proporciona a los agentes un protocolo estandarizado para implementar en proyectos web satélite el consentimiento de cookies conforme a la AEPD/RGPD (mediante la librería abierta y sin dependencias `vanilla-cookieconsent` v3), el scaffolding de las páginas legales obligatorias (`/aviso-legal`, `/politica-privacidad`, `/politica-cookies`) y la inyección de cabeceras de endurecimiento HTTP en `next.config.*` (CSP, HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy).

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan para la tarea T-209 presenta una arquitectura limpia, desacoplada y orientada a estandarización mediante templates autónomos en .agents/skills/web-compliance/. El uso de 'vanilla-cookieconsent' v3 como estándar sin dependencias pesadas garantiza portabilidad, mientras que la separación en bloques (Cookies/RGPD, textos LSSI y cabeceras defensivas HTTP) respeta el principio SRP sin introducir acoplamientos ni dependencias no autorizadas en el core.
- **Prospección Scout**: `CONFORME (sprint-39-research.md)`
  - Scout OSS**: Evaluado `vanilla-cookieconsent` v3.3.0 y `@meetreeve/consent-kit`.
  - Veredicto**: `Integración OSS recomendada` de `vanilla-cookieconsent` v3 combinada con plantillas declarativas en `.agents/skills/web-compliance/`.
- **Mensaje de Cierre**: `docs(sprint): planificar sprint-39 (T-209 a T-213) web compliance y resiliencia multi-agente`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/config/skills-manifest.yaml`
- `.agents/context/skills-inventory.md`
- `.agents/skills/web-compliance/SKILL.md`
- `.agents/skills/web-compliance/templates/CookieBanner.tsx.template`
- `.agents/skills/web-compliance/templates/aviso-legal.tsx.template`
- `.agents/skills/web-compliance/templates/politica-cookies.tsx.template`
- `.agents/skills/web-compliance/templates/politica-privacidad.tsx.template`
- `.agents/skills/web-compliance/templates/security-headers.snippet.ts`
- `.agents/tasks/_archived/task-209.md`
- `.agents/tasks/task-210.md`
- `.agents/tasks/task-211.md`
- `.agents/tasks/task-212.md`
- `.agents/tasks/task-213.md`
- `docs/idea-inbox/_archived/2026-11-13-hermes-v0.23.1.md`
- `docs/idea-inbox/_archived/2026-11-13-infisical-v0.45.7.md`
- `docs/idea-inbox/_archived/2026-11-13-opencode-v2.3.0.md`
- `docs/idea-inbox/_archived/2026-11-13-orca-v1.4.258.md`
- `docs/sprints/sprint-39-research.md`
- `docs/sprints/sprint-39.md`
- `roadmap.md`

## 🧠 Skills Declaradas y Aplicadas
- Ninguna skill adicional registrada.
