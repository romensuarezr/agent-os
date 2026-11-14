---
name: coolify-nextjs-deploy
description: Auditoría pre-build, dockerización multi-stage standalone de Next.js (soporte flat y monorepo pnpm), aprovisionamiento de DNS Cloudflare y despliegue programático en Coolify.
---

# Coolify Next.js Deployment Skill

Esta habilidad guía al agente para preparar, auditar y desplegar aplicaciones Next.js en Coolify mediante Docker multi-stage standalone, automatizando la selección de plantilla (plana vs monorepo pnpm workspaces), el aprovisionamiento de DNS en Cloudflare y el control programático del despliegue en Coolify.

> 📖 **Runbook Canónico**: Para el procedimiento detallado paso a paso, consulta [docs/runbooks/coolify-nextjs-deploy.md](../../../docs/runbooks/coolify-nextjs-deploy.md).

## Cuándo usar
- Preparar y dockerizar aplicaciones Next.js 14/15 con modo `output: 'standalone'`.
- Auditar configuraciones pre-build (`audit-next.sh`) detectando automáticamente si el proyecto es flat o monorepo pnpm.
- Generar Dockerfiles optimizados para proyectos planos (`Dockerfile.flat.template`) o monorepos (`Dockerfile.monorepo.template`).
- Aprovisionar y gestionar registros DNS en Cloudflare vinculados al VPS de Coolify.
- Controlar despliegues programáticamente vía API de Coolify (`scripts/ops/coolify.sh`).

---

## 📋 Flujo de Trabajo Operativo

### Paso 1: Auditoría Técnica Pre-Build
Ejecuta el script determinista de auditoría para diagnosticar tipología, gestor de paquetes y validar `output: 'standalone'`:

```bash
bash .agents/skills/coolify-nextjs-deploy/scripts/audit-next.sh .
```

Si falta la propiedad `output: 'standalone'` en `next.config.*`, incorpórala:
```typescript
const nextConfig = {
  output: 'standalone',
  // ... resto de la configuración
};
export default nextConfig;
```

---

### Paso 2: Generación del Dockerfile de Producción
Copia la plantilla adecuada recomendada por `audit-next.sh`:

#### Opción A: Aplicación Flat (estándar en raíz)
```bash
cp .agents/skills/coolify-nextjs-deploy/templates/Dockerfile.flat.template Dockerfile
cp .agents/skills/coolify-nextjs-deploy/templates/dockerignore.template .dockerignore
```

#### Opción B: Monorepo pnpm (workspaces `apps/web` y `packages/*`)
```bash
cp .agents/skills/coolify-nextjs-deploy/templates/Dockerfile.monorepo.template Dockerfile
cp .agents/skills/coolify-nextjs-deploy/templates/dockerignore.template .dockerignore
```

- **Variables `NEXT_PUBLIC_*`**: Decláralas con `ARG` y `ENV` dentro de la fase `builder` del `Dockerfile`, y regístralas en Coolify como **Build Args**.
- **Variables Secretas (`runtime`)**: Manténlas exclusivamente en las variables de entorno de Coolify o inyéctalas con Infisical.

---

### Paso 3: Aprovisionamiento DNS en Cloudflare
Ejecuta el script determinista de Cloudflare para apuntar el dominio al VPS:

```bash
# Modo Nube Gris (recomendado para el primer despliegue mientras Traefik emite SSL ACME)
bash .agents/skills/coolify-nextjs-deploy/scripts/cloudflare-dns.sh tudominio.com [IP_VPS] --unproxied

# Conmutar a Modo Proxy (Nube Naranja activa tras verificar SSL)
bash .agents/skills/coolify-nextjs-deploy/scripts/cloudflare-dns.sh tudominio.com [IP_VPS] --proxied

# Verificación de registros existentes mediante Nango (solo lectura, cero tokens en repo)
bash scripts/agent/lib/nango-client.sh --proxy "/v4/zones?name=tudominio.com" --provider cloudflare-dns --connection <id-conexion>
```

---

### Paso 4: Despliegue y Control en Coolify vía CLI
Utiliza la herramienta determinista `scripts/ops/coolify.sh` (sincronizada desde el core) para operar la API de Coolify:

```bash
# Listar aplicaciones en el servidor para obtener el UUID
infisical run -- bash scripts/ops/coolify.sh list

# Consultar estado de la aplicación
infisical run -- bash scripts/ops/coolify.sh get <UUID_APP>

# Disparar despliegue inmediato
infisical run -- bash scripts/ops/coolify.sh deploy <UUID_APP>
```

---

## 🛠️ Resolución de Errores Frecuentes (Troubleshooting)

- **Entrypoint en Monorepos (`apps/web/server.js`)**: En monorepos, Next.js genera el servidor en `apps/web/server.js`. Verifica que el `Dockerfile` contenga `CMD ["node", "apps/web/server.js"]`.
- **Variables `NEXT_PUBLIC_*` vacías en producción**: Asegúrate de que las variables estén definidas en **Build Args** de Coolify y declaradas con `ARG` en la fase `builder` de compilación.
- **Error 522 Cloudflare**: Comprueba que el registro DNS apunta a la IP pública correcta del VPS con `bash .agents/skills/coolify-nextjs-deploy/scripts/cloudflare-dns.sh tudominio.com`.
- **Fallo de SSL Challenge (Let's Encrypt)**: Conmuta temporalmente a Nube Gris con `--unproxied`, emite el certificado en Coolify, y vuelve a conmutar a `--proxied`.
