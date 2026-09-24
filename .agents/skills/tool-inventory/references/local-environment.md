# 💻 Capa 1: Host Local & Consola (`inteligencia-colectiva`)

> **Ámbito**: Herramientas locales instaladas en la máquina de desarrollo (`~` / `$HOME`)  
> **Propósito**: Ejecución interactiva, pair programming, desarrollo CLI y orquestación supervisada.

---

## 1. IDEs y Agentes de Pair Programming

| Herramienta | Binario / Comando | Ubicación Típica | Capacidades Clave |
| :--- | :--- | :--- | :--- |
| **Antigravity IDE** | `antigravity` | `~/apps/Antigravity-x64/antigravity` | Entorno de desarrollo interactivo de agentes de IA con inspección de contexto y subagentes. |
| **Antigravity CLI** | `agy`, `agy2` | `~/.local/bin/agy` | Cliente CLI para ejecutar instrucciones, slash commands y gestionar proyectos en terminal. |
| **Orca Desktop** | `orca-ide` | `/opt/Orca/resources/bin/orca-ide` | Orquestador de agentes. Base SQLite local `orchestration.db` (en modo solo lectura para agentes), validación de Decision Gates (L3) y supervisión de relays remotos. |
| **Hermes Local** | `hermes`, `hermes-acp` | `~/.local/bin/hermes` | Cliente del protocolo Agent Client Protocol (ACP) y nodo local de Hermes. |
| **OpenCode CLI** | `opencode` | `~/.opencode/bin/opencode` (v1.3.9) | Agente autónomo de terminal para edición de código y tests. Integra FreeLLMAPI local y promo cloud `space-bunny-free` ($0). |

---

## 2. Herramientas CLI y Utilidades en `~/.local/bin`

| Binario | Propósito | Cuándo Usarlo |
| :--- | :--- | :--- |
| **`uv` / `uvx`** | Gestor ultrarrápido de paquetes y entornos virtuales Python (escrito en Rust). | Instalar dependencias Python o ejecutar herramientas efímeras sin alterar el entorno global (`uvx <tool>`). |
| **`gitingest`** | Extractor CLI de repositorios para LLMs. | Volcar directorios o repositorios enteros en un archivo único formateado para ser analizado por un modelo de IA. |
| **`gh`** | GitHub CLI oficial. | Búsquedas deterministas de repositorios, issues y releases a 0 tokens de inferencia. |
| **`scout.sh`** | Script determinista de prospección pre-código (`scripts/agent/scout.sh`). | Buscar librerías en GitHub, npm y PyPI simultáneamente antes de escribir código. |
| **`audit-host.sh`** | Diagnóstico no destructivo de VPS (`scripts/agent/audit-host.sh`). | Inspeccionar espacio en disco, contenedores Docker y puertos abiertos en `oracle` y `datamanager`. |
| **`check-git-remote.sh`** | Verificador de autenticación SSH (`scripts/agent/check-git-remote.sh`). | Validar conectividad SSH con GitHub en servidores remotos. |
| **`huggingface-cli`** | Cliente de Hugging Face. | Descargar modelos, datasets o comprobar estado de tokens de Hugging Face. |
| **`chroma`** | ChromaDB local. | Base de datos vectorial ligera en memoria o archivo para pruebas locales de embeddings. |
| **`pytest` / `pyright`** | Testing y tipado estático Python. | Validación de suites de tests y comprobación estricta de tipos. |

---

## 3. Catálogo de Repositorios Hermanos (`~/Proyectos/`)

Directorio raíz de proyectos donde existen scripts, arquitecturas previas y código de producción:

| Repositorio | Descripción / Stack | Utilidades Reutilizables |
| :--- | :--- | :--- |
| **`agent-os`** | Core del sistema operativo de agentes. | Workflows, skills, scripts de ciclo de vida (`sync.sh`, `install.sh`, `close-task.sh`). |
| **`Agencia_IA`** | Monorepo de producción de servicios de IA y SEO. | Contexto de infraestructura (`.agent/context/infrastructure.md`), cliente n8n (`agents/integrations/n8n_client.py`), scripts de automatización Google. |
| **`n8n-backups`** | Backups y exportaciones de workflows de n8n. | Definiciones JSON de flujos existentes en producción. |
| **`romensuarez-web`** | Sitio web personal y portafolio. | Next.js / Astro, despliegues en Coolify. |
| **`kanairos` / `kanarii`** | Plataformas de agentes y proyectos de producto. | Integraciones y plantillas de frontend/backend. |
| **`polymarket`** | Bots e integraciones de predicción. | Scripts de monitoreo y APIs financieras. |
| **`seedbox`** | Configuración de descargas en VPS `oracle`. | Docker-compose de qBittorrent y utilidades de almacenamiento. |
| **`bot3-multimoneda`** | Bots de trading y trading multimoneda. | Conectores a exchanges y lógica de trading. |
