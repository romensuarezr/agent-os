# Runbook — Configuración y Operación de OpenCode CLI con FreeLLMAPI ($0 Inferencia)

> **Versión**: 1.0.0  
> **Fecha**: 2026-09-24  
> **Ámbito**: Control Plane Local & Remoto (`agent-os` ↔ `datamanager`)  
> **Propósito**: Establecer el procedimiento estándar para configurar, operar y diagnosticar OpenCode CLI consumiendo los modelos locales autoalojados en FreeLLMAPI con coste verificado $0.

---

## 1. Topología y Arquitectura del Sistema

```
┌──────────────────────────────────────────────┐
│  Host Local (Desarrollador / Agente)         │
│  - Binario: ~/.opencode/bin/opencode (1.3.9) │
│  - Config: ~/.config/opencode/opencode.json  │
│    (o ./opencode.json a nivel de proyecto)   │
└──────────────────────┬───────────────────────┘
                       │ HTTP / Bearer Auth (puerto 3001)
                       │ Red privada Tailscale (100.77.82.13)
┌──────────────────────▼───────────────────────┐
│  VPS `datamanager`                           │
│  ├── Contenedor `freellmapi` (:3001)         │
│  │   - Enrutador OpenAI-compatible           │
│  │   - Unified API Key en SQLite             │
│  │   - Base URL: http://100.77.82.13:3001/v1 │
│  └── Contenedor `datamanager-ollama-1`       │
│      - Backend de inferencia local CPU       │
│      - Modelos: qwen2.5:7b, llama3.1:8b, etc.│
└──────────────────────────────────────────────┘
```

- **Aislamiento de red**: El puerto 3001 de FreeLLMAPI está vinculado exclusivamente a la IP de Tailscale (`100.77.82.13`). No existe exposición a internet público.
- **Coste cero ($0)**: Todas las inferencias son procesadas en el backend local de Ollama en `datamanager`. No se realizan llamadas a APIs cloud externas de pago.

---

## 2. Credenciales y Acceso

FreeLLMAPI protege sus endpoints OpenAI-compatibles (`/v1/*`) mediante un token Bearer unificado (`unified_api_key`).

### Obtención no destructiva de la clave

```bash
UNIFIED_KEY=$(ssh datamanager "docker exec freellmapi node -e \"console.log(require('better-sqlite3')('/app/server/data/freeapi.db').prepare(\\\"SELECT value FROM settings WHERE key='unified_api_key'\\\").get().value)\"")
echo "Clave obtenida: $UNIFIED_KEY"
```

### Verificación de conectividad directa

```bash
curl -s -H "Authorization: Bearer $UNIFIED_KEY" \
  http://100.77.82.13:3001/v1/models | jq '.data[] | select(.owned_by=="freellmapi") | .id'
```

---

## 3. Configuración de OpenCode CLI

OpenCode lee su configuración desde `~/.config/opencode/opencode.json` (global) o desde `./opencode.json` (en la raíz del proyecto).

