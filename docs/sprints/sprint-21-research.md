# Research y Prospección Tecnológica — Sprint 21

> **Documento de Respaldo Scout (Fase 2d / 2e del Sprint Planning)**  
> **Tema**: Arquitectura Multi-Agente, Orquestación y Workflows  
> **Herramienta determinista de prospección**: `scripts/agent/scout.sh` (coste $0 de inferencia).  
> **Fecha de ejecución**: 2026-10-28

---

## Metodología y Ejecución de Búsquedas Scout

Se ejecutaron consultas deterministas sobre el ecosistema open source (GitHub, NPM Registry y Hacker News) mediante `scripts/agent/scout.sh`:
1. `multi-agent orchestration handover protocol`
2. `declarative agent profiles roles`
3. `git worktree parallel agents dispatch`
4. `agent deliberation consensus design review`

---

## Descubrimientos Scout (por tarea)

### T-124: Persistencia y Handover de Deliberación Multi-Sesión (`deliberation-${TASK_ID}.json`)

- **Alternativas detectadas**:
  - `@antonbabenko/deliberation-mcp` (v4.0.0, NPM): Deliberación multi-modelo para Claude Code y hosts MCP (GPT, Gemini, Grok, OpenRouter) (`https://www.npmjs.com/package/@antonbabenko/deliberation-mcp`).
  - `@allocator-one/rcl` (v4.5.20, NPM): CLI de "Review Council" para revisión de código con múltiples modelos de IA (`https://www.npmjs.com/package/@allocator-one/rcl`).
  - `@kastalien-research/thoughtbox` (v1.2.5, NPM): CLI para conectar entornos Claude Code con instancias remotas alojadas de Thoughtbox (`https://www.npmjs.com/package/@kastalien-research/thoughtbox`).
- **Recomendación del agente**: Construir. El core de agent-os requiere un mecanismo determinista, local y sin dependencias externas de runtime que persista el estado de deliberación en el sistema de archivos (`.agents/context/`).
- **Decisión vigente**: Construcción interna (ya decidida en el planning y consolidada en T-124). Se implementó la persistencia mediante `.agents/context/deliberation-${TASK_ID}.json` con jerarquía de lectura (nombrada → genérica → fallback degradado) a coste $0.
- **Notas de integración**: El esquema de deliberación desacopla completamente el almacenamiento del protocolo de inferencia, garantizando supervivencia a través de cambios de contexto o sesiones concurrentes.
- **Alternativas rechazadas y motivos**:
  - `@antonbabenko/deliberation-mcp`: Rechazado. Impone una arquitectura basada en un servidor MCP externo y conexiones activas a proveedores comerciales en red; vulnera el principio de coste $0 de tokens para el plano de control y carece de degradación offline determinista.
  - `@allocator-one/rcl`: Rechazado. CLI de gran peso atado al ecosistema Node.js que introduce fricción de instalación; incompatible con la portabilidad pura en Bash/Python estándar sin dependencias de agent-os.
  - `@kastalien-research/thoughtbox`: Rechazado. Exige el uso de un backend propietario alojado (SaaS/cloud), vulnerando el principio de soberanía local y ausencia de dependencias de red no declaradas.

---

### T-125: Protocolo de Handover y Contratos Inter-Agente en Perfiles Declarativos

- **Alternativas detectadas**:
  - `@microsoft/agent-host-protocol` (v1.0.0, NPM): Cliente TypeScript para el Agent Host Protocol (AHP) de Microsoft (`https://www.npmjs.com/package/@microsoft/agent-host-protocol`).
  - `@langchain/langgraph` (v1.5.3, NPM): Framework de orquestación de agentes con estados y grafos de decisión cíclicos (`https://www.npmjs.com/package/@langchain/langgraph`).
  - `@deepseek-ai/dsh-agent-preset-registry` (v0.1.7-alpha.1, NPM): Registro declarativo de presets de agentes y perfiles (`https://www.npmjs.com/package/@deepseek-ai/dsh-agent-preset-registry`).
  - `@inkeep/agents-run-api` (v0.41.2, NPM): API de ejecución y streaming para frameworks de agentes (`https://www.npmjs.com/package/@inkeep/agents-run-api`).
- **Recomendación del agente**: Construir. Formalización nativa de contratos declarativos en Markdown y YAML dentro de `.agents/profiles/`, auditables estáticamente sin runtime pesado.
- **Decisión vigente**: Construcción interna (ya decidida en el planning y consolidada en T-125). Se actualizaron `coordinator.md`, `coder.md`, `qa-judge.md` y `reviewer.yaml` estableciendo la máquina de estados determinista `DISPATCHED` → `DELIBERATING` → `REVIEWED` → `EVALUATED` → `MERGED`.
- **Notas de integración**: Los perfiles actúan como contratos de interfaz operados mediante herramientas estándar de CLI (`deliberate-plan.sh`, `verify-goal.sh`, `worktree-merge.sh`).
- **Alternativas rechazadas y motivos**:
  - `@microsoft/agent-host-protocol`: Rechazado. Protocolo cliente TypeScript que introduce capas RPC complejas y acoplamiento a runtimes Node.js; innecesario para flujos coordinados por Git y filesystem local.
  - `@langchain/langgraph`: Rechazado. Framework de alta complejidad y consumo de memoria que oculta las transiciones de estado en abstracciones programáticas; atenta contra la transparencia de los contratos de texto auditables por humanos y git.
  - `@deepseek-ai/dsh-agent-preset-registry`: Rechazado. Paquete alfa experimental enfocado a edición interactiva dentro del entorno DeepSeek DSH; carece de interoperabilidad agnóstica de plataforma.
  - `@inkeep/agents-run-api`: Rechazado. Orientado a aplicaciones conversacionales de atención al cliente y soporte, no a pipelines de ingeniería de software desatendida.

