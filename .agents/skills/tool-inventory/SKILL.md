---
name: tool-inventory
description: Consulta, selecciona y aprovecha el catálogo de herramientas activas de la flota (local, nodos remotos, web AI y MCPs) leyendo dinámicamente config/fleet.yaml antes de desarrollar soluciones desde cero.
---

# 🛠️ Tool Inventory (Inventario Activo de la Flota)

Esta habilidad permite a cualquier agente de **Agent OS** descubrir, evaluar y reutilizar el ecosistema de herramientas, nodos de computación, servidores MCP y servicios en la nube configurados para la flota activa.

Su objetivo es evitar la duplicación de esfuerzos, prevenir costes innecesarios de APIs externas y aprovechar capacidades operativas avanzadas ya desplegadas (como pasarelas OpenAI-compatibles a coste $0, servidores MCP de infraestructura, mensajería y almacenamiento S3).

---

## ⚡ Dinámica de Carga: La Fuente de Verdad es `config/fleet.yaml`

El agente **DEBE** seguir este orden prioritario para obtener el estado y las direcciones de la infraestructura:

1. **Lectura Prioritaria Dinámica (`config/fleet.yaml`)**:
   - Comprueba si existe el archivo de configuración privado `config/fleet.yaml` en la raíz del proyecto.
   - Si existe: extrae de allí las herramientas instaladas localmente (`local_environment`), los nodos activos (`nodes`), los servidores MCP registrados (`mcpServers`) y las políticas de inferencia (`routing`).
2. **Fallback y Guía de Inicialización (`config/fleet.example.yaml`)**:
   - Si `config/fleet.yaml` no existe en la máquina:
     - Consulta la plantilla de referencia `config/fleet.example.yaml`.
     - Informa al usuario: *"💡 No se ha detectado `config/fleet.yaml`. Puedes crear uno ejecutando `cp config/fleet.example.yaml config/fleet.yaml` o mediante `bash scripts/agent/discover-fleet.sh` para auto-descubrir tu entorno."*

---

## 📖 Documentación Arquitectónica y Catálogos Humanos (`docs/architecture/tools/`)

Para consultar o auditar la arquitectura en formato legible por personas, consulta los documentos de diseño en el repositorio:
- **Hub Central**: [docs/architecture/tool-inventory.md](../../../docs/architecture/tool-inventory.md)
- **Capa 1 (Local & Consola)**: `docs/architecture/tools/local-environment.md`
- **Capa 2 (Worker Nodes)**: `docs/architecture/tools/persistent-agents-vps.md`
- **Capa 3 (SaaS Nodes)**: `docs/architecture/tools/saas-infrastructure-vps.md`
- **Capa 4 (Cloud & Web AI)**: `docs/architecture/tools/cloud-and-web-ai.md`

> [!NOTE]
> Esta skill es 100% portable y ligera. No contiene subcarpetas de referencias estáticas para no sobrecargar los proyectos hijos durante la sincronización (`sync.sh`). Toda la información operativa de runtime se extrae de `config/fleet.yaml`.


---

## 🧭 Protocolo de Decisión y Selección

Antes de escribir código, desplegar contenedores o instalar librerías pesadas, sigue este flujo de 3 pasos:

### Paso 1: Clasificación de la Necesidad
- **Automatización / Pipelines**: Webhooks, sincronización multi-app, eventos programados.
- **Inferencia LLM / Programación**: Refactorización de código, generación de tests, análisis masivo.
- **Mensajería / Notificaciones**: Canales de mensajería (WhatsApp, Telegram), webhooks de alerta.
- **Infraestructura / Despliegue**: Creación de contenedores, proxies inversos, bases de datos.
- **Almacenamiento / Media**: Archivos estáticos, backups, objetos S3.

### Paso 2: Consulta Dinámica de la Flota
Verifica si el servicio ya existe leyendo `config/fleet.yaml`:

| Categoría | Servicio Típico | Protocolo / Acceso Recomendado | ¿Cuándo Utilizarlo? |
| :--- | :--- | :--- | :--- |
| **Automatización** | **n8n** | `nodes.<saas-node>.services.n8n`<br>• **MCP**: `/mcp-server/http`<br>• **REST API** | • **MCP**: ejecutar flujos ya creados.<br>• **REST API**: crear/editar workflows programáticamente. |
| **Mensajería** | **Evolution API** | `nodes.<saas-node>.services.evolution` | Alertas automáticas o bots conversacionales. |
| **Infraestructura** | **Coolify** | `nodes.<saas-node>.services.coolify`<br>• **MCP de Despliegue** | Desplegar apps Docker o gestionar variables sin SSH interactivo. |
| **Base de Datos** | **Unified-DB** | PostgreSQL unificada en nodo PaaS | **Regla**: Reutilizar la base unificada; no instanciar contenedores PostgreSQL adicionales. |
| **Almacenamiento** | **MinIO / S3** | `nodes.<saas-node>.services.minio` | Guardar imágenes o assets sin costes de almacenamiento comercial. |
| **Modelos Locales** | **FreeLLMAPI** | `nodes.<worker-node>.services.freellmapi` | Inferencia privada y autónoma a coste $0 con tool-calling. |

### Paso 3: Selección de Inferencia (Matriz de Coste y Privacidad)

| Necesidad | Modelo Recomendado | Entorno / Acceso | Coste |
| :--- | :--- | :--- | :---: |
| **Código local / confidencial** | `qwen2.5:7b` / `llama3.1:8b` | OpenCode + FreeLLMAPI local (`routing.default_local_llm_endpoint`) | **$0** (Inferencia local) |
| **Refactor amplio con tool-calling** | `opencode/space-bunny-free` | OpenCode Zen Gateway (1M tokens contexto) | **$0** (Promo gratuita) |
| **Volcado masivo de repositorio (>50k líneas)** | `gemini-2.5-pro` / `flash` | Google AI Studio (2M tokens contexto) | **$0** (Free tier) |
| **Búsqueda técnica y scraping profundo** | Perplexity Pro | Web / API Search | Incluido |

---

## 🔒 Reglas de Oro y Seguridad

1. **Secreto Cero en Git**: Nunca registres credenciales o tokens en claro en archivos versionados. Úsalos vía variables de entorno (`$N8N_MCP_TOKEN`, `$UNIFIED_KEY`) o en el archivo ignorado `config/fleet.yaml`.
2. **Priorizar MCP sobre Webhooks crudos**: Para interactuar con orquestadores (como n8n o Coolify), prefiere la especificación estandarizada MCP.
3. **No reinventar infraestructura**: Antes de instalar nuevas dependencias de bases de datos o servicios de almacenamiento, reutiliza los servicios ya aprovisionados en la flota.

---

## 🔄 Gobernanza: Cómo Actualizar el Inventario

1. Al instalar un nuevo servicio o conectar un nuevo nodo: actualiza `config/fleet.yaml` localmente.
2. Si descubres nuevas herramientas instaladas en la máquina local: ejecuta `bash scripts/agent/discover-fleet.sh` (disponible desde T-046).
3. Si el cambio introduce un nuevo patrón de arquitectura reusable: documéntalo en `config/fleet.example.yaml` y en las referencias de esta skill.
