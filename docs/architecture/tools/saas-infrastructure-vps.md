# 🏗️ Capa 3: SaaS Nodes (Infraestructura PaaS, Servicios y Automatizaciones)

> **Ámbito**: Nodos de hosting y servidores de aplicaciones en producción  
> **Acceso**: Conexión SSH o túnel seguro hacia el nodo PaaS (`saas-node-02`)  
> **Configuración Activa**: Consultar la sección `nodes` en `config/fleet.yaml`

---

## 1. Gestor Central PaaS (Coolify)

- **URL Típica**: `https://coolify.example.com` (o puerto interno 8000 tras proxy inverso).
- **Proxy Inverso**: Traefik con certificados automáticos Let's Encrypt y terminación SSL.
- **Capacidad**: Orquestación y despliegue continuo de contenedores Docker y microservicios.
- **Acceso para Agentes**:
  - Servidores MCP dedicados para inspección y reinicio de contenedores.
  - API REST del gestor para automatizaciones CI/CD.

---

## 2. Base de Datos Relacional Unificada (Unified-DB)

- **Motor**: PostgreSQL 16 sobre contenedor Docker con volumen persistente en red interna privada.
- **Bases de Datos Aisladas Típicas**:
  - `n8n`: Automatizaciones de flujos y credenciales de conectores.
  - `typebot`: Formularios y datos de sesiones de chatbot.
  - `chatwoot`: Conversaciones y tickets de soporte omnicanal.
  - `evolution`: Instancias y estados de conexión de mensajería WhatsApp.

> [!IMPORTANT]
> **Regla de Oro de Bases de Datos**: NUNCA desplegar contenedores adicionales de PostgreSQL en el mismo nodo. Cualquier servicio nuevo que requiera PostgreSQL debe aprovisionar su base de datos dentro de Unified-DB para optimizar memoria RAM. Las credenciales se centralizan en el gestor de secretos (Infisical).

---

## 3. n8n (Automatización con Soporte Dual MCP / REST)

- **URL Pública Típica**: `https://n8n.example.com` (puerto interno 5678).
- **Integración para Agentes**:
  1. **N8N Native MCP (Preferido para ejecución por Agentes)**:
     - Endpoint: `https://n8n.example.com/mcp-server/http`
     - Autenticación: `$N8N_MCP_TOKEN`
     - Ventaja: Permite a los agentes descubrir y ejecutar flujos seleccionados (marcados con "Available in MCP") como herramientas nativas de IA, sin requerir webhooks individuales.
  2. **N8N REST API**:
     - Operaciones programáticas de creación, lectura, actualización y activación de workflows.

---

## 4. Servicios de Comunicación y Almacenamiento

### Evolution API (WhatsApp)
- **URL Típica**: `https://whatsapp.example.com` (puerto interno 8080).
- **Uso**: API HTTP completa para envío/recepción de mensajes de WhatsApp, webhooks de eventos y conexión directa para agentes conversacionales.

### MinIO (Almacenamiento de Objetos S3 Compatible)
- **Consola**: `https://minio.example.com` (puerto interno 9001).
- **API S3**: `https://cdn.example.com` (puerto interno 9000).
- **Buckets Típicos**:
  - `public-media`: Archivos multimedia públicos (política GET pública).
  - `user-uploads`: Assets y uploads de usuarios en aplicaciones (política privada).

### Chatwoot & Typebot
- **Chatwoot**: `https://chatwoot.example.com` — Bandeja omnicanal de soporte y supervisión de agentes.
- **Typebot**: `https://typebot.example.com` — Creador visual de flujos conversacionales interactivos.

### Respaldo y Continuidad (S3 / R2)
- Scripts de backup automatizado diario de bases de datos hacia almacenamiento de objetos externo (ej. Cloudflare R2 / S3) con política de retención configurable.