### Archivo de Configuración Estándar (`opencode.json`)

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "freellmapi": {
      "name": "FreeLLMAPI (datamanager)",
      "npm": "@ai-sdk/openai",
      "options": {
        "baseURL": "http://100.77.82.13:3001/v1",
        "apiKey": "freellmapi-dfabc2cbb27c69b4a29053996ae9463f9240ce48afc57f84",
        "timeout": 300000,
        "headerTimeout": 300000,
        "chunkTimeout": 300000
      },
      "models": {
        "qwen2.5:7b": {
          "id": "qwen2.5:7b",
          "name": "Qwen 2.5 7B (Local Ollama)",
          "tool_call": true,
          "attachment": false,
          "reasoning": false,
          "temperature": true,
          "cost": {
            "input": 0,
            "output": 0
          },
          "limit": {
            "context": 16384,
            "output": 4096
          }
        },
        "llama3.1:8b": {
          "id": "llama3.1:8b",
          "name": "Llama 3.1 8B (Local Ollama)",
          "tool_call": true,
          "attachment": false,
          "reasoning": false,
          "temperature": true,
          "cost": {
            "input": 0,
            "output": 0
          },
          "limit": {
            "context": 16384,
            "output": 4096
          }
        },
        "qwen2.5:3b": {
          "id": "qwen2.5:3b",
          "name": "Qwen 2.5 3B (Local Ollama)",
          "tool_call": false,
          "attachment": false,
          "reasoning": false,
          "temperature": true,
          "cost": {
            "input": 0,
            "output": 0
          },
          "limit": {
            "context": 8192,
            "output": 2048
          }
        }
      }
    }
  },
  "model": "freellmapi/qwen2.5:7b",
  "small_model": "freellmapi/qwen2.5:3b",
  "permission": {
    "read": "allow",
    "edit": "allow",
    "bash": "allow"
  }
}
```

### Parámetros Críticos

1. **Driver `@ai-sdk/openai`**: OpenCode integra nativamente el SDK de Vercel. Al especificar este driver, OpenCode envía payloads estándar compatibles con OpenAI a la pasarela FreeLLMAPI.
2. **Timeouts asimétricos (300.000 ms)**: `timeout`, `headerTimeout` y `chunkTimeout` se fijan en 5 minutos (300s). En servidores CPU, la generación de un turno completo de agente con contextos extensos puede requerir entre 120 y 210 segundos. Si los timeouts fueran los predeterminados de llamadas cloud rápidas (30s-60s), el cliente abortaría prematuramente.
3. **`cost.input` y `cost.output` en 0**: Garantiza que el rastreador de métricas (`opencode stats`) registre con exactitud el gasto real ($0.00).

---

## 4. Modelos Validados y Capacidades

| Modelo | Identificador en OpenCode | Tamaño | Tool Calling Nativo | Tiempo Respuesta (CPU) | Caso de Uso Recomendado |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **Qwen 2.5 7B** | `freellmapi/qwen2.5:7b` | 4.7 GB | ✅ Sí | 20s - 200s | Generación de código, refactorización y resolución de tests |
| **Llama 3.1 8B** | `freellmapi/llama3.1:8b` | 4.9 GB | ✅ Sí | 20s - 180s | Clasificación, reasoning estructurado y toma de decisiones |
| **Qwen 2.5 3B** | `freellmapi/qwen2.5:3b` | 1.9 GB | ⚠️ No (Inconsistente) | 5s - 15s | Tareas conversacionales simples, resúmenes rápidos y `small_model` |

### Verificación de Tool-Calling Nativo

Ambos modelos de 7B/8B fueron verificados respondiendo con formato OpenAI Function Calling nativo:
```json
{
  "choices": [{
    "message": {
      "role": "assistant",
      "tool_calls": [{
        "id": "call_dv75r206",
        "type": "function",
        "function": { "name": "add", "arguments": "{\"a\":2,\"b\":2}" }
      }]
    },
    "finish_reason": "tool_calls"
  }]
}
```

---

## 5. Modos de Uso de OpenCode CLI

### A. Listar modelos registrados
```bash
opencode models freellmapi
opencode models --verbose freellmapi
```

### B. Ejecución Headless / No Interactiva
Para scripts de testing o ejecución batch en CI/CD o subagentes:
```bash
opencode run -m freellmapi/qwen2.5:7b "Escribe una función de validación en util.py"
```

### C. Adjuntar archivos a la instrucción
Si se adjuntan archivos con `--file`, se debe usar `--` para separar la lista de archivos del mensaje de instrucción:
```bash
opencode run -m freellmapi/qwen2.5:7b --file=calculator.py -- "Implementa la función multiply"
```

### D. Continuar una sesión previa
```bash
opencode run -c "Ejecuta los tests unitarios y reporta el resultado"
```

### E. Comprobar estadísticas y coste de inferencia
```bash
opencode stats
```
Salida esperada:
```
┌────────────────────────────────────────────────────────┐
│                    COST & TOKENS                       │
├────────────────────────────────────────────────────────┤
│Total Cost                                        $0.00 │
│Input                                             16.4K │
│Output                                              690 │
└────────────────────────────────────────────────────────┘
```

---

## 6. Buenas Prácticas y Diagnóstico de Incidencias

### 1. Clamping de Contexto e Inflación por Skills
- **Problema**: OpenCode escanea recursivamente el directorio de trabajo y sus carpetas padres. Si se ejecuta dentro de un repositorio de agent-os con múltiples skills (`.agents/skills/*`), OpenCode inyectará todas las skills como herramientas del sistema en el prompt inicial (~5.000 tokens), ralentizando la inferencia en CPU.
- **Mitigación**: Para tareas de desarrollo aisladas, ejecutar OpenCode dentro de un subdirectorio o worktree con su propio `opencode.json` acotado.

### 2. Detección de "Empty Completion" en Modelos Pequeños (3B)
- **Problema**: Cuando un modelo de 3B intenta llamar a herramientas complejas sin el formateo adecuado, Ollama puede devolver una respuesta vacía o con finish_reason inesperado, provocando que FreeLLMAPI active un enfriamiento (*cooldown*) temporal sobre la ruta.
- **Mitigación**: Utilizar `freellmapi/qwen2.5:7b` o `freellmapi/llama3.1:8b` como modelos primarios para tareas con herramientas y restringir los modelos 3B a prompts textuales simples.

### 3. Diagnóstico en el Servidor Remoto
Si una petición se demora o no responde:
```bash
# Comprobar logs en tiempo real de FreeLLMAPI
ssh datamanager "docker logs --tail 20 -f freellmapi"

# Comprobar uso de CPU/RAM de Ollama
ssh datamanager "docker stats --no-stream datamanager-ollama-1"
```
