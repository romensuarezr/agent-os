# Nango Unified OAuth & API Integration Service — Runbook Operativo

> Guía técnica y operativa para el aprovisionamiento, despliegue soberano, verificación de salud, gestión de credenciales y consumo del servicio Nango en la flota de Agent OS.

---

## 1. Arquitectura y Rol en la Flota

Nango es la plataforma open-source de referencia para la integración y gestión unificada de autenticación OAuth hacia APIs externas (GitHub, Google, Notion, Slack, Jira, etc.).

Dentro de la arquitectura de Agent OS, Nango se aloja de forma soberana en el nodo de orquestación (`<nodo-orquestacion>`), actuando como pasarela centralizada de autenticación para herramientas y agentes:

```
[Agente / Herramienta CLI]
        │
        ▼ (HTTP REST API :3003)
┌────────────────────────────────────────────────────────┐
│ Nodo de Cómputo: `<nodo-orquestacion>`                 │
│                                                        │
│ Red Docker Bridge: `nango-network`                     │
│ ┌────────────────────────────────────────────────────┐ │
│ │ • nango-server (:3003 API / :3009 Connect UI)      │ │
│ │   Imagen: `nangohq/nango-server:hosted`            │ │
│ └──────────────┬─────────────────────────┬───────────┘ │
│                │                         │             │
│                ▼ (TCP :5432)             ▼ (TCP :6379) │
│         nango-db (PostgreSQL 16)   nango-redis (7.2.4) │
└────────────────────────────────────────────────────────┘
```

### Características Principales
- **Arquitectura Oficial Self-Hosted**: 3 servicios desacoplados (`nango-server`, `nango-db`, `nango-redis`).
- **Cifrado de Credenciales**: Clave simétrica de 32 bytes (DEK / Data Encryption Key) en memoria para el cifrado en reposo de tokens y secretos OAuth.
- **Connect UI Integrada**: Interfaz web en puerto 3009 (`FLAG_SERVE_CONNECT_UI=true`) para autorizaciones visuales y flujos OAuth interactivos.
- **Compatibilidad Multi-Arquitectura**: En plataformas aarch64 (ARM64), soporta ejecución transparente mediante registro de emulación binfmt (`tonistiigi/binfmt`).

---

## 2. Requisitos de Hardware y Red

| Recurso | Mínimo Recomendado | Notas |
|---|---|---|
| **CPU** | 2-4 vCPUs | Límite por defecto: `nango-server` 1.5, `nango-db` 1.0, `nango-redis` 0.5 |
| **RAM** | 2 GB libres | Límite por defecto: `nango-server` 1024MB, `nango-db` 512MB, `nango-redis` 256MB |
| **Disco** | 10 GB SSD | Volúmenes persistentes `nango-db-data`, `nango-redis-data`, `nango-server-data` |
| **Red** | Red interna / Tailscale | Puertos `3003` (API Server) y `3009` (Connect UI) |

---

## 3. Procedimiento de Despliegue Soberano (Docker Compose)

La plantilla estándar está formalizada en `templates/nango/docker-compose.yml` y el fichero de variables de entorno en `templates/nango/.env.example`.

### Paso 1: Aprovisionar directorio de servicio en el nodo
```bash
ssh <nodo-orquestacion> "mkdir -p ~/services/nango"
scp templates/nango/docker-compose.yml <nodo-orquestacion>:~/services/nango/
```

### Paso 2: Generar y aprovisionar variables de entorno (`.env`)
En el servidor remoto, generar una clave de cifrado segura de 32 bytes en base64 y una contraseña de base de datos:
```bash
ssh <nodo-orquestacion> "bash -s" << 'EOF'
cd ~/services/nango
KEY=$(openssl rand -base64 32)
PASS=$(openssl rand -hex 16)
cat <<ENV > .env
HOST_BIND_IP=0.0.0.0
NANGO_SERVER_PORT=3003
NANGO_CONNECT_UI_PORT=3009
NANGO_ENCRYPTION_KEY=${KEY}
NANGO_DB_USER=nango
NANGO_DB_PASSWORD=${PASS}
NANGO_DB_NAME=nango
NANGO_SERVER_URL=http://localhost:3003
NANGO_PUBLIC_SERVER_URL=http://localhost:3003
NANGO_LOG_LEVEL=info
NANGO_SERVER_CPU_LIMIT=1.5
NANGO_SERVER_MEMORY_LIMIT=1024M
NANGO_SERVER_CPU_RESERVATION=0.2
NANGO_SERVER_MEMORY_RESERVATION=256M
NANGO_DB_CPU_LIMIT=1.0
NANGO_DB_MEMORY_LIMIT=512M
NANGO_DB_CPU_RESERVATION=0.1
NANGO_DB_MEMORY_RESERVATION=128M
NANGO_REDIS_CPU_LIMIT=0.5
NANGO_REDIS_MEMORY_LIMIT=256M
NANGO_REDIS_CPU_RESERVATION=0.05
NANGO_REDIS_MEMORY_RESERVATION=64M
ENV
chmod 600 .env
EOF
```

