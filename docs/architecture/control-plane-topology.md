# Topología de Arquitectura del Control Plane de Agentes

> Documento técnico de topología, conectividad, componentes y flujos de datos entre el host Local y los servidores remotos.

---

## 1. Diagrama General de Topología

```
                                      CONSOLA LOCAL
                    ┌─────────────────────────────────────────────────┐
                    │ Host: inteligencia-colectiva (100.65.217.64)   │
                    │ OS: Ubuntu 24.04 LTS (x86_64)                   │
                    │                                                 │
                    │  - Antigravity CLI (Arquitecto Senior / Core)   │
                    │  - Orca Desktop IDE (Supervisión & Decision)   │
                    │  - OpenCode CLI (Worker auxiliar / ACP)         │
                    │  - Repo local: agent-os (Rama activa)          │
                    └────────────────────────┬────────────────────────┘
                                             │
                       Red Privada Tailscale Mesh (Cifrado E2EE)
                     (Latencia media verificada: 27 ms – 30 ms)
                                             │
               ┌─────────────────────────────┴─────────────────────────────┐
               ▼                                                           ▼
     PERSISTENCIA Y CEREBRO 24/7                               INFRAESTRUCTURA Y COMPUTE
┌───────────────────────────────────────────┐             ┌───────────────────────────────────────────┐
│ Host: datamanager (100.77.82.13)          │             │ Host: oracle (100.96.20.7)                │
│ Hostname: vnic-susana                     │             │ Hostname: vnic-rsr                        │
│ HW: 4 vCPU ARM, 23 GiB RAM, 143 GiB libres│             │ HW: 4 vCPU ARM, 23 GiB RAM, 55 GiB libres │
│ Firewall: UFW Activo (Solo SSH 22 externo)│             │ Disco: 72% ocupado (Restricción de carga) │
│                                           │             │                                           │
│ [Servicios 24/7 (Systemd User)]           │             │ [Plataforma Web (Docker)]                 │
│  - hermes-gateway.service (PID persistente)│    Relay    │  - Coolify 4 (Dashboard en :8000)         │
│  - whatsapp-bridge (Node en :3000)        │────────────▶│  - coolify-proxy (Traefik :80, :443)      │
│  - rag-service (Uvicorn FastAPI en :8643) │    E2EE     │  - ~25 contenedores (Ghost, n8n, APIs)    │
│  - whatsapp-groups-watcher                │             │                                           │
│                                           │             │ [Target de Ejecución Supervisada]         │
│ [Contenedores Docker]                     │             │  - orca-relay (Node socket activo)        │
│  - freellmapi (:3001 atado a Tailscale)   │             │  - Git Worktrees efímeros bajo demanda    │
│  - datamanager-ollama-1 (:11434 local)    │             │  - ⚠️ Decision Gate Humano Obligatorio    │
│  - datamanager-qdrant-1 (:6333 local)     │             │                                           │
│  - omniroute (:20128 local)               │             │ [Repositorios en ~/projects]              │
│                                           │             │  - hermes-vps-config (main)               │
│ [Repositorios en ~/projects]              │             └───────────────────────────────────────────┘
│  - agent-os (skills enlazadas a Hermes)   │
│  - hermes-vps-config (infraestructura)    │
│  - rag-service                            │
└───────────────────────────────────────────┘
```

---

## 2. Inventario de Nodos y Componentes

### 2.1 Host Local (`inteligencia-colectiva`)
- **IP Tailscale:** `100.65.217.64`
- **Rol:** Consola de mando, desarrollo principal y supervisión humana.
- **Componentes:**
  - **Antigravity CLI (1.2.7):** Agente principal de desarrollo de software, planificación de sprints y refactors complejos.
  - **Orca Desktop IDE (1.4.207):** Entorno gráfico de orquestación, gestión de runs y control de decision gates.
  - **OpenCode (1.3.9):** Motor de codificación headless y compatible con ACP/MCP.
  - **Almacén de Secretos Local:** `/home/romen/Proyectos/configuraciones/api_keys.env` (permisos 600, excluido de Git).

