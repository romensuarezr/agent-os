# Research Sprint 28 — Autonomía Acotada (Opción D), Enrutado por Dificultad e Integración Soberana de Bane

> Prospección técnica previa determinista ($0 tokens) realizada mediante `scripts/agent/scout.sh` conforme al Gate Scout-First (T-129).

---

## Metodología y Consultas Scout

1. **Tests Unitarios de Borde y Mocking de Timeout/Kill en Bash**: `bash scripts/agent/scout.sh "mock cli unit testing bash timeout"`
2. **Enrutamiento por Dificultad y Cascada de Modelos LLM**: `bash scripts/agent/scout.sh "llm difficulty routing fallback cascade"`
3. **Canal de Señalización Directa y Piloto Autónomo Opción D**: `bash scripts/agent/scout.sh "cli signal gate autonomous agent"`
4. **Bane Docker Compose y Despliegue Reproducible**: `bash scripts/agent/scout.sh "bane self-hosted deep research docker compose"`
5. **Cliente CLI Determinista para Deep Research**: `bash scripts/agent/scout.sh "curl cli wrapper deep research api client bash"`
6. **Workflow Bifurcado Autónomo / Manual**: `bash scripts/agent/scout.sh "agent workflow branch autonomous manual fallback"`
7. **Sondas de Flota, Runbooks y Diagnóstico Determinista**: `bash scripts/agent/scout.sh "fleet health probe diagnosis runbook bash"`

---

## Descubrimientos Scout (por tarea)

### T-155: Batería de tests de hueco del Revisor Dual en Check 34

- **Alternativa detectada:** `jest-canvas-mock` (v2.5.8), `office-addin-mock` (v4.0.1), `jest-date-mock` (v1.0.10).
- **Recomendación del agente:** Desarrollo a medida justificado (scripts mock deterministas en Bash y aserciones en `tests/validate-control-plane.sh`).
- **Decisión del usuario:** Desarrollo a medida justificado — carry-over acordado en T-154 (Opción A de Gobernanza). Se trata de cubrir los 3 huecos de integración identificados en la suite de control plane para el Revisor Tier 1 (`agy`) y su cascada a Tier 2 (`Orca ADE`):
  1. *Binario ausente*: salto determinista inmediato (0s) hacia Orca cuando `agy` no está en PATH ni en ruta configurada (`evaluator_tier != agy`).
  2. *Timeout real con kill*: terminación efectiva del proceso colgado mediante `SIGKILL` tras agotar el presupuesto de 30s sin dejar procesos huérfanos ni zombies en el sistema.
  3. *Handoff agy → Orca*: degradación fluida de agy ante indisponibilidad hacia Orca ADE con captura y aceptación de veredicto válido (`evaluator_tier=orca`).
- **Notas de integración:**
  - Integrar como sub-checks específicos dentro de Check 34 de `tests/validate-control-plane.sh`.
  - Emplear fixtures mock ejecutables temporales (`mktemp -d`) con trampas de señales y retardos simulados.
  - Denominador de la suite se mantiene rigurosamente en **37/37** (0 errores).
- **Alternativas rechazadas y motivos:**
  - Librerías mock de Jest/Node: Incompatibles con el motor de validación en Bash puro y $0 dependencias de Agent OS.

---

### T-156: Experimento empírico de enrutamiento por dificultad (Orca vs. agy)

- **Alternativa detectada:** `@monoes/routing` (v2.24.0, NPM), `@csstools/postcss-cascade-layers` (v6.0.2).
- **Recomendación del agente:** Desarrollo a medida justificado (batería empírica comparativa directa con telemetría local).
- **Decisión del usuario:** Desarrollo a medida justificado — en T-154 se constató que ante planes fuertemente discordantes con el diseño macro (C-04: omisión de tests, C-06: fuga a main/tags, C-07: alteración de contratos), `agy` agotó su ventana de 30s provocando degradación por timeout a `SIN_REVISOR`. El experimento somete estos mismos casos discordantes al worker de inferencia de Orca ADE con presupuesto temporal amplio (60s a 120s) para determinar empíricamente si:
  - *Hipótesis A (Orca resuelve)*: Orca emite veredictos estructurados limpios de rechazo (`ESCALADO_A_HUMANO` o `REVISADO_CON_CAMBIOS`), demostrando que un enrutador por complejidad aporta valor real.
  - *Hipótesis B (Orca también agota/falla)*: Orca también excede el tiempo o se desorienta, demostrando que los planes complejos o discordantes deben canalizarse directamente a supervisión humana por diseño ($0 cómputo en cascadas infructuosas).
