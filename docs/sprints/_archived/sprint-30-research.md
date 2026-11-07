# Research Sprint 30

> Fuente: Análisis técnico determinista pre-código, prospección determinista OSS (scout.sh), diagnóstico de campo de la flota (2026-11-03) y especificaciones oficiales Docker Compose / Nango / Homepage.
> Fecha: 2026-11-03
> Siguiente sprint: Sprint 30
> Régimen de ejecución: Opción D (Autonomía acotada por defecto)

---

## Descubrimientos Scout (por tarea)

### T-165 — Despliegue en vivo y validación operativa de Bane en la flota
- **Alternativa detectada:** Imagen oficial `ghcr.io/pythops/bane` (1060⭐), SearXNG (`searxng/searxng`), cliente `bane-client.sh` nativo del core.
- **Recomendación del agente:** Adopción de la imagen oficial Docker existente en el core (`templates/bane/docker-compose.yml`), operando en producción viva sobre el VPS de inferencia.
- **Dictamen del Relé (Enmienda vinculante):** Recomendación ratificada. Precisiones operativas: el endpoint vivo se registra exclusivamente en el overlay privado (`fleet.yaml`), nunca en `fleet.example.yaml` commiteado (que solo contiene placeholders o esquema). El criterio de done exige una búsqueda real ejecutada a través de la rama autónoma del workflow `deep-research` con Bane activo, no solo un `--query` aislado del cliente CLI.
- **Notas de integración:**
  1. Conectar con el VPS de inferencia (<nodo-inferencia>) vía SSH determinista o Coolify.
  2. Desplegar el stack de Bane configurando las variables de entorno (`BANE_PORT`, `BANE_INFERENCE_URL`, `BANE_EMBEDDING_URL`) conforme a `templates/bane/.env.example`.
  3. Actualizar el overlay privado `fleet.yaml` para registrar el servicio Bane con su endpoint alcanzable.
  4. Ejecutar verificación viva con `bash scripts/agent/lib/bane-client.sh --check` validando código de salida 0.
  5. Ejecutar una consulta real mediante la rama autónoma del workflow canónico `@[.agents/workflows/deep-research.md]`, validando la integración de extremo a extremo sin intermediación manual.
- **Alternativas rechazadas y motivos:**
  - Perplexity Pro manual: Descartado por requerir intermediación interactiva humana y no permitir ejecución 100% desatendida.
  - Re-implementar motor de búsqueda propio desde cero: Descartado por violar la regla OSS-first (Bane ya provee el clon soberano de Perplexity).

### T-166 — Plantilla de despliegue soberano de Nango en VPS y runbook de integración
- **Alternativa detectada:** `NangoHQ/nango` (13101⭐ | Open Source / Source-Available), CLI oficial `nango` (v0.71.14 npm), `Anil-matcha/open-agent-connector` (849⭐ Apache-2.0).
- **Recomendación del agente:** Adoptar `NangoHQ/nango` oficial como plataforma de autenticación unificada OAuth y token broker para la flota de Agent OS.
- **Dictamen del Relé (Enmienda vinculante):** Recomendación ratificada con despliegue vivo obligatorio. Se añade como criterio de done desplegar en vivo su propia plantilla en el VPS y verificar que el health check real responde, con evidencia en el reporte y sin secretos en el repo. Si el despliegue vivo resulta inviable, eso es aborto a humano (fail-closed), no cierre con solo plantilla. Además, la composición Compose debe validarse contra la especificación oficial de Nango self-hosted antes de sellarla (no asumir que server + postgres basten, y el puerto no queda fijo en 4004 si el spec oficial define otro; la versión del CLI npm no determina la imagen Docker).
- **Notas de integración:**
  1. Auditar la especificación oficial de despliegue de Nango self-hosted para determinar los contenedores exactos requeridos, variables de entorno obligatorias y puertos canónicos.
  2. Diseñar `templates/nango/docker-compose.yml` conteniendo los servicios requeridos por el spec oficial con límites de recursos estándar.
  3. Proveer `templates/nango/.env.example` con variables saneadas.
  4. Declarar el servicio en `.agents/config/fleet.example.yaml` bajo el nodo de orquestación (<nodo-orquestacion>) usando placeholders.
  5. Desplegar en vivo en el VPS y verificar que el endpoint de salud responde satisfactoriamente.
  6. Documentar el runbook operativo `docs/runbooks/nango-oauth-service.md` detallando aprovisionamiento en Coolify/VPS, flujo de rotación de claves y uso por herramientas/agentes.
- **Alternativas rechazadas y motivos:**
  - `open-agent-connector`: Descartado por menor madurez (849⭐ vs 13.1k⭐ de Nango) y ecosistema de conectores más limitado.
  - Gestión manual de tokens en archivos `.env`: Descartada por riesgos de expiración de tokens, dispersión y falta de interfaz de renovación OAuth automática.
  - Cierre con solo plantilla sin despliegue vivo: Descartado terminantemente por el Relé.

