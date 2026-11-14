# Runbook: Despliegue Universal Determinista de Next.js en Coolify (Flat & Monorepo)

> **Fecha**: 2026-11-14  
> **Objetivo**: Procedimiento Operativo Estándar (SOP) para que cualquier agente satélite o mantenedor audite, prepare, dockerice y despliegue aplicaciones Next.js 14/15 en Coolify VPS de forma autónoma, determinista y segura.  
> **Cobertura**: Proyectos Next.js planos (ej. `annascheer-web`) y monorepos pnpm workspaces (ej. `leaderboard-platform`).  
> **Hosts aplicables**: `<nodo-infraestructura>` (PaaS Coolify).

---

## 1. Visión y Matriz de Decisión Arquitectónica

El despliegue de aplicaciones Next.js en Coolify requiere compilación contenerizada multi-stage mediante Docker, garantizando un tamaño mínimo de imagen y aislamiento de permisos de ejecución.

### 1.1 Tipologías de Repositorio Soportadas

| Tipología | Indicadores de Detección | Plantilla Recomendada | Entrypoint Runner |
|---|---|---|---|
| **Flat (Estándar)** | `package.json` en raíz, sin `apps/` ni `pnpm-workspace.yaml` | `templates/Dockerfile.flat.template` | `CMD ["node", "server.js"]` |
| **Monorepo (pnpm)** | `pnpm-workspace.yaml`, `apps/web/` o `packages/*` | `templates/Dockerfile.monorepo.template` | `CMD ["node", "apps/web/server.js"]` |

### 1.2 Regla de Separación de Variables de Entorno

- **Variables Públicas de Compilación (`NEXT_PUBLIC_*`)**:
  - Next.js embebe estas variables en el bundle estático **durante el build**.
  - **Deben declararse** como `ARG` y `ENV` en la fase `builder` del `Dockerfile`.
  - En Coolify deben registrarse como: **Build Variable (Build Args)**.
- **Variables Secretas de Ejecución (`runtime`)**:
  - Credenciales de base de datos, tokens de API privadas, claves maestras (`DATABASE_URL`, `STRIPE_SECRET_KEY`, `SESSION_SECRET`).
  - **Nunca deben declararse** como `ARG` en el `Dockerfile`.
  - Se configuran directamente en Coolify o se inyectan en memoria con Infisical.

---

## 2. Flujo Operativo Paso a Paso

```
 [1. Auditoría Pre-Build] ──▶ [2. Dockerfile Standalone] ──▶ [3. DNS Cloudflare] ──▶ [4. Coolify Deploy]
   (audit-next.sh)             (Flat vs Monorepo)              (cloudflare-dns.sh)     (scripts/ops/coolify.sh)
```

---

### Paso 1: Auditoría Técnica Pre-Build

Antes de generar o modificar Dockerfiles, ejecuta la sonda determinista de auditoría desde la raíz del satélite o pasando la ruta del proyecto:

```bash
# Ejecutar auditoría sobre el proyecto actual
bash .agents/skills/coolify-nextjs-deploy/scripts/audit-next.sh .

# O sobre un directorio específico
bash .agents/skills/coolify-nextjs-deploy/scripts/audit-next.sh /ruta/al/satelite
```

#### Verificaciones Críticas de la Sonda:
1. **`output: 'standalone'`**:
   - En Next.js plano: debe constar en `next.config.ts`, `next.config.mjs` o `next.config.js`.
   - En Monorepo: debe constar en `apps/web/next.config.*`.
   - Si no está presente, añade:
     ```typescript
     const nextConfig = {
       output: 'standalone',
     };
     export default nextConfig;
     ```
2. **Dependencia `sharp`**:
   - Requerida para optimización eficiente de imágenes bajo standalone Alpine.
   - Si se usa `next/image`, instálala: `npm i sharp` o `pnpm add sharp`.
3. **Directorio `public/`**:
   - Requiere al menos un archivo (ej. `public/.gitkeep`) para evitar errores en Docker durante `COPY public`. La sonda lo crea automáticamente si no existe.

---

### Paso 2: Generación del Dockerfile Multi-Stage

Basado en la recomendación emitida por `audit-next.sh`, copia la plantilla adecuada a la raíz del repositorio satélite:

#### Caso A: Aplicación Next.js Plana
```bash
cp .agents/skills/coolify-nextjs-deploy/templates/Dockerfile.flat.template Dockerfile
cp .agents/skills/coolify-nextjs-deploy/templates/dockerignore.template .dockerignore
```