- **Notas de integración:**
  - Ejecutar los casos C-04, C-06 y C-07 a través del adaptador `scripts/agent/lib/orca-client.sh` con timeout extendido.
  - Documentar latencias, tasas de acierto y calidad del veredicto en `docs/sprints/sprint-28-difficulty-routing-report.md`.
  - Concluir con un dictamen arquitectónico vinculante: `ENRUTADO_DIFICIL_VIABLE` o `ENRUTADO_DIFICIL_DESCARTADO`.
- **Alternativas rechazadas y motivos:**
  - Frameworks semánticos externos (`@monoes/routing`): Añaden capas de abstracción innecesarias frente al stack ya disponible en el core.

---

### T-157: Marco del piloto de autonomía Opción D, compuertas deterministas e informe

- **Alternativa detectada:** `alvin-bot` (v5.165.0, NPM), `@anthropic-ai/claude-agent-sdk` (v0.3.316, NPM), `signal-exit` (v4.1.0, NPM).
- **Recomendación del agente:** Desarrollo a medida justificado (protocolo determinista de autonomía en camino limpio).
- **Decisión del usuario:** Desarrollo a medida justificado — formalizar las reglas del **Piloto Opción D** para que el agente avance sin señal humana en camino limpio:
  - *Camino limpio*: Revisor emite `CONSENSO` + suite de tests en verde (37/37) + diff estrictamente dentro de la caja de archivos + macro intacto.
  - *Acción autónoma autorizada*: El agente avanza desatendidamente por las compuertas internas, incluyendo el commit de implementación, el merge `--no-ff` a `multi-agent`, push a `origin` y ejecución de `close-task.sh`.
  - *Auditoría a posteriori*: Todo queda publicado en `origin` (rama de feat conservada o referenciada, recibo de deliberación `.agents/context/deliberation-T-XXX.json` y digest redactado) para inspección asíncrona del relé.
  - *Aborto inmediato a humano (Fail-Closed)*: Ante `SIN_REVISOR`, `ESCALADO_A_HUMANO`, `RECHAZADO`, desviación del macro, alteración de archivos fuera de caja, disparo de centinelas de seguridad o fallo de la suite, el agente aborta de inmediato y escala al humano.
  - *Puertas humanas inmutables*: El diseño macro de planning, las anomalías/desviaciones y la promoción a `main` se reservan de forma exclusiva y obligatoria al operador humano.
- **Notas de integración:**
  - Formalizar los contratos operativos del piloto en `.agents/rules/` y workflows de sesión.
  - Preparar la estructura de métricas de intervención para evaluar en las tareas testigo subsiguientes (T-158 a T-161).
  - Documentar el informe base en `docs/sprints/sprint-28-autonomy-pilot-report.md`.
- **Alternativas rechazadas y motivos:**
  - SDKs externos y bots propietarios: Incompatibles con los principios de soberanía local y $0 dependencias de Agent OS.

---

### T-158: Plantillas Docker Compose y configuración de flota de Bane con frontera portable

- **Alternativa detectada:** `docker-compose` (v1.5.0, NPM), `@powersync/cli-plugin-docker` (v0.10.3, NPM).
- **Recomendación del agente:** Desarrollo a medida justificado (plantilla compose agnóstica en `templates/bane/`).
- **Decisión del usuario:** Desarrollo a medida justificado — incorporar las plantillas y esquemas de configuración para el despliegue soberano de Bane (motor open-source de deep research y clon de Perplexity Pro) en la flota de Agent OS:
  - *Plantilla*: `templates/bane/docker-compose.yml` parametrizada con variables de entorno estándar (`BANE_PORT`, `BANE_INFERENCE_URL`, `BANE_API_KEY`).
  - *Flota*: Declaración en `.agents/config/fleet.example.yaml` bajo `services.bane` con placeholders genéricos (`http://<nodo-inferencia>:3000` o `${BANE_API_URL}`).
  - *Frontera portable*: Prohibición absoluta de literales de infraestructura personal, IPs privadas o credenciales en el core (validado por Check 22).
- **Notas de integración:**
  - Seguir el patrón establecido en `templates/freellmapi/` y `templates/homepage/`.
  - Garantizar compatibilidad con Coolify / Traefik y despliegues aislados en Docker.
- **Alternativas rechazadas y motivos:**
  - Wrappers npm de compose: Innecesarios; Docker Compose nativo cubre el 100% de los requisitos.

---

### T-159: Cliente CLI determinista para Bane (`bane-client.sh`) con salida stdout