### T-167 — Remediación determinista de compatibilidad en generate-homepage-config.sh y puesta a punto de Homepage Dashboard
- **Alternativa detectada:** Paquete `gethomepage.dev`, `0xN1nja/homepagectl` (207⭐), generador nativo determinista `scripts/agent/generate-homepage-config.sh`.
- **Recomendación del agente:** Desarrollo a medida justificado sobre el generador nativo existente del core (`generate-homepage-config.sh`) para asegurar tolerancia a esquemas heterogéneos de `fleet.yaml` sin añadir dependencias runtime.
- **Dictamen del Relé (Enmienda vinculante):** Recomendación ratificada con remediación viva obligatoria y dependencia de T-166. Criterio de done: regenerar la configuración con el generador ya tolerante y redesplegar en la instancia viva, con verificación tarjeta por tarjeta desde el contenedor y pase visual. Corrección estrictamente vía generador y redespliegue, nunca editando a mano el volumen Docker. El proxy de Docker y Glances se resuelven según la realidad viva (Glances solo se reactiva si responde, si no queda documentado). La tolerancia al esquema abreviado queda como fallback con defaults transparentes (el esquema estándar sigue siendo el preferido y documentado, y los fixtures en tests deben cubrir casos estándar, abreviado y mixto). En la plantilla, nada de URLs inventadas: placeholders reconocibles por el filtro de omisión, Orca configurable u omitida (no localhost rígido), y la tarjeta de Ollama reflejando la realidad viva verificada.
- **Notas de integración:**
  1. En `scripts/agent/generate-homepage-config.sh`, normalizar el parsing de servicios: si el valor de un servicio es un entero o string (puerto numérico), convertirlo internamente a diccionario estándar `{ "port": int, "enabled": true }` como fallback transparente, evitando el fallo `AttributeError: 'int' object has no attribute 'get'`.
  2. Soportar el campo `ip` como fallback automático cuando no exista el campo `host` en la definición del nodo.
  3. Incorporar tarjeta de Nango en Homepage utilizando el puerto y esquema efectivamente verificados en T-166.
  4. Sanear `templates/homepage/config/services.yaml`: sustituir dominios ficticios (`example.com`) por placeholders controlados reconocibles por el filtro, hacer configurable o condicional la tarjeta de Orca, y alinear la tarjeta de Ollama con la realidad viva.
  5. Redesplegar Homepage en vivo y verificar tarjeta por tarjeta desde dentro del contenedor y visualmente.
  6. Actualizar `docs/runbooks/coolify-homepage-deployment.md`.
- **Alternativas rechazadas y motivos:**
  - `homepagectl`: Descartado por asumir un daemon Docker local exclusivo, mientras que Agent OS opera sobre una flota heterogénea distribuida (Tailscale + nodos remotos).
  - Edición manual directa en volúmenes Docker del VPS: Rechazada terminantemente; todo cambio debe partir de plantillas y generadores del core trazables en git.

### T-168 — Arreglo en vivo de Homepage, ping granular y descubrimiento portable multi-repo
- **Alternativa detectada:** Docker Swarm Service Discovery integrado en Homepage, API manual de comprobación, generador determinista `generate-homepage-config.sh` con overlay privado `fleet.yaml`.
- **Recomendación del agente:** Eliminar el socket proxy Swarm discovery (`docker.yaml`) que causa fallos continuos 403 Forbidden y `ECONNREFUSED` al estar configurado `SERVICES: '0'`. Fundamentar el descubrimiento enteramente en el overlay privado `fleet.yaml`. Implementar soporte para `ping_path` granular por servicio (permitiendo `/` para OmniRoute y resolviendo el 404 de `/health`). Integrar Glances si responde vivo en nodo secundario. Garantizar backup fechado (`.bak.<timestamp>`) previo a la sobrescritura y compuerta estricta de pase visual por el usuario en navegador.
- **Dictamen del Relé (Enmienda vinculante):** Recomendación ratificada. El descubrimiento se mantiene portable: mismo generador y plantillas en cualquier repo hijo, cada repo con su overlay privado, 0 datos privados en git. Triage riguroso de tarjetas faltantes (Ollama en su nodo real, clarificación de Open-WebUI y Hermes). Cierre solo con pase visual del usuario en navegador, no con HTTP del agente.
- **Alternativas rechazadas y motivos:**
  - Habilitar `SERVICES: 1` en el socket proxy de Docker: Descartado por elevar la superficie de ataque y privilegios del proxy de Docker sobre la API del daemon innecesariamente, cuando los servicios de la flota ya están declarados y versionados en `fleet.yaml`.
  - Cierre automático sin inspección del usuario: Rechazado taxativamente por el Relé; Homepage es una interfaz de usuario visual y requiere validación en navegador.

