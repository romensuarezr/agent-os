# Research Sprint 33

> Fuente: Prospección determinista OSS (scout.sh), meta-búsqueda soberana (SearXNG), diagnóstico del repositorio (2026-11-10) y contratos de gobernanza de Agent OS.
> Fecha: 2026-11-10
> Siguiente sprint: Sprint 33
> Régimen de ejecución: Opción D (Autonomía acotada por defecto)

---

## Descubrimientos Scout (por tarea)

### T-183 — Estandarización de variables, endpoints y pre-flights en coolify.sh y coolify-admin
- **Alternativa detectada:** Repositorio oficial `coollabsio/coolify-cli` (497★ | MIT), paquetes npm `coolify-axi` y wrapper actual `scripts/ops/coolify.sh`.
- **Recomendación del agente:** Mantener el script wrapper bash determinista propio (`scripts/ops/coolify.sh`) a coste $0 de tokens sin introducir dependencias binarias pesadas externas. Estandarizar la resolución de endpoints con fallback dinámico a `fleet.yaml` (nodo de orquestación / PaaS) y variables de entorno (`COOLIFY_BASE_URL` / `COOLIFY_TOKEN`), integrar `scripts/agent/lib/cli-help.sh` y pre-flights conformes a la frontera portable.
- **Dictamen del Operador:** [Pendiente de ratificación en planning].
- **Notas de integración:**
  1. Integrar `scripts/agent/lib/cli-help.sh` con flag `-h` / `--help` estándar.
  2. Sustituir fallback hardcodeado `https://coolify.example.com/api/v1` por detección dinámica desde `.agents/config/fleet.yaml` o variable ambiental.
  3. Actualizar la especificación en `.agents/skills/coolify-admin/SKILL.md` para reflejar la precedencia de configuración.
- **Alternativas rechazadas y motivos:**
  - Instalar `coollabsio/coolify-cli`: Rechazado; binario Go compilado pesado cuando un wrapper `curl` determinista de 150 líneas resuelve el 100% de operaciones con soporte nativo para Infisical.

### T-184 — Auditoría determinista de integridad y salud de scripts en satélites (audit-satellites.sh)
- **Alternativa detectada:** Herramientas genéricas como `audit-ci`, `codeowners-audit` o utilidades git.
- **Recomendación del agente:** Desarrollo a medida 100% justificado en Bash determinista. Las herramientas del ecosistema no comprenden la arquitectura de Agent OS (`.agents/`, contratos, scripts globales sincronizados vía `sync.sh` ni ledgers `last-sync.md`). Crear `scripts/agent/audit-satellites.sh` que inspeccione los satélites declarados en `.agents/config/satellites.yaml` (o argumentos CLI), valide hashes de scripts del core vs satélite, compruebe permisos de ejecución y detecte desvíos locales sin tocar git y sin red.
- **Dictamen del Operador:** [Pendiente de ratificación en planning].
- **Notas de integración:**
  1. Diseñar `scripts/agent/audit-satellites.sh` con soporte `--satellites <yaml>`, `--check`, `--json` y `--fix` (o `--sync`).
  2. Asegurar idempotencia, lectura pasiva y reporte legible compacto a $0 tokens.
  3. Añadir check determinista en `tests/validate-control-plane.sh`.
- **Alternativas rechazadas y motivos:**
  - Depender de `fleet-version.sh` exclusivamente: `fleet-version.sh` solo lee cadenas semver en `last-sync.md`, no detecta scripts corruptos, modificados o con permisos revocados.

### T-185 — Refinamiento y paridad de session-close.md con régimen Opción D
- **Alternativa detectada:** Flujo actual `.agents/workflows/session-close.md` (última revisión 2026-10-27) previo a la consolidación de Opción D (T-157/T-164) y el flujo inteligente de arranque (T-177).
- **Recomendación del agente:** Actualizar `.agents/workflows/session-close.md` para reflejar con exactitud la gobernanza moderna:
  1. Cierre y archivado atómico con `close-task.sh`.
  2. Verificación del relé (`validate-control-plane.sh`) como guardián post-cierre con escalado fail-closed a humano si falla.
  3. Handoff y encadenamiento autónomo a la siguiente tarea en el carril sin reabrir sesión humana cuando hay consenso limpio.
  4. Sincronización automática de `last-sync.md`.
- **Dictamen del Operador:** [Pendiente de ratificación en planning].
- **Notas de integración:**
  1. Modificar `.agents/workflows/session-close.md` armonizándolo con `session-start.md` y `AGENTS.md`.
  2. Documentar el contrato de transición entre tareas de un carril bajo Opción D.
- **Alternativas rechazadas y motivos:**
  - Mantener workflow legado: Descartado; genera discrepancias entre lo que instruye el workflow de inicio y lo que asume el de cierre.

### T-186 — Cobertura de control plane y hardening de rotate-freellmapi-token.sh
- **Alternativa detectada:** Script local `scripts/agent/lib/rotate-freellmapi-token.sh` creado en T-182 para resolver el incidente de autenticación 401 en Hermes y OpenCode.
- **Recomendación del agente:** Integrar la validación sintáctica, de permisos y de ayuda estándar de `rotate-freellmapi-token.sh` dentro de `tests/validate-control-plane.sh` (ej. en Check 9 o Check 13), asegurando que el script use `lib/cli-help.sh` y mantenga invariante su ejecución segura sin credenciales en argv ni stdout.
- **Dictamen del Operador:** [Pendiente de ratificación en planning].
- **Notas de integración:**
  1. Refactorizar la función de ayuda en `scripts/agent/lib/rotate-freellmapi-token.sh` para usar `lib/cli-help.sh`.
  2. Incorporar test determinista en `tests/validate-control-plane.sh` (validar sintaxis bash, permisos 0755, flags `--help`, `--check` con fallback offline limpio).
  3. Mantener denominador de suite inmutable en 38/38.