#### Caso B: Monorepo pnpm Workspaces
```bash
cp .agents/skills/coolify-nextjs-deploy/templates/Dockerfile.monorepo.template Dockerfile
cp .agents/skills/coolify-nextjs-deploy/templates/dockerignore.template .dockerignore
```

#### Personalización de Build Args en Dockerfile:
Abre el `Dockerfile` y descomenta las variables públicas requeridas por tu aplicación:
```dockerfile
# Build-time environment variables (NEXT_PUBLIC_*)
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL

ARG NEXT_PUBLIC_SITE_URL
ENV NEXT_PUBLIC_SITE_URL=$NEXT_PUBLIC_SITE_URL
```

---

### Paso 3: Aprovisionamiento DNS en Cloudflare

Para que Coolify emita los certificados SSL y enrute el tráfico correctamente, los registros DNS deben apuntar a la IP del VPS:

```bash
# Modo Nube Gris (recomendado para el primer despliegue mientras Traefik emite SSL ACME)
bash .agents/skills/coolify-nextjs-deploy/scripts/cloudflare-dns.sh tudominio.com <IP_VPS> --unproxied

# Conmutar a Nube Naranja (Proxy Cloudflare activo tras verificar SSL)
bash .agents/skills/coolify-nextjs-deploy/scripts/cloudflare-dns.sh tudominio.com <IP_VPS> --proxied
```

*Nota*: `cloudflare-dns.sh` busca automáticamente credenciales en `.env*` o a través de `nango-client.sh`.

---

### Paso 4: Creación y Despliegue en Coolify

#### 4.1 Configuración de la Aplicación en Coolify:
- **Build Pack**: `Dockerfile`
- **Docker Compose / Dockerfile Path**: `/Dockerfile`
- **Exposed Port**: `3000`
- **Domains (FQDN)**: `https://tudominio.com,https://www.tudominio.com`
- **Build Args**:
  - `NEXT_PUBLIC_API_URL=https://api.tudominio.com`
- **Runtime Environment Variables**:
  - Inyectar las variables secretas no expuestas al cliente.

#### 4.2 Control Programático vía CLI Determinista (`scripts/ops/coolify.sh`):
Gracias a la sincronización del core (T-222), cualquier satélite tiene acceso a la herramienta CLI:

```bash
# 1. Listar aplicaciones para obtener el UUID de la app
infisical run -- bash scripts/ops/coolify.sh list

# 2. Obtener estado y detalles de la aplicación
infisical run -- bash scripts/ops/coolify.sh get <UUID_APP>

# 3. Disparar el despliegue programáticamente
infisical run -- bash scripts/ops/coolify.sh deploy <UUID_APP>
```

---

## 3. Resolución de Errores Frecuentes (Troubleshooting)

### 3.1 Error: `Cannot find module '/app/server.js'` en Monorepos
- **Causa**: En un monorepo pnpm con `apps/web`, Next.js standalone preserva la jerarquía del workspace y genera el archivo en `/app/apps/web/server.js`.
- **Solución**: En el `Dockerfile.monorepo.template`, verifica que el entrypoint sea:
  ```dockerfile
  CMD ["node", "apps/web/server.js"]
  ```

### 3.2 Error 522 Cloudflare (Connection Timed Out)
- **Causa**: El registro DNS apunta a una IP incorrecta o el contenedor en Coolify no responde en el puerto 3000.
- **Diagnóstico**:
  ```bash
  # Verificar IP y estado de registro DNS
  bash .agents/skills/coolify-nextjs-deploy/scripts/cloudflare-dns.sh tudominio.com
  # Verificar estado en Coolify
  bash scripts/ops/coolify.sh get <UUID_APP>
  ```

### 3.3 Error de Validación ACME SSL (Let's Encrypt)
- **Causa**: Cloudflare tiene activada la redirección automática HTTPS y bloquea la validación HTTP-01 de Traefik.
- **Solución**: Conmuta a modo Nube Gris (`--unproxied`), realiza el deploy en Coolify para que emita el certificado, y vuelve a activar el proxy (`--proxied`).

### 3.4 Build Falla por Variables `NEXT_PUBLIC_*` No Definidas
- **Causa**: El código del cliente asume que `NEXT_PUBLIC_API_URL` tiene un valor durante `pnpm run build`.
- **Solución**: Asegúrate de definir el valor tanto en los Build Args de Coolify como en los `ARG` y `ENV` de la fase `builder` del Dockerfile.
