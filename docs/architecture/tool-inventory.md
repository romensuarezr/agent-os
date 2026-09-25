# 🛠️ Hub de Herramientas de la Flota (Tooling Hub)

> **Versión**: 2.0.0 (Agnóstica y Declarativa)  
> **Fecha**: 2026-09-25  
> **Ámbito**: Índice central, especificación declarativa y router de capacidades de la flota (`Local` ↔ `Worker Nodes` ↔ `SaaS Nodes` ↔ `Cloud AI` ↔ `MCP Servers`)  
> **Propósito**: Proporcionar a los agentes un marco modular, estandarizado y desacoplado para descubrir herramientas y capacidades de computación sin hardcodear infraestructura privada en el código fuente.

---

## 🏛️ Arquitectura Declarativa y Desacoplamiento

Para garantizar que el núcleo de **Agent OS** sea completamente agnóstico y portable entre diferentes usuarios, equipos o entornos de nube, la infraestructura física se desacopla del código del repositorio:

```
agent-os/
├── config/
│   ├── fleet.example.yaml                ← Plantilla pública agnóstica versionada en git
│   └── fleet.yaml                        ← Configuración real local del usuario (IGNORADA en git)
├── docs/architecture/
│   ├── tool-inventory.md                 ← Este documento: arquitectura y matriz de decisión
│   └── tools/                            ← Catálogos pedagógicos y legibles por humanos (en core)
│       ├── local-environment.md          ← Capa 1: Host Local & Consola
│       ├── persistent-agents-vps.md       ← Capa 2: Worker Nodes (Inferencia & Agentes)
│       ├── saas-infrastructure-vps.md     ← Capa 3: SaaS Nodes (PaaS & Automatizaciones)
│       └── cloud-and-web-ai.md           ← Capa 4: Cloud & Web AI
└── .agents/skills/tool-inventory/
    └── SKILL.md                          ← Habilidad operativa pura (lectura dinámica de fleet.yaml)
```

### Principio de Operación
1. **El repositorio versiona la abstracción**: Esquemas estándar (YAML, especificación MCP) y documentación pedagógica con marcadores educativos (`worker-node-01`, `saas-node-02`, `100.x.y.z`, `example.com`).
2. **El entorno local define la realidad**: Cada desarrollador o servidor cuenta con su propio `config/fleet.yaml` donde se mapean las IPs privadas (ej. Tailscale), credenciales o endpoints específicos.

---

## 🧭 Las 4 Capas de la Flota

| Capa | Entorno / Tipo de Nodo | Documento de Detalle (Humano) | Capacidades y Servicios Clave |
| :---: | :--- | :--- | :--- |
| **1** | **Host Local & Consola** | [docs/architecture/tools/local-environment.md](tools/local-environment.md) | Antigravity CLI/IDE, Orca Desktop (`audit-orca.sh`), OpenCode CLI, `scout.sh` (0 tokens), `uv`/`uvx`, `gitingest`, repositorios de trabajo locales. |
| **2** | **Worker Nodes (Inferencia & Datos)** | [docs/architecture/tools/persistent-agents-vps.md](tools/persistent-agents-vps.md) | Hermes Agent 24/7 (con servidor MCP para PaaS), FreeLLMAPI (inferencia local $0 con tool-calling nativo: `qwen2.5:7b`, `llama3.1:8b`), base de datos vectorial Qdrant. |
| **3** | **SaaS Nodes (PaaS & Automatizaciones)** | [docs/architecture/tools/saas-infrastructure-vps.md](tools/saas-infrastructure-vps.md) | Gestor PaaS (Coolify con reverse proxy Traefik), Unified-DB (PostgreSQL 16 unificada), **n8n con Native MCP** (`/mcp-server/http`) y REST API, Evolution API (WhatsApp), MinIO (S3 compatible), Chatwoot, Typebot. |
| **4** | **Cloud & Web AI** | [docs/architecture/tools/cloud-and-web-ai.md](tools/cloud-and-web-ai.md) | Google AI Studio (**2.000.000 tokens de contexto** en free tier), Perplexity Pro (búsqueda técnica profunda), Space Bunny (MiniMax M3.1 con 1M tokens $0), APIs Cloud (Search Console, Sheets, Drive) y Cloudflare Edge/R2. |


---

## 🔌 Ecosistema Model Context Protocol (MCP)

Agent OS adopta la especificación de servidores **MCP** como el protocolo estándar de la industria para exponer herramientas operativas a los agentes de IA de forma estructurada y segura.

Los servidores MCP se configuran de manera declarativa en `config/fleet.yaml` bajo la clave `mcpServers`:

```yaml
mcpServers:
  filesystem:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/workspaces"]
  github:
    command: "npx"
    args: ["-y", "@modelcontextprotocol/server-github"]
    env:
      GITHUB_PERSONAL_ACCESS_TOKEN: "${GITHUB_TOKEN}"
  fetch:
    command: "uvx"
    args: ["mcp-server-fetch"]
```

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
│     ├── Mensajería WhatsApp bidireccional                ──▶ Evolution API (`https://whatsapp.example.com`) [Capa 3]
│     └── Creación o edición de pipelines complejos       ──▶ n8n REST API [Capa 3]
│
└── 🚀 Gestión de Infraestructura y Despliegue
      ├── Agente autónomo gestionando contenedores         ──▶ Hermes Agent (con MCP de Coolify) [Capa 2]
      └── Auditoría o reinicio supervisado                ──▶ Coolify Web UI / scripts `remote-admin` [Capa 3]
```

---

## 🔒 Reglas de Oro y Seguridad

1. **Secreto Cero en Git**: Nunca registres credenciales o tokens en claro dentro de ningún archivo del repositorio. Refiérelos como variables de entorno (`$N8N_MCP_TOKEN`, `$UNIFIED_KEY`) o en el archivo ignorado `config/fleet.yaml`.
2. **Centralización en Gestor de Secretos (Infisical)**: Todas las variables sensibles se gestionarán en Infisical con inyección directa en memoria (`infisical run`) vía identidades máquina (Universal Auth).
3. **No duplicar infraestructura**:
   - Para bases de datos PostgreSQL: reutilizar instancias unificadas (`Unified-DB`) en nodos dedicados.
   - Para almacenamiento de objetos S3: utilizar instancias de **MinIO** o almacenamiento de objetos S3 sin costes de salida.
   - Para automatizaciones multi-app: utilizar **n8n Native MCP** antes de programar endpoints HTTP personalizados.

---

## 🔄 Gobernanza: Cómo Añadir Nuevas Herramientas a la Flota

1. Añadir la herramienta o servicio a tu archivo local privado `config/fleet.yaml`.
2. Si la herramienta aporta un nuevo patrón arquitectónico reutilizable para otros desarrolladores:
   - Añadir su especificación pedagógica en `config/fleet.example.yaml`.
   - Documentarla en el archivo de referencia correspondiente de `.agents/skills/tool-inventory/references/`.
   - Actualizar este Hub y notificar en el commit: `docs(tools): update fleet tool hub`.
