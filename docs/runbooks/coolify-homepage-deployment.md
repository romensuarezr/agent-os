# Runbook: Despliegue de Homepage en Coolify con Docker Compose y MCP Tooling

> **Fecha**: 2026-09-28  
> **Objetivo**: Procedimiento Operativo Estándar (SOP) para migrar y desplegar Homepage en Coolify (`oracle`) como stack Docker Compose desacoplado, contención de Docker Socket con `tecnativa/docker-socket-proxy` RO (32MB RAM, ADR 004), mapeo persistente de configuraciones y automatización mediante Coolify MCP / API.  
> **Hosts aplicables**: `oracle` (PaaS/Coolify, dominio `https://homepage.example.com`).

---

## 1. Visión y Justificación Técnica

Actualmente, el despliegue original de Homepage en Coolify consistía en una aplicación monolítica ("Docker Image" simple) con montaje directo de `/var/run/docker.sock` en el contenedor web.

### 1.1 El Problema
1. **Riesgo de Seguridad en el Host**: El montaje directo de `/var/run/docker.sock` otorga privilegios equivalentes a `root` en `oracle`. Si Homepage sufriera una vulnerabilidad RCE, el host quedaría comprometido.
2. **Restricción de Recursos (ADR 004)**: El nodo `oracle` aloja servicios esenciales de la flota y cuenta con almacenamiento y memoria limitados. Cualquier componente auxiliar debe ser ultra-ligero y predecible.
3. **Fricción Operativa**: Actualizar configuraciones YAML mediante la GUI web de Coolify genera deriva de configuración respecto al repositorio Git y dificulta despliegues reproducibles.

### 1.2 La Solución
- Migrar la aplicación en Coolify a **Docker Compose**.
- Interpolar `tecnativa/docker-socket-proxy` en la red privada `homepage-internal` con cuota estricta de memoria (`mem_limit: 32m`) y verbos destructivos bloqueados (`POST=0`).
- Automatizar actualizaciones de configuración y redeploys mediante el **Coolify MCP Server** / Coolify API.

---

## 2. Arquitectura del Stack en Coolify

```
               [ Internet / WAN ]
                        │
                        ▼ (HTTPS / 443)
        [ Traefik Edge Proxy (Coolify Network) ]
                        │
                        ▼ (HTTP / 3000)
    ┌───────────────────┴───────────────────────────────┐
    │  Servicio: homepage                              │
    │  - Imagen: ghcr.io/gethomepage/homepage:latest    │
    │  - Redes: coolify (Traefik) + homepage-internal   │
    │  - Volúmenes: /data/coolify/services/.../config   │
    └───────────────────┬───────────────────────────────┘
                        │
                        ▼ (tcp://docker-socket-proxy:2375)
    ┌───────────────────┴───────────────────────────────┐
    │  Servicio: docker-socket-proxy                    │
    │  - Imagen: tecnativa/docker-socket-proxy:latest  │
    │  - Redes: homepage-internal (aislada / internal)  │
    │  - Memoria: mem_limit: 32m (ADR 004)             │
    │  - Volúmenes: /var/run/docker.sock:ro             │
    │  - Filtro: HAProxy RO (CONTAINERS=1, POST=0)      │
    └───────────────────┬───────────────────────────────┘
                        │ (Solo llamadas GET autorizadas)
                        ▼
              [ Docker Daemon Host ]
```

---

## 3. Definición Canónica de Docker Compose para Coolify

En la interfaz de Coolify o a través de su API/MCP, el recurso debe configurarse como tipo **Docker Compose** (`docker-compose.yaml`):

```yaml
version: '3.8'

services:
  docker-socket-proxy:
    image: tecnativa/docker-socket-proxy:latest
    container_name: homepage-docker-socket-proxy
    restart: unless-stopped
    mem_limit: 32m
    deploy:
      resources:
        limits:
          memory: 32M
    environment:
      - CONTAINERS=1
      - INFO=1
      - POST=0
      - BUILD=0
      - COMMIT=0
      - CONFIGS=0
      - DISTRIBUTION=0
      - EXEC=0
      - IMAGES=0
      - NETWORKS=0
      - NODES=0
      - PLUGINS=0
      - SECRETS=0
      - SERVICES=0
      - SESSION=0
      - SWARM=0
      - SYSTEM=0
      - TASKS=0
      - VOLUMES=0
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - homepage-internal

  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    restart: unless-stopped
    depends_on:
      - docker-socket-proxy
    environment:
      - PUID=1000
      - PGID=1000
    volumes:
      - ./config:/app/config
    networks:
      - coolify
      - homepage-internal
    labels:
      - "coolify.managed=true"

networks:
  coolify:
    external: true
  homepage-internal:
    internal: true
```

