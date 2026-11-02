# Bane Deep Research Service — Runbook Operativo

> Guía técnica y operativa para el aprovisionamiento, consumo, diagnóstico y mantenimiento del motor soberano de investigación profunda Bane en la flota de Agent OS.

---

## 1. Arquitectura y Rol en la Flota

Bane es un motor de razonamiento profundo y búsqueda técnica open-source (alternativa autoalojada a Perplexity Pro) integrado en la flota para asistir a los agentes en fases de investigación previa y diseño de sprints:

```
[Agente / Script CLI]
       │
       ▼
scripts/agent/lib/bane-client.sh
       │
       ▼ (HTTP REST :3000)
┌────────────────────────────────────────────────────────┐
│ Nodo de Cómputo: `<nodo-inferencia>`                   │
│                                                        │
│ Contenedor Docker: `bane`                              │
│ ┌────────────────────────────────────────────────────┐ │
│ │ • Motor de razonamiento e iteración profunda       │ │
│ └──────────────┬─────────────────────────┬───────────┘ │
│                │                         │             │
│                ▼                         ▼             │
│   FreeLLMAPI (:3001)               SearXNG (:8080)     │
│   (Modelos LLM locales/proxy)      (Meta-búsqueda web) │
└────────────────────────────────────────────────────────┘
```

### Características Principales
- **Autonomía $0 Tokens**: Se conecta a pasarelas OpenAI-compatibles gratuitas locales (FreeLLMAPI, Ollama) y motores de meta-búsqueda privados (SearXNG).
- **Salida UNIX-First**: Emite Markdown estructurado directamente por stdout para composición en pipelines deterministas.
- **Fail-Soft por Diseño**: Si el servicio está inactivo o no responde, el agente conmuta de forma instantánea al flujo manual con Perplexity Pro sin bloqueos.

---

## 2. Requisitos de Hardware y Red

| Recurso | Mínimo Recomendado | Notas |
|---|---|---|
| **CPU** | 1-2 vCPUs | Límite por defecto: 1.0 CPU (`BANE_CPU_LIMIT`), reserva: 0.1 |
| **RAM** | 512 MB - 2 GB libres | Límite por defecto (<250MB spec): 250MB (`BANE_MEMORY_LIMIT`), reserva: 64MB |
| **Disco** | 5 GB SSD | Volumen persistente `bane-data` para índices temporales |
| **Red** | Red privada / Tailscale | Acceso restringido al puerto `3000` |

---

## 3. Procedimiento de Despliegue (Docker Compose)

La plantilla estándar está disponible en `templates/bane/docker-compose.yml` y las variables de configuración en `templates/bane/.env.example`.

### Paso 1: Aprovisionar directorio de servicio en el nodo
```bash
mkdir -p ~/services/bane
cp templates/bane/docker-compose.yml ~/services/bane/
cp templates/bane/.env.example ~/services/bane/.env
cd ~/services/bane
```

### Paso 2: Configurar variables de entorno (`.env`)
Ajustar los valores en `.env` según la topología del nodo:
```bash
# Puerto local de escucha y enlace
HOST_BIND_IP=127.0.0.1
BANE_PORT=3000

# Conexión con la pasarela de inferencia de la flota
BANE_INFERENCE_URL=http://<nodo-inferencia>:3001/v1
BANE_API_KEY=

# Conexión con motor de búsqueda SearXNG
BANE_SEARCH_URL=http://<nodo-inferencia>:8080

# Límites de recursos de contenedor (Compose v2)
BANE_CPU_LIMIT=1.0
BANE_MEMORY_LIMIT=250M
BANE_CPU_RESERVATION=0.1
BANE_MEMORY_RESERVATION=64M
```

### Paso 3: Desplegar el contenedor
```bash
docker compose up -d
```

### Paso 4: Verificar que el servicio responde
```bash
curl -s http://127.0.0.1:3000/health
# Respuesta esperada: {"status":"ok"}
```

---

## 4. Registro Declarativo en la Flota

En `.agents/config/fleet.yaml` de la estación de trabajo:

```yaml
nodes:
  <nodo-inferencia>:
    services:
      bane:
        endpoint: "http://<nodo-inferencia>:3000"
        description: "Self-hosted deep research and reasoning search engine"
```

Alternativamente, el cliente reconoce la variable de entorno:
```bash
export BANE_API_URL="http://<nodo-inferencia>:3000"
```

---

## 5. Operación y Consumo desde el Core

### 5.1 Sonda determinista de disponibilidad
```bash
bash scripts/agent/lib/bane-client.sh --check
# Exit code 0: Activo y alcanzable
# Exit code 2: Inactivo o no configurado
```

### 5.2 Consulta interactiva o en pipeline
```bash
# Salida Markdown directa a stdout
bash scripts/agent/lib/bane-client.sh --query "Comparativa arquitecturas auth Next.js 15"

# Volcado directo a archivo de research
bash scripts/agent/lib/bane-client.sh --query "Análisis dependencias MCP" --output docs/sprints/sprint-XX-research.md
```

### 5.3 Integración con Workflows
El workflow `@[.agents/workflows/deep-research.md]` y el paso 5 de `sprint-planning.md` consumen automáticamente esta interfaz de forma desatendida.

---

## 6. Diagnóstico y Monitoreo

La herramienta determinista `fleet-doctor.sh` audita la disponibilidad de Bane sin coste de inferencia:

```bash
# Diagnóstico rápido de flota
bash scripts/agent/fleet-doctor.sh

# Verificación estructurada JSON
bash scripts/agent/fleet-doctor.sh --json | jq .summary.bane_probe
```

La sonda opera en modo **warn-only**: si Bane está caído o no responde, emite `[WARN]` sin alterar el código de salida ni romper el pipeline de CI/CD.

---

## 7. Troubleshooting

| Síntoma | Causa Probable | Solución |
|---|---|---|
| `Exit code 2: not_configured` | No existe `fleet.yaml` con `services.bane` ni `BANE_API_URL` | Declarar el endpoint en `fleet.yaml` o exportar `BANE_API_URL` |
| `Exit code 2: unreachable` | Contenedor detenido o firewall bloqueando el puerto 3000 | Comprobar `docker ps` y verificar conectividad de red con `curl` |
| Búsquedas sin resultados web | SearXNG inalcanzable o bloqueado | Verificar variable `BANE_SEARCH_URL` y logs de SearXNG |
| Errores 500 en inferencia | FreeLLMAPI sin modelos disponibles o sin cuota | Verificar `check-inference-gateway.sh --url <URL>` |
