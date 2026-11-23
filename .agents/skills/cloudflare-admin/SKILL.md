---
name: cloudflare-admin
description: Administración programática de Cloudflare en la flota de Agent OS. Documenta autenticación dual (Scoped API Token vs Global API Key), gestión de registros DNS, activación y reglas de Email Routing, y políticas de seguridad perimetral a coste $0 tokens.
---

# Cloudflare Admin — Guía Operativa de Cloudflare para Agent OS

Esta habilidad proporciona el protocolo operativo, patrones de autenticación y llamadas API deterministas para administrar dominios, registros DNS y el enrutamiento de correos en **Cloudflare** dentro del ecosistema de Agent OS.

---

## 1. Topología de Credenciales y Autenticación Dual

⚠️ **DISTINCIÓN CRÍTICA DE TOKENS**: Cloudflare opera bajo dos esquemas de autenticación que **NO** son intercambiables. Usar el tipo equivocado provoca errores inmediatos de `HTTP 401 Unauthorized` o `HTTP 403 Forbidden`:

| Tipo de Clave | Variable en Infisical | Cabeceras Requeridas | Alcance / Cuándo Usar |
|---|---|---|---|
| **Scoped API Token** | `CLOUDFLARE_API_TOKEN` | `Authorization: Bearer <TOKEN>` | **Agotado a DNS**: Crear, editar o borrar registros A, CNAME, TXT, MX. Adecuado para CI/CD y despliegues. |
| **Global API Key** | `CLOUDFLARE_API_TOKEN_GLOBAL` | `X-Auth-Email: <EMAIL>`<br>`X-Auth-Key: <GLOBAL_KEY>` | **Administración Total**: Habilitar Email Routing, añadir destinos a nivel cuenta, crear zonas y gestionar Zero Trust. |

> 🔒 **Almacenamiento**: Ambas credenciales deben custodiarse en Infisical (`/shared` o `/leaderboard-platform`), inyectándose efímeramente en memoria (`infisical run`) sin exponerlas en git.

---

## 2. Gestión de Registros DNS (`/zones/{zone_id}/dns_records`)

Para operar sobre DNS, se puede utilizar tanto el Scoped API Token como la Global Key:

### A. Listar Registros Filtrados
```bash
curl -fsSL "https://api.cloudflare.com/client/v4/zones/<ZONE_ID>/dns_records?type=MX" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json"
```

### B. Crear Registro MX
```bash
curl -fsSL -X POST "https://api.cloudflare.com/client/v4/zones/<ZONE_ID>/dns_records" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "MX",
    "name": "@",
    "content": "route1.mx.cloudflare.net",
    "priority": 13,
    "ttl": 1
  }'
```

### C. Registro SPF Unificado (TXT)
⚠️ **Nunca crees múltiples registros TXT de SPF en la misma raíz**: Cloudflare y los validadores de correo marcarán `PermError`. Unifica los proveedores en una sola línea:
```json
{
  "type": "TXT",
  "name": "@",
  "content": "v=spf1 include:_spf.mx.cloudflare.net include:spf.brevo.com ~all",
  "ttl": 1
}
```

---

## 3. Aprovisionamiento de Cloudflare Email Routing

Email Routing requiere permisos a nivel de cuenta (`Account`) y zona (`Zone`), por lo que **requiere obligatoriamente la Global API Key**:

### Paso 1: Habilitar Email Routing en la Zona
```bash
curl -fsSL -X POST "https://api.cloudflare.com/client/v4/zones/<ZONE_ID>/email/routing/enable" \
  -H "X-Auth-Email: $CLOUDFLARE_AUTH_EMAIL" \
  -H "X-Auth-Key: $CLOUDFLARE_API_TOKEN_GLOBAL" \
  -H "Content-Type: application/json"
```

### Paso 2: Añadir y Verificar Buzón de Destino
Las direcciones de destino residen a nivel de cuenta (`/accounts/{account_id}/...`):
```bash
# Si el destino coincide con el email del propietario de Cloudflare, se valida automáticamente
curl -fsSL -X POST "https://api.cloudflare.com/client/v4/accounts/<ACCOUNT_ID>/email/routing/addresses" \
  -H "X-Auth-Email: $CLOUDFLARE_AUTH_EMAIL" \
  -H "X-Auth-Key: $CLOUDFLARE_API_TOKEN_GLOBAL" \
  -H "Content-Type: application/json" \
  -d '{"email": "tu-correo@gmail.com"}'
```

### Paso 3: Crear Reglas de Reenvío (Custom Addresses)
```bash
curl -fsSL -X POST "https://api.cloudflare.com/client/v4/zones/<ZONE_ID>/email/routing/rules" \
  -H "X-Auth-Email: $CLOUDFLARE_AUTH_EMAIL" \
  -H "X-Auth-Key: $CLOUDFLARE_API_TOKEN_GLOBAL" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Forward hola@tu-dominio.com",
    "matchers": [
      {
        "type": "literal",
        "field": "to",
        "value": "hola@tu-dominio.com"
      }
    ],
    "actions": [
      {
        "type": "forward",
        "value": ["tu-correo@gmail.com"]
      }
    ],
    "enabled": true
  }'
```

---

## 4. Diagnóstico Determinista y Resolución Global (DNS over HTTPS)

Para verificar la propagación real sin sufrir la caché DNS del sistema local ni gastar tokens de inferencia:

```python
import urllib.request, json

def query_doh(name, type_name):
    url = f"https://dns.google/resolve?name={name}&type={type_name}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req) as resp:
        return [a["data"] for a in json.loads(resp.read().decode()).get("Answer", [])]

print("MX Records:", query_doh("tu-dominio.com", "MX"))
print("SPF Record:", [t for t in query_doh("tu-dominio.com", "TXT") if "v=spf1" in t])
```

---

## 5. Anti-patrones y Errores Comunes

1. ❌ **Usar `Bearer <TOKEN>` para llamadas a `/email/routing/addresses`**:
   Devolverá `403 Forbidden` o `401 Unauthorized` si el token fue creado únicamente con el template "Edit zone DNS". Usa la Global API Key con `X-Auth-Email` y `X-Auth-Key`.
2. ❌ **Dejar registros MX directos apuntando a la IP del VPS**:
   Si activas Cloudflare Email Routing pero conservas un registro `MX tu-dominio.com -> IP`, los correos colisionarán y se perderán. Los únicos MX deben ser `route1.mx.cloudflare.net`, `route2.mx.cloudflare.net` y `route3.mx.cloudflare.net`.
3. ❌ **Múltiples registros TXT SPF**:
   Tener dos registros `v=spf1 ...` rompe la validación SPF en proveedores como Gmail o Microsoft. Deben fusionarse siempre con directivas `include:`.
