---
name: tool-inventory
description: Consulta, selecciona y aprovecha el catálogo de herramientas activas de la flota (local, VPS datamanager/oracle, web AI y MCPs) antes de desarrollar soluciones desde cero o delegar a servicios externos.
---

# 🛠️ Tool Inventory (Inventario Activo de la Flota)

Esta habilidad permite a cualquier agente de `agent-os` conocer, evaluar y reutilizar el ecosistema completo de herramientas, servidores, agentes persistentes y servicios en la nube ya desplegados en la infraestructura.

Su objetivo es evitar la duplicación de esfuerzos, prevenir costes innecesarios de APIs y aprovechar de inmediato capacidades operativas avanzadas (como los MCPs de n8n y Coolify, pasarelas de modelos locales a coste $0 y almacenamiento S3).

---

## 📖 Documento Fuente y Estructura Modular

El catálogo está organizado en documentos de referencia especializados y autocontenidos dentro de esta misma habilidad (`references/`), garantizando que sean 100% portables al sincronizarse con cualquier proyecto o máquina:
- **Capa 1 (Local & Consola)**: [references/local-environment.md](references/local-environment.md) (Antigravity, Orca, OpenCode, `uv`, `gitingest`, `scout.sh`, repos en `~/Proyectos/`).
- **Capa 2 (VPS datamanager)**: [references/persistent-agents-vps.md](references/persistent-agents-vps.md) (Hermes Agent con MCP Coolify, FreeLLMAPI local, Qdrant).
- **Capa 3 (VPS oracle)**: [references/saas-infrastructure-vps.md](references/saas-infrastructure-vps.md) (Coolify, Unified-DB, n8n Native MCP, Evolution API, MinIO).
- **Capa 4 (Cloud & Web AI)**: [references/cloud-and-web-ai.md](references/cloud-and-web-ai.md) (Google AI Studio 2M context, Perplexity Pro, Space Bunny 1M context).
- **Hub Arquitectónico en Core**: `docs/architecture/tool-inventory.md` (router central presente en el repositorio `agent-os`).

---

## ⚡ Cuándo Activar esta Habilidad

Activa esta habilidad cuando:
1. El usuario plantee una necesidad de producto o infraestructura (ej: "¿cómo enviamos alertas por WhatsApp?", "¿dónde guardamos imágenes?", "¿podemos automatizar este flujo?").
2. Vayas a proponer crear un nuevo microservicio, base de datos o script desde cero: **debes comprobar primero si la capacidad ya existe en la flota**.
3. Necesites elegir el modelo o entorno de inferencia óptimo según el tamaño del contexto, coste ($0 vs cloud) y nivel de privacidad requerido.
4. Quieras delegar una acción de despliegue o reinicio de contenedores a un agente persistente (como Hermes Agent con su MCP de Coolify).

---

## 🧭 Protocolo de Decisión y Selección

Antes de escribir código o proponer dependencias nuevas, sigue este flujo de 4 pasos:

### Paso 1: Clasificación de la Necesidad
Identifica a qué categoría funcional pertenece la tarea:
- **Automatización / Pipelines**: Orquestación de datos, webhooks, sincronización multi-app.
- **Inferencia LLM / Programación**: Refactorización de código, generación de tests, análisis masivo.
- **Mensajería / Comunicación**: WhatsApp, livechat, tickets de soporte.
- **Infraestructura / Despliegue**: Creación de contenedores, gestión de proxies, bases de datos.
- **Almacenamiento / Media**: Archivos estáticos, backups, almacenamiento de objetos S3.

### Paso 2: Consulta del Catálogo de la Flota
Verifica si el servicio ya está corriendo en alguno de los nodos:

| Categoría | Servicio Disponible | Ubicación / Protocolo | ¿Cuándo Utilizarlo? |
| :--- | :--- | :--- | :--- |
| **Automatización** | **n8n** | `https://n8n.romensuarez.com`<br>• **MCP**: `/mcp-server/http`<br>• **REST API** | • **MCP**: cuando el agente necesita ejecutar flujos ya creados.<br>• **REST API**: cuando se requiere crear/editar workflows vía código. |
| **Mensajería WhatsApp** | **Evolution API** | `https://whatsapp.romensuarez.com` (:8080) | Para enviar alertas automáticas, triggers conversacionales o conectar bots a WhatsApp. |
| **Infraestructura** | **Coolify** | `https://coolify.romensuarez.com`<br>• **Hermes MCP**<br>• Web UI | Para desplegar apps Docker, gestionar variables o delegar a Hermes tareas operativas sin acceso SSH interactivo. |
| **Base de Datos** | **Unified-DB** | `postgresql-p88...` en `oracle` (PostgreSQL 16) | **Regla de oro**: No crear nuevos contenedores PostgreSQL; crear una base adicional dentro de Unified-DB. |
| **Almacenamiento S3** | **MinIO** | `https://cdn.romensuarez.com` (:9000/9001) | Para guardar imágenes, archivos generados o assets sin pagar por almacenamiento S3 de terceros. |
| **Atención Omnicanal**| **Chatwoot** | `https://chatwoot.romensuarez.com` (:3000) | Para hand-off humano de conversaciones iniciadas por agentes. |
| **Chatbots Web** | **Typebot** | `https://typebot-builder.romensuarez.com` | Para formularios conversacionales guiados o portales interactivos. |
| **Google Cloud** | **Service Account** | `google_credentials.json` | Indexación en Google Search Console, lectura/escritura en Google Sheets y Drive. |

### Paso 3: Selección de Inferencia (Matriz de Coste y Privacidad)

| Necesidad | Modelo Recomendado | Entorno / Acceso | Coste |
| :--- | :--- | :--- | :---: |
| **Código privado / confidencial** | `qwen2.5:7b` / `llama3.1:8b` | OpenCode + FreeLLMAPI (`100.77.82.13:3001/v1`) | **$0** (Ollama local en VPS) |
| **Refactor amplio con tool-calling** | `opencode/space-bunny-free` | OpenCode Zen Gateway (1M tokens contexto) | **$0** (Promo gratuita activa) |
| **Volcado masivo de repositorio (>50k líneas)** | `gemini-2.5-pro` / `flash` | Google AI Studio (2M tokens contexto) | **$0** (Free tier) |
| **Búsqueda técnica y scraping profundo** | Perplexity Pro | Web / API Search | Incluido |

---

## 🔒 Reglas de Oro y Seguridad

1. **Secreto Cero en Git**: Nunca registres credenciales o tokens en claro dentro de ningún archivo del repositorio. Refiérelos como variables de entorno (`$N8N_MCP_TOKEN`, `$UNIFIED_KEY`).
2. **Priorizar MCP sobre Webhooks crudos**: Si interactúas con n8n, prefiere el servidor MCP (`/mcp-server/http`) para descubrir y llamar workflows como herramientas estructuradas de IA.
3. **No reinventar almacenamiento ni bases de datos**: Antes de sugerir Supabase, Firebase o AWS S3 de pago, utiliza **Unified-DB (PostgreSQL 16)** o **MinIO (S3)** ya aprovisionados en `oracle`.

---

## 🔄 Gobernanza: Cómo Actualizar el Inventario

Cuando se instale un nuevo servicio en Coolify, se añada un MCP a Hermes o se valide un nuevo modelo de IA:
1. Actualiza `docs/architecture/tool-inventory.md` añadiendo la herramienta a la capa correspondiente.
2. Incrementa la versión menor del documento (ej: de 1.0.0 a 1.1.0).
3. Notifica en el commit de la tarea correspondiente: `docs(tools): add <nueva-herramienta> to tool inventory`.
