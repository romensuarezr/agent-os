# Executive Design Digest — T-210

## 🎯 Objetivo
Desarrollar la herramienta de auditoría determinista `scripts/agent/audit-web-compliance.sh` a coste $0 tokens de inferencia. El script inspecciona estáticamente un repositorio satélite web (Next.js, React, HTML) para verificar la conformidad con los estándares de cumplimiento legal, cookies y seguridad, reportando hallazgos estructurados en terminal o formato `--json`. Actualizar `scripts/agent/assets-manifest.txt` y `scripts/agent/audit-satellites.sh` para incorporar la nueva skill y script al catálogo de activos distribuidos.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan para T-210 se alinea rigurosamente con los principios de diseño de Agent OS: coste $0 tokens, portabilidad Bash (`set -euo pipefail`), soporte canónico de flags (`--path`, `--json`, `--help`) y ausencia de dependencias de red o exploits activos. La modularización estática (CMP/Cookies, rutas legales LSSI/RGPD, cabeceras HTTP y SEO hygiene) sigue la convención desacoplada de los scripts en `scripts/agent/`.

La delimitación de archivos es estricta y controlada, registrando el script y la skill `web-compliance` en `scripts/agent/assets-manifest.txt`, manteniendo la integridad de satélites mediante `audit-satellites.sh`, y cerrando con la validación de control plane preexistente.
- **Prospección Scout**: `CONFORME (sprint-39-research.md)`
  - Scout OSS**: Búsqueda de scripts estáticos de auditoría de consentimiento web.
  - Veredicto**: `Desarrollo a medida justificado` dentro de `scripts/agent/audit-web-compliance.sh` analizando estáticamente scripts externos, rutas legales y cabeceras.
- **Mensaje de Cierre**: `merge(task): integrar T-209 skill web-compliance en multi-agent`

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
- `.agents/tasks/_archived/task-210.md`
- `docs/sprints/design-decisions/T-209-digest.md`
- `docs/sprints/design-decisions/T-209-raw.json`
- `docs/sprints/sprint-39.md`
- `scripts/agent/assets-manifest.txt`
- `scripts/agent/audit-satellites.sh`
- `scripts/agent/audit-web-compliance.sh`

## 🧠 Skills Declaradas y Aplicadas
- Ninguna skill adicional registrada.
