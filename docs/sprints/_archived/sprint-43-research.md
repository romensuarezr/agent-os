# Research Sprint 43 — 2026-11-18
> Fuentes reales: Base de Datos de Coolify (`coolify-db` en `<nodo-orquestacion>`) + Traefik Dynamic Configs (`/data/coolify/proxy/dynamic/`) + Búsqueda Soberana SearXNG (`http://searxng-lswo0woww0sswwsk0wkcc4o0.<nodo-orquestacion-ip>.sslip.io`) + Activos Internos de Agent OS (`.agents/config/fleet.yaml`, `scripts/agent/generate-homepage-config.sh`, `docs/runbooks/glances-setup.md`) + Sonda OSS Scout ($0 tokens).
> Tarea principal: Puesta a punto integral del panel de control Homepage (`http://g8o4sgwsw8k4c0cscoskkks8.<nodo-orquestacion-ip>.sslip.io/`), integración del stack completo verificado en Coolify y despliegue de telemetría de hardware en VPS DataManager.

---

## Inventario Empírico del Stack en Coolify (Evidencia Directa de DB y Traefik)

### 1. Panel de Control & PaaS
- **Homepage Dashboard**: `http://g8o4sgwsw8k4c0cscoskkks8.<nodo-orquestacion-ip>.sslip.io/` (puerto interno 3000)
- **Coolify Console**: `https://coolify.romensuarez.com` (operativo HTTPS con Let's Encrypt / puerto 8000)
- **Nango Unified OAuth**: `http://<TAILSCALE_IP_ORACLE>:3009` (Connect UI) / `http://<TAILSCALE_IP_ORACLE>:3003` (API)
- **Infisical Backend**: `http://backend-vcg80040ogcgsskkw08k48w4.<nodo-orquestacion-ip>.sslip.io:8080`

### 2. Inferencia IA & Gateways ($0) en DataManager VPS (`<TAILSCALE_IP_DATAMANAGER>`)
- **FreeLLMAPI**: `http://<TAILSCALE_IP_DATAMANAGER>:3001` (ping `/health`)
- **OmniRoute Gateway**: `http://<TAILSCALE_IP_DATAMANAGER>:20128` (ping `/`)
- **Open-WebUI**: `http://<TAILSCALE_IP_DATAMANAGER>:3005`
- **Ollama**: `http://<TAILSCALE_IP_DATAMANAGER>:11434`
- **Glances Telemetry (Pendiente)**: `http://<TAILSCALE_IP_DATAMANAGER>:61208` (despliegue en T-229)

### 3. Herramientas de Productividad, Automatización y Operación
- **SearXNG Meta-Search**: `http://searxng-lswo0woww0sswwsk0wkcc4o0.<nodo-orquestacion-ip>.sslip.io`
- **n8n Automation**: `https://n8n.romensuarez.com`
- **Umami Analytics**: `https://umami.romensuarez.com`
- **ByteBox Snippets & CLI**: `https://bytebox.romensuarez.com`
- **Ghost Blog**: `https://blog.romensuarez.com`
- **WhatsApp Bridge (Evolution API)**: `https://whatsapp.romensuarez.com`
- **Twenty CRM**: `http://j44wc80o8oc04w08880sgw00.<nodo-orquestacion-ip>.sslip.io`
- **Calibre Web**: `http://calibre-fggk84oowsw888cw4sgcc8k4.<nodo-orquestacion-ip>.sslip.io:8083` (y descargas `downloader-ewgsk0k0004gwswogks088gc.<nodo-orquestacion-ip>.sslip.io:8084`)

### 4. Productos & Satélites Desplegados
- **Outbid (Leaderboard Web)**: `https://outbid.romensuarez.com` (Staging: `http://bs84c08s40c0sooc8kgoc08k.<nodo-orquestacion-ip>.sslip.io`)
- **Kanarii Web**: `http://lwwcgo8kggokcwcgc0kkk0kc.<nodo-orquestacion-ip>.sslip.io`
- **Finca Adama**: `https://fincaadama.com`
- **HD-API**: `https://hd-api.romensuarez.com`
- **Bots de Trading/Ejecución (Background)**: Polybot (`ps0cw4s8w4c4skgsgkoc4kg8`), Polybot Staging (`oo08o8k4sgookokgcskgc084`), Bot3 Multimoneda (`zk8csgs040w8wscg4wwgs0oo`)

---

## Descubrimientos Scout (por tarea)

### T-228: Sincronización Integral del Inventario de Servicios en `fleet.yaml`
- **Alternativas detectadas**: Consulta en caliente a la API de Coolify por cada render de Homepage vs Modelo declarativo en `.agents/config/fleet.yaml` compilado estáticamente.
- **Recomendación**: Mantener el principio declarativo de Agent OS. `fleet.yaml` actúa como la fuente de verdad del inventario de la flota, versionada en git y enriquecida con los metadatos auditados de Coolify.

### T-229: Despliegue de Telemetría Glances en VPS DataManager vía Tailscale
- **Alternativas detectadas**: `nicolargo/glances` (33.978⭐, Docker Compose con bind exclusivo a Tailscale IP `<TAILSCALE_IP_DATAMANAGER>:61208`).
- **Recomendación**: Despliegue con `templates/homepage/glances-compose.yml` ejecutado en `<nodo-inferencia>` sin tocar WAN pública (ADR 004).

### T-230: Reestructuración Modular de `generate-homepage-config.sh` para Soporte Completo del Stack
- **Alternativas detectadas**: Grupos monolíticos vs categorización clara (IA, Control/PaaS, Productividad/Dev, Productos/Satélites, Bots) con widgets de recursos multi-host (Oracle VPS local + DataManager VPS vía Glances).
- **Recomendación**: Actualizar el generador determinista para compilar todas las tarjetas activas auditadas, con saneamiento de pings y configuración adecuada de bookmarks.

### T-231: Despliegue en Vivo y Verificación del Panel Homepage en VPS Oracle
- **Alternativas detectadas**: Despliegue manual vs sincronización remota automatizada sobre el volumen Docker persistente de Coolify con backup fechado previo y verificación de URLs.

### T-232: Homologación de Tooling de Flota (OpenCode, Hermes, Orca, Infisical)
- **Alternativas detectadas**: Bump aislado vs alineación consolidada en scripts y catálogo.
- **Recomendación**: Consolidación atómica de versiones reportadas por la sonda.

---

## Investigación Técnica y Fuentes

### T-228 y T-230: Estructura Óptima de Servicios y Grupos en Homepage
- **Consultas SearXNG**: `gethomepage services bookmarks yaml configuration`, `gethomepage homepage glances widget configuration`.
- **Referencias clave**:
  - [Bookmarks - Homepage - gethomepage.dev](https://gethomepage.dev/configs/bookmarks/)
  - [Services - Homepage - gethomepage.dev](https://gethomepage.dev/configs/services/)
  - [Glances Information Widget - Homepage.dev](https://gethomepage.dev/widgets/info/glances/)
- **Decisión de Maquetación**:
  - `AI Gateways & Inferencia ($0)`: FreeLLMAPI, OmniRoute, Open-WebUI, Ollama.
  - `PaaS, Infraestructura & Control Plane`: Coolify (`https://coolify.romensuarez.com`), Nango OAuth, Infisical, Homepage.
  - `Productividad, Automatización & Búsqueda`: SearXNG, n8n, Umami, ByteBox, Ghost, WhatsApp Bridge, Twenty CRM, Calibre Web.
  - `Aplicaciones Satélite & Productos`: Outbid, Kanarii, Finca Adama, HD-API, Polybot & Bot3.
  - `Cabecera (widgets.yaml)`: Buscador DuckDuckGo + Widget Local `resources` (Oracle VPS) + Widget Remoto `glances` (DataManager VPS).