### T-169 — Motor de búsqueda profunda (ensayo Vane en vivo, reactivación de SearXNG e integración de backend)
- **Alternativa detectada:** Vane (`pythops/vane`), SearXNG (`searxng/searxng`), DuckDuckGo HTML scraping, APIs comerciales (Tavily, Perplexity).
- **Recomendación del agente:** Ensayo de Vane con compuerta fail-closed: pull previo obligatorio de imagen Docker pública; si no existe o el ensayo no da informe útil, aborto inmediato a humano. Reactivación del contenedor SearXNG preexistente en la flota (sin duplicar instancias), probando consulta real y conectándolo como backend del motor de búsqueda profunda. Sustituir componentes de Bane por los del motor probado.
- **Dictamen del Relé (Enmienda vinculante):** Ratificado. T-169 sucede a T-165 con nuevo ID. El cierre exige investigación real autónoma ejecutada por el workflow canónico `deep-research.md`. Denominador inmutable en 38/38.
- **Alternativas rechazadas y motivos:**
  - Desplegar una segunda instancia de SearXNG desde cero: Rechazado por ineficiencia de recursos; la flota ya aloja una instancia inactiva que debe auditarse y reactivarse.
  - Asumir la existencia de Vane sin pull determinista previo: Rechazado para prevenir el mismo fallo fail-closed de T-165.

### T-170 — Primera integración real de Nango en flujo operativo de agente
- **Alternativa detectada:** Cloudflare API / OAuth, Infisical Universal Auth, GitHub App Connector, Slack / Notion.
- **Recomendación del agente:** Elaborar propuesta formal sellada ante el humano con trade-offs, analizando Cloudflare e Infisical como candidatos inmediatos, flujos desbloqueados y credenciales implicadas. Bloquear toda conexión hasta obtener aprobación humana expresa. Conectar en Nango y crear/adaptar flujo de agente con evidencia real.
- **Dictamen del Relé (Enmienda vinculante):** Ratificado. La compuerta humana previa es estricta: ninguna credencial ni conector se aprovisiona sin la aprobación explícita en chat. Denominador inmutable en 38/38.
- **Alternativas rechazadas y motivos:**
  - Conectar APIs de producción sin revisión humana previa: Rechazado terminantemente por seguridad y gobernanza de credenciales.

### T-171 — Re-ensayo de Vane (`itzcrazykns1337/vane:latest`), investigación real y posible integración soberana
- **Alternativa detectada:** `itzcrazykns1337/vane:latest` (Docker Hub oficial de Vane, 3.91 GB amd64 / 3.43 GB arm64), SearXNG preexistente de la flota (`searxng/searxng`).
- **Recomendación del agente:** Probar estrictamente la imagen exacta `itzcrazykns1337/vane:latest` descartando cualquier variante `slim` o repositorios inexistentes como `pythops/vane`.
- **Dictamen del Relé (Enmienda vinculante):** Ratificado. Gate 0 determinista: pull previo obligatorio; si falla, aborto inmediato a humano sin cierre de plantilla. El ensayo exige despliegue y una investigación real autónoma con generación de informe útil (no solo citas). Si no hay informe útil, aborto a humano sin forzar integración. Solo si se justifica, conectar el SearXNG preexistente (sin duplicar instancias). Denominador inmutable en 38/38.
- **Alternativas rechazadas y motivos:**
  - `pythops/vane`: Inexistente en Docker Hub / GHCR (error de namespace en T-169).
  - Variantes `slim`: Descartadas expresamente por el usuario para garantizar paridad completa de dependencias de investigación.
  - Desplegar un segundo SearXNG: Prohibido taxativamente; se reutiliza la instancia existente si el ensayo lo justifica.

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

- **Decisión 1**: Desplegar Bane en el nodo de inferencia y validar el flujo determinista con `bane-client.sh --check` (`exit 0`) y búsqueda real por la rama autónoma del workflow `deep-research`, cerrando la brecha entre el código del core y la operativa viva.
- **Decisión 2**: Incorporar la plantilla oficial de Nango (`templates/nango/`) validada contra el spec self-hosted oficial, ejecutar despliegue en vivo en VPS con health check real verificado (fail-closed) y runbook operativo para habilitar gestión OAuth soberana en la flota.
- **Decisión 3**: Robustecer `generate-homepage-config.sh` eliminando el fallo con puertos numéricos y campos `ip` (fallback transparente), sanear `templates/homepage/config/services.yaml` de URLs ficticias y redesplegar en vivo verificando tarjeta por tarjeta y pase visual.
- **Decisión 4**: El denominador de la suite de validación `tests/validate-control-plane.sh` se mantiene **estrictamente inmutable en 38/38** (0 errores), integrando las nuevas aserciones como subchecks dentro de checks existentes.

---

## Descartado

- No se emplean servicios SaaS de pago para búsqueda profunda (Perplexity comercial) una vez que Bane entre en servicio.
- No se realizan modificaciones ad-hoc directas sobre el VPS sin reflejar las plantillas y generadores en el repositorio del core.
- No se admiten configuraciones con dominios de ejemplo no enrutables (`example.com`) en plantillas rastreadas en git.
