# Research Sprint 08 — Core
> Fuente: Perplexity — 2026-09-25  
> Tareas principales: Despliegue de OmniRoute Gateway Headless (T-048) e Infisical CE Standalone Lite (T-042)

---

## 1. OmniRoute Gateway Headless (Docker + RTK + Tailscale)

Para operar en modo gateway OpenAI-compatible detrás de Tailscale, OmniRoute se ejecuta exponiendo únicamente su puerto al bus local/Tailscale sin montar UI frontend innecesaria y activando la compresión de contexto RTK (*Real-Time Token Compression*).

### docker-compose.yml

```yaml
services:
  omniroute:
    image: diegosouzapw/omniroute:latest
    container_name: omniroute-gateway
    restart: unless-stopped
    # Se enlaza a localhost o a la IP específica de la interfaz tailscale0
    ports:
      - "127.0.0.1:3002:3002"
    environment:
      - PORT=3002
      - NODE_ENV=production
      - HEADLESS_MODE=true
      - API_KEY=${OMNIROUTER_API_KEY}
      # Integración con plugin de compresión RTK
      - ENABLE_RTK_COMPRESSION=true
      - RTK_COMPRESSION_RATIO=0.4
      - RTK_PRESERVE_SYSTEM_PROMPTS=true
      # Límites de proceso y log
      - LOG_LEVEL=warn
    volumes:
      # Persistencia mínima para mapeo de rutas y configuración de proveedores
      - ./data/config:/app/config:ro
    deploy:
      resources:
        limits:
          memory: 256M
```

### Parámetros clave y OpenCode CLI

- **Compresión RTK:** `ENABLE_RTK_COMPRESSION=true` activa el pipeline de reducción semántica de tokens antes de despachar a los proveedores upstream.
- **Integración `opencode-omniroute-auth`:** En el cliente OpenCode CLI/Orca ADE, la configuración se enlaza apuntando a la IP de Tailscale del nodo:
```json
{
  "omniroute": {
    "baseUrl": "http://100.77.82.13:3002/v1",
    "apiKey": "OMNIROUTER_API_KEY",
    "plugins": ["opencode-omniroute-auth"]
  }
}
```

---

## 2. Infisical Community Edition Standalone (<500MB RAM)

Infisical CE requiere por defecto PostgreSQL y Redis. Para mantenerse **estrictamente por debajo de los 500 MB**, se deben desactivar telemetry, workers asíncronos en contenedores separados, y ajustar los buffers compartidos de PostgreSQL.

### docker-compose.yml (Configuración Standalone Lite)

```yaml
services:
  infisical-db:
    image: postgres:15-alpine
    container_name: infisical-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: infisical
      POSTGRES_PASSWORD: ${DB_PASSWORD:-infisicalSecretPass123}
      POSTGRES_DB: infisical
    command: >
      postgres -c shared_buffers=64MB
               -c max_connections=20
               -c work_mem=2MB
               -c maintenance_work_mem=16MB
    volumes:
      - infisical_pg_data:/var/lib/postgresql/data
    deploy:
      resources:
        limits:
          memory: 128M

  infisical-backend:
    image: infisical/infisical:latest
    container_name: infisical-core
    restart: unless-stopped
    depends_on:
      - infisical-db
    ports:
      # Exponer en Tailscale o vincular mediante Traefik en Coolify
      - "127.0.0.1:8080:8080"
    environment:
      - NODE_ENV=production
      - DB_CONNECTION_URI=postgres://infisical:${DB_PASSWORD:-infisicalSecretPass123}@infisical-db:5432/infisical
      - ENCRYPTION_KEY=${ENCRYPTION_KEY} # 32 bytes hex: openssl rand -hex 16
      - AUTH_SECRET=${AUTH_SECRET}         # openssl rand -base64 32
      - TELEMETRY_ENABLED=false
      - CAPTCHA_ENABLED=false
      - SMTP_HOST=""
      # Límite de memoria para Node.js V8
      - NODE_OPTIONS=--max-old-space-size=256
    deploy:
      resources:
        limits:
          memory: 320M

volumes:
  infisical_pg_data:
```

---

## 3. Advertencias y Compatibilidades Clave

- **Picos de arranque en Infisical:** Al inicializar migraciones de base de datos (`knex`/`prisma`), Infisical puede alcanzar ~350MB por unos segundos antes de estabilizarse en ~160-220MB. Si Coolify impone un hard-limit menor a 300MB, el contenedor morirá con un error OOMKilled durante el arranque.
- **Redis opcional:** En despliegues comunitarios de un solo nodo destinados exclusivamente a inyección CLI (`infisical run`), Redis se puede omitir si no se requiere cacheo distribuido masivo de UI.
- **MTU en Tailscale y llamadas Streaming/RTK:** Si se observan desconexiones en respuestas streaming tipo `text/event-stream` entre `oracle` y `datamanager`, asegúrate de que el buffer TCP de Traefik no mantenga los chunks abiertos y que no existan discrepancias de MTU (Tailscale usa 1280 por defecto). Desactiva el buffering de proxy en Traefik mediante la label:
```yaml
traefik.http.middlewares.buffering.buffering.maxResponseBodyBytes=0
```
