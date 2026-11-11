# Research Sprint 32

> Fuente: Prospección determinista OSS (scout.sh), diagnóstico del repositorio (2026-11-10), especificación oficial MCP y decisiones vinculantes del operador en planning.
> Fecha: 2026-11-10
> Siguiente sprint: Sprint 32
> Régimen de ejecución: Opción D (Autonomía acotada por defecto)

---

## Descubrimientos Scout (por tarea)

### T-178 — Purga definitiva de residuos fantasma de Bane
- **Alternativa detectada:** Residuos de configuración y fallback detectados en `fleet.example.yaml:89` (`bane:`), fallback `BANE_API_URL` y bloque `svcs['bane']` en `scripts/agent/lib/searxng-client.sh`, y verificación existente en `tests/validate-control-plane.sh` Check 34 (§18).
- **Recomendación del agente:** Erradicación determinista y completa de las referencias residuales a Bane en la configuración de ejemplo y en el cliente de SearXNG. Blindar en el Check 34 (§18) de `validate-control-plane.sh` que ni `fleet.example.yaml` ni `searxng-client.sh` contengan menciones al motor obsoleto Bane, preservando el denominador 38/38.
- **Dictamen del Operador:** Aprobada. Se aclara explícitamente que las comprobaciones de Bane viven en Check 34 (§18) y no en Check 18.
- **Notas de integración:**
  1. Purgar bloque `bane:` en `.agents/config/fleet.example.yaml`.
  2. Purgar `BANE_API_URL` y `svcs['bane']` en `scripts/agent/lib/searxng-client.sh`.
  3. Extender Check 34 (§18) en `tests/validate-control-plane.sh` para verificar la ausencia de `bane` en ambos archivos.
- **Alternativas rechazadas y motivos:**
  - Mantener fallback hacia Bane: Rechazado formalmente en Sprint 31; SearXNG es el motor soberano activo.

### T-179 — Soporte declarativo de servidores MCP remotos HTTP/SSE en Fleet
- **Alternativa detectada:** Especificación oficial de Model Context Protocol (MCP) para transporte Streamable HTTP / Server-Sent Events (SSE); servidores MCP comunitarios y remotos; esquema actual de `mcpServers` en `.agents/config/fleet.yaml` y `.agents/config/fleet.example.yaml` limitado a stdio (`command`/`args`/`env`).
- **Recomendación del agente:** Extender el esquema declarativo de `fleet.yaml` para soportar servidores MCP remotos vía `url` (con tipo opcional `transport: http` o `sse`), validando sintaxis de forma determinista en `fleet-doctor.sh` y `validate-control-plane.sh`.
- **Dictamen del Operador:** Aprobada. Base indispensable para registrar servidores como DeepWiki sin necesidad de wrappers de ejecución local pesados.
- **Notas de integración:**
  1. Actualizar esquema YAML en `.agents/config/fleet.example.yaml` documentando servidores remotos (`url`, `headers`, `transport`).
  2. Ajustar `scripts/agent/fleet-doctor.sh` para sondear la disponibilidad de endpoints HTTP sin filtrar credenciales.
  3. Validar consistencia sintáctica en Check 1 y Check 12 de `validate-control-plane.sh`.
- **Alternativas rechazadas y motivos:**
  - Embalar cada servidor MCP en un binario local Node/Python: Descartado por pesadez y complejidad de dependencias locales innecesarias cuando el proveedor ya expone HTTP streamable.

