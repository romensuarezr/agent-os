# Idea: Inventario Activo de Herramientas Multi-Entorno y Prospección Automatizada

**Fecha**: 2026-09-24  
**Estado**: 💡 Capturada en Idea Inbox  
**Área**: Capacidades / Agentes / Herramientas / DX  

---

## 1. Contexto y Problema Actual
A medida que el ecosistema de desarrollo y control plane se expande, las herramientas disponibles se encuentran distribuidas en múltiples capas y ubicaciones sin un inventario unificado ni mantenible:
- **Local (`inteligencia-colectiva`)**: Antigravity CLI, Orca Desktop, OpenCode, Node, Python, herramientas CLI (`gh`, `jq`, `scout.sh`).
- **VPS `datamanager`**: Hermes Agent 24/7, FreeLLMAPI, Ollama local, base vectorial Qdrant, RAG service, y **MCPs de Hermes** (incluyendo el MCP de Coolify para gestionar infraestructura de forma autónoma).
- **VPS `oracle`**: Coolify (gestor de Docker con ~25 contenedores), Traefik reverse proxy, PostgreSQL, Redis, servicios activos.
- **Herramientas Web AI y Proveedores**: Google AI Studio, Gemini Advanced, Perplexity Pro, Anthropic, OpenRouter, etc.
- **Dificultad actual**: La ausencia de un registro mantenible provoca que el agente "olvide" qué herramientas o integraciones tiene a mano (por ejemplo, tener que recordar manualmente que Hermes ya tiene un MCP para hablar con Coolify).

---

## 2. Propuesta: Habilidad de Inventario Activo + Prospección Automatizada

### Componente A: Registro Declarativo de Capacidades (Tooling Hub)
Diseñar una estructura viva dentro de `agent-os` (por ejemplo, en `.agents/context/tools-inventory.md` o una skill específica `tool-inventory` / `fleet-capabilities`) estructurada en 4 capas:
1. **Capa Local (Consola y Ejecución)**: CLIs, agentes locales, modelos locales, IDEs.
2. **Capa VPS / Agentes Persistentes**: Servicios 24/7, modelos autoalojados, MCPs activos instalados (ej: Coolify MCP en Hermes).
3. **Capa Web AI y Cloud**: Herramientas con cuentas activas (Google AI Studio, Perplexity Pro, etc.) con sus prompts recomendados para delegación.
4. **Capa Infraestructura Remota**: Coolify y contenedores desplegados disponibles para consumir.

### Componente B: Prospección Periódica de Herramientas Freemium / OSS
Integrar un script o cron ligero que, apoyándose en la prospección determinista de `scripts/agent/scout.sh`:
- Evalúe periódicamente o antes de planificar un sprint qué nuevas herramientas gratuitas, librerías OSS o servicios con tiers freemium han emergido en la comunidad para resolver los ítems del roadmap.
- Evite casarse con herramientas de pago si ha salido una alternativa abierta o gratuita equivalente.

---

## 3. Plan de Acción Propuesto

1. **Creación del Registro Base**:
   - Auditar y formalizar el inventario en un archivo estructurado `.agents/context/tools-inventory.md`, unificando accesos, endpoints Tailscale y MCPs activos.
2. **Creación de la Skill `tool-inventory`**:
   - Skill con instrucciones claras para que el agente consulte el catálogo completo antes de proponer crear soluciones desde cero o delegar a servicios externos.
3. **Automatización de Prospección con `scout.sh`**:
   - Crear un script complementario (ej: `scripts/agent/discover-tools.sh`) que cruce las keywords de tareas pendientes con `scout.sh` para sugerir herramientas recién descubiertas al planificar sprints.

---

## 4. Criterio de Éxito
- Cualquier agente que opere en el sistema puede responder en un solo paso qué herramientas tiene disponibles en cada nodo (local, VPS, web, MCPs).
- El agente aprovecha de inmediato capacidades ya existentes (como el MCP de Coolify en Hermes para autoalojar servicios) sin duplicar esfuerzos humanos.
