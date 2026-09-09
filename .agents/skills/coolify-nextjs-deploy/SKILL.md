---
name: coolify-nextjs-deploy
description: Auditoría pre-build, dockerización multi-stage standalone de Next.js 15, aprovisionamiento de registros DNS A/CNAME en Cloudflare (multi-env) y despliegue en Coolify VPS.
---

# Coolify Next.js Deployment Skill

Esta habilidad guía al agente para preparar, auditar y desplegar aplicaciones Next.js en Coolify mediante Docker multi-stage, automatizando el aprovisionamiento de registros DNS en Cloudflare con soporte multi-entorno.

---

## 📋 Flujo de Trabajo Operativo

### Paso 1: Auditoría Técnica Pre-Build
Ejecuta el script determinista de auditoría para verificar la configuración de Next.js, presencia de `sharp`, coherencia de `.env*` y estado del socket Docker:

```bash
./.agents/skills/coolify-nextjs-deploy/scripts/audit-next.sh .
```

Si falta la propiedad `output: 'standalone'` en `next.config.ts`, agrégala:
```typescript
const nextConfig: NextConfig = {
  output: 'standalone',
  // ... resto de la configuración
};
```

---

### Paso 2: Generación de Archivos Docker de Producción
Copia las plantillas estáticas de la habilidad a la raíz del repositorio:

```bash
cp .agents/skills/coolify-nextjs-deploy/templates/Dockerfile.template Dockerfile
cp .agents/skills/coolify-nextjs-deploy/templates/dockerignore.template .dockerignore
```

- **Variables `NEXT_PUBLIC_*`**: Declara cualquier variable de compilación pública con `ARG` y `ENV` dentro de la fase `builder` del `Dockerfile`.
- **Variables Secretas (`runtime`)**: Manténlas exclusivamente en la sección de variables de entorno de Coolify (`GEMINI_API_KEY`, etc.).

---

### Paso 3: Aprovisionamiento DNS en Cloudflare
Ejecuta el script determinista de Cloudflare para crear/actualizar los registros `A` y `CNAME` (`www`). El script buscará automáticamente las credenciales (`CLOUDFLARE_API_TOKEN` / `CLOUDFLARE_DNS_API_TOKEN`) en `.env.local`, `.env.production`, `.env.dev` o `.env`:

```bash
# Modo estándar con Proxy activado (Nube Naranja)
./.agents/skills/coolify-nextjs-deploy/scripts/cloudflare-dns.sh tudominio.com [IP_VPS] --proxied

# Modo Nube Gris (recomendado durante el primer despliegue si Traefik en Coolify requiere validación ACME SSL HTTP-01)
./.agents/skills/coolify-nextjs-deploy/scripts/cloudflare-dns.sh tudominio.com [IP_VPS] --unproxied
```

---

### Paso 4: Despliegue y Registro en Coolify
1. En el panel de Coolify, crea una **Application** apuntando al repositorio de GitHub y la rama principal (`main`).
2. Configura los parámetros:
   - **Build Pack**: `Dockerfile`
   - **Exposed Port**: `3000`
   - **Domains (FQDN)**: `https://tudominio.com`
3. Inyecta las variables de entorno de `runtime` en Coolify.
4. Presiona **Deploy**.

---

## 🛠️ Resolución de Errores Frecuentes (Troubleshooting)

- **Error 522 Cloudflare (Connection Timed Out)**:
  Ocurre cuando el registro DNS apunta a la IP equivocada (ej: IP local) o cuando Traefik no está escuchando en el puerto 80/443 de la IP del VPS. Ejecuta `cloudflare-dns.sh tudominio.com IP_REAL_VPS` para corregir la IP en Cloudflare al instante.
- **Error ACME SSL Challenge**:
  Si Let's Encrypt falla en el primer despliegue de Coolify por bloqueo de Cloudflare HTTPS redirect, conmuta temporalmente a Nube Gris con `./scripts/cloudflare-dns.sh tudominio.com --unproxied`, emite el certificado en Coolify, y reconmuta a Nube Naranja con `--proxied`.
