# Task-210: Script determinista audit-web-compliance.sh ($0 tokens) y manifiesto de activos

## Objetivo
Desarrollar la herramienta de auditoría determinista `scripts/agent/audit-web-compliance.sh` a coste $0 tokens de inferencia. El script inspecciona estáticamente un repositorio satélite web (Next.js, React, HTML) para verificar la conformidad con los estándares de cumplimiento legal, cookies y seguridad, reportando hallazgos estructurados en terminal o formato `--json`. Actualizar `scripts/agent/assets-manifest.txt` y `scripts/agent/audit-satellites.sh` para incorporar la nueva skill y script al catálogo de activos distribuidos.

## Contexto técnico
- Para evitar que los satélites se publiquen sin los requisitos legales o con cabeceras inseguras, los agentes y el operador necesitan una compuerta estática rápida ($0 tokens) que verifique la presencia de consentimientos, rutas legales y cabeceras de seguridad.
- La herramienta debe detectar de forma heurística la inclusión de scripts de terceros (Calendly, Google Analytics, Tag Manager, Hotjar, Facebook Pixel) y alertar si no existe un banner de consentimiento configurado.

### Research integrado (`docs/sprints/sprint-39-research.md` → `### T-210`)
- **Scout OSS**: Auditoría estática determinista sin dependencias de red.
- **Veredicto**: `Desarrollo a medida justificado` dentro de `scripts/agent/`.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 39 / 2026-11-13
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - Crear `scripts/agent/audit-web-compliance.sh` con soporte para:
    - Verificación de banner de cookies (`CookieConsent`, `vanilla-cookieconsent` o similar).
    - Verificación de rutas legales (`/aviso-legal`, `/politica-privacidad`, `/politica-cookies`).
    - Verificación de cabeceras de seguridad en `next.config.*` (CSP, HSTS, X-Frame-Options, X-Content-Type-Options).
    - Verificación de higiene SEO (`robots.*`, `sitemap.*`).
    - Flags CLI: `--path <dir>`, `--json`, `-h/--help`.
  - Registrar activos en `scripts/agent/assets-manifest.txt` para distribución en `sync.sh`.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/audit-web-compliance.sh` (nuevo)
- `scripts/agent/assets-manifest.txt`
- `scripts/agent/audit-satellites.sh`
- `docs/sprints/sprint-39.md`
- `.agents/tasks/task-210.md`

## Criterios de done
- [x] Script `audit-web-compliance.sh` ejecutable (0755), determinista y con soporte `--json`.
- [x] Detección precisa de scripts externos, páginas legales y cabeceras.
- [x] `assets-manifest.txt` y `audit-satellites.sh` actualizados con los nuevos activos.
- [x] Suite `tests/validate-control-plane.sh` pasando limpia sin regresiones (38/38 checks verdes).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
- [x] Plan presentado al usuario (Fase 3.5)
- [x] Rama de trabajo creada
- [x] Verificación con verify-goal.sh
- [x] Cierre y merge formalizado
