# Sprint 39 Research — Web Compliance, Seguridad de Cabeceras y Resiliencia Multi-Agente (Heartbeat & Fast Build)

## 1. Estado de la Investigación
- **Fecha**: 2026-11-13
- **Gate Scout-First**: Verificado a $0 tokens (`scout.sh "vanilla-cookieconsent"`).
- **Prospección OSS**: Detectado paquete `vanilla-cookieconsent` v3.3.0 (MIT, 0 dependencias, soporte completo GDPR/AEPD/ePrivacy con botones simétricos Aceptar/Rechazar y autoClear).
- **Inspección de entorno en vivo**:
  - Satélite real `annascheer-web`: Sprint 03 completado (Homepage, Calendly y Schema.org integrados). Calendly inyecta scripts y cookies de terceros sin banner de consentimiento ni páginas de privacidad/cookies obligatorias.
  - Orquestación multi-agente: Tiempo de ejecución de 3 agentes concurrentes >30 min debido a compilación estática de 34 rutas Next.js 15 en cada worktree aislado y silencio de radio sin latidos de progreso (*Black Box Anxiety*).

---

## 2. Hallazgos y Decisiones de Arquitectura

### A. Gestión Web y Cumplimiento Legal (AEPD / RGPD / LSSI-CE)
1. **El Banner de Consentimiento**:
   - Evitar soluciones SaaS privativas de suscripción recurrente (15–40 €/mes por dominio como Cookiebot o Axeptio).
   - Adoptar `vanilla-cookieconsent` v3.3.0: autosuficiente, sin dependencias, compatible con Next.js App Router (`'use client'`), estéticamente adaptable a Tailwind mediante variables CSS, y cumplidor estricto del criterio AEPD 2024 (mismo peso y visibilidad para «Rechazar todas» que para «Aceptar todas»).
2. **Scaffolding de Páginas Legales**:
   - `/aviso-legal`: Exigido por LSSI-CE (titularidad, CIF/NIF, domicilio, contacto).
   - `/politica-privacidad`: Exigido por RGPD (fines de tratamiento, base jurídica, derechos ARCO, encargado de tratamiento).
   - `/politica-cookies`: Exigido por ePrivacy/LSSI-CE (tabla de cookies técnicas vs analíticas, duración y revocar consentimiento).
3. **Endurecimiento de Cabeceras HTTP (Security Headers)**:
   - Configuración determinista en `next.config.*` con CSP, HSTS, X-Frame-Options (SAMEORIGIN), X-Content-Type-Options (nosniff) y Referrer-Policy para calificación A+ en auditorías de seguridad web.

### B. Optimización del Bucle Multi-Agente: Latidos y Desacoplamiento de Build
1. **Heartbeat Proactivo contra la Ansiedad de la Caja Negra**:
   - El Coordinador debe emitir breves actualizaciones de progreso cada 3–5 minutos si un lote concurrente está en marcha, eliminando la incertidumbre del operador humano.
2. **Build Desacoplado (Fast Verification en Worker vs Full Build en Merge)**:
   - En el worktree del worker, la compuerta de `verify-goal.sh` debe priorizar verificación estricta pero rápida (`tsc --noEmit` + `test`, ~10-15s).
   - El `next build` exhaustivo de prerenderizado estático masivo (30+ rutas) se delega a la compuerta final del Coordinador al integrar en `main`, reduciendo el tiempo de ejecución en paralelo de 30 min a menos de 8 min.

---

## 3. Descubrimientos Scout (por tarea)

### T-209: Skill `web-compliance` (Cookies, Scaffolding Legal y Cabeceras de Seguridad)
- **Scout OSS**: Evaluado `vanilla-cookieconsent` v3.3.0 y `@meetreeve/consent-kit`.
- **Veredicto**: `Integración OSS recomendada` de `vanilla-cookieconsent` v3 combinada con plantillas declarativas en `.agents/skills/web-compliance/`.

### T-210: Script determinista `audit-web-compliance.sh` ($0 tokens) y manifiesto de activos
- **Scout OSS**: Búsqueda de scripts estáticos de auditoría de consentimiento web.
- **Veredicto**: `Desarrollo a medida justificado` dentro de `scripts/agent/audit-web-compliance.sh` analizando estáticamente scripts externos, rutas legales y cabeceras.

### T-211: Heartbeat Proactivo & Telemetría de Latidos en Orquestación Multi-Agente
- **Scout OSS**: Modelos de heartbeat en orquestadores concurrentes.
- **Veredicto**: `Desarrollo a medida justificado` en `coordinator.md`, `coordinator-boot.md` y `orchestration-playbooks.yaml`.

### T-212: Desacoplamiento de Build en Worktrees (Fast Verification vs Full Static Merge)
- **Scout OSS**: Prácticas de CI/CD para monorrepos y ramas efímeras.
- **Veredicto**: `Desarrollo a medida justificado` en `verify-goal.sh` y directivas del Coder.

### T-213: Ensayo E2E y despliegue real en satélite `annascheer-web` (Sprint 04 Piloto)
- **Scout OSS**: N/A (validación sobre satélite real de la flota).
- **Veredicto**: `Aprovechar utilidades del core` para desplegar la skill y remediar la falta de cookies y legal en `annascheer-web`.
