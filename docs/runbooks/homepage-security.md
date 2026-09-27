# Runbook: Seguridad Perimetral y Contención de Docker Socket para Homepage

> **Fecha**: 2026-09-27  
> **Objetivo**: Blindaje de Homepage contra accesos externos no autorizados y contención estricta del socket de Docker conforme a ADR 004.  
> **Hosts aplicables**: `oracle` (PaaS/Coolify) y nodos de la flota Agent OS.

---

## 1. Visión y Principios de Seguridad

Homepage es el centro de visualización de métricas y servicios de la flota. Si se expone sin control o con privilegios elevados, representa dos riesgos críticos:
1. **Escalada de Privilegios vía Docker Socket**: Montar `/var/run/docker.sock` directamente en un contenedor web permite a un atacante enviar comandos a la API de Docker y tomar control de root del host.
2. **Exposición Pública de Topología**: Dejar el dashboard accesible a internet sin autenticación filtra URLs internas, nombres de contenedores, topología de red privada e IPs de Tailscale.

Para mitigar ambos riesgos sin penalizar la infraestructura de `oracle` (**ADR 004**), se aplica una política de defensa en profundidad en dos capas:
- **Capa Interna**: Aislamiento del Docker daemon mediante `tecnativa/docker-socket-proxy` en modo solo lectura (`CONTAINERS=1`, `INFO=1`, `POST=0`) con cuota de memoria limitada a **32MB**.
- **Capa Perimetral**: Protección de acceso web mediante Cloudflare Zero Trust (Access) o middleware Basic Auth en Traefik.

---

## 2. Arquitectura de Aislamiento del Docker Socket (ADR 004)

### 2.1 Diagrama de Flujo

```
[ Red WAN / Cloudflare Access ]
             │
             ▼
      [ Traefik / Edge Proxy ] (Puerto 3000)
             │
             ▼
    [ Contenedor Homepage ] ──(Red interna: homepage-internal)──▶ [ docker-socket-proxy ]
                                                                       (Puerto 2375)
                                                                             │
                                                                 (Montaje RO: /var/run/docker.sock)
                                                                             ▼
                                                                     [ Docker Daemon Host ]
```

### 2.2 Variables de Entorno del Proxy (Mínimo Privilegio)

El proxy (`tecnativa/docker-socket-proxy`) se configura con reglas HAProxy embebidas que deniegan por defecto todo verbo que no sea de consulta elemental:

| Variable | Valor | Justificación |
| :--- | :---: | :--- |
| `CONTAINERS` | `1` | Permite a Homepage consultar estado, CPU y RAM de contenedores activos (`GET /containers/json`). |
| `INFO` | `1` | Permite consultar versión e información general de Docker (`GET /info`). |
| `POST` | `0` | **Bloqueo total**: Cualquier petición de creación, inicio, parada o borrado de contenedores retorna `403 Forbidden`. |
| `BUILD`, `COMMIT`, `EXEC` | `0` | Deniega ejecución arbitraria dentro de contenedores (`POST /containers/{id}/exec`). |
| `VOLUMES`, `SECRETS` | `0` | Bloquea inspección y manipulación de volúmenes persistentes y secretos de Swarm/Docker. |
| `NETWORKS`, `PLUGINS` | `0` | Bloquea reconfiguración de interfaces de red y extensiones del daemon. |

### 2.3 Restricción de Recursos (ADR 004)

Para garantizar que el proxy no degrade la RAM disponible en el VPS `oracle`:
```yaml
mem_limit: 32m
deploy:
  resources:
    limits:
      memory: 32M
```
El consumo habitual de `tecnativa/docker-socket-proxy` en reposo es de **~10 a 14 MB**, manteniéndose holgadamente por debajo del umbral de 32MB.

---

## 3. Verificación Determinista del Socket Proxy

Desde dentro del nodo o mediante un contenedor temporal en la red `homepage-internal`:

### 3.1 Comprobación de lectura permitida (GET)
```bash
# Debe devolver JSON con lista de contenedores y código HTTP 200
docker exec -it homepage wget -qO- http://docker-socket-proxy:2375/containers/json
```

### 3.2 Comprobación de bloqueo de escritura (POST)
```bash
# Debe devolver HTTP 403 Forbidden
docker exec -it homepage wget --spider --server-response --post-data="" \
  http://docker-socket-proxy:2375/containers/create 2>&1 | grep "403 Forbidden"
```

---

## 4. Protección Perimetral de Acceso

### 4.1 Opción A: Cloudflare Zero Trust (Access) — Recomendada

1. Acceder al panel de **Cloudflare Zero Trust** > **Access** > **Applications**.
2. Crear aplicación de tipo **Self-hosted**:
   - **Application name**: `Agent OS Fleet Dashboard`
   - **Application domain**: `homepage.tu-dominio.com` (o subdominio asignado en Coolify).
3. Configurar **Policy**:
   - **Action**: `Allow`
   - **Rule type**: `Include` > `Emails` (ej. tu cuenta de administrador) o `Email domain`.
4. Habilitar **Session Duration** (ej. 24 horas).
5. Homepage queda inmediatamente inaccesible para bots, escáneres WAN e IPs no autorizadas sin necesidad de tocar el código de la app.

### 4.2 Opción B: Traefik Basic Auth (Alternativa Local)

Si el tráfico no transita por Cloudflare Tunnel / Access:

1. Generar credenciales cifradas con `htpasswd`:
   ```bash
   echo $(htpasswd -nb admin "TuPasswordSeguro") | sed -e s/\\$/\\$\\$/g
   ```
2. Añadir labels de Traefik en `templates/homepage/docker-compose.yml` (o en la UI de Coolify):
   ```yaml
   labels:
     - "traefik.enable=true"
     - "traefik.http.routers.homepage.middlewares=homepage-auth"
     - "traefik.http.middlewares.homepage-auth.basicauth.users=admin:$$apr1$$xyz..."
   ```

---

## 5. Configuración de Homepage para Usar el Proxy

En el archivo de configuración declarativo `templates/homepage/config/docker.yaml`:

```yaml
local-docker:
  host: "tcp://docker-socket-proxy:2375"
```

Y en `templates/homepage/config/services.yaml`, vincular cualquier servicio que corresponda a un contenedor Docker de la flota:

```yaml
- Control Plane & Secretos:
    - ByteBox:
        icon: si-gnubash
        href: https://bytebox.tu-dominio.com
        description: Developer CLI & Snippets
        server: local-docker
        container: bytebox
```
Homepage consultará de forma autónoma las métricas de estado (`running`, `healthy`), CPU (%) y memoria (MB) a través del proxy seguro.

---

## 6. Procedimiento ante Incidentes

1. **Homepage muestra `Error communicating with socket`**:
   - Comprobar que el proxy está levantado: `docker ps -f name=homepage-docker-socket-proxy`.
   - Verificar logs: `docker logs --tail 50 homepage-docker-socket-proxy`.
   - Verificar conectividad en la red interna: `docker network inspect homepage_homepage-internal`.

2. **Reinicio de Emergencia**:
   ```bash
   docker restart homepage-docker-socket-proxy && docker restart homepage
   ```
