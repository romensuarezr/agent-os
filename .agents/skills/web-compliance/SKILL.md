---
name: web-compliance
description: Protocolo de cumplimiento normativo web (cookies AEPD/RGPD con vanilla-cookieconsent v3, páginas legales obligatorias LSSI/RGPD y endurecimiento de cabeceras HTTP de seguridad).
---

# Skill: Web Compliance & Security Headers

Guía integral y estandarizada para garantizar que cualquier satélite web del ecosistema Agent OS cumpla con la legislación europea y española en materia de privacidad (RGPD, ePrivacy, LSSI-CE, directrices AEPD de cookies) y cuente con defensas perimetrales mediante cabeceras HTTP seguras en producción.

---

## 1. Cuándo Activar este Skill

- **Desarrollo o auditoría previa al despliegue** de cualquier aplicación web satélite (Next.js, Remix, Astro, etc.).
- **Detección de ausencia de CMP**: Cuando una web satélite utiliza cookies técnicas, analíticas o de terceros (ej. Google Analytics, Calendly, Stripe, píxeles) sin un banner de consentimiento simétrico.
- **Auditoría legal**: Cuando falten las rutas legales mínimas exigidas por la LSSI-CE y el RGPD (`/aviso-legal`, `/politica-privacidad`, `/politica-cookies`).
- **Endurecimiento HTTP**: Cuando el satélite no tenga configuradas cabeceras como CSP, HSTS, X-Frame-Options o nosniff en su servidor o framework.

---

## 2. Bloque 1: Cookies & Consentimiento (AEPD / RGPD) con `vanilla-cookieconsent` v3

### 2.1 Por qué `vanilla-cookieconsent` v3
- **Cero dependencias**: No requiere librerías pesadas externas ni suscripciones SaaS mensuales.
- **Ligero**: ~5 KB gzipped, con excelente rendimiento Core Web Vitals.
- **Cumplimiento estricto AEPD**: Permite simetría total en botones («Aceptar todo» y «Rechazar todo» con idéntico contraste visual, tamaño y nivel de jerarquía).
- **Control granular**: Bloqueo y categorización (necesarias, analíticas, publicidad) con `autoClear` para purgar cookies en caso de revocación.
- **Compatible con Next.js App Router**: Se integra limpiamente como Client Component (`'use client'`).

### 2.2 Instalación en el Satélite
```bash
npm install vanilla-cookieconsent
```

### 2.3 Implementación con la Plantilla
Copiar la plantilla desde el catálogo de Agent OS:
```bash
# Desde la raíz del satélite:
cp .agents/skills/web-compliance/templates/CookieBanner.tsx.template components/legal/CookieBanner.tsx
```

E inyectar `<CookieBanner />` en el `layout.tsx` raíz del satélite:
```tsx
import { CookieBanner } from '@/components/legal/CookieBanner';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es">
      <body>
        {children}
        <CookieBanner />
      </body>
    </html>
  );
}
```

### 2.4 Reglas Críticas AEPD
1. **Simetría obligatoria**: El botón de "Rechazar todo" debe estar al mismo nivel que "Aceptar todo". Está prohibido forzar al usuario a entrar en configuración para rechazar.
2. **Cero pre-marcados**: Las casillas no técnicas deben estar desmarcadas por defecto.
3. **Revocabilidad**: Debe existir un enlace en el footer o en `/politica-cookies` que permita reabrir el panel de configuración en cualquier momento usando el atributo `data-cc="show-preferencesModal"`.

---

## 3. Bloque 2: Páginas Legales Obligatorias en España / UE

Toda web con actividad económica, profesional, captación de leads o formularios debe contar con tres páginas accesibles desde el footer:

| Ruta | Normativa | Propósito |
|---|---|---|
| `/aviso-legal` | LSSI-CE art. 10 | Identificación del responsable (nombre/razón social, NIF/CIF, domicilio, email de contacto, registro mercantil o titulación colegiada). |
| `/politica-privacidad` | RGPD art. 13 | Responsable del tratamiento, finalidad, base legal, plazos de conservación, cesiones a terceros y ejercicio de derechos ARCO/RGPD. |
| `/politica-cookies` | Directiva ePrivacy / LSSI art. 22.2 | Inventario de cookies utilizadas, fines, caducidad, y botón de reapertura del modal de configuración. |

### 3.1 Scaffolding desde Plantillas
```bash
# En satélites Next.js App Router:
mkdir -p app/aviso-legal app/politica-privacidad app/politica-cookies

cp .agents/skills/web-compliance/templates/aviso-legal.tsx.template app/aviso-legal/page.tsx
cp .agents/skills/web-compliance/templates/politica-privacidad.tsx.template app/politica-privacidad/page.tsx
cp .agents/skills/web-compliance/templates/politica-cookies.tsx.template app/politica-cookies/page.tsx
```

Reemplazar los marcadores entre corchetes (`[NOMBRE_DEL_RESPONSABLE]`, `[NIF_O_CIF]`, `[EMAIL_CONTACTO]`, etc.) con la información del proyecto o cliente.

---

## 4. Bloque 3: Cabeceras de Seguridad HTTP (Hardening)

Las cabeceras HTTP defensivas protegen a los usuarios contra ataques comunes como Clickjacking, Cross-Site Scripting (XSS) y sniffing MIME.

### 4.1 Inyección en `next.config.js` / `next.config.ts`
Copiar el fragmento desde:
`.agents/skills/web-compliance/templates/security-headers.snippet.ts`

Ejemplo de configuración recomendada:
```ts
const securityHeaders = [
  { key: 'X-DNS-Prefetch-Control', value: 'on' },
  { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains; preload' },
  { key: 'X-Frame-Options', value: 'SAMEORIGIN' },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=(), browsing-topics=()' },
  {
    key: 'Content-Security-Policy',
    value: "default-src 'self'; script-src 'self' 'unsafe-eval' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https:; frame-src 'self' https:;"
  }
];

const nextConfig = {
  async headers() {
    return [
      {
        source: '/:path*',
        headers: securityHeaders,
      },
    ];
  },
};
```

---

## 5. Verificación Determinista con `audit-web-compliance.sh`

Para verificar el cumplimiento técnico del satélite sin consumo de tokens, ejecutar:

```bash
# Diagnóstico de un proyecto satélite:
bash scripts/agent/audit-web-compliance.sh --path /ruta/al/satelite --json
```

El script inspecciona:
1. Presencia de `vanilla-cookieconsent` o solución de CMP activa.
2. Rutas legales `/aviso-legal`, `/politica-privacidad` y `/politica-cookies`.
3. Cabeceras HTTP de seguridad configuradas en el archivo de configuración del framework.
4. Presencia de `robots.txt` y `sitemap.xml`.
