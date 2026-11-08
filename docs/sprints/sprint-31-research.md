# Research Sprint 31

> Fuente: Prospección determinista OSS (scout.sh), diagnóstico de campo de la flota (2026-11-08), especificaciones oficiales de CLIs y decisiones vinculantes del operador en planning.
> Fecha: 2026-11-08
> Siguiente sprint: Sprint 31
> Régimen de ejecución: Opción D (Autonomía acotada por defecto)

---

## Descubrimientos Scout (por tarea)

### T-172 — Matriz de roles y capacidades de CLIs de la flota (OpenCode 2, Claude Code, Aider, Hermes, Antigravity)
- **Alternativa detectada:** CLIs de agentes en ecosistema OSS y comercial (`@opencode/cli` npm v2.2.6 / repo `anomalyco/opencode`, `stablyai/orca` / binario `orca-ide`, `NousResearch/hermes-agent` v0.22.7, Anthropic Claude Code CLI con flag `--dangerously-skip-permissions`, Aider CLI con `--yes-always`, Google Antigravity CLI `agy`).
- **Recomendación del agente:** Formalizar la gobernanza de herramientas mediante una matriz declarativa de roles y perfiles YAML en `.agents/profiles/`, acotando el radio de impacto de cada CLI y delimitando claramente qué herramientas actúan como workers, jueces, coordinadores o deliberadores.
- **Dictamen del Relé (Decisiones Macro Vinculantes del Usuario):**
  - **OpenCode 2:** Rol ratificado como Worker / Coder acotado en sandbox / worktrees efímeros.
  - **Claude Code:** **DESCARTADO** formalmente como juez. Se mantiene la jerarquía determinista actual del core: `agy` (Tier 1) / Orca ADE (Tier 2).
  - **Aider:** **DESCARTADO** formalmente como rescatador de merges. Se ratifica sin excepciones la doctrina estricta de Sprint 25: solo el coordinador o el humano fusionan ramas de trabajo.
  - **Hermes:** **DESCARTADO** como front door separado. El daemon `whatsapp-bridge` fue construido por Hermes para comunicarse con el usuario en el host; Hermes opera a través de su propio puente y no se crea un gateway redundante.
  - **Antigravity:** Agente principal de desarrollo, planificación y deliberación arquitectónica.
- **Notas de integración:**
  1. Registrar perfiles YAML en `.agents/profiles/` para las herramientas ratificadas con sus capacidades y guardarraíles mínimos.
  2. Documentar la matriz en `docs/architecture/tools/fleet-cli-roles-matrix.md` con las restricciones y motivos de exclusión sellados.
  3. Asegurar que las referencias en perfiles y reglas preserven la compatibilidad agnóstica de stack y la política portable (sin rutas absolutas personales ni IPs privadas).
- **Alternativas rechazadas y motivos:**
  - Aider en rescate de merges: Descartado por contravenir el principio de aislamiento y gobernanza unificada de Git de Agent OS.
  - Claude Code como juez: Descartado por redundancia y riesgo de desalineación frente a la cadena determinista establecida.
  - Hermes como front door separado: Descartado por duplicidad técnica frente al puente existente.

### T-173 — Sonda determinista de actualización de herramientas (check-tooling-updates.sh)
- **Alternativa detectada:** `new-releases.io` (servicio SaaS de monitorización), Renovate con Custom Regex Managers (`datasource=github-releases`), API pública de GitHub (`releases/latest`), registro npm (`registry.npmjs.org`), API de PyPI (`pypi.org/pypi/<pkg>/json`).
- **Recomendación del agente:** Implementación de un script CLI determinista en `scripts/agent/check-tooling-updates.sh` con coste $0 de tokens, que verifique versiones sin autenticación obligatoria y con fallback fail-soft ante cuotas o desconexión.
- **Dictamen del Relé:** Recomendación ratificada. Mapeo explícito de la fuente verídica de versión por herramienta (ejemplo: npm para `@opencode/cli` debido a que GitHub releases devuelve v1.x; GitHub para repositorios como `stablyai/orca` o `hermes-agent`). Normalización semver (eliminando prefijo `v`), soporte de flags `--json`, `--check` y timeout estricto.
- **Notas de integración:**
  1. Diseñar el CLI para consultar registros oficiales mediante `curl` con timeout breve (máx 5s) y captura limpia.
  2. Evitar quemar cuotas de GitHub API (60 peticiones/hora sin autenticar) implementando cacheo efímero o preferencia por npm/PyPI cuando corresponda.
  3. Integrar salida legible para terminal y opción estructurada JSON para consumo agéntico.
- **Alternativas rechazadas y motivos:**
  - Renovate CLI completo: Descartado por excesiva pesadez e incompatibilidad con inspecciones ligeras de terminal.
  - Dependabot: Descartado por falta de flexibilidad para repositorios externos y nulo soporte de inspección bajo demanda local.

