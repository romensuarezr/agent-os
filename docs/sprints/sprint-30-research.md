# Research Sprint 30

> Fuente: Análisis técnico determinista pre-código, prospección determinista OSS (scout.sh), diagnóstico de campo de la flota (2026-11-03) y especificaciones oficiales Docker Compose / Nango / Homepage.
> Fecha: 2026-11-03
> Siguiente sprint: Sprint 30
> Régimen de ejecución: Opción D (Autonomía acotada por defecto)

---

## Descubrimientos Scout (por tarea)

### T-165 — Despliegue en vivo y validación operativa de Bane en la flota
- **Alternativa detectada:** Imagen oficial `ghcr.io/pythops/bane` (1060⭐), SearXNG (`searxng/searxng`), cliente `bane-client.sh` nativo del core.
- **Recomendación del agente:** Desarrollo a medida y adopción de la imagen oficial Docker existente en el core (`templates/bane/docker-compose.yml`), operando en vivo sobre el host VPS de inferencia.
- **Decisión del usuario:** Adoptar la imagen oficial `ghcr.io/pythops/bane` desplegada con la plantilla declarativa validada en T-162.
- **Notas de integración:**
  1. Conectar con el VPS de inferencia (<nodo-inferencia>) vía SSH determinista o Coolify.
  2. Desplegar el stack de Bane configurando las variables de entorno (`BANE_PORT`, `BANE_INFERENCE_URL`, `BANE_EMBEDDING_URL`) conforme a `templates/bane/.env.example`.
  3. Actualizar el overlay `fleet.yaml` para registrar el servicio Bane con su endpoint alcanzable.
  4. Ejecutar verificación viva con `bash scripts/agent/lib/bane-client.sh --check` validando código de salida 0.
  5. Ejecutar una query real mediante `bane-client.sh --query "..."` y certificar la integración con el workflow `deep-research`.
- **Alternativas rechazadas y motivos:**
  - Perplexity Pro manual: Descartado por requerir intermediación interactiva humana y no permitir ejecución 100% desatendida.
  - Re-implementar motor de búsqueda propio desde cero: Descartado por violar la regla OSS-first (Bane ya provee el clon soberano de Perplexity).

### T-166 — Plantilla de despliegue soberano de Nango en VPS y runbook de integración
- **Alternativa detectada:** `NangoHQ/nango` (13101⭐ | Open Source / Source-Available), CLI oficial `nango` (v0.71.14 npm), `Anil-matcha/open-agent-connector` (849⭐ Apache-2.0).
- **Recomendación del agente:** Adoptar `NangoHQ/nango` oficial como plataforma de autenticación unificada OAuth y token broker para la flota de Agent OS.
- **Decisión del usuario:** Adoptar `NangoHQ/nango` creando la plantilla Compose declarativa soberana (`templates/nango/docker-compose.yml` y `.env.example`) bajo estricta frontera portable.
- **Notas de integración:**
  1. Diseñar `templates/nango/docker-compose.yml` conteniendo el servidor Nango (`nangohq/nango-server`) y base de datos PostgreSQL dedicada, con puertos configurables y límites de recursos estándar.
  2. Proveer `templates/nango/.env.example` con variables saneadas (`NANGO_SERVER_PORT`, `NANGO_DB_PASSWORD`, `NANGO_ENCRYPTION_KEY`, etc.).
  3. Declarar el servicio en `.agents/config/fleet.example.yaml` bajo el nodo de orquestación (<nodo-orquestacion>).
  4. Documentar el runbook operativo `docs/runbooks/nango-oauth-service.md` detallando aprovisionamiento en Coolify/VPS, flujo de rotación de claves y uso por herramientas/agentes.
- **Alternativas rechazadas y motivos:**
  - `open-agent-connector`: Descartado por menor madurez (849⭐ vs 13.1k⭐ de Nango) y ecosistema de conectores más limitado.
  - Gestión manual de tokens en archivos `.env`: Descartada por riesgos de expiración de tokens, dispersión y falta de interfaz de renovación OAuth automática.

