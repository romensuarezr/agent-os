# Research Sprint 27 — Revisor Antigravity CLI, Observabilidad de Liveness y Paridad de Gobernanza

> Prospección técnica previa determinista ($0 tokens) realizada mediante `scripts/agent/scout.sh` conforme al Gate Scout-First (T-129).

---

## Metodología y Consultas Scout

1. **Trial de Liveness y Monitorización de Workers**: `bash scripts/agent/scout.sh "process liveness check worker monitor bash"`
2. **Cableado CLI y JSON Schema**: `bash scripts/agent/scout.sh "cli wrapper structured output json schema timeout"`
3. **Guardas de Sandbox y Git Limpio**: `bash scripts/agent/scout.sh "git clean check readonly sandbox guard bash"`
4. **Medición de Paridad y Benchmarks de Gobernanza**: `bash scripts/agent/scout.sh "ai model evaluation benchmark parity measurement"`

---

## Descubrimientos Scout (por tarea)

### T-151: Trial de liveness y observabilidad del worker de inferencia en deliberación

- **Alternativa detectada:** `jest-worker` (v30.5.1, NPM), `@deepseek-ai/dsh-subprocess-local` (v0.0.1-rc.1, NPM).
- **Recomendación del agente:** Desarrollo a medida justificado (sonda determinista en Bash nativo).
- **Decisión del usuario:** Desarrollo a medida justificado — se trata de un ensayo empírico previo a cualquier cableado estructural para diagnosticar el estado del worker de inferencia (`Orca ADE`) al alcanzar el timeout (vivo+avanzando, vivo+atascado o muerto) y determinar si el veredicto llega dentro de una ventana de extensión de gracia (+30 a +60s) o nunca. No altera el veredicto `SIN_REVISOR` ni la compuerta humana; emite diagnóstico estructurado para decidir si liveness requiere componente dedicado o se descarta.
- **Notas de integración:**
  - Inspeccionar estado del proceso del worker en host / contenedor (`kill -0`, `/proc/$PID/status` o `orca orchestration worker-list`).
  - Medir latencia residual en ventana +30-60s post-timeout.
  - Documentar veredicto de viabilidad (`LIVENESS_VIABLE` o `LIVENESS_DESCARTADO`).
- **Alternativas rechazadas y motivos:**
  - `jest-worker`: Diseñado para paralelización en NodeJS, no aplicable al runtime de orquestación en Bash de Agent OS.
  - `@deepseek-ai/dsh-subprocess-local`: Requiere infraestructura y dependencias Node pesadas ajenas al control plane ligero del core.

---

### T-152: Cableado del Revisor Antigravity CLI (agy) como Tier 1 en deliberate-plan.sh

- **Alternativa detectada:** `node-llama-cpp` (v3.22.2, NPM), `json-schema-to-zod` (v2.8.1, NPM), `json-schema-traverse` (v1.0.0, NPM).
- **Recomendación del agente:** Desarrollo a medida justificado (cableado CLI directo sobre `agy` en PATH o `~/.local/bin/agy`).
- **Decisión del usuario:** Desarrollo a medida justificado — `agy` es un CLI local nativo disponible en el entorno (`agy --version 1.4.12`, accesible en PATH o `~/.local/bin/agy`), con soporte para `--print`, `--output-format json`, `--json-schema` y `--mode plan`. Debe integrarse como primer tier prioritario en `deliberate-plan.sh`, con degradación en cascada a Orca → HTTP → `SIN_REVISOR`.
- **Notas de integración:**
  - Gestionar el comportamiento particular de `agy` donde un timeout puede emitir código de salida 0: usar delimitadores y validación estricta de estructura JSON.
  - Envolver la llamada en wrapper de timeout portátil (`lib/portable-timeout.sh`).
  - Incorporar sonda de flags, disponibilidad y credenciales antes del despacho.
- **Alternativas rechazadas y motivos:**
  - `node-llama-cpp`: Innecesario; `agy` ya encapsula el runtime de inferencia y la interfaz con los modelos de Google Antigravity.
  - Herramientas npm de esquemas: La validación JSON Schema es nativa en `agy` (`--json-schema`) y en `python3 -c "import json"`.

---

### T-153: Guardas de seguridad, aislamiento read-only y certificación git-limpio para agy

- **Alternativa detectada:** `@deepseek-ai/dsh-fs-sandbox` (v0.0.1-rc.1, NPM), `@deepseek-ai/dsh-bash-sandbox` (v0.0.1-rc.1, NPM), `@deepseek-ai/dsh-sandbox` (v0.0.1-rc.1, NPM).
- **Recomendación del agente:** Desarrollo a medida justificado (guardarraíles en Bash nativo mediante `git status` y aislamiento temporal).
- **Decisión del usuario:** Desarrollo a medida justificado — el rol de Revisor es estrictamente de solo lectura (*read-only*). No puede bajo ningún concepto mutar archivos del repositorio, alterar ramas ni dejar residuos untracked.
- **Notas de integración:**
  - Ejecutar `agy` con banderas de contención (`--mode plan` / sandbox) y variables de entorno aisladas (`env -i`).
  - Comprobación estricta de `git status --porcelain` antes y después de la invocación: si el Revisor genera mutaciones, abortar fail-closed y restaurar el árbol.
  - Test automatizado en `tests/validate-control-plane.sh` asegurando bloqueo de mutaciones y working tree limpio.
- **Alternativas rechazadas y motivos:**
  - Librerías `@deepseek-ai`: Modelos sandbox propietarios en TypeScript/NodeJS que añaden dependencias incompatibles con los principios portables y $0 tokens del core.

---

### T-154: Batería de calibración, medición de cuota/coste y paridad Revisor-vs-Relé (T-147)

- **Alternativa detectada:** `@deepseek-ai/dsh-token-meter` (v0.0.1-rc.1, NPM), `@ai-sdk/provider` (v4.0.35, NPM).
- **Recomendación del agente:** Desarrollo a medida justificado (arnés de calibración estadística local).
- **Decisión del usuario:** Desarrollo a medida justificado — medir de forma cuantitativa la coincidencia de veredictos entre el Revisor automático (`agy`) y el Relé humano sobre una batería representativa de planes, operando bajo el nuevo flujo de gobernanza de dos niveles formalizado en T-147 (macro en planning, micro en tarea). Medir además coste de tokens y consumo de cuota por deliberación.
- **Notas de integración:**
  - Batería de prueba con planes conformes, planes con desviación de alcance (para validar `ESCALADO_A_HUMANO`) y planes con skills no existentes.
  - Registro de concordancia (%) entre veredicto automático y humano.
  - Medición de coste en tokens / tiempo de deliberación.
- **Alternativas rechazadas y motivos:**
  - Frameworks comerciales de evaluación (LangSmith, Promptfoo): Introducen dependencias externas de red y suscripciones de pago contrarias al diseño sobrio de Agent OS.
