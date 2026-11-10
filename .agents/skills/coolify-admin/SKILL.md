---
name: coolify-admin
description: Gestión programática, despliegues y control de aplicaciones y stacks Docker Compose en Coolify vía API / CLI determinista con soporte Infisical.
---

# Coolify Admin (Universal Coolify PaaS Ops)

Habilidad estándar de `agent-os` para interactuar programáticamente con la API de Coolify (v4+) para listar aplicaciones, inspeccionar configuraciones, actualizar stacks Docker Compose y disparar redeploys de forma determinista (a 0 tokens de inferencia).

## Cuándo usar
- Desplegar, reiniciar o verificar el estado de aplicaciones y servicios en Coolify PaaS.
- Automatizar despliegues continuos o actualizar variables de entorno y stacks Docker Compose.
- Consultar recursos, UUIDs de aplicaciones o logs de ejecución en nodos gestionados por Coolify.

## Prerrequisitos, Endpoints y Gestión de Credenciales

La habilidad interactúa con la API de Coolify (v4+) de forma determinista y segura:

1. **Resolución de Endpoint Base**:
   - **Prioridad 1**: Variable de entorno `COOLIFY_BASE_URL`, `COOLIFY_API_URL` o `COOLIFY_URL` (ej: `http://127.0.0.1:8000/api/v1`).
   - **Prioridad 2 (Fleet)**: Inspección determinista automática del nodo PaaS (`role: orchestration-and-paas` o servicio `coolify`) en `.agents/config/fleet.yaml`.
   - **Fail-closed**: Si no está definido en el entorno ni en Fleet, el script aborta con error explicativo (sin URLs mockeadas ni hardcodeadas).

2. **Gestión de Credenciales (Bearer Token)**:
   - **Prioridad 1 (Infisical / Env)**:
     ```bash
     infisical run -- bash scripts/ops/coolify.sh <subcomando>
     # O inyección efímera:
     export COOLIFY_TOKEN="<token>"
     ```
   - **Fallback 2**: Archivo local `${COOLIFY_ENV_FILE:-$HOME/.config/agent-os/api_keys.env}`.

3. **Ayuda Estándar**:
   ```bash
   bash scripts/ops/coolify.sh --help
   ```

---

## Subcomandos Disponibles (`scripts/ops/coolify.sh`)

### 1. Listar Aplicaciones
Devuelve una tabla compacta con UUID, Nombre, Estado y FQDN de todas las aplicaciones:

```bash
bash scripts/ops/coolify.sh list
```

Para obtener salida JSON pura parseable con `jq`:
```bash
bash scripts/ops/coolify.sh list --json
```

### 2. Obtener Detalles de una Aplicación
Muestra la configuración completa de una aplicación (build_pack, puertos, etiquetas Traefik, compose, etc.):

```bash
bash scripts/ops/coolify.sh get <uuid>
```

### 3. Actualizar Stack Docker Compose
Convierte o actualiza la aplicación para que utilice una definición Docker Compose, codificando el archivo local en base64 y enviándolo a `PATCH /applications/<uuid>`:

```bash
bash scripts/ops/coolify.sh update-compose <uuid> <ruta_a_compose.yml>
```

### 4. Disparar Despliegue Forzado (Redeploy)
Inicia de inmediato un despliegue forzado (`POST /deploy?uuid=<uuid>&force=true`):

```bash
bash scripts/ops/coolify.sh deploy <uuid>
```

---

## Buenas Prácticas y Restricciones de Flota

1. **Gobernanza de Recursos (ADR 004)**:
   - Al desplegar stacks en servidores con limitaciones de RAM o disco (como `<nodo-orquestacion>`), limitar siempre los servicios auxiliares (`tecnativa/docker-socket-proxy` a `mem_limit: 32m`).
2. **No Montar Docker Socket Directo**:
   - Evitar `volumes: - /var/run/docker.sock:/var/run/docker.sock`. Interpolar siempre el proxy de solo lectura en una red interna (`internal: true`).
3. **Persistencia de Datos**:
   - Asegurar que los volúmenes nombrados o bind mounts (`homepage-config`, etc.) estén correctamente definidos en la sección `volumes` del Compose.
