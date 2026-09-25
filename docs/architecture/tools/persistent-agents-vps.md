# 🤖 Capa 2: Worker Nodes (Agentes Persistentes e Inferencia Local)

> **Ámbito**: Nodos de cómputo dedicados a agentes continuos 24/7 e inferencia de modelos locales sin coste de API  
> **Acceso**: Conexión vía VPN Mesh (ej. Tailscale `100.x.y.z`) o SSH a host de computación  
> **Configuración Activa**: Consultar la sección `nodes` en `config/fleet.yaml`

---

## 1. Hermes Agent 24/7

- **Tipo**: Servicio daemon / systemd (`hermes-gateway.service`).
- **Función**: Agente conversacional persistente con capacidad de atención ininterrumpida por canales de mensajería (WhatsApp, Telegram) y webhooks.
- **MCP para PaaS / Despliegues**:
  - Hermes Agent puede contar con un **servidor MCP de integración con el gestor PaaS** (ej. Coolify), lo que le permite consultar el estado de contenedores en nodos remotos, verificar despliegues y desencadenar operaciones de infraestructura de forma autónoma sin accesos SSH interactivos manuales.
- **Pipeline HITL (Human-in-the-Loop)**:
  - Encolado de solicitudes en estado `pending_approval` hacia la orquestación de Orca para operaciones sensibles (L3).

---

## 2. FreeLLMAPI (Pasarela OpenAI-Compatible a Coste Cero)

- **Endpoint Típico**: `http://<worker-node-ip>:3001/v1`
- **Autenticación**: `Authorization: Bearer $UNIFIED_KEY` (definida en el nodo local/remoto).
- **Seguridad**: Se recomienda exponer el puerto exclusivamente a interfaces de red privadas (Tailscale, WireGuard o LAN). El tráfico desde internet público debe ser descartado a nivel de socket.

### Modelos Locales Validados (Backend Ollama / vLLM)

| Modelo en FreeLLMAPI | Tamaño | Tool-Calling Nativo | Latencia CPU | Caso de Uso |
| :--- | :---: | :---: | :---: | :--- |
| **`qwen2.5:7b`** | ~4.7 GB | ✅ Sí (`tool_calls` OpenAI) | 20s - 200s | Generación de código, refactorización y resolución de tests con OpenCode. |
| **`llama3.1:8b`** | ~4.9 GB | ✅ Sí (`tool_calls` OpenAI) | 20s - 180s | Razonamiento estructurado, extracción de datos y decisiones lógicas. |
| **`qwen2.5:3b`** | ~1.9 GB | ⚠️ No recomendado para tools | 5s - 15s | Respuestas conversacionales rápidas y tareas de clasificación ligera. |
| **`mistral-nemo:12b`** | ~7.1 GB | ✅ Sí | 40s - 250s | Tareas complejas de lenguaje natural. |

> [!IMPORTANT]
> **Mitigación de Timeouts en Inferencia Local**: Al invocar FreeLLMAPI desde clientes externos (OpenCode, scripts Python), configurar siempre un `timeout` de lectura mínimo de **180 a 300 segundos** para contextos amplios.

---

## 3. Base de Datos Vectorial (Qdrant / Chroma)

- **Endpoint Típico**: `http://<worker-node-ip>:6333`
- **Uso**:
  - Almacenamiento de embeddings vectoriales para búsqueda semántica.
  - Memoria asociativa de largo plazo para agentes autónomos.
  - Soporte para pipelines RAG (Retrieval-Augmented Generation).