> [!IMPORTANT]
> `NANGO_ENCRYPTION_KEY` **debe ser generada con `openssl rand -base64 32`**. Nango decodifica la clave en formato base64 y valida estrictamente que la longitud resultante sea de 32 bytes (`DEK_BYTE_LENGTH`). El uso de cadenas hexadecimales o longitudes distintas provocará un fallo fatal en el módulo KMS (`assertDekLength`).

### Paso 3: Soporte para nodos ARM64 (si aplica)
Si el host corre sobre arquitectura ARM64 (`aarch64`), habilitar los emuladores binfmt en el kernel del host antes de iniciar el contenedor:
```bash
docker run --privileged --rm tonistiigi/binfmt --install all
```

### Paso 4: Iniciar el stack de servicios
```bash
cd ~/services/nango
docker compose up -d
```

---

## 4. Verificación de Salud y Diagnóstico en Vivo

### Comprobación del endpoint de salud (API)
```bash
curl -s -i http://localhost:3003/health
```
Respuesta esperada:
```http
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Content-Length: 15

{"result":"ok"}
```

### Comprobación de la interfaz Connect UI
```bash
curl -s -I http://localhost:3009
```
Respuesta esperada:
```http
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
```

### Inspección de logs y contenedores
```bash
# Ver estado de los 3 contenedores
docker compose ps

# Verificar log de inicio de nango-server
docker logs nango-server --tail 50
```

---

## 5. Gestión de Secretos y Rotación

Los secretos de producción y credenciales maestras (`NANGO_SECRET_KEY`, `NANGO_ENCRYPTION_KEY`, `NANGO_DB_PASSWORD`) deben gestionarse centralizadamente según el estándar de la flota:
1. Almacenar las credenciales en Infisical bajo el path canónico de la flota:
   - **Proyecto**: `Agent OS Fleet`
   - **Entorno**: `dev`
   - **Path canónico**: `/shared`
   - **Claves gestionadas**:
     - `NANGO_SECRET_KEY`: Clave maestra consumida por agentes y clientes deterministas (`nango-client.sh`).
     - `NANGO_ENCRYPTION_KEY`: Clave simétrica de 32 bytes en base64 para cifrado de datos en reposo (DEK).
     - `NANGO_DB_PASSWORD`: Contraseña de la base de datos PostgreSQL de Nango.
2. En caso de requerir rotación de `NANGO_ENCRYPTION_KEY`, consultar el procedimiento de re-cifrado de DEK documentado en Nango KMS antes de modificar la variable.

---

## 6. Registro en el Inventario de Flota

El servicio debe registrarse en `.agents/config/fleet.yaml` bajo el bloque `<nodo-orquestacion>.services`:

```yaml
nodes:
  <nodo-orquestacion>:
    services:
      nango:
        endpoint: "http://<nodo-orquestacion>:3003"
        url: "http://<nodo-orquestacion>:3003"
        connect_ui_url: "http://<nodo-orquestacion>:3009"
        description: "Self-hosted unified OAuth & API integration platform"
```

---

## 7. Consumo Delegado por Agentes (`nango-client.sh`)

Agent OS provee un cliente determinista CLI en `scripts/agent/lib/nango-client.sh` para interactuar con Nango sin exponer claves privadas en código ni archivos de entorno:

### Sonda de salud fail-soft
```bash
bash scripts/agent/lib/nango-client.sh --check
```
- Devuelve código de salida `0` si Nango está saludable y accesible.
- Degrada limpiamente con código `2` si Nango no está configurado o está inactivo.

### Inspección de integraciones y conexiones autorizadas
```bash
# Listar integraciones configuradas en Nango
bash scripts/agent/lib/nango-client.sh --list-integrations

# Listar conexiones autorizadas activas
bash scripts/agent/lib/nango-client.sh --list-connections
```

### Consultas delegadas a través del proxy de Nango
El proxy unificado permite a los agentes ejecutar peticiones autenticadas contra APIs externas (por ejemplo Cloudflare DNS) sin que el agente conozca el token final:
```bash
# Consultar zonas DNS a través del conector cloudflare-dns
bash scripts/agent/lib/nango-client.sh \
  --proxy "/v4/zones?name=<dominio>" \
  --provider cloudflare-dns \
  --connection <id-conexion>

# Listar registros DNS de una zona en modo JSON estructurado
bash scripts/agent/lib/nango-client.sh \
  --proxy "/v4/zones/<zone_id>/dns_records?per_page=10" \
  --provider cloudflare-dns \
  --connection <id-conexion> \
  --json
```