- **Alternativas rechazadas y motivos:**
  - Dejar el script sin cobertura de test: Viola la Definition of Done del core (todo script CLI del repositorio debe estar protegido contra regresiones).

### T-187 — Skill ui-critique para auditoría y revisión de interfaces UI en satélites
- **Alternativa detectada:** Repositorios OSS `rgranet/designlint-skill` (1★ | MIT) y `ShadowFull12/overhaul-ui` (craft skill de auditoría UX/UI), junto con ítem del roadmap ("Impeccable critique: protocolo de auditoría y revisión de interfaces UI para satélites").
- **Recomendación del agente:** Formalizar la skill canónica `.agents/skills/ui-critique/SKILL.md` (en español) adaptando los mejores principios de auditoría de interfaces frontend (jerarquía visual, contraste y accesibilidad WCAG, consistencia de espaciado, uso DRY de componentes UI y responsiveness) enfocada a proyectos satélites (React/Tailwind/Next.js).
- **Dictamen del Operador:** [Pendiente de ratificación en planning].
- **Notas de integración:**
  1. Redactar `.agents/skills/ui-critique/SKILL.md` siguiendo la plantilla estándar de skills.
  2. Incluir checklist de auditoría visual determinista previa a merges en proyectos frontend.
  3. Registrar en `.agents/config/skills-manifest.yaml` y verificar en Check 1 y Check 5 de `validate-control-plane.sh`.
- **Alternativas rechazadas y motivos:**
  - Depender de librerías npm de linting visual en tiempo de ejecución: Excesivamente intrusivo en el build pipeline; la skill actúa como guía de auditoría para el agente sin forzar dependencias npm adicionales.

### T-188 — Endurecimiento del flujo desatendido
- **Alternativa detectada:**
  1. Fuga de procesos huérfanos de `agy --conversation` detectada en producción durante timeouts de `deliberate-plan.sh` (ej. PID 814302, 38+ min activos) debido a que `portable-timeout.sh` señalizaba únicamente al proceso directo y no a todo el process group.
  2. Paso 6 de `sprint-planning.md` rígido, que forzaba pausa y prompt de Perplexity incluso cuando SearXNG ejecutó la investigación técnica de forma 100% autónoma.
  3. Compuerta de arranque de sprint en `session-start.md`: diagnóstico de activación ante estado `[PENDIENTE_ARRANQUE]` y estandarización del bloque interactivo proactivo de opciones (A/B + carriles).
- **Recomendación del agente:** Implementar los tres arreglos de forma integral:
  1. Asegurar en `portable-timeout.sh` y `deliberate-plan.sh` la terminación garantizada de todo el grupo de procesos (`PGID`) tras timeout (SIGTERM con escalado a SIGKILL).
  2. Modificar el Paso 6 de `sprint-planning.md` para ser estrictamente condicional: si SearXNG está activo, no emitir prompt ni bloquear; si está inactivo, anunciar explícitamente el estado/código de error de SearXNG (fallback nunca silencioso) y emitir el prompt + pausa asistida.
  3. Blindar el pre-flight de `session-start.md` para que ante `[PENDIENTE_ARRANQUE]` emita de forma consistente e invariable la consulta estructurada de Régimen (A/B) y orden de carriles derivados del DAG.
- **Dictamen del Operador:** Aprobado en enmienda al planning de Sprint 33.
- **Notas de integración:**
  1. Actualizar `scripts/agent/lib/portable-timeout.sh` y `deliberate-plan.sh` con `kill -- -$PGID` / `killpg`.
  2. Actualizar `.agents/workflows/sprint-planning.md` (Paso 5 y Paso 6).
  3. Actualizar `.agents/workflows/session-start.md` (Fase 1, compuerta proactiva).
  4. Validar en `tests/validate-control-plane.sh` Check 34.
- **Alternativas rechazadas y motivos:**
  - Dejar huérfanos sin matar o matanza individual por PID: Deja procesos de inferencia colgados consumiendo memoria y CPU.
  - Fallback silencioso a Perplexity: Descartado por mandato explícito; el operador debe saber siempre por qué se recurre a la asistencia manual.

---

## Hallazgos de Investigación Soberana (SearXNG)

- **Automatización de Coolify API**: Documentación oficial y repositorios comunitarios (`coollabsio/coolify-cli`, `nevyn/coolify`) confirman que la API REST v4 de Coolify responde en `/api/v1/` autenticada con token Bearer (`Authorization: Bearer <token>`). Para despliegues y chequeo de salud, las llamadas `GET /applications` y `POST /deploy?uuid=<uuid>` son el estándar de facto. Integrar variables consistentes (`COOLIFY_BASE_URL`, `COOLIFY_TOKEN`) garantiza compatibilidad universal entre invocaciones directas y entornos orquestados por Infisical.
- **Auditoría de Satélites**: Los satélites de Agent OS comparten la convención de almacenar scripts en `scripts/agent/` y leen su ledger en `.agents/context/last-sync.md`. La comparación mediante sumas de verificación sha256 contra la versión del core en local permite una comprobación instantánea (menos de 50ms) y a coste cero de tokens.
