# Task-209: Skill web-compliance: protocolo de cookies (vanilla-cookieconsent v3), legal y seguridad

## Objetivo
Crear la nueva habilidad global `.agents/skills/web-compliance/SKILL.md` y sus plantillas declarativas en `.agents/skills/web-compliance/templates/`. Proporciona a los agentes un protocolo estandarizado para implementar en proyectos web satélite el consentimiento de cookies conforme a la AEPD/RGPD (mediante la librería abierta y sin dependencias `vanilla-cookieconsent` v3), el scaffolding de las páginas legales obligatorias (`/aviso-legal`, `/politica-privacidad`, `/politica-cookies`) y la inyección de cabeceras de endurecimiento HTTP en `next.config.*` (CSP, HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy).

## Contexto técnico
- En proyectos satélite como `annascheer-web`, la integración de servicios de terceros (ej. Calendly en T-013, analítica o píxeles) introduce cookies y scripts externos en producción.
- Sin un CMP (*Consent Management Platform*) con botones simétricos de aceptación y rechazo, la web incurre en infracción de la normativa europea y española (AEPD / LSSI-CE).
- `vanilla-cookieconsent` v3.3.0 es una solución open-source MIT sin suscripciones recurrentes ni sobrecarga de runtime (~5 KB gzipped), compatible con Next.js App Router (`'use client'`).

### Research integrado (`docs/sprints/sprint-39-research.md` → `### T-209`)
- **Scout OSS**: Evaluado `vanilla-cookieconsent` v3.3.0.
- **Veredicto**: `Integración OSS recomendada` con plantillas declarativas en Agent OS.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 39 / 2026-11-13
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - Crear `.agents/skills/web-compliance/SKILL.md` estructurada con las 3 dimensiones: 1) Cookies & Consentimiento, 2) Páginas Legales, 3) Cabeceras de Seguridad.
  - Suministrar plantillas declarativas listas para usar en `.agents/skills/web-compliance/templates/`:
    - `CookieBanner.tsx.template`: componente React Client con `vanilla-cookieconsent`, soporte multi-idioma (es/en) y autoClear.
    - `aviso-legal.tsx.template`: página accesible con campos fiscales estándar LSSI-CE.
    - `politica-privacidad.tsx.template`: página conforme a RGPD con fines, base jurídica y derechos ARCO.
    - `politica-cookies.tsx.template`: tabla explicativa de cookies y mecanismo de revocación.
    - `security-headers.snippet.ts`: snippet listo para fusionar en `headers()` de `next.config.*`.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/skills/web-compliance/SKILL.md` (nuevo)
- `.agents/skills/web-compliance/templates/CookieBanner.tsx.template` (nuevo)
- `.agents/skills/web-compliance/templates/aviso-legal.tsx.template` (nuevo)
- `.agents/skills/web-compliance/templates/politica-privacidad.tsx.template` (nuevo)
- `.agents/skills/web-compliance/templates/politica-cookies.tsx.template` (nuevo)
- `.agents/skills/web-compliance/templates/security-headers.snippet.ts` (nuevo)
- `.agents/config/skills-manifest.yaml`
- `.agents/context/skills-inventory.md`
- `docs/sprints/sprint-39.md`
- `.agents/tasks/task-209.md`

## Criterios de done
- [x] Skill `web-compliance/SKILL.md` creada con guía metodológica y técnica completa.
- [x] 5 plantillas declarativas creadas en `templates/`.
- [x] Integración de `vanilla-cookieconsent` v3 documentada con patrón App Router.
- [x] Suite `tests/validate-control-plane.sh` pasando limpia sin regresiones (38/38 checks verdes).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
- [x] Plan presentado al usuario (Fase 3.5)
- [x] Rama de trabajo creada
- [x] Verificación con verify-goal.sh
- [x] Cierre y merge formalizado
