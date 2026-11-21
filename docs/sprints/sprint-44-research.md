# Research Sprint 44
> Fecha: 2026-11-21
> Fuente: Investigación autónoma SearXNG y activos internos de Agent OS
> Estado: 100% Desatendido (SearXNG activo en flota HTTP 200)

---

## Descubrimientos Scout (por tarea)

### T-233: Homologación y Actualización Integral del Stack de Flota
- **Herramientas**: OpenCode v2.3.2, Hermes v0.23.3, Infisical v0.45.14, Orca v1.4.268.
- **Alternativa OSS**: Paquetes upstream oficiales de npm (`@opencode/cli`, `@infisical/cli`), GitHub releases (`NousResearch/hermes-agent`, `stablyai/orca`).
- **Dictamen**: Actualización determinista sin desarrollo nuevo.

### T-234: Actualización de la Skill `orca-cli` a v1.4.268
- **Alternativa OSS**: Skill nativa del ecosistema Agent OS.
- **Dictamen**: Desarrollo a medida justificado; enriquecimiento de `.agents/skills/orca-cli/SKILL.md` con las interfaces de Orca v1.4.268 (Bots, Hermes, OpenCode, multimodalidad y anotación remota).

### T-235: Puente Declarativo: `.agents/profiles/` → Orca Bot Identities
- **Alternativa OSS**: APIs internas de Orca Bots (Soul, Memory, Identity).
- **Dictamen**: Desarrollo a medida justificado; mapeo de los perfiles agnósticos de Agent OS (`coder`, `coordinator`, `qa-judge`) hacia las standing instructions y tarjetas de identidad de Orca.

### T-236: Optimización Reactiva de Coordinación en `orca-reactive-wait.sh`
- **Alternativa OSS**: Event loop nativo de Orca v1.4.268 (*worker final report wakeup*).
- **Dictamen**: Desarrollo a medida justificado; eliminación de intervalos de sondeo pasivo mediante el despertar de señal nativo.

### T-237: Validación Integral del Control Plane y Sincronización de Flota
- **Alternativa OSS**: Suite de verificación determinista de Agent OS (`tests/validate-control-plane.sh`).
- **Dictamen**: Ejecución y validación determinista sin dependencias externas.

---

## Investigación Técnica y Fuentes

### T-233 — Stack de Flota: Novedades Upstream
- **OpenCode v2.3.2**: Mejoras en carga de instrucciones permanentes en caliente y estabilidad CLI.
- **Hermes Agent v0.23.3**: Soporte mejorado para function calling MCP, streaming de respuestas y compatibilidad con slots de contexto extendidos.
- **Infisical CLI v0.45.14**: Rendimiento de inyección de variables en subprocesos y compatibilidad con Universal Auth v2.
- **Orca v1.4.268**: Integración de bots para Cursor/Hermes/Copilot, soporte multimodal en comentarios de worktree y optimizaciones en el renderizado y lecturas de credenciales.

### T-234 — Skill orca-cli v1.4.268
- **Activo interno inspeccionado**: `.agents/skills/orca-cli/SKILL.md`
- **Ampliaciones requeridas**:
  - `orca bot run --agent hermes|opencode`: Comandos para inicializar bots gestionados.
  - `orca item comment --attach <file>`: Adjuntos multimodales en worktrees.
  - `orca browser open --remote <url>`: Anotaciones web en hosts remotos.

### T-235 — Adaptador de Perfiles a Standing Instructions
- **Activo interno inspeccionado**: `.agents/profiles/*.md` y `.agents/rules/*.md`.
- **Patrón**: Mapear la tríada `Role + Rules + Constraints` al esquema de *Identity, Soul & Memory* consumible por OpenCode 2.x y Hermes dentro de Orca ADE.

### T-236 — Reactividad sin Polling
- **Activo interno inspeccionado**: `scripts/agent/lib/orca-reactive-wait.sh`.
- **Patrón**: Suscripción directa a eventos de terminación de workers (`worker_done`), eliminando bucles de sleep arbitrarios ($0 tokens).

### T-237 — Validación de Integridad
- **Activo interno**: `tests/validate-control-plane.sh` (16 pruebas canónicas sin regresiones).
