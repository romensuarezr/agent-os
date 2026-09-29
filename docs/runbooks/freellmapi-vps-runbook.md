# FreeLLMAPI VPS Runbook — Inferencia Unificada en Nodo Remoto

> Guía operativa y técnica para la administración, consumo y mantenimiento de la pasarela unificada de inferencia FreeLLMAPI desplegada en un nodo de cómputo/worker (`.agents/config/fleet.yaml`).

---

## 1. Arquitectura y Topología de Red

```
[Cliente / Agente / Script]
             │
   Tailscale VPN (Red Privada)
             │
             ▼
 VPS `<worker-node>` (<TAILSCALE_IP>:3001)
 ┌─────────────────────────────────────────────────────────────┐
 │ Contenedor Docker: `freellmapi`                             │
 │  - Base de datos: SQLite (/app/server/data/freeapi.db)      │
 │  - Config: /app/config/freellmapi.config.json               │
 └───────────────────────┬─────────────────────────────────────┘
                         │
        Red Docker Interna (`<worker-node>_default`)
                         │
                         ▼
 Contenedor Docker: `ollama` (http://ollama:11434/v1)
  - llama3.1:8b
  - qwen2.5:7b
  - qwen2.5:3b
                         ▲
                         │ Fallback / Enrutamiento Cloud
   API Providers Externos (Groq, HuggingFace, OpenRouter, Google)
```

### Datos de Infraestructura (parametrizados en `.agents/config/fleet.yaml`)
- **Host Alias**: `<worker-node>` (definido en `.agents/config/fleet.yaml` o `~/.ssh/config`)
- **IP Tailscale**: `<TAILSCALE_IP>`
- **IP Pública**: `<WAN_IP>` (restringida por firewall)
- **Ruta de Despliegue**: `~/freellmapi/` o `/opt/freellmapi/`
- **Contenedor**: `freellmapi` (`ghcr.io/tashfeenahmed/freellmapi:latest`)
- **Puerto de Servicio**: `3001`

---

## 2. Seguridad y Bind Tailscale

Para evitar la exposición accidental de la API o el dashboard de administración a internet público sin control:
1. **Binding Exclusivo**: El puerto 3001 está mapeado estrictamente a la interfaz de Tailscale:
   ```yaml
   ports:
     - "<TAILSCALE_IP>:3001:3001"
   ```
2. Cualquier petición desde internet directo (`<WAN_IP>:3001`) es rechazada inmediatamente a nivel de socket o firewall.
3. El acceso está restringido a máquinas autenticadas dentro de la Tailnet privada.

---

## 3. Autenticación y Clave Unificada (Unified Key)

FreeLLMAPI implementa autenticación Bearer compatible con el estándar OpenAI tanto para consultar modelos (`/v1/models`) como para generar inferencias (`/v1/chat/completions`).

La autenticación se realiza mediante la **Unified API Key** almacenada en la base de datos SQLite del servicio.

### Obtener la Unified API Key en tiempo de ejecución
Desde cualquier máquina con acceso SSH a `<worker-node>`:

```bash
ssh <worker-node> "docker exec freellmapi node -e \"const db = require('better-sqlite3')('/app/server/data/freeapi.db'); console.log(db.prepare(\\\"SELECT value FROM settings WHERE key='unified_api_key'\\\").get().value);\""
```

El token sigue el patrón:
```
freellmapi-[a-f0-9]{48}
```

---

## 4. Conectividad con Ollama Local

FreeLLMAPI y Ollama se ejecutan en el mismo VPS pero en contenedores separados. Para permitir comunicación DNS directa sin depender de la red host o loopback:
- FreeLLMAPI está conectado a la red externa de compose del host.
- Endpoint base configurado en FreeLLMAPI:
  ```
  http://ollama:11434/v1
  ```
- Requisito de FreeLLMAPI para Custom Providers: Requiere un atributo `apiKey` presente (por ejemplo `"apiKey": "ollama"`).

### Modelos Locales Registrados
- `llama-3.1-8b` (`llama3.1:8b`)
- `qwen-2.5-7b` (`qwen2.5:7b`)
- `qwen-2.5-3b` (`qwen2.5:3b`)

---

## 5. Ejemplos de Consumo E2E

### A. Listar modelos disponibles

```bash
UNIFIED_KEY=$(ssh <worker-node> "docker exec freellmapi node -e \"console.log(require('better-sqlite3')('/app/server/data/freeapi.db').prepare(\\\"SELECT value FROM settings WHERE key='unified_api_key'\\\").get().value)\"")

curl -s -H "Authorization: Bearer $UNIFIED_KEY" \
  http://<TAILSCALE_IP>:3001/v1/models | jq '.data[] | {id: .id, owned_by: .owned_by}'
```

### B. Inferencia con Backend Local Ollama (ej. `qwen-2.5-3b`)

```bash
curl -s -X POST http://<TAILSCALE_IP>:3001/v1/chat/completions \
  -H "Authorization: Bearer $UNIFIED_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-2.5-3b",
    "messages": [
      {"role": "user", "content": "¿Cuál es la capital de Francia?"}
    ],
    "max_tokens": 50
  }' | jq
```

**Respuesta verificada:**
```json
{
  "id": "chatcmpl-demo",
  "object": "chat.completion",
  "model": "qwen2.5:3b",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "La capital de Francia es París."
      },
      "finish_reason": "stop"
    }
  ],
  "_routed_via": {
    "platform": "custom",
    "model": "qwen2.5:3b"
  }
}
```

### C. Inferencia con Enrutamiento Dinámico Cloud (`model: "auto"`)

```bash
curl -s -X POST http://<TAILSCALE_IP>:3001/v1/chat/completions \
  -H "Authorization: Bearer $UNIFIED_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "auto",
    "messages": [
      {"role": "user", "content": "Genera una lista de 3 frutas"}
    ],
    "max_tokens": 50
  }' | jq
```

### D. Uso con SDK de OpenAI (Python)

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://<TAILSCALE_IP>:3001/v1",
    api_key="freellmapi-<UNIFIED_KEY>",
)

response = client.chat.completions.create(
    model="qwen-2.5-3b", # o "auto" para balanceo automático cloud
    messages=[{"role": "user", "content": "Hola desde agent-os"}],
)

print(response.choices[0].message.content)
```

---

## 6. Operaciones de Mantenimiento y Ciclo de Vida

### Iniciar o reiniciar el contenedor
```bash
ssh <worker-node> "cd ~/freellmapi && docker compose restart freellmapi"
```

### Ver logs en tiempo real
```bash
ssh <worker-node> "docker logs -f --tail 100 freellmapi"
```

### Comprobar estado de salud
```bash
ssh <worker-node> "docker ps --filter name=freellmapi --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
```

### Actualizar configuración declarativa
1. Editar `~/freellmapi/config/freellmapi.config.json` en `<worker-node>`.
2. Reiniciar el contenedor: `docker compose restart freellmapi`.
3. Validar logs: Buscar la línea `[config] applied /app/config/freellmapi.config.json: ...`.
