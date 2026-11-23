---
name: twenty-crm-admin
description: Operación agnóstica, administración y sincronización de datos con Twenty CRM en la flota de Agent OS. Documenta autenticación Bearer, API Core REST (/rest/people, /rest/companies, /rest/opportunities), API de Metadatos (/rest/metadata), campos de atribución UTM y operaciones CLI/Docker en contenedor.
---

# Twenty CRM Admin — Guía Operativa Agnóstica para Agent OS

Esta habilidad proporciona el contrato técnico, patrones de consulta, manipulación de metadatos y protocolos de mantenimiento para operar instancias de **Twenty CRM** (v2.46.x+) alojadas en la infraestructura PaaS (Docker/Coolify) de cualquier satélite o nodo del ecosistema de Agent OS.

Twenty CRM actúa habitualmente como una **réplica reactiva** del funnel comercial y relacional. La regla de oro en todos los satélites es el **desacoplamiento**: los fallos de red o errores de API del CRM nunca deben bloquear el flujo principal de los usuarios finales ni las transacciones de negocio.

---

## 1. Topología y Variables de Entorno

Para preservar la portabilidad absoluta entre satélites, todos los clientes y scripts deben resolver sus credenciales dinámicamente mediante variables de entorno o la bóveda de secretos (Infisical CE):

| Variable | Descripción | Formato / Ejemplo | Ámbito |
|---|---|---|---|
| `TWENTY_API_URL` | URL base canónica de la instancia | `https://crm.tu-dominio.com` (**sin barra final**) | Público / Host |
| `TWENTY_API_KEY` | Token Bearer JWT (ES256) | Clave de workspace (444 chars) | Confidencial (Infisical) |
| `CRM_PROVIDER` | Selector de backend CRM | `twenty` | Configuración |

> 🔒 **Seguridad de Secretos**: Las claves nunca se comitean en el repositorio. Se inyectan en memoria en tiempo de ejecución (`infisical run`) o se leen con Universal Auth (`CLIENT_ID` + `CLIENT_SECRET`).

---

## 2. Contrato de la API Core REST (v2.46.0+)

⚠️ **Regla Fundamental de Envoltorio (Data Envelope)**:
- **Peticiones GET (Lecturas)**: La respuesta anida los resultados dentro de un array en plural:
  ```json
  {
    "data": {
      "people": [ ... ],
      "totalCount": 1
    },
    "pageInfo": {
      "hasNextPage": false,
      "endCursor": "..."
    }
  }
  ```
- **Peticiones POST / PATCH (Escrituras)**: La respuesta anida el resultado en la acción singular:
  - `POST /rest/people` → `{ "data": { "createPerson": { "id": "..." } } }`
  - `PATCH /rest/people/:id` → `{ "data": { "updatePerson": { "id": "..." } } }`
  - `POST /rest/companies` → `{ "data": { "createCompany": { "id": "..." } } }`
  - `POST /rest/opportunities` → `{ "data": { "createOpportunity": { "id": "..." } } }`

> ⚠️ Leer `res.data` directamente como array o como entidad fallará silenciosamente retornando `undefined`. Comprueba siempre la clave anidada.

---

## 3. Relaciones y Claves Foráneas

Twenty CRM valida rígidamente los esquemas. El uso de nombres intuitivos de frontend causa un fallo inmediato con **HTTP 400 Bad Request**:

| Entidad Relacionada | Campo Válido en Payload | ❌ Nombres Inválidos (devuelven 400) |
|---|---|---|
| Oportunidad → Contacto | `pointOfContactId` | `personId`, `targetPerson`, `contactId` |
| Oportunidad → Empresa | `companyId` | `organizationId`, `targetCompany` |
| Contacto → Empresa | `companyId` | `company`, `organizationId` |

---

## 4. Sintaxis de Filtros y Búsquedas

Los filtros en las URLs de endpoints REST utilizan la sintaxis `filter=campo[operador]:valor`:

```http
# Búsqueda exacta por email primario:
GET /rest/people?filter=emails.primaryEmail[eq]:lead@empresa.com&limit=1

# Búsqueda por subcadena en nombre:
GET /rest/companies?filter=name[ilike]:%Acme%&limit=5

# Filtro por fuente o atributo UTM:
GET /rest/people?filter=utmSource[eq]:youtube&limit=20
```

Operadores soportados comunes: `[eq]`, `[neq]`, `[ilike]`, `[in]`, `[is]`.

---