### T-180 — DeepWiki MCP como fuente secundaria de comprensión estructural en tooling-advisor
- **Alternativa detectada:** Servidor oficial DeepWiki MCP (`https://mcp.deepwiki.com/mcp`), paquetes de la comunidad (`regenrek/deepwiki-mcp` 1,390★ MIT, `@physihan/deepwiki-mcp`), captura en `docs/idea-inbox/2026-11-09-deepwiki-complemento-scout.md`.
- **Recomendación del agente:** Integrar DeepWiki como fuente de comprensión profunda estructural para repositorios públicos tras la fase determinista de `scout.sh`, con guardarraíl inviolable: DeepWiki consulta una wiki generada y no el HEAD vivo; toda conclusión debe contrastarse contra el árbol real del repo antes de generar un plan o propuesta.
- **Dictamen del Operador:** Aprobada. Absorbe integralmente la propuesta del inbox `2026-11-09-deepwiki-complemento-scout.md`.
- **Notas de integración:**
  1. Registrar la herramienta en la skill `.agents/skills/tooling-advisor/SKILL.md` como herramienta de análisis de código OSS.
  2. Especificar guardarraíles: solo repos públicos, nunca tokens privados en prompts, y contraste obligatorio contra HEAD.
  3. Cero auto-ejecución: las conclusiones se canalizan como propuestas estructuradas en `docs/idea-inbox/`.
- **Alternativas rechazadas y motivos:**
  - Usar DeepWiki en tiempo de implementación o sustituyendo scout.sh: Rechazado; scout.sh opera a coste $0 determinista; DeepWiki es solo una capa complementaria de comprensión estructural.

### T-181 — Sincronización y automatización de last-sync.md
- **Alternativa detectada:** Fichero de marca `.agents/context/last-sync.md` desfasado en Sprint 19 (`v1.14.0`); script `scripts/agent/close-sprint.sh` que actualiza changelog y VERSION pero no sincronizaba `last-sync.md`.
- **Recomendación del agente:** Actualizar `.agents/context/last-sync.md` al estado real del core (`v1.27.0`, Sprint 31/32) e incorporar la sincronización determinista de este fichero dentro de `close-sprint.sh`.
- **Dictamen del Operador:** Aprobada. Mejora la trazabilidad del core sobre sí mismo y elimina deuda de metadatos históricos.
- **Notas de integración:**
  1. Actualizar `.agents/context/last-sync.md` con la versión semver actual y sprints cerrados.
  2. Modificar `scripts/agent/close-sprint.sh` para actualizar `last-sync.md` atómicamente al archivar sprints.
  3. Asegurar que `tests/validate-control-plane.sh` Check 19 valide la actualización limpia de `last-sync.md`.
- **Alternativas rechazadas y motivos:**
  - Actualización manual periódica: Descartada por propensión al olvido humano o agéntico.

### T-182 — Remediación planificada y rotación de FreeLLMAPI en pasarela Hermes
- **Alternativa detectada:** Incidente documentado en `docs/runbooks/incident-hermes-401-remediation.md` (reversión provisional a OmniRoute tras error 401 en FreeLLMAPI); base de datos SQLite `freeapi.db` y variables en `~/.hermes/.env` en el host de inferencia.
- **Recomendación del agente:** Ejecutar formalmente la Opción B: rotación controlada de la API key de FreeLLMAPI en la base de datos de FreeLLMAPI y configuración de Hermes, verificación de inferencia y reactivación sin interrupción del servicio de mensajería.
- **Dictamen del Operador:** Aprobada con condición estricta: **la rotación debe realizarse exclusivamente con maquinaria de scripts, sin imprimir valores de secretos en pantalla ni logs, y con compuerta HITL del operador (solicitud de ventana + confirmación OK del operador antes de aplicar cambios destructivos o reiniciar servicios)**.
- **Notas de integración:**
  1. Diseñar script determinista o procedimiento guiado con variables leídas por stdin o fichero efímero protegido.
  2. Cero eco de tokens en terminal o digest.
  3. Sometimiento a compuerta HITL interactiva con el operador.
  4. Pruebas de verificación de liveness: `hermes -z ping` y llamada de inferencia real antes de dar por cerrada la tarea.
- **Alternativas rechazadas y motivos:**
  - Modificación manual directa imprimiendo credenciales: Terminantemente prohibida por la política de seguridad y frontera portable del core.
