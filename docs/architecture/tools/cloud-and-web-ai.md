# ☁️ Capa 4: Cloud, Web AI e Integraciones Externas

> **Ámbito**: Servicios en la nube, APIs de terceros y plataformas de inferencia masiva  
> **Propósito**: Tareas de investigación profunda, contextos masivos (>1M tokens) e integraciones con servicios globales.

---

## 1. Google AI Studio (Ventana Masiva de 2M Tokens)

- **Acceso**: Consola Web de Google AI Studio / API en Free Tier.
- **Modelos**: Gemini 2.5 Pro y Gemini 2.5 Flash.
- **Ventana de Contexto**: **2.000.000 de tokens** (la mayor capacidad de ingesta de la flota).
- **Casos de Uso Óptimos para el Agente**:
  - **Volcado completo de repositorios**: Uso combinado de `gitingest <repo>` + Gemini 2.5 Pro para analizar bases de código completas en un único prompt.
  - **Auditorías arquitectónicas cross-repositorio**: Ingesta simultánea de múltiples proyectos para detectar duplicidades e inconsistencias.
  - **Análisis multimodal**: Ingesta masiva de documentación técnica, esquemas y bases de conocimiento.

---

## 2. Perplexity Pro (Investigación Técnica y Benchmarking)

- **Acceso**: Interfaz Web / Pro Search / API.
- **Capacidades**:
  - Búsqueda en tiempo real cruzando múltiples fuentes técnicas con citación estricta de URLs.
  - Búsqueda profunda de changelogs, breaking changes y comparativas de librerías.
- **Casos de Uso Óptimos**:
  - Investigación previa de sprint (`sprint-XX-research.md`).
  - Benchmarking de dependencias y alternativas OSS cuando `scout.sh` requiere mayor contraste cualitativo.
  - Diagnóstico de errores de compilación o incompatibilidades de paquetes recientes.

---

## 3. OpenCode Zen Gateway (`opencode/space-bunny-free`)

- **Acceso**: CLI directo mediante `opencode run -m opencode/space-bunny-free "<prompt>"`.
- **Modelo Subyacente**: MiniMax M3.1.
- **Ventana de Contexto**: **1.048.576 tokens (1 Millón de tokens)**.
- **Coste**: **$0.00** (Promo gratuita activa en OpenCode).
- **Capacidades Validadas**:
  - Tool-calling nativo (lectura, edición de archivos y ejecución de terminal con Bash).
  - Autodescubrimiento de skills locales en `.agents/skills/`.
  - Latencia reducida (~30s frente a inferencia local pura en CPU).

---

## 4. Google Cloud Service Account

- **Credenciales**: Centralizadas en gestor de secretos o `google_credentials.json` (fuera del control de versiones).
- **Librería**: `google-api-python-client`.
- **Servicios Habilitados Típicos**:
  - **Google Search Console**: Indexación y monitoreo de URLs vía API.
  - **Google Sheets**: Lectura y escritura programática para pipelines de datos y métricas.
  - **Google Drive**: Almacenamiento y sincronización de reportes.

---

## 5. Cloudflare (Edge, DNS y Storage)

- **Zona DNS**: Administrada vía Cloudflare Dashboard / API.
- **Servicios Típicos**:
  - **DNS & WAF**: Proxy activado con SSL Full/Strict hacia los proxies inversos de los nodos SaaS.
  - **Cloudflare R2**: Almacenamiento de objetos S3 sin costes de salida de datos (egress fees), óptimo para backups programados de bases de datos.