## 5. Modelo de Atribución y Campos UTM

Para unificar la captación desde múltiples canales (web, YouTube, prospección outbound, etc.) sin fragmentar la base de datos en instancias aisladas, se adopta el modelo de **campos de atribución UTM** en la entidad `Person`:

| Campo REST | Tipo | Propósito | Ejemplo |
|---|---|---|---|
| `source` | `TEXT` / `SELECT` | Origen macrosistema | `"YouTube"`, `"Web Assessment"`, `"Radar Outbound"` |
| `utmSource` | `TEXT` | Canal o plataforma | `"youtube"`, `"google"`, `"linkedin"` |
| `utmCampaign` | `TEXT` | Campaña o temática | `"seneca_manual"`, `"mvp_growth"` |
| `utmContent` | `TEXT` | Variante o ángulo | `"pinned_comment"`, `"reciprocity"` |
| `leadMagnet` | `TEXT` | Activo captador | `"seneca_manual.md"`, `"audit_checklist"` |

### Vistas Guardadas (Segmentación UI)
En lugar de múltiples workspaces con subdominios wildcard, la segmentación en la consola web de Twenty se realiza mediante **Vistas Guardadas (Saved Views)**:
- **Vista "YouTube Funnel"**: Filtro `source CONTAINS "YouTube"`.
- **Vista "Web Leads"**: Filtro `source CONTAINS "Web"`.
- **Vista "Outbound Prospects"**: Filtro `source CONTAINS "Radar"`.

---

## 6. Configuración de Email Transaccional en Twenty CRM

Twenty CRM utiliza internamente un driver modular de correo. Para habilitar notificaciones y recuperación de contraseñas vía SMTP Relay (ej. Brevo, Postmark):

### Variables en el Contenedor Server/Worker (`.env` de Coolify):
```env
EMAIL_DRIVER="smtp"
EMAIL_FROM_ADDRESS="no-reply@tu-dominio.com"
EMAIL_FROM_NAME="Tu Organización"
EMAIL_SMTP_HOST="smtp-relay.brevo.com"
EMAIL_SMTP_PORT="587"
EMAIL_SMTP_USER="<usuario_smtp>"
EMAIL_SMTP_PASSWORD="<password_smtp>"
EMAIL_SMTP_NO_TLS="false"
```

> ⚠️ **Prefijo OBLIGATORIO**: Twenty CRM v2.46.0 ignora variables genéricas como `SMTP_HOST` o `SMTP_PORT`. Requiere estrictamente el prefijo `EMAIL_SMTP_*` y `EMAIL_DRIVER="smtp"`.

---

## 7. Operaciones de Contenedor y Mantenimiento Avanzado

Cuando se requiere aprovisionar campos personalizados o consultar esquemas internos de TypeORM sin pasar por el panel web:

### A. Inspección del Contrato OpenAPI Vivo ($0 tokens)
```bash
# Comprobación de endpoints y campos expuestos:
curl -fsSL -H "User-Agent: Mozilla/5.0 (compatible; AgentOS/1.0)" \
  "https://crm.tu-dominio.com/rest/open-api/core" | jq '.paths | keys'
```

### B. Ejecución de Tareas Administrativas dentro del Contenedor
Accediendo al contenedor `server` vía Docker / Coolify:
```bash
# 1. Inspeccionar migraciones pendientes:
docker exec -it <container_id> yarn typeorm:run-migrations

# 2. Comprobar salud del microservicio:
docker exec -it <container_id> curl -s http://localhost:3000/healthz
```

---

## 8. Anti-patrones y Errores Críticos

1. ❌ **Usar la etiqueta `latest` en Docker**:
   Fija siempre una versión semántica explícita (`twentycrm/twenty:v2.46.0`). Un despliegue con `latest` puede introducir cambios de esquema incompatibles de forma imprevista.
2. ❌ **Reutilizar tokens personales en servicios desatendidos**:
   Crea siempre API Keys dedicadas con nombre descriptivo (ej. `Ops-Hub Funnel Connector`, `Web Client`) para poder rotarlas independientemente sin afectar a los usuarios humanos.
3. ❌ **Bloquear peticiones HTTP de usuario si Twenty CRM responde 5xx**:
   Las peticiones a Twenty CRM deben aislarse en bloques `try/catch`. Si el CRM falla, se loguea el error en auditoría y el frontend devuelve confirmación al usuario persistiendo el dato en la base de datos primaria (Postgres/SQLite local).