- **Alternativa detectada:** `firecrawl-cli` (v1.26.24, NPM), `@anthropic-ai/sandbox-runtime` (v0.0.81, NPM).
- **Recomendación del agente:** Desarrollo a medida justificado (script CLI ligero en `scripts/agent/lib/bane-client.sh`).
- **Decisión del usuario:** Desarrollo a medida justificado — cliente determinista en Bash para interactuar con la API REST de Bane:
  - *Salida estándar (stdout)*: La salida primaria del cliente es el resultado de la investigación en Markdown directo por stdout (o archivo de destino opcional con `--output`), facilitando pipes y composición UNIX.
  - *Semántica de disponibilidad ("Activo")*: El servicio se considera activo única y exclusivamente si está **configurado Y alcanzable dentro de una cota de timeout estricta** (ej. 3s). Si no está configurado o no responde, degrada limpiamente a código de salida reconocible sin bloquear al agente ni lanzar errores fatales.
  - *Sin dependencias pesadas*: Basado en `curl` nativo, `jq`/python para parsing y `scripts/agent/lib/portable-timeout.sh`.
- **Notas de integración:**
  - Argumentos canónicos: `--query`, `--timeout`, `--json`, `--check`.
  - Manejo fail-soft con diagnóstico limpio en stderr sin exponer secretos en argv.
- **Alternativas rechazadas y motivos:**
  - SDKs de Node/Python externos: Rompen el principio de $0 dependencias del control plane.

---

### T-160: Workflow `deep-research` con bifurcación autónomo / manual

- **Alternativa detectada:** `@mastra/core` (v1.81.0, NPM), `@anthropic-ai/claude-agent-sdk` (v0.3.316, NPM).
- **Recomendación del agente:** Desarrollo a medida justificado (evolución determinista de `.agents/workflows/`).
- **Decisión del usuario:** Desarrollo a medida justificado — crear el workflow especializado `.agents/workflows/deep-research.md` e integrarlo en `sprint-planning.md` con bifurcación automática:
  - *Rama A (Bane Activo / Autónomo)*: Si `bane-client.sh --check` confirma que el servicio está configurado y alcanzable en timeout, el workflow despacha la consulta automáticamente, captura la investigación estructurada en stdout y la deposita directamente en el research del sprint o tarea sin requerir intervención humana.
  - *Rama B (Bane Inactivo / Manual)*: Si Bane no está configurado o no responde en timeout, el workflow preserva al 100% el comportamiento manual actual: emite el prompt optimizado para copiar y pegar en Perplexity Pro / buscador web, sin bloquear la sesión ni provocar errores.
- **Notas de integración:**
  - Asegurar que el flujo manual preexistente permanezca byte-compatible y funcional en ausencia de Bane.
  - Formatear el reporte de deep research con las secciones canónicas de Agent OS (`## Hallazgos clave`, `## Decisiones tomadas`, `## Descartado`).
- **Alternativas rechazadas y motivos:**
  - Orquestadores externos de workflows: Incompatibles con la estructura Markdown de workflows de Antigravity / Agent OS.

---

### T-161: Diagnóstico de flota (`fleet-doctor`), compuerta técnica, runbook y suite

- **Alternativa detectada:** `@hasna/uptime` (v0.1.71, NPM), `@deepseek-ai/dsh-sandbox-local` (v0.0.1-rc.1, NPM).
- **Recomendación del agente:** Desarrollo a medida justificado (sonda determinista en `fleet-doctor.sh` y Check 38 en la suite).
- **Decisión del usuario:** Desarrollo a medida justificado — cerrar el ciclo de integración de Bane con herramientas de diagnóstico y certificación integral del control plane:
  - *Sonda en `fleet-doctor.sh`*: Añadir verificación de servicio `bane` en modo `warn-only` (exit code 0, status OK si responde, WARN si está ausente/caído).
  - *Runbook operativo*: Documentar la guía paso a paso de despliegue, configuración y troubleshooting en `docs/runbooks/bane-deep-research-service.md`.
  - *Certificación en suite de tests*: Añadir Check 38 dedicado a la integración y cliente de Bane en `tests/validate-control-plane.sh`, actualizando explícitamente el denominador de la suite de **37/37 a 38/38**.
- **Notas de integración:**
  - La suite de validación debe certificar: sintaxis de compose, degradación fail-soft del cliente ante caída, comportamiento de `fleet-doctor.sh` y ausencia de literales privados.
  - Denominador declarado formalmente: **38/38** (0 errores).
- **Alternativas rechazadas y motivos:**
  - Herramientas externas de uptime/monitoreo: Excesivas para el diagnóstico estático y de pre-flight local del core.