### 2.2 VPS `datamanager` (`vnic-susana`)
- **IP Tailscale:** `100.77.82.13` (IP Pública: `141.253.197.108` protegida por UFW)
- **Rol:** Centro neurálgico 24/7, memoria vectorial, bridge conversacional e inferencia.
- **Componentes:**
  - **Hermes Agent (0.21.2):** Corre como servicio systemd persistente (`hermes-gateway.service`), gestionando WhatsApp y triage.
  - **RAG Local:** FastAPI en puerto `8643` + base de datos vectorial Qdrant en puerto `6333`.
  - **FreeLLMAPI:** Pasarela de modelos en puerto `3001` (restringido estrictamente a `100.77.82.13`).
  - **Ollama Local:** Motor de modelos GGUF en `127.0.0.1:11434` (`llama3.1:8b`, `qwen2.5:7b`, `qwen2.5:3b`, `mistral-nemo:12b`).
  - **Orca Relay:** Proceso Node que conecta este VPS como nodo subordinado a la consola local de Orca.

### 2.3 VPS `oracle` (`vnic-rsr`)
- **IP Tailscale:** `100.96.20.7` (IP Pública: `158.179.213.240`)
- **Rol:** Servidor de producción web y aplicaciones desplegadas.
- **Componentes:**
  - **Coolify 4:** Gestor de despliegues y contenedores de producción.
  - **Traefik Proxy:** Enrutador de tráfico SSL/HTTP.
  - **Orca Relay:** Proceso Node conectado a Orca local para operaciones de mantenimiento supervisadas.
  - **Restricción de Recursos:** 72% de disco ocupado (139 GiB de 193 GiB). **Prohibido ejecutar builds o workers masivos en este host**.

---

## 3. Flujos de Trabajo e Interacción

### Flujo 1: Recepción y Triage Conversacional (Front Door 24/7)
1. Usuario envía mensaje vía WhatsApp.
2. Bridge Node (`bridge.js`) en `datamanager` recibe el payload y lo transfiere a `hermes-gateway.service`.
3. Hermes consulta contexto vectorial en `rag-service` (Qdrant).
4. Si la consulta es informativa: Hermes responde de inmediato usando su modelo de lenguaje configurado.
5. Si la petición requiere una tarea de ingeniería o modificación de infraestructura: Hermes genera una tarea en el inbox de `agent-os` o solicita la apertura de un run en Orca.

### Flujo 2: Desarrollo y Refactor Supervisado (Engineering Plane)
1. El usuario abre una sesión en Local con Antigravity CLI u Orca.
2. Se ejecuta el ritual `session-start.md` en `agent-os`.
3. Se crea una rama aislada de Git (`feat/T-XXX-...`) y se establece la "Caja de archivos autorizados".
4. El agente genera el plan de acción (Fase 3.5) y **se detiene esperando `APROBADO`**.
5. Tras aprobación, se ejecutan cambios en código y tests.
6. La tarea se valida y se cierra con `scripts/agent/close-task.sh`, dejando el árbol limpio.

### Flujo 3: Inferencia Desacoplada y Fallback
1. Cualquier agente que requiera inferencia de coste cero o tolerante a fallos llama a `http://100.77.82.13:3001/v1/chat/completions`.
2. FreeLLMAPI evalúa la petición:
   - Si `model: "auto"`: Balancea hacia proveedores gratuitos cloud activos (Groq, HuggingFace, etc.).
   - Si el proveedor cloud falla o se solicita modelo local: Enruta hacia Ollama (`http://ollama:11434/v1`) en la red interna `datamanager_default`.
3. La respuesta retorna en formato estándar OpenAI compatible con streaming.

---

## 4. Perímetro de Seguridad

1. **Sin Exposición Pública de APIs**: Ni Ollama, ni Qdrant, ni FreeLLMAPI tienen puertos abiertos a internet directo (0.0.0.0). Todo el tráfico inter-nodo pasa exclusivamente por la interfaz virtual de Tailscale (`100.x.x.x`).
2. **Aislamiento de Secretos**: Los secretos residen en `.env` locales protegidos por permisos `600`. Ningún token, sesión de WhatsApp ni certificado se incluye en los repositorios Git.
3. **Decision Gates Humanos**: Ningún agente puede modificar contenedores de Coolify, reglas de firewall, o ejecutar `git push` a producción sin confirmación humana explícita.
