# 💻 Capa 1: Host Local & Consola de Desarrollo

> **Ámbito**: Herramientas locales instaladas en la máquina de desarrollo (`$HOME` / `~`)  
> **Propósito**: Ejecución interactiva, pair programming, desarrollo en terminal y orquestación supervisada.

---

## 1. IDEs y Agentes de Pair Programming

| Herramienta | Binario / Comando | Ubicación Típica | Capacidades Clave |
| :--- | :--- | :--- | :--- |
| **Antigravity IDE** | `antigravity` | `~/apps/Antigravity/antigravity` | Entorno de desarrollo interactivo de agentes de IA con inspección de contexto y subagentes. |
| **Antigravity CLI** | `agy`, `agy2` | `~/.local/bin/agy` | Cliente CLI para ejecutar instrucciones, slash commands y gestionar proyectos en terminal. |
| **Orca Desktop** | `orca-ide` | `/opt/Orca/resources/bin/orca-ide` | Orquestador de agentes. Base SQLite local `orchestration.db` (en modo solo lectura para agentes), validación de Decision Gates (L3) y supervisión de relays remotos. |
| **Hermes Local** | `hermes`, `hermes-acp` | `~/.local/bin/hermes` | Cliente del protocolo Agent Client Protocol (ACP) y nodo local de Hermes. |
| **OpenCode CLI** | `opencode` | `~/.opencode/bin/opencode` | Agente autónomo de terminal para edición de código y tests. Integra FreeLLMAPI local y promo cloud `space-bunny-free` ($0). |

---

## 2. Herramientas CLI y Utilidades en PATH (`~/.local/bin`, `/usr/local/bin`)

| Binario | Propósito | Cuándo Usarlo |
| :--- | :--- | :--- |
| **`uv` / `uvx`** | Gestor ultrarrápido de paquetes y entornos virtuales Python (escrito en Rust). | Instalar dependencias Python o ejecutar herramientas efímeras sin alterar el entorno global (`uvx <tool>`). |
| **`gitingest`** | Extractor CLI de repositorios para LLMs. | Volcar directorios o repositorios enteros en un archivo único formateado para ser analizado por un modelo de IA. |
| **`gh`** | GitHub CLI oficial. | Búsquedas deterministas de repositorios, issues y releases a 0 tokens de inferencia. |
| **`scout.sh`** | Script determinista de prospección pre-código (`scripts/agent/scout.sh`). | Buscar librerías en GitHub, npm y PyPI simultáneamente antes de escribir código. |
| **`audit-host.sh`** | Diagnóstico no destructivo de hosts remotos (`scripts/agent/audit-host.sh`). | Inspeccionar espacio en disco, contenedores Docker y puertos abiertos en nodos remotos. |
| **`check-git-remote.sh`** | Verificador de autenticación SSH (`scripts/agent/check-git-remote.sh`). | Validar conectividad SSH con GitHub en servidores remotos. |
| **`huggingface-cli`** | Cliente de Hugging Face. | Descargar modelos, datasets o comprobar estado de tokens de Hugging Face. |
| **`chroma`** | ChromaDB local. | Base de datos vectorial ligera en memoria o archivo para pruebas locales de embeddings. |
| **`pytest` / `pyright`** | Testing y tipado estático Python. | Validación de suites de tests y comprobación estricta de tipos. |

---

## 3. Descubrimiento Dinámico de Repositorios y Proyectos Locales

Los agentes pueden descubrir workspaces hermanos consultando el directorio común de proyectos (típicamente `~/Proyectos` o `$WORKSPACE_DIR` definido en el entorno).

| Patrón de Proyecto | Propósito Típico | Utilidades Reutilizables |
| :--- | :--- | :--- |
| **`agent-os`** | Core del sistema operativo de agentes. | Workflows, skills, scripts de ciclo de vida (`sync.sh`, `install.sh`, `close-task.sh`, `scout.sh`). |
| **Monorepos de Servicios** | Aplicaciones en producción, clientes API y scripts. | Módulos de automatización, scripts de integraciones y contextos de infraestructura. |
| **Repositorios de Flujos / Backups** | Definiciones de pipelines (ej: n8n). | Workflows JSON listos para exportar o importar. |
| **Frontends / Portafolios** | Sitios web y aplicaciones Next.js, Astro, React. | Configuraciones Dockerfile, pipelines CI/CD y despliegues PaaS. |

> [!TIP]
> Para conocer el inventario real y actualizado de binarios y repositorios en la máquina actual, consulta la sección `local_environment` de `config/fleet.yaml` o ejecuta el script de auto-descubrimiento (`scripts/agent/discover-fleet.sh`).
