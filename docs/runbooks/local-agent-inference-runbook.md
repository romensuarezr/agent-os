# Runbook: Inferencia Local de Agentes vía Pasarelas en Tailscale ($0)

> Guía verificada para configurar y diagnosticar agentes locales (Hermes Agent y OpenCode CLI) consumiendo pasarelas de inferencia OpenAI-compatible alojadas en la malla privada de Tailscale, con coste cero y rotación automática de proveedores.
>
> **Estado de la evidencia**: todo lo afirmado aquí se comprobó con peticiones reales contra la flota. Donde algo no funciona, se dice explícitamente.

---

## 1. Topología

```
[Cliente local: Hermes / OpenCode]
        │
        ▼  red privada Tailscale (interfaz tailscale0)
┌──────────────────────────────────────────────────────────────┐
│  Nodo gateway  (<GATEWAY_HOST> = MagicDNS del tailnet)       │
│                                                              │
│  ├── FreeLLMAPI   http://<GATEWAY_HOST>:3001/v1   (primaria)  │
│  │     ├── model "auto"  → rota entre Google, Groq, OpenRouter,│
│  │     │                  HuggingFace, Zhipu y Ollama local   │
│  │     └── clave propia:  unified_api_key (NO es la de OmniRoute)
│  │                                                           │
│  ├── OmniRoute    http://<GATEWAY_HOST>:20128/v1  (respaldo)  │
│  │     ├── "auto/best-free"   → operativo                     │
│  │     ├── "auto/cheap"       → operativo                     │
│  │     └── "auto/best-coding" → ROTO (ver §4)                 │
│  │                                                           │
│  └── tailscale serve  https://<GATEWAY_HOST>/ → :20128        │
│        ⚠ proxyea solo a OmniRoute; nunca a FreeLLMAPI         │
└──────────────────────────────────────────────────────────────┘
```

### Cómo resolver `<GATEWAY_HOST>` sin hardcodear nada

```bash
tailscale status              # lista nodos, IPs y nombre MagicDNS
tailscale ip -4               # IP del propio cliente
```

Este runbook no versiona ni IP ni nombre de nodo: `<GATEWAY_HOST>` se resuelve en tiempo de ejecución. El nombre MagicDNS real aparece enmascarado (`ts.*`) porque así lo emite el script de pre-flight.

> [!TIP]
> Usa siempre el **nombre MagicDNS + puerto explícito** en `http://`. Sobrevive a un cambio de IP del nodo y no depende de `tailscale serve`. El esquema `https://<GATEWAY_HOST>/` solo funciona para el puerto 20128.

---

## 2. Diagnóstico: causas raíz reales (verificadas)

No todos los "503 de Cloudflare" son túneles expirados. Esta es la taxonomía que se confirmó en producción:

| Síntoma | Causa raíz real | Comprobación | Corrección |
|---|---|---|---|
| **HTTP 502** en `https://<GATEWAY_HOST>/` | `tailscale serve` proxyea a `127.0.0.1:20128`, pero el contenedor publica el puerto **solo** en la IP de Tailscale → connection refused | `ssh <nodo> 'sudo tailscale serve status'` | `sudo tailscale serve --bg http://<TAILSCALE_IP>:20128` |
| **HTTP 401** en FreeLLMAPI con la clave de OmniRoute | Cada pasarela tiene su propia credencial. La `unified_api_key` de FreeLLMAPI vive en su SQLite (`settings.unified_api_key`) | `curl -H "Authorization: Bearer $FREELLMAPI_KEY" http://<GATEWAY_HOST>:3001/v1/models` | Usar la clave de cada gateway en su propia variable |
| **HTTP 503** `Maximum combo retry limit reached` (OmniRoute) | El combo `auto/*` recorre un pool de ~1400 modelos y agota 24 reintentos. Suele durar >60 s | `curl ... -d '{"model":"auto/best-coding",...}'` | No usar `auto/best-coding`; usar `auto/best-free` o `auto/cheap` |
| **HTTP 402** `requires an opencode API key` | Los modelos `oc/*` de OmniRoute exigen una clave de OpenCode registrada en su panel | — | Añadir la clave en el panel de OmniRoute o usar modelos no-`oc/` |
| **`No inference provider configured`** | `config.yaml` sin proveedor, o proveedor con nombre que no coincide con `custom_providers` | `grep -A5 '^model:' ~/.hermes/config.yaml` | Nombre del proveedor = `custom:<nombre-de-la-entrada>` |
| **200 OK pero `content` vacío** | Falso negativo de diagnóstico: `max_tokens` pequeño + modelo con razonamiento consume todo el presupuesto en `reasoning_content` | Comparar con `max_tokens: 300` | Subir `max_tokens` en los sondeos; no es un fallo del gateway |

