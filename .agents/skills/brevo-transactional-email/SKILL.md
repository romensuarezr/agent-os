---
name: brevo-transactional-email
description: Despacho y administración de correo transaccional con Brevo (Sendinblue) en la flota de Agent OS. Documenta autenticación REST API v3, SMTP Relay, clientes zero-dependencies en Node.js y Python, y el protocolo de autorización de IPs en servidores VPS.
---

# Brevo Transactional Email — Guía de Operación para Agent OS

Esta habilidad estandariza el envío de correos transaccionales (confirmaciones, diagnósticos, lead magnets y recuperación de accesos) mediante **Brevo** (antiguo Sendinblue) a coste permanente de $0 para proyectos y satélites de Agent OS.

---

## 1. Arquitectura de Transporte Asimétrico

Brevo soporta dos canales de despacho transaccional. La elección depende del entorno de ejecución:

| Canal de Despacho | Protocolo / Endpoint | Entorno Recomendado | Ventajas / Inconvenientes |
|---|---|---|---|
| **REST API v3** | `POST https://api.brevo.com/v3/smtp/email` | Aplicaciones Web (Next.js, Node.js, Serverless) | **Cero dependencias** (nativo `fetch`), sin sockets persistentes, inmune a bloqueos de puertos SMTP en hostings compartidos. |
| **SMTP Relay** | `smtp-relay.brevo.com:587` (TLS) | Contenedores y daemons persistentes (Twenty CRM, n8n) | Estándar universal sin código adicional; se configura puramente vía variables de entorno (`EMAIL_SMTP_*`). |

---

## 2. ⚠️ El Gotcha Crítico: Filtro "Authorised IPs"

Brevo activa de forma predeterminada una política de seguridad estricta para sus claves API: **"Bloquear direcciones IP no autorizadas para tus claves API"**.

Si un contenedor o script invoca la API desde una IP desconocida (por ejemplo, al migrar de servidor o arrancar en un nuevo VPS), Brevo responderá con:
```json
HTTP 401 Unauthorized
{
  "code": "unauthorized",
  "message": "We have detected you are using an unrecognised IP address <IP>. If you performed this action make sure to add the new IP address in this link: https://app.brevo.com/security/authorised_ips"
}
```

### Protocolo de Resolución Inmediata:
1. Averigua la IP pública de salida del servidor:
   ```bash
   curl -s https://ifconfig.me
   ```
2. Accede a la consola web: **Settings** → **Seguridad** → [Authorized IPs](https://app.brevo.com/security/authorised_ips).
3. Añade la IP pública del servidor a la lista blanca.
*(Nota: El SMTP Relay no suele bloquear IPs salvo que se pulse explícitamente el botón "Activar para claves SMTP").*

---

## 3. Implementación de Clientes Zero-Dependencies

### A. TypeScript / Next.js (HTTP Fetch Nativo)
Sin necesidad de instalar paquetes pesados como `nodemailer` o el SDK oficial de Brevo:

```typescript
export async function sendTransactionalEmail(input: {
  apiKey: string;
  senderName: string;
  senderEmail: string;
  recipientEmail: string;
  recipientName: string;
  subject: string;
  htmlContent: string;
}): Promise<{ success: boolean; messageId?: string; error?: string }> {
  try {
    const res = await fetch("https://api.brevo.com/v3/smtp/email", {
      method: "POST",
      headers: {
        "api-key": input.apiKey,
        "accept": "application/json",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        sender: { name: input.senderName, email: input.senderEmail },
        to: [{ email: input.recipientEmail, name: input.recipientName }],
        subject: input.subject,
        htmlContent: input.htmlContent,
      }),
    });

    if (!res.ok) {
      const err = await res.text();
      return { success: false, error: `HTTP ${res.status}: ${err}` };
    }

    const data = (await res.json()) as { messageId?: string };
    return { success: true, messageId: data.messageId };
  } catch (err: unknown) {
    return { success: false, error: err instanceof Error ? err.message : String(err) };
  }
}
```

### B. Python (Estándar `urllib`)
```python
import json, urllib.request

def send_brevo_email(api_key, sender_email, sender_name, to_email, to_name, subject, html):
    req = urllib.request.Request(
        'https://api.brevo.com/v3/smtp/email',
        data=json.dumps({
            'sender': {'name': sender_name, 'email': sender_email},
            'to': [{'email': to_email, 'name': to_name}],
            'subject': subject,
            'htmlContent': html
        }).encode(),
        headers={
            'api-key': api_key,
            'Content-Type': 'application/json',
            'accept': 'application/json'
        },
        method='POST'
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode())
```

---

## 4. Configuración en Twenty CRM y Stacks Docker

En Twenty CRM v2.46.0+, inyectar en el entorno del contenedor (`.env`):

```env
EMAIL_DRIVER="smtp"
EMAIL_FROM_ADDRESS="seguridad@tu-dominio.com"
EMAIL_FROM_NAME="Tu Nombre / Organización"
EMAIL_SMTP_HOST="smtp-relay.brevo.com"
EMAIL_SMTP_PORT="587"
EMAIL_SMTP_USER="<usuario_smtp_brevo>"
EMAIL_SMTP_PASSWORD="<clave_smtp_brevo>"
EMAIL_SMTP_NO_TLS="false"
```

---

## 5. Anti-patrones Críticos

1. ❌ **Instalar SDKs pesados en microservicios**:
   El SDK oficial de Brevo en npm/pip introduce dependencias innecesarias de axios o librerías de red. El endpoint `/v3/smtp/email` es simple y estándar con `fetch` o `urllib`.
2. ❌ **Ignorar el registro DMARC**:
   Si configuras DKIM en Brevo pero no añades el registro TXT `_dmarc.tu-dominio.com`, servidores como Yahoo y Gmail penalizarán la entregabilidad transaccional.
3. ❌ **Usar el remitente por defecto de Brevo**:
   Nunca envíes correos desde dominios genéricos. Valida tu dominio canónico en Brevo y firma siempre desde `@tu-dominio.com`.