---

## 4. Configuración de Volúmenes y Archivos YAML

Homepage monta el directorio `./config` (mapeado en el host en la ruta del proyecto de Coolify, típicamente `/data/coolify/applications/<app-uuid>/config` o volumen nombrado).

### 4.1 Archivo `docker.yaml`
Para que Homepage se conecte al proxy aislado en lugar de buscar `/var/run/docker.sock`:

```yaml
# config/docker.yaml
my-docker:
  host: tcp://docker-socket-proxy:2375
```

### 4.2 Archivos de Configuración Declarativos
Los siguientes archivos deben generarse previamente mediante `scripts/agent/generate-homepage-config.sh` y copiarse al volumen `./config`:

| Archivo | Función |
| :--- | :--- |
| `settings.yaml` | Título del dashboard, tema visual, layout y buscador DuckDuckGo. |
| `widgets.yaml` | Banner de recursos: CPU/RAM/Disco local y Glances en `datamanager` (`100.99.88.77:61208`). |
| `services.yaml` | Grupos de servicios: Inferencia IA ($0) con pings seguros a `/health`, Docker Apps, ByteBox y GitHub. |
| `bookmarks.yaml` | Accesos rápidos a documentación, consola Coolify y repositorios. |
| `custom.css` | Personalización visual y contraste adaptativo. |

### 4.3 Reglas de Saneamiento y Resiliencia en Producción (T-068)
Para evitar bucles de diagnóstico y falsas alarmas operativas en los agentes:
1. **FreeLLMAPI y Gateways IA**: El health check (`ping:`) apunta estrictamente a `/health` (HTTP 200 sin credenciales). Se evita pingear `/v1/models` sin cabecera `Authorization: Bearer`, ya que retorna HTTP 401 y marca erróneamente la tarjeta como `DOWN`.
2. **Eliminación de Dominios Placeholder**: `generate-homepage-config.sh` detecta y omite automáticamente tarjetas con dominios no configurados (`*.example.com`, `*.example.org`), garantizando 0 tarjetas `DOWN` por fallos de resolución DNS en entornos de producción.
3. **Inferencia Ollama Condicional**: El estado de Ollama (:11434) se valida en tiempo de generación mediante sondeo de socket TCP no bloqueante. Si el daemon está detenido en el nodo remoto, la tarjeta se omite para no inventar estado ni alertar falsos caídos; en plantillas y documentación permanece en modo bajo demanda sin ping.

---

## 5. Procedimiento de Migración Paso a Paso en Coolify

### Paso 1: Inventario del Recurso Existente
1. Acceder al dashboard de Coolify en `oracle` (`http://100.99.88.78:8000` o dominio Coolify).
2. Localizar la aplicación `Homepage` actual.
3. Copiar las variables de entorno existentes y el UUID del recurso.
4. Si la app actual estaba montando `/var/run/docker.sock`, proceder a detenerla antes de migrar para evitar colisión de puertos o nombres de contenedores.

### Paso 2: Crear / Cambiar a Recurso Docker Compose
1. En el proyecto correspondiente de Coolify, añadir un nuevo recurso seleccionando **Docker Compose**.
2. Pegar la definición del bloque de la **Sección 3**.
3. En la sección **Domains**, asignar:
   ```
   https://homepage.example.com
   ```
4. Asegurar que el puerto enrutado sea `3000`.

### Paso 3: Aprovisionar los Archivos de Configuración
Desde la terminal o vía SSH/SCP con `remote-admin`:
```bash
# Directorio base en el servidor oracle
APP_DIR="/data/coolify/source" # o ruta gestionada por Coolify
# Transferir configuración generada
scp -r templates/homepage/config/* romen@oracle:/data/coolify/applications/<uuid>/config/
```

### Paso 4: Despliegue Inicial
1. En Coolify, pulsar **Deploy**.
2. Supervisar los logs de construcción e inicio:
   - `homepage-docker-socket-proxy`: debe arrancar en <2 segundos y reportar HAProxy activo en puerto 2375.
   - `homepage`: debe inicializar Next.js en puerto 3000 y reportar conexión exitosa a `tcp://docker-socket-proxy:2375`.

