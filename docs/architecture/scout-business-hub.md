# Scout Report: Holding & Business Operations Hub

> **Fecha**: 2026-09-27  
> **Rol**: Tech Scout & Research Engineer de Agent OS  
> **Objetivo**: Estructurar un repositorio central de holding y operaciones de negocio para coordinar proyectos satélite (`romensuarez-web`, `leaderboard-platform`, `polybot`).  
> **Coste de prospección**: $0 tokens (100% determinista vía `scout.sh`, GitHub REST API y Hacker News Algolia).

---

## 1. Prospección Tecnológica por Categorías

### Categoría 1: Second Brain / RAG con Servidor MCP

Buscamos sincronizar notas técnicas y de negocio (Notion, Google Drive, Markdown) y exponerlas mediante el estándar Model Context Protocol (MCP) para que los agentes consulten memoria contextual antes de programar o tomar decisiones estratégicas.

| Repositorio / Paquete | Estrellas / Licencia | Enfoque Arquitectónico | Pros | Contras / Riesgos |
| :--- | :---: | :--- | :--- | :--- |
| **[`makenotion/notion-mcp-server`](https://github.com/makenotion/notion-mcp-server)** | 4.648⭐<br>`MIT` | Servidor MCP oficial de Notion en TypeScript (`@notionhq/notion-mcp-server`). | • Mantenido oficialmente por Notion.<br>• Consulta páginas, bases de datos y bloques directamente.<br>• 0 infraestructura de BD adicional. | • No indexa embeddings locales; depende de la API REST de Notion y su latencia.<br>• Requiere token de integración. |
| **[`MODSetter/SurfSense`](https://github.com/MODSetter/SurfSense)** | 16.268⭐<br>`Apache-2.0` | Alternativa open source y *air-gapped* a NotebookLM. Backend FastAPI + LangGraph + Next.js + Ollama. | • Indexa documentos masivos con RAG local.<br>• Alta privacidad y soporte nativo para modelos locales.<br>• Excelente interfaz de síntesis. | • Proyecto monolítico pesado (>500MB RAM).<br>• No fue diseñado originalmente como servidor MCP ligero; actúa como aplicación completa. |
| **[`rahilp/second-brain-cloudflare`](https://github.com/rahilp/second-brain-cloudflare)** | 793⭐<br>`MIT` | Capa de memoria unificada autohospedada en Cloudflare Workers (Free tier) con servidor MCP. | • Coste $0 en free tier.<br>• Expone memoria vía MCP nativo compatible con Claude, Cursor y Antigravity.<br>• Extremadamente ligero. | • Requiere configurar Workers, Vectorize y D1 en Cloudflare.<br>• Lógica de ingesta más básica que un RAG dedicado. |
| **[`flepied/second-brain-agent`](https://github.com/flepied/second-brain-agent)** | 311⭐<br>`GPL-3.0` | Agente Python basado en LangChain para gestión de conocimiento personal (PKM). | • Conectores a diversas fuentes.<br>• Código legible en Python. | • Licencia restrictiva GPL-3.0.<br>• Carece de servidor MCP nativo estándar; arquitectura clásica de chatbot. |

---

### Categoría 2: Revenue & Operations Hubs / Indie Hacker Dashboards

Buscamos consolidar KPIs clave (Stripe MRR, churn, analítica de visitas, status de bots/APIs) y exponer un endpoint JSON compacto consumible por el dashboard de flota (**Homepage** vía widget `customapi`).

| Repositorio / Proyecto | Estrellas / Licencia | Enfoque Arquitectónico | Pros | Contras / Riesgos |
| :--- | :---: | :--- | :--- | :--- |
| **[`talivia-group/talivia`](https://github.com/talivia-group/talivia)** | 2.392⭐<br>`Apache-2.0` | Analítica *revenue-first* autoalojada: analítica web, session replay y atribución de ingresos con Stripe. | • Alternativa completa a Datafast/Mixpanel.<br>• Correlaciona visitas web con cobros reales de Stripe.<br>• Autoalojable en Docker. | • Stack complejo con dependencias de ingestión pesadas para un único desarrollador.<br>• Sobredimensionado si solo se busca telemetría de alto nivel. |
| **[`ctrlaltdylan/MRRmaid`](https://github.com/ctrlaltdylan/MRRmaid)** | 26⭐<br>`MIT` | Agregador y CLI en Node para cálculo de MRR, NRR y concentración de clientes vía API de Stripe y Shopify. | • Script conciso y determinista.<br>• Calcula métricas financieras estándar sin bases de datos intermedias.<br>• Fácil de encapsular en script Bash/Node. | • Proyecto pequeño sin UI web propia (aunque ideal para alimentar un cron o API). |
| **Micro-Endpoint Nativo (`ops/metrics-collector`)** | Custom<br>`MIT` | Script determinista en Node/Python que consulta Stripe API (`stripe-node`) + Cloudflare Analytics y genera `metrics.json`. | • **0 MB de RAM persistente** (ejecución por cron o endpoint HTTP mínimo de 20 líneas).<br>• Se mapea directo a Homepage (`customapi`).<br>• 100% adaptable a las particularidades de `polybot` y `leaderboard`. | • Requiere mantener las 50 líneas del script recolector. |

---

### Categoría 3: Multi-Repo Orchestration Patterns

Buscamos coordinar tareas y flujos de trabajo sobre repositorios secundarios (`romensuarez-web`, `leaderboard-platform`, `polybot`) desde un centro de mando central, sin fusionar códigos ni crear monorepos engorrosos.

| Patrón / Repositorio | Mecanismo de Aislamiento | Pros | Contras |
| :--- | :--- | :--- | :--- |
| **[`alex-reysa/singular-lite`](https://github.com/alex-reysa/singular-lite)** (39⭐, GPL-3.0) | Motor de orquestación multi-agente autónomo con leases, compuertas HITL y aislamiento estricto vía **Git Worktrees**. | • Arquitectura idéntica a los objetivos de Agent OS.<br>• Despacho desacoplado (*detached dispatch*) por defecto.<br>• Audita antes de mergear. | • Licencia GPL-3.0.<br>• Requiere adaptar su jerarquía L0/L1/L2 a los perfiles de Agent OS. |
| **Patrón *Satellite Manifest* + Git Worktrees (Recomendado)** | Repositorio central mantiene únicamente un manifiesto declarativo (`config/satellites.yaml`). El agente monta worktrees efímeros en carpetas hermanas (`../satellites/`). | • **0 contaminación de código**: Los satélites conservan su ciclo de vida, CI/CD y despliegues independientes.<br>• El hub solo gestiona contratos, objetivos de negocio y auditorías.<br>• Totalmente compatible con `agent-os install.sh`. | • Requiere que el entorno local tenga acceso a los directorios hermanos de los repositorios. |
| **Git Submodules Tradicionales** | Enlace estático mediante punteros de commit de git (`git submodule add`). | • Estándar nativo de git. | • Frágil ante commits concurrentes de agentes.<br>• Frecuentes problemas de *detached HEAD* y sincronización. |

---

## 2. Recomendación Estratégica: ¿Repo Limpio o Fork?

### Veredicto: **CREAR UN REPOSITORIO LIMPIO DESDE CERO (`business-hub` o `operations-center`)**

**Justificación Técnica:**
1. **Evitar la trampa del Monolito:** Proyectos como SurfSense o Talivia son aplicaciones de producto final, no hubs de gobernanza. Forkearlos obligaría a cargar con dependencias de frontend, migraciones de bases de datos pesadas y mantenimiento ajeno que colisiona con el principio de *"Global pequeño, local fino"*.
2. **Arquitectura desacoplada de Servicios vs Hub:**
   - Si se desea la UI de **SurfSense** o **Talivia**, se despliegan de forma independiente en Coolify (`oracle`) como servicios Docker aislados, tal y como hicimos con ByteBox o Homepage.
   - El nuevo repositorio actúa estrictamente como **plano de control de negocio, conocimiento y coordinación agéntica**.
3. **Bootstrapping nativo con Agent OS:**
   - Se crea el repositorio vacío, se ejecuta `bash scripts/agent/install.sh ../operations-hub`, y de inmediato hereda los flujos de sprint, las skills agénticas y el control de sesiones.

---

## 3. Propuesta de Estructura de Carpetas para el Nuevo Repo

```
operations-hub/                            ← Nuevo repositorio limpio
├── AGENTS.md                              ← Guía del holding, metas de facturación, satélites y políticas
├── README.md                              ← Visión general del portafolio
├── changelog.md
├── .agents/                               ← Instalado automáticamente vía agent-os install.sh
│   ├── rules/
│   ├── skills/                            ← Skills heredadas + skills de negocio (ej. stripe-audit)
│   └── workflows/                         ← session-start, sprint-planning, etc.
├── config/
│   ├── fleet.yaml                         ← Configuración local de herramientas, MCPs y nodos
│   ├── satellites.yaml                    ← Declaración de satélites (romensuarez-web, leaderboard, polybot)
│   └── metrics-sources.yaml               ← Credenciales y mapeo de Stripe, Cloudflare, Uptime
├── docs/
│   ├── sprints/                           ← Sprints de alto nivel de negocio / holding
│   ├── adrs/                              ← Decisiones de gobernanza, pricing y arquitectura
│   └── knowledge/                         ← Second Brain local en Markdown (notas estratégicas, playbooks)
├── scripts/
│   ├── agent/                             ← Scripts operativos de Agent OS (check-sprint, close-task...)
│   └── ops/
│       ├── collect-metrics.sh             ← Generador de digest de KPIs ($0 tokens) para Homepage
│       └── dispatch-satellite.sh          ← Orquestador para enviar órdenes/tareas a repos satélites
└── services/
    └── metrics-api/                       ← Micro-servicio mínimo (FastAPI / Node)
        ├── main.py                        ← Expone /api/kpis (MRR, visitas, estado bots) para Homepage
        └── docker-compose.yml             ← Desplegable opcional en Coolify
```

---

## 4. Hoja de Ruta de Implementación Sugerida

1. **Fase 1 — Bootstrapping del Repositorio**:
   - Inicializar el repo `operations-hub` en GitHub.
   - Instalar Agent OS: `bash scripts/agent/install.sh ../operations-hub`.
   - Redactar `AGENTS.md` definiendo el rol de cada satélite (`romensuarez-web`, `leaderboard-platform`, `polybot`).

2. **Fase 2 — Integración de Second Brain (MCP)**:
   - Registrar en `config/fleet.yaml` el servidor MCP oficial de Notion (`@notionhq/notion-mcp-server`) para que los agentes lean la documentación estratégica existente en Notion.
   - Mantener un directorio local `docs/knowledge/` en Markdown para notas técnicas directas.

3. **Fase 3 — Métricas de Negocio hacia Homepage**:
   - Crear el script `scripts/ops/collect-metrics.sh` que consulte la API de Stripe (MRR, volumen de transacciones) y genere un JSON estructurado.
   - Conectar dicho JSON al widget `customapi` de Homepage en el VPS `oracle`.

4. **Fase 4 — Orquestación Multi-Repo**:
   - Implementar el patrón de *Satellite Manifest* con `dispatch-satellite.sh` que abra sesiones o inspeccione el estado de los 3 proyectos satélite sin mezclar sus historias de git.
