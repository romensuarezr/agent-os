# 🏗️ Capa 3: VPS `oracle` (Infraestructura SaaS y Automatizaciones)

> **Ámbito**: Servidor de aplicaciones y servicios de producción en Oracle Cloud (OCI Free Tier)  
> **Acceso**: `ssh oracle` | IP Pública: `158.179.213.240` | Dominio DNS: `romensuarez.com`  
> **Entorno**: ARM64 Ampere A1 (Ubuntu 22.04 LTS con 8 GB de Swap obligatoria)

---

## 1. Coolify (Gestor Central de Infraestructura)

- **URL de Acceso**: `https://coolify.romensuarez.com` (puerto interno 8000).
- **Proxy Inverso**: Traefik con certificados automáticos y Cloudflare SSL en modo Full.
- **Capacidad**: Orquestación y despliegue continuo de ~25 contenedores Docker.
- **Acceso para Agentes**:
  - Hermes Agent cuenta con un **MCP de Coolify** preinstalado para inspección y reinicio de contenedores.
  - API REST de Coolify para automatizaciones CI/CD.

---

## 2. Base de Datos Unificada (Unified-DB)

- **Contenedor**: `postgresql-p88osccsk0wk0wswk4so80cc` (PostgreSQL 16).
- **Red Docker**: `p88osccsk0wk0wswk4so80cc` (red privada interna sin exposición directa a internet).
- **Bases de Datos Aisladas**:
  - `n8n`: Automatizaciones de flujos.
  - `typebot`: Formularios y datos de sesiones de chatbot.
  - `chatwoot`: Conversaciones y tickets de soporte omnicanal.
  - `evolution`: Instancias y estados de conexión de WhatsApp.

> [!IMPORTANT]
> **Regla de Oro de Bases de Datos**: NUNCA desplegar contenedores adicionales de PostgreSQL en `oracle`. Cualquier servicio nuevo que requiera PostgreSQL debe aprovisionar su base de datos dentro de Unified-DB. Las credenciales se centralizarán en Infisical.

---

## 3. n8n (Automatización con Soporte Dual MCP / REST)

- **URL Pública**: `https://n8n.romensuarez.com` (puerto interno 5678).
- **Integración para Agentes**:
  1. **N8N Native MCP (Preferido para ejecución por Agentes)**:
     - Endpoint: `https://n8n.romensuarez.com/mcp-server/http`
     - Autenticación: `$N8N_MCP_TOKEN`
     - Ventaja: Permite a los agentes descubrir y ejecutar flujos seleccionados (marcados con "Available in MCP") como herramientas nativas de IA, sin requerir webhooks individuales.
  2. **N8N REST API**:
     - Operaciones programáticas de creación, lectura, actualización y activación de workflows.

---

## 4. Servicios de Comunicación y Almacenamiento

### Evolution API (WhatsApp)
- **URL**: `https://whatsapp.romensuarez.com` (puerto interno 8080).
- **Uso**: API HTTP completa para envío/recepción de mensajes de WhatsApp, webhooks de eventos y conexión directa para agentes conversacionales.

### MinIO (Almacenamiento de Objetos S3 Compatible)
- **Consola**: `https://minio.romensuarez.com` (puerto interno 9001).
- **API S3**: `https://cdn.romensuarez.com` (puerto interno 9000).
- **Buckets Configurados**:
  - `ghost-media`: Archivos multimedia públicos para el blog (política GET pública).
  - `typebot`: Assets y uploads de usuarios en chatbots (política privada).

### Chatwoot & Typebot
- **Chatwoot**: `https://chatwoot.romensuarez.com` (puerto 3000) — Bandeja omnicanal de soporte y supervisión de agentes.
- **Typebot**: `https://typebot-builder.romensuarez.com` / `typebot-viewer` (puerto 3000) — Creador visual de flujos conversacionales interactivos.

### Respaldo y Continuidad (Cloudflare R2)
- Script de backup automatizado diario de Unified-DB hacia Cloudflare R2 con una política de retención de 7 días.