---

## 6. Automatización vía Coolify MCP Server / API

El servidor MCP de Coolify permite interactuar de forma programática con la instancia de Coolify sin abrir el navegador.

### 6.1 Variables de Entorno del Entorno de Agente
Para interactuar con la API de Coolify:
```bash
COOLIFY_API_URL="http://100.99.88.78:8000/api/v1"  # O endpoint público con SSL
COOLIFY_API_TOKEN="<coolify-bearer-token>"
```

### 6.2 Obtener Estado y UUID de la Aplicación
```bash
curl -fsSL -H "Authorization: Bearer ${COOLIFY_API_TOKEN}" \
  "${COOLIFY_API_URL}/applications" | jq '.[] | select(.name=="homepage") | {uuid: .uuid, status: .status}'
```

### 6.3 Actualizar Definición Compose mediante API / MCP
Para empujar un nuevo `docker-compose.yaml` al recurso de Coolify:
```bash
COMPOSE_CONTENT=$(cat templates/homepage/docker-compose.yml | jq -s -R .)

curl -fsSL -X PATCH \
  -H "Authorization: Bearer ${COOLIFY_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"docker_compose_raw\": ${COMPOSE_CONTENT}}" \
  "${COOLIFY_API_URL}/applications/${APP_UUID}"
```

### 6.4 Disparar Re-despliegue Inmediato
```bash
curl -fsSL -X POST \
  -H "Authorization: Bearer ${COOLIFY_API_TOKEN}" \
  "${COOLIFY_API_URL}/deploy?uuid=${APP_UUID}&force=false"
```

---

## 7. Verificación Post-Despliegue Determinista

Tras el despliegue, ejecutar la siguiente batería de comprobaciones automáticas:

### 7.1 Verificación de Enrutamiento y Certificado SSL
```bash
# 1. Comprobar código HTTP 200 y cabeceras seguras
curl -fsSL -I https://homepage.example.com | grep -E "HTTP/|server|content-type"
```
**Salida esperada**:
```http
HTTP/2 200 
content-type: text/html; charset=utf-8
```

### 7.2 Verificación de Latencia y Contenido HTML
```bash
curl -fsSL -s https://homepage.example.com | grep -q "<title>Homepage</title>" && echo "✅ Homepage HTML verificado"
```

### 7.3 Verificación de Aislamiento de Socket (Prueba Red-Team en Proxy)
Desde el host `oracle`:
```bash
# Verificar que las llamadas GET a contenedores están permitidas
curl -fsSL http://127.0.0.1:2375/containers/json >/dev/null && echo "✅ GET /containers/json permitido"

# Verificar que las llamadas POST destructivas son bloqueadas (403 Forbidden)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://127.0.0.1:2375/containers/create)
if [ "$HTTP_CODE" -eq 403 ]; then
  echo "✅ POST /containers/create bloqueado (HTTP 403 Forbidden - ADR 004 Cumplido)"
else
  echo "❌ ALERTA: Docker socket proxy no está bloqueando verbos POST (Código: $HTTP_CODE)"
fi
```

### 7.4 Verificación de Consumo de Recursos en `oracle`
```bash
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}" | grep -E "homepage|docker-socket-proxy"
```
**Consumo esperado**:
- `homepage-docker-socket-proxy`: `< 15MB` (Tope configurado: `32MB`).
- `homepage`: `~ 70MB - 120MB`.

---

## 8. Procedimiento de Rollback

Si el nuevo stack experimenta un fallo de inicio (`CrashLoopBackOff`) o no conecta con el proxy:

1. **Revisar Logs del Contenedor**:
   ```bash
   docker logs --tail 50 homepage
   docker logs --tail 50 homepage-docker-socket-proxy
   ```
2. **Reversión a Configuración Previa**:
   - En Coolify, acceder a **Deployments** y seleccionar el commit previo funcional.
   - Si se requiere rollback manual de emergencia, volver a montar el socket directo temporalmente mientras se depura la red interna `homepage-internal`.
3. **Validación de Red Docker**:
   - Asegurarse de que ambos contenedores comparten la red bridge interna (`docker network inspect <project_name>_homepage-internal`).
