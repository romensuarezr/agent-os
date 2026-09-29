# Runbook: Configuración y Despliegue de Glances Web en Nodo de Cómputo

> **Fecha**: 2026-09-27  
> **Objetivo**: Proveer telemetría de hardware en tiempo real desde un nodo worker de cómputo (`<worker-node>`) hacia el panel Homepage en el nodo de infraestructura (`<infra-node>`).  
> **Host destino**: Nodo de cómputo/inferencia (`<worker-node>`).  
> **Cumplimiento**: **ADR 004** — Cero consumo de disco ni servicios de telemetría adicionales en `<infra-node>` VPS.

---

## 1. Visión y Arquitectura

Para monitorizar el nodo de cómputo/inferencia `<worker-node>` sin saturar el almacenamiento ni la memoria del VPS de infraestructura `<infra-node>` (ADR 004):
- **Worker Node (`<TAILSCALE_IP_WORKER>`)**: Ejecuta el daemon de telemetría Glances en modo web server (`glances -w`) escuchando en el puerto `61208`.
- **Restricción de Red**: El puerto `61208` se amarra estrictamente a la interfaz Tailscale (`tailscale0`), de modo que no queda expuesto a WAN ni a redes públicas no seguras.
- **VPS de Infraestructura**: Homepage simplemente consume la API REST de Glances a través del túnel cifrado privado de Tailscale, sin levantar ningún proceso de telemetría local pesado.

---

## 2. Opciones de Despliegue en `<worker-node>`

### Opción A: Despliegue vía Docker Compose (Recomendada)

Utilizar la plantilla [`templates/homepage/glances-compose.yml`](templates/homepage/glances-compose.yml):

```yaml
services:
  glances:
    image: nicolargo/glances:latest-full
    container_name: glances-telemetry
    restart: unless-stopped
    ports:
      - "${GLANCES_BIND_IP:-127.0.0.1}:61208:61208"
    environment:
      - GLANCES_OPT=-w
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /etc/os-release:/etc/os-release:ro
    pid: host
```

Puesta en marcha:
```bash
docker compose -f templates/homepage/glances-compose.yml up -d
```

### Opción B: Servicio Nativo / Systemd (Sin Docker)

Si se prefiere ejecutar directamente en el entorno Python del host:

1. Instalar Glances con soporte web:
   ```bash
   pip install "glances[web]"
   ```
2. Crear la unidad de servicio systemd `/etc/systemd/system/glances.service`:
   ```ini
   [Unit]
   Description=Glances Telemetry Web Service
   After=network.target tailscaled.service

   [Service]
   ExecStart=/usr/local/bin/glances -w -B ${TAILSCALE_IP:-127.0.0.1} -p 61208
   Restart=on-failure
   RestartSec=5s
   User=root

   [Install]
   WantedBy=multi-user.target
   ```
3. Habilitar e iniciar:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable --now glances.service
   ```

---

## 3. Configuración de Firewall Perimetral (UFW)

Para autorizar exclusivamente el tráfico entrante a través de la interfaz de Tailscale hacia el puerto `61208` en `<worker-node>`:

```bash
sudo ufw allow in on tailscale0 to any port 61208 proto tcp
sudo ufw status verbose | grep 61208
```

---

## 4. Comprobaciones Deterministas con cURL

Desde el propio nodo `<worker-node>` o desde el host de control/infraestructura:

### 4.1 Comprobación de API v4 / v3
```bash
# Variables del entorno (definidas en config/fleet.yaml o localmente)
WORKER_IP="${WORKER_TAILSCALE_IP:-127.0.0.1}"

# Comprobación API v4
curl -s -f "http://${WORKER_IP}:61208/api/4/all" | jq -r 'keys | .[0:10]'

# Comprobación API v3 (fallback de compatibilidad)
curl -s -f "http://${WORKER_IP}:61208/api/3/all" | jq -r 'keys | .[0:10]'
```

### 4.2 Métricas Específicas
```bash
# CPU
curl -s "http://${WORKER_IP}:61208/api/4/cpu" | jq .

# Memoria RAM
curl -s "http://${WORKER_IP}:61208/api/4/mem" | jq .

# Sistema de ficheros y discos
curl -s "http://${WORKER_IP}:61208/api/4/fs" | jq .
```

---

## 5. Configuración en Homepage (`widgets.yaml`)

En `templates/homepage/config/widgets.yaml`:

```yaml
- resources:
    cpu: true
    memory: true
    disk: /
    label: "Infra VPS"

- glances:
    label: "Worker Node"
    url: "http://${WORKER_TAILSCALE_IP}:61208"
    version: 4
    cpu: true
    mem: true
    expanded: true
    disk:
      - /
```

---

## 6. Solución de Problemas

1. **Homepage muestra `API Error` en Worker Node**:
   - Verificar si Glances está corriendo: `curl -I "http://${WORKER_IP}:61208/api/4/status"`.
   - Si la versión de Glances instalada es 3.x, cambiar `version: 3` en `widgets.yaml`.
2. **Conexión rechazada o timeout**:
   - Verificar que Tailscale está levantado en ambos nodos (`tailscale status`).
   - Comprobar que UFW permite el tráfico en `tailscale0` (`sudo ufw status`).

