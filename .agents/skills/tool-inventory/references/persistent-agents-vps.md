# 🤖 Capa 2: VPS `datamanager` (Agentes Persistentes e Inferencia)

> **Ámbito**: Servidor de backend para agentes continuos 24/7 e inferencia privada local  
> **Acceso**: `ssh datamanager` | IP Tailscale: `100.77.82.13` (puerto aislado)

---

## 1. Hermes Agent 24/7

- **Tipo**: Servicio systemd (`hermes-gateway.service`).
- **Función**: Agente conversacional persistente con capacidad de atención ininterrumpida por WhatsApp y webhooks.
- **MCP de Coolify Instalado**:
  - Hermes Agent cuenta con un **servidor MCP de Coolify preconfigurado**, lo que le permite consultar el estado de los contenedores en `oracle`, verificar despliegues y desencadenar operaciones de infraestructura de forma autónoma sin requerir accesos SSH interactivos manuales.
- **Pipeline HITL (Human-in-the-Loop)**:
  - Encolado de solicitudes en estado `pending_approval` hacia la orquestación de Orca para operaciones sensibles (L3).

---

## 2. FreeLLMAPI (Pasarela OpenAI-Compatible de Coste Cero)

- **Endpoint**: `http://100.77.82.13:3001/v1`
- **Autenticación**: `Authorization: Bearer $UNIFIED_KEY`
  - Clave unificada almacenada en SQLite (`/app/server/data/freeapi.db`).
- **Seguridad**: El puerto 3001 está mapeado exclusivamente a la IP de Tailscale (`100.77.82.13:3001:3001`). Cualquier acceso desde internet público es descartado a nivel de socket.

### Modelos Locales Validados (Backend Ollama)

| Modelo en FreeLLMAPI | Tamaño | Tool-Calling Nativo | Latencia CPU | Caso de Uso |
| :--- | :---: | :---: | :---: | :--- |
| **`qwen2.5:7b`** | 4.7 GB | ✅ Sí (`tool_calls` OpenAI) | 20s - 200s | Generación de código, refactorización y resolución de tests con OpenCode. |
| **`llama3.1:8b`** | 4.9 GB | ✅ Sí (`tool_calls` OpenAI) | 20s - 180s | Razonamiento estructurado, extracción de datos y decisiones lógicas. |
| **`qwen2.5:3b`** | 1.9 GB | ⚠️ No recomendado para tools | 5s - 15s | Respuestas conversacionales rápidas y tareas de clasificación ligera. |
| **`mistral-nemo:12b`** | 7.1 GB | ✅ Sí | 40s - 250s | Tareas complejas de lenguaje natural. |

> [!IMPORTANT]
> **Mitigación de Timeouts en CPU**: Al llamar a FreeLLMAPI desde clientes externos (OpenCode, scripts Python), configurar siempre un `timeout` de lectura mínimo de **180 a 300 segundos**.

---

## 3. Qdrant Vector Database & Memoria Semántica

- **Endpoint**: `http://100.77.82.13:6333`
- **Contenedor**: `datamanager-qdrant-1`
- **Uso**:
  - Almacenamiento de embeddings vectoriales para búsqueda semántica.
  - Memoria asociativa de largo plazo para Hermes Agent.
  - Soporte para pipelines RAG (Retrieval-Augmented Generation).
