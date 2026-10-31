# Captura de Ideas de Vídeos — Ecosistema Agéntico y Flujos Autónomos

- **Fecha:** 2026-10-29
- **Origen:** Monitoreo y captura continua de conceptos, técnicas y patrones arquitectónicos presentados en vídeos técnicos sobre agentes autónomos, gobernanza y tooling.
- **Estado:** REGISTRADA NO APROBADA (evaluada y triada en el planning del Sprint 22).
- **Tipo:** Catálogo de Ideas y Capacidades Externas para Evaluación.

---

## 1. Inventario de Ideas Capturadas

### 1. `natural-communication`
- **Concepto:** Guías y directivas para comunicación más fluida, natural y directa entre agente y operador, reduciendo la rigidez sintética o el exceso de ceremonial robótico sin sacrificar concisión ni rigor técnico.
- **Ámbito:** Perfiles y reglas de interacción (`.agents/rules/`).

### 2. `fact-check`
- **Concepto:** Mecanismo o fase de verificación de hechos, métricas o aserciones técnicas contra fuentes primarias locales o contrastadas antes de emitir informes o dar por válidas asunciones.
- **Ámbito:** Skills de verificación / workflows de testing y documentación.

### 3. `self-healing pre-flight`
- **Concepto:** Diagnósticos previos a la ejecución (pre-flights) que, ante fallos determinables y acotados (ej. ficheros de lock residuales, directorios temporales ausentes o permisos no ejecutables), aplican auto-reparación segura sin abortar de inmediato.
- **Ámbito:** Scripts de verificación previa (`scripts/agent/check-*.sh`).

### 4. `cascada de inferencia en routing-policy`
- **Concepto:** Enrutamiento jerárquico de inferencia con tolerancia a fallos: definir una lista ordenada de pasarelas/endpoints alternativos en la configuración de políticas de inferencia, de modo que si el tier primario no responde en ventana acotada, se escale automáticamente al siguiente antes de degradar a modo offline.
- **Ámbito:** `.agents/config/routing-policy.yaml` y `scripts/agent/deliberate-plan.sh`.

### 5. `idea-validator`
- **Concepto:** Workflow o rol de arbitraje para contrastar deterministamente la factibilidad, el solapamiento con código existente y el coste operativo de ideas nuevas antes de incorporarlas al backlog.
- **Ámbito:** Workflows de ideación y evaluación de producto.

### 6. `sprint-planning v2 condicionadas a Bane`
- **Concepto:** Evolución del workflow de planificación de sprints integrando consultas de razonamiento profundo desatendidas contra el motor local de búsqueda Bane (`docs/external-inbox/2026-10-27-bane-deep-research-in-sprint-planning.md`), condicionada al despliegue efectivo del servicio.
- **Ámbito:** `.agents/workflows/sprint-planning.md`.

### 7. `plantilla Nango opcional de satélite`
- **Concepto:** Plantilla Docker Compose y configuración pre-empaquetada para desplegar Nango (gestor de autenticaciones y sincronizaciones OAuth de terceros) en proyectos satélite que requieran integraciones SaaS.
- **Ámbito:** `templates/satellites/` (proyectos hijo / satélites).

### 8. `clean-room-contracts derivada a REA`
- **Concepto:** Metodología de contratos limpios (clean room) para ingeniería inversa, aislamiento estricto de especificaciones y desacoplamiento de código propietario.
- **Ámbito:** Proyecto satélite independiente REA (Reverse Engineering Automation / MCP analysis).

### 9. `frontend-critic`
- **Concepto:** Rol o perfil evaluador enfocado en criticar constructivamente componentes visuales, consistencia tipográfica, contraste, jerarquía y accesibilidad web.
- **Ámbito:** Perfil satélite para aplicaciones cliente con frontend.

### 10. `web-privacy-noindex`
- **Concepto:** Reglas universales y plantillas de cabeceras/meta-tags (`X-Robots-Tag: noindex, nofollow`, `robots.txt`) para asegurar que despliegues internos de herramientas y portales de flotas no sean indexados públicamente por buscadores.
- **Ámbito:** Plantillas de infraestructura y reglas web en satélites.

---

## 2. Evaluación y Triaje en Sprint 22

Durante la sesión de planificación del Sprint 22 ([`docs/sprints/sprint-22-core.md`](../sprints/sprint-22-core.md)), se realizó el triaje formal de este bloque:
1. **Adopción Inmediata en Core (Sprint 22):**
   - `cascada de inferencia en routing-policy` → Aceptada como **T-130** ([`task-130.md`](../../.agents/tasks/task-130.md)) para mitigar fallos transitorios de pasarela sin dependencias externas.
2. **Diferidas al Backlog del Core:**
   - `natural-communication` y `fact-check`: Cubiertas operativamente por las directivas actuales de concisión y rigor; diferidas a futuras revisiones de reglas.
   - `self-healing pre-flight`: Requiere análisis de seguridad para evitar reparaciones automáticas no deseadas; diferida a backlog.
   - `idea-validator`: Diferida a espera de unificación con el flujo de deliberación.
3. **Condicionadas a Infraestructura:**
   - `sprint-planning v2 condicionadas a Bane`: Congelada hasta validación y despliegue del servicio Bane en Coolify.
4. **Derivadas / Fuera del Core:**
   - `clean-room-contracts`: Derivada al proyecto independiente REA.
   - `plantilla Nango opcional`, `frontend-critic`, `web-privacy-noindex`: Ámbito específico de proyectos satélite o aplicaciones UI, fuera del repositorio central `agent-os`.