> [!WARNING]
> El sintoma "503 = túnel de Cloudflare expirado" es una hipótesis, no un diagnóstico. El 503 de OmniRoute con `Maximum combo retry limit reached` es interno del gateway y no tiene nada que ver con Cloudflare.

---

## 3. Pre-flight determinista (0 tokens de decisión)

Antes de lanzar cualquier agente, ejecuta el script del core:

```bash
# Digest legible
bash scripts/agent/check-inference-gateway.sh \
  --url http://<GATEWAY_HOST>:3001/v1 \
  --key-env FREELLMAPI_KEY --probe

# Digest estructurado para orquestadores
bash scripts/agent/check-inference-gateway.sh \
  --url http://<GATEWAY_HOST>:3001/v1 \
  --key-env FREELLMAPI_KEY --probe --json
```

Salida real verificada:

```
Gateway: http://<GATEWAY_HOST>.ts.*:3001/v1
Auth:    bearer:present ($FREELLMAPI_KEY)
Models:  OK (218 modelos)
Probe:   OK | pedido=auto servido=dots-studio/dots-3-note-preview:free via=openrouter responde=sí
Veredicto: OK
```

Códigos de salida: `0` OK · `2` NOT_FOUND · `3` AUTH_FAIL · `4` UPSTREAM_DOWN · `5` UNREACHABLE · `64` uso incorrecto.

El script nunca imprime la clave y enmascara el host. Funciona con cualquier gateway OpenAI-compatible (FreeLLMAPI, OmniRoute, LiteLLM, vLLM, Ollama).

---

## 4. Qué resiste una caída y qué no (respuesta honesta)

La pregunta "si un modelo falla, ¿sirve otro?" tiene respuesta distinta en cada pasarela, y hay una trampa importante.

### FreeLLMAPI — sí rota, y está verificado en vivo

`model: "auto"` consulta la tabla `fallback_config` (286 modelos, 6 credenciales sanas) y salta al siguiente cuando el actual falla. **Probado**: en la misma tarde una petición `auto` devolvió `google/gemini-3.5-flash` en 2.8 s y otra devolvió `openrouter/dots-3-note-preview:free` en 1.5 s. En una misma tarde el gateway registró `groq → HTTP 413` y, segundos después, `google → success`: la rotación ocurrió sola, sin que el cliente hiciera nada.

Proveedores con credencial activa: `google`, `groq`, `openrouter`, `huggingface`, `zhipu`, y `custom` (Ollama local dentro del nodo).

### OmniRoute — la rotación existe pero el combo por defecto está roto

- `auto/best-free` y `auto/cheap`: operativos (< 1 s y ~7 s respectivamente).
- `auto/best-coding`: **no usable**. Devuelve 503 tras agotar 24 reintentos sobre un pool de 1437 modelos, y las peticiones sin `max_tokens` se quedan colgadas >60 s.

### La trampa de `max_tokens`

Al sondear con `max_tokens: 16` un modelo con razonamiento, todo el presupuesto se consume en `reasoning_content` y `content` llega vacío. Parece un gateway roto y no lo es: con `max_tokens: 300` la respuesta llega íntegra. Usa ≥256 tokens en cualquier sondeo de diagnóstico.

### Red de seguridad real

1. **Nivel 1**: FreeLLMAPI `auto` (cloud gratuito rotativo).
2. **Nivel 2**: OmniRoute `auto/best-free`.
3. **Nivel 3**: Ollama dentro del propio nodo (`http://ollama:11434/v1`), inmune a internet pero lento en CPU.

---

## 5. Configuración de Hermes Agent (local)

### A. Secretos en `~/.hermes/.env` (permisos 600)

```bash
chmod 600 ~/.hermes/.env
```

```bash
FREELLMAPI_KEY=<unified_api_key de FreeLLMAPI>
OMNIROUTE_API_KEY=<api key de OmniRoute>
```

Cómo obtener cada una (desde el nodo de gateways):

```bash
# FreeLLMAPI
ssh <nodo> 'docker exec -i freellmapi node -' <<'EOF'
const D = require("better-sqlite3");
const db = new D("/app/server/data/freeapi.db", { readonly: true });
process.stdout.write(db.prepare("select value from settings where key='unified_api_key'").get().value);
EOF
```

