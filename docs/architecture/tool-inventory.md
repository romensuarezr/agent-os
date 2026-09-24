# 🛠️ Hub de Herramientas de la Flota (Tooling Hub)

> **Versión**: 1.1.0  
> **Fecha**: 2026-09-25  
> **Ámbito**: Índice central y router de capacidades de la flota (`Local` ↔ `datamanager` ↔ `oracle` ↔ `Cloud`)  
> **Propósito**: Proporcionar a los agentes un punto de entrada rápido y ligero para descubrir herramientas, evaluar capacidades y saltar a la documentación detallada de cada capa sin sobrecargar el contexto.

---

## 🏛️ Topología en 4 Capas (Índice Modular)

Para mantener el principio de responsabilidad única (SRP) y evitar saturar el contexto del agente con un único documento monolítico, el inventario se divide en cuatro documentos especializados:

```
```
agent-os/
├── docs/architecture/tool-inventory.md    ← Hub central del core y matriz de decisión
└── .agents/skills/tool-inventory/
    ├── SKILL.md                          ← Habilidad portable de consulta
    └── references/                       ← Catálogos de detalle (sincronizables a proyectos hijos)
        ├── local-environment.md          ← Capa 1: Host Local & Consola
        ├── persistent-agents-vps.md       ← Capa 2: VPS datamanager
        ├── saas-infrastructure-vps.md     ← Capa 3: VPS oracle
        └── cloud-and-web-ai.md           ← Capa 4: Cloud & Web AI
```

### Acceso a Cada Capa

| Capa | Nombre del Nodo / Entorno | Documento de Detalle (Portable) | Capacidades Clave |
| :---: | :--- | :--- | :--- |
| **1** | **Host Local & Consola** | [.agents/skills/tool-inventory/references/local-environment.md](file:///home/romen/Proyectos/agent-os/.agents/skills/tool-inventory/references/local-environment.md) | Antigravity CLI/IDE, Orca Desktop (`audit-orca.sh`), OpenCode CLI, `scout.sh` (0 tokens), `uv`/`uvx`, `gitingest`, repositorios en `~/Proyectos/`. |
| **2** | **VPS `datamanager`** | [.agents/skills/tool-inventory/references/persistent-agents-vps.md](file:///home/romen/Proyectos/agent-os/.agents/skills/tool-inventory/references/persistent-agents-vps.md) | Hermes Agent 24/7 (con **MCP de Coolify** preinstalado), FreeLLMAPI (:3001 en Tailscale, modelos locales $0 con tool-calling `qwen2.5:7b` y `llama3.1:8b`), Qdrant Vector DB (:6333). |
| **3** | **VPS `oracle`** | [.agents/skills/tool-inventory/references/saas-infrastructure-vps.md](file:///home/romen/Proyectos/agent-os/.agents/skills/tool-inventory/references/saas-infrastructure-vps.md) | Coolify (~25 contenedores tras Traefik), Unified-DB (PostgreSQL 16), **n8n con Native MCP** (`/mcp-server/http`) y REST API, Evolution API (WhatsApp), MinIO S3, Chatwoot, Typebot, R2 Backups. |
| **4** | **Cloud & Web AI** | [.agents/skills/tool-inventory/references/cloud-and-web-ai.md](file:///home/romen/Proyectos/agent-os/.agents/skills/tool-inventory/references/cloud-and-web-ai.md) | Google AI Studio (**2.000.000 tokens de contexto** en free tier para volcado masivo de código), Perplexity Pro (búsqueda técnica profunda), Space Bunny (MiniMax M3.1 con 1M tokens $0), Google APIs (GSC, Sheets, Drive). |

---

## 🧭 Matriz de Decisión Rápida: ¿A Dónde Acudir?

```
¿Qué tarea vas a realizar?
│
├── 🔍 Prospección de librerías / dependencias
│     ├── Búsqueda determinista sin inferencia (0 tokens)  ──▶ `scout.sh` (gh, npm, pypi) [Capa 1]
│     └── Benchmark técnico, trade-offs complejos         ──▶ Perplexity Pro [Capa 4]
│
├── 💻 Generación o refactorización de código
│     ├── Código local / confidencial a coste $0           ──▶ OpenCode + FreeLLMAPI (`qwen2.5:7b`) [Capa 2]
│     ├── Tarea amplia rápida con tool-calling ($0)        ──▶ OpenCode + Space Bunny (`space-bunny-free`) [Capa 4]
│     └── Repositorio completo masivo (>50k líneas)       ──▶ Google AI Studio (Gemini 2.5 Pro - 2M tokens) [Capa 4]
│
├── ⚙️ Automatización de flujos o integraciones
│     ├── Workflow ya existente en producción             ──▶ n8n Native MCP (`/mcp-server/http`) [Capa 3]
│     ├── Mensajería WhatsApp bidireccional                ──▶ Evolution API (`whatsapp.romensuarez.com`) [Capa 3]
│     └── Creación o edición de pipelines complejos       ──▶ n8n REST API [Capa 3]
│
└── 🚀 Gestión de Infraestructura y Despliegue
      ├── Agente autónomo gestionando contenedores         ──▶ Hermes Agent (con MCP de Coolify) [Capa 2]
      └── Auditoría o reinicio supervisado                ──▶ Coolify Web UI / scripts `remote-admin` [Capa 3]
```

---

## 🔒 Reglas de Oro y Seguridad

1. **Secreto Cero en Git**: Nunca registres credenciales o tokens en claro dentro de ningún archivo del repositorio. Refiérelos como variables de entorno (`$N8N_MCP_TOKEN`, `$UNIFIED_KEY`).
2. **Centralización en Infisical (Sprint 08 / T-042)**: Todas las variables sensibles se centralizarán en Infisical autoalojado en `oracle` con inyección en memoria (`infisical run`) vía identidades máquina (Universal Auth).
3. **No duplicar infraestructura**:
   - Para bases de datos PostgreSQL: usar **Unified-DB** en `oracle`.
   - Para almacenamiento de objetos S3: usar **MinIO** en `oracle` (`cdn.romensuarez.com`).
   - Para automatizaciones multi-app: usar **n8n Native MCP** en `oracle`.

---

## 🔄 Gobernanza: Cómo Añadir Nuevas Herramientas

1. Si es una herramienta local o CLI: documentar en `docs/architecture/tools/local-environment.md`.
2. Si es un servicio en `datamanager` o `oracle`: documentar en su archivo correspondiente de `docs/architecture/tools/`.
3. Actualizar la tabla resumen en este Hub y notificar en el commit: `docs(tools): update fleet tool hub`.