### T-167 — Remediación determinista de compatibilidad en generate-homepage-config.sh y puesta a punto de Homepage Dashboard
- **Alternativa detectada:** Paquete `gethomepage.dev`, `0xN1nja/homepagectl` (207⭐), generador nativo determinista `scripts/agent/generate-homepage-config.sh`.
- **Recomendación del agente:** Desarrollo a medida justificado sobre el generador nativo existente del core (`generate-homepage-config.sh`) para asegurar tolerancia a esquemas heterogéneos de `fleet.yaml` sin añadir dependencias runtime.
- **Decisión del usuario:** Desarrollo a medida justificado — extender y robustecer el script nativo determinista y corregir las plantillas del core.
- **Notas de integración:**
  1. En `scripts/agent/generate-homepage-config.sh`, normalizar el parsing de servicios: si el valor de un servicio es un entero o string (puerto numérico), convertirlo internamente a diccionario estándar `{ "port": int, "enabled": true }`, evitando el fallo `AttributeError: 'int' object has no attribute 'get'`.
  2. Soportar el campo `ip` como fallback automático cuando no exista el campo `host` en la definición del nodo.
  3. Sanear `templates/homepage/config/services.yaml`: sustituir dominios ficticios (`example.com`) por placeholders controlados o configurables, y corregir las referencias locales de Ollama y Orca para evitar `localhost:8000` / `ECONNREFUSED` dentro del contenedor.
  4. Actualizar `docs/runbooks/coolify-homepage-deployment.md` documentando la configuración del proxy de Docker (`docker-socket-proxy`) y variables `HOMEPAGE_VAR_*`.
- **Alternativas rechazadas y motivos:**
  - `homepagectl`: Descartado por asumir un daemon Docker local exclusivo, mientras que Agent OS opera sobre una flota heterogénea distribuida (Tailscale + nodos remotos).
  - Edición manual directa en volúmenes Docker del VPS: Rechazada terminantemente; todo cambio debe partir de plantillas y generadores del core trazables en git.

---

## Hallazgos clave

1. **Arquitectura Soberana de Bane en Producción**:
   El despliegue de Bane requiere conexión a un endpoint de inferencia OpenAI-compatible (Ollama, vLLM o FreeLLMAPI) y a un modelo de embeddings para reranking. Al contar con FreeLLMAPI y Ollama en la flota, Bane puede operar de forma 100% soberana sin coste por token de búsqueda.
2. **Nango como Hub Unificado OAuth**:
   Nango desacopla la autenticación externa (GitHub, Google, Slack, Notion, etc.) de la lógica de los agentes. En lugar de que cada script o MCP gestione refresh tokens, Nango actúa como proxy y almacén cifrado de credenciales.
3. **Robustez de Esquemas en `generate-homepage-config.sh`**:
   Los overlays de flota reales (`fleet.yaml`) tienden a simplificarse para reducir verbosidad (ej. `ollama: 11434` en vez de `ollama: { endpoint: "...", description: "..." }`). El generador debe ser tolerante a ambas representaciones, aplicando defaults transparentes.

---

## Decisiones tomadas

- **Decisión 1**: Desplegar Bane en el nodo de inferencia y validar el flujo determinista con `bane-client.sh --check` (`exit 0`) y query real, cerrando la brecha entre el código del core y la operativa viva.
- **Decisión 2**: Incorporar la plantilla oficial de Nango (`templates/nango/`) y su runbook operativo para habilitar gestión OAuth soberana en la flota.
- **Decisión 3**: Robustecer `generate-homepage-config.sh` eliminando el fallo con puertos numéricos y campos `ip`, saneando `templates/homepage/config/services.yaml` de URLs ficticias.
- **Decisión 4**: El denominador de la suite de validación `tests/validate-control-plane.sh` se mantiene o expande según corresponda (mínimo 38/38, 0 errores).

---

## Descartado

- No se emplean servicios SaaS de pago para búsqueda profunda (Perplexity comercial) una vez que Bane entre en servicio.
- No se realizan modificaciones ad-hoc directas sobre el VPS sin reflejar las plantillas y generadores en el repositorio del core.
- No se admiten configuraciones con dominios de ejemplo no enrutables (`example.com`) en plantillas rastreadas en git.