Hermes carga `~/.hermes/.env` automáticamente y expande `${VAR}` en el YAML.

### B. `~/.hermes/config.yaml`

```yaml
model:
  default: auto
  provider: custom:freellmapi
  base_url: http://<GATEWAY_HOST>:3001/v1
  api_key: "${FREELLMAPI_KEY}"

fallback_providers:
  - provider: custom
    model: auto/best-free
    base_url: http://<GATEWAY_HOST>:20128/v1
    key_env: OMNIROUTE_API_KEY

custom_providers:
  - name: freellmapi
    base_url: http://<GATEWAY_HOST>:3001/v1
    api_key: "${FREELLMAPI_KEY}"
    model: auto
  - name: omniroute
    base_url: http://<GATEWAY_HOST>:20128/v1
    api_key: "${OMNIROUTE_API_KEY}"
    model: auto/best-free
```

Puntos que importan:
- El proveedor del bloque `model:` debe coincidir con `custom:<name>` de una entrada existente.
- `fallback_providers` exige `provider` **y** `model`; las entradas incompletas se ignoran silenciosamente.
- El fallback se evalúa por turno: si el primario falla, entra el de respaldo y al turno siguiente se reintenta el primario.

### C. Verificación

```bash
hermes -z "responde solo: pong" --yolo
```

---

## 6. Configuración de OpenCode CLI (local)

OpenCode lee `~/.config/opencode/opencode.jsonc`. Usa `{env:VAR}` para no dejar secretos en disco.

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "freellmapi": {
      "name": "FreeLLMAPI (gateway)",
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "http://<GATEWAY_HOST>:3001/v1",
        "apiKey": "{env:FREELLMAPI_KEY}",
        "timeout": 300000
      },
      "models": {
        "auto": {
          "name": "FreeLLMAPI auto (rotacion $0)",
          "tool_call": true,
          "cost": { "input": 0, "output": 0 },
          "limit": { "context": 1048576, "output": 8192 }
        }
      }
    },
    "omniroute": {
      "name": "OmniRoute (gateway)",
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "http://<GATEWAY_HOST>:20128/v1",
        "apiKey": "{env:OMNIROUTE_API_KEY}",
        "timeout": 300000
      },
      "models": {
        "auto/best-free": {
          "name": "OmniRoute auto/best-free",
          "tool_call": true,
          "cost": { "input": 0, "output": 0 },
          "limit": { "context": 200000, "output": 8192 }
        }
      }
    }
  },
  "model": "freellmapi/auto"
}
```

> [!NOTE]
> `FREELLMAPI_KEY` y `OMNIROUTE_API_KEY` deben estar exportadas en el entorno antes de invocar OpenCode (`set -a; . ~/.hermes/.env; set +a`). OpenCode no lee ese `.env` por sí solo.

### Verificación

```bash
opencode models freellmapi
opencode run --dir /tmp -m freellmapi/auto "responde unicamente: pong"
opencode run --dir /tmp -m omniroute/auto/best-free "responde unicamente: pong"
```

---

## 7. Checklist para un agente nuevo

- [ ] `tailscale status` → el nodo de gateways aparece activo.
- [ ] `bash scripts/agent/check-inference-gateway.sh --url http://<GATEWAY_HOST>:3001/v1 --key-env FREELLMAPI_KEY --probe --json` → `"verdict": "OK"`.
- [ ] Credenciales en `~/.hermes/.env` con permisos 600, y exportadas para OpenCode.
- [ ] `hermes -z "ping" --yolo` responde en < 10 s.
- [ ] `opencode run --dir /tmp -m freellmapi/auto "responde unicamente: pong"` responde en < 10 s.

Si el veredicto es `UPSTREAM_DOWN` en OmniRoute, es el bug conocido de `auto/best-coding`: cambia a `auto/best-free` y sigue. Si es `AUTH_FAIL`, estás usando la clave del gateway equivocado.

---

## 8. Mantenimiento del `tailscale serve` del nodo

Si alguien vuelve a_publicar los contenedores en `127.0.0.1` o cambia el binding, el endpoint HTTPS vuelve a dar 502:

```bash
ssh <nodo> 'sudo tailscale serve status'                     # ver objetivo actual
ssh <nodo> 'sudo tailscale serve reset && sudo tailscale serve --bg http://<TAILSCALE_IP>:20128'
```

El proxy debe apuntar a la **IP de Tailscale** del nodo, nunca a `127.0.0.1`, mientras el contenedor no publique en localhost.