### T-174 — Skill canónica tooling-advisor
- **Alternativa detectada:** Skill preexistente `tool-inventory` (inventario estático de herramientas), propuesta `tooling-advisor` en `docs/idea-inbox/2026-11-07-tooling-advisor-roles-y-capacidades.md`.
- **Recomendación del agente:** Desarrollo de la habilidad `.agents/skills/tooling-advisor/SKILL.md` como agente de prospección pasiva que evalúe periódicamente el estado de las herramientas de la flota invocando `check-tooling-updates.sh` y formule propuestas estructuradas en `docs/idea-inbox/`.
- **Dictamen del Relé:** Recomendación ratificada. **Principio Inviolable: CERO auto-ejecución**. La skill solo genera propuestas redactadas y concisas en el buzón canónico de ideas; nunca aplica updates ni modifica binarios sin autorización humana explícita.
- **Notas de integración:**
  1. La skill debe consumir la salida estructurada de `check-tooling-updates.sh`.
  2. Formato de propuesta estrictamente alineado con la plantilla canónica de `docs/idea-inbox/`.
  3. Filtrado de changelogs para evitar contaminación de contexto (solo resumen de cambios críticos o breaking changes, nunca el markdown crudo entero).
- **Alternativas rechazadas y motivos:**
  - Auto-actualización de herramientas: Rechazada terminantemente por violar el principio de estabilidad y reproducibilidad de la flota.

### T-175 — Saneamiento integral del fantasma Bane
- **Alternativa detectada:** Cliente soberano SearXNG existente `scripts/agent/lib/searxng-client.sh` (283 líneas, validado en T-169), wrapper de compatibilidad `scripts/agent/lib/bane-client.sh`, plantillas `templates/bane/`, runbook `docs/runbooks/bane-deep-research-service.md`.
- **Recomendación del agente:** Saneamiento total del core erradicando el motor fantasma Bane. Cero duplicación de `searxng-client.sh` (cliente primario activo). Purga de plantillas, cliente y runbook obsoletos, y adaptación de workflows y de los Checks 34 y 38 en `validate-control-plane.sh` manteniendo el denominador inmutable en 38/38.
- **Dictamen del Relé:** **APROBADA formalmente con el alcance verificado**.
- **Notas de integración:**
  1. Eliminar de git: `scripts/agent/lib/bane-client.sh`, `templates/bane/` y `docs/runbooks/bane-deep-research-service.md`.
  2. En `sprint-planning.md`, sustituir la comprobación de `bane-client.sh` por `searxng-client.sh`.
  3. En `deep-research.md`, purgar la referencia al wrapper de Bane y canalizar exclusivamente a través de SearXNG.
  4. En `fleet-doctor.sh`, unificar la sonda de búsqueda profunda sobre SearXNG.
  5. En `tests/validate-control-plane.sh`, adaptar Check 34 y Check 38 para auditar la suite soberana de SearXNG y la ausencia de residuos de Bane, certificando 38/38 (0 errores).
- **Alternativas rechazadas y motivos:**
  - Mantener `bane-client.sh` como enlace simbólico o wrapper: Descartado por perpetuar confusión y acoplamiento a un proyecto descontinuado/inexistente.
  - Reducir el denominador de la suite a 37/38: Descartado por violar la regla de inmutabilidad del denominador.

### T-176 — Diagnóstico determinista de inoperatividad de whatsapp-bridge
- **Alternativa detectada:** Diagnóstico forense en el host/VPS (`systemctl --user status whatsapp-bridge`, `journalctl`, `ss -tulpn`, inspección de sockets y procesos Node.js).
- **Recomendación del agente:** Auditoría forense determinista, segura y no destructiva para identificar con precisión la causa de fallo de `whatsapp-bridge` en `<nodo-inferencia>`.
- **Dictamen del Relé:** Recomendación ratificada con **directiva estricta de diagnóstico puro**: determinar por qué no funciona y reportar causa + evidencia. Prohibido aplicar parches, modificaciones de código o reinicios arbitrarios a ciegas. El arreglo se decidirá tras la entrega del diagnóstico.
- **Notas de integración:**
  1. Comprobar el estado del servicio systemd de usuario en el nodo de inferencia.
  2. Auditar la escucha en el puerto `:3000` y socket relay local.
  3. Extraer los últimos 100 eventos de log mediante `journalctl --user -u whatsapp-bridge` analizando errores de inicialización, stack traces de Node o cierres de conexión.
  4. Diagnosticar la capa de sesión de WhatsApp (estado de Baileys / Evolution API, token de sesión expirado, QR no leído o bloqueo de red upstream).
  5. Redactar el informe de diagnóstico en `docs/runbooks/whatsapp-bridge-diagnostic-report.md` con hallazgos, causa raíz y opciones de remediación para decisión del usuario.
- **Alternativas rechazadas y motivos:**
  - Arreglo a ciegas (reiniciar servicio o modificar dependencias sin aislar el fallo): Terminantemente descartado por orden expresa del operador.
  - Sustituir el puente por otro servicio sin diagnosticar: Descartado; el puente existente es el canal nativo de Hermes.