---

### T-126: Integración del Bucle de Deliberación en Workflows de Despacho y Worktrees

- **Alternativas detectadas**:
  - `ClipboardHealth/groundcrew` (67⭐, MIT, GitHub) y paquete NPM `@clipboard-health/groundcrew` (v4.53.1): Orquestador basado en issues de Linear que lanza agentes en Git Worktrees efímeros (un worktree por tarea) (`https://github.com/ClipboardHealth/groundcrew`).
  - `mcdays94/pocock-agents` (43⭐, MIT, GitHub): Agentes OpenCode que estructuran el flujo de trabajo en fases de entrevista/planificación/ejecución (`https://github.com/mcdays94/pocock-agents`).
  - `Vikrant-Khedkar/gingerpaw` (9⭐, No lic, GitHub): Entorno de trabajo local para paralelizar múltiples agentes de codificación (`https://github.com/Vikrant-Khedkar/gingerpaw`).
  - `@deepseek-ai/dsh-experimental-worktree` (v0.2.1-alpha.2, NPM): Utilidad experimental para crear Git Worktrees y cambiar el directorio activo de la sesión (`https://www.npmjs.com/package/@deepseek-ai/dsh-experimental-worktree`).
  - Discusiones en Hacker News: *Stoneforge* (orquestación open-source para agentes paralelos, HN:47267105), *Batty* (equipo de agentes en tmux con test gating, HN:47638715), y reflexiones sobre *Claude Code 2.1.139 Agent View & Background Sessions* (HN:48124057).
- **Recomendación del agente**: Construir. Extender el script canónico `scripts/agent/worktree-dispatch.sh` y el workflow `.agents/workflows/parallel-orchestration.md` integrando el bucle deliberativo antes de la ejecución técnica.
- **Decisión vigente**: Construcción interna (ya decidida en el planning).
- **Notas de integración**: Aprovecha el diseño consolidado de agent-os: ubicación hermana fuera del árbol (`<repo>-<task-id>/`), gate de disco ADR 004, registro append-only en `.agents/context/dispatched.jsonl` y variables inyectadas (`AGENT_OS_DELIBERATION_FILE`).
- **Alternativas rechazadas y motivos**:
  - `ClipboardHealth/groundcrew`: Rechazado. Fuerte dependencia del servicio SaaS propietario Linear y de un pipeline Node/TypeScript foráneo; agent-os opera de manera autónoma y autocontenida sin requerir plataformas externas de ticketing.
  - `mcdays94/pocock-agents`: Rechazado. Implementación específica de OpenCode sin gestión de aislamiento por worktrees, sin cálculo de uso de disco ni purga determinista de inodos.
  - `Vikrant-Khedkar/gingerpaw`: Rechazado. Código sin licencia libre reconocida y limitado exclusivamente al sistema operativo macOS; viola las directrices de código libre y portabilidad cruzada Linux/macOS.
  - `@deepseek-ai/dsh-experimental-worktree`: Rechazado. Muta el directorio de trabajo del proceso principal de la sesión en lugar de mantener la frontera desacoplada entre el checkout principal y los worktrees efímeros (T-107).
  - *Batty* y *Stoneforge* (HN): Rechazados. Batty requiere interacción con el multiplexor de terminales `tmux`, inviable en entornos desatendidos o pipelines CI/headless; Stoneforge introduce servicios demonizados externos que añaden complejidad operativa y consumo de recursos innecesario.

---

### T-127: Extensión de la Suite de Validación con Check 35 para Gobernanza Multi-Agente

- **Alternativas detectadas**:
  - sin alternativa aplicable.
- **Recomendación del agente**: Construir. Incorporar el Check 35 directamente en `tests/validate-control-plane.sh` y actualizar el denominador de la suite (34→35).
- **Decisión vigente**: Construcción interna (ya decidida en el planning).
- **Notas de integración**: El validador `tests/validate-control-plane.sh` comprueba de extremo a extremo la integridad de los contratos YAML, frontmatters, scripts CLI, permisos y flujos deterministas del núcleo sin dependencias de frameworks externos.
- **Motivo de "sin alternativa aplicable" y alternativas rechazadas**:
  - Ningún framework de testing genérico de la industria (p. ej., Bats, PyTest, Jest) posee conocimiento contextual ni aserciones de dominio específicas sobre los perfiles de agentes, las compuertas ADR 004, las políticas de secretos o la estructura de gobernanza de agent-os sin requerir la escritura de los mismos checks en un lenguaje que añadiría dependencias externas. Un script Bash autocontenido mantiene el coste $0 de tokens, ejecución instantánea y portabilidad total.
