/**
 * Snippet de cabeceras de seguridad HTTP recomendadas para Next.js (App Router).
 * Proporciona endurecimiento contra Clickjacking, sniffing MIME, XSS e inyecciones de recursos.
 *
 * Modo de uso en next.config.ts / next.config.mjs:
 *
 * import { securityHeaders } from './security-headers'; // o copia directa
 *
 * const nextConfig = {
 *   async headers() {
 *     return [
 *       {
 *         source: '/:path*',
 *         headers: securityHeaders,
 *       },
 *     ];
 *   },
 * };
 */

export const securityHeaders = [
  // Habilita control de prefetching DNS seguro
  {
    key: 'X-DNS-Prefetch-Control',
    value: 'on',
  },
  // Fuerza HTTPS estricto durante 2 años incluyendo subdominios y precarga
  {
    key: 'Strict-Transport-Security',
    value: 'max-age=63072000; includeSubDomains; preload',
  },
  // Previene clickjacking embebiendo el sitio en iframes no autorizados
  {
    key: 'X-Frame-Options',
    value: 'SAMEORIGIN',
  },
  // Bloquea sniffing de tipos MIME por parte del navegador
  {
    key: 'X-Content-Type-Options',
    value: 'nosniff',
  },
  // Limita la información del referente enviada en peticiones cruzadas
  {
    key: 'Referrer-Policy',
    value: 'strict-origin-when-cross-origin',
  },
  // Deshabilita acceso no autorizado a APIs sensibles del dispositivo
  {
    key: 'Permissions-Policy',
    value: 'camera=(), microphone=(), geolocation=(), browsing-topics=()',
  },
  // Política de seguridad de contenido modular base
  {
    key: 'Content-Security-Policy',
    value: [
      "default-src 'self'",
      "script-src 'self' 'unsafe-eval' 'unsafe-inline' https://assets.calendly.com",
      "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
      "img-src 'self' data: https: blob:",
      "font-src 'self' data: https://fonts.gstatic.com",
      "connect-src 'self' https:",
      "frame-src 'self' https://calendly.com https://*.calendly.com",
      "object-src 'none'",
      "base-uri 'self'",
      "form-action 'self'",
      "frame-ancestors 'self'",
      "upgrade-insecure-requests",
    ].join('; '),
  },
];
