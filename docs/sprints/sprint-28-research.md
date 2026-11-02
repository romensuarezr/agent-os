# Research Sprint 28 — Autonomía Acotada, Enrutado por Dificultad y Hardening del Revisor Dual

> Prospección técnica previa determinista ($0 tokens) realizada mediante `scripts/agent/scout.sh` conforme al Gate Scout-First (T-129).

---

## Metodología y Consultas Scout

1. **Tests Unitarios de Borde y Mocking de Timeout/Kill en Bash**: `bash scripts/agent/scout.sh "mock cli unit testing bash timeout"`
2. **Enrutamiento por Dificultad y Cascada de Modelos LLM**: `bash scripts/agent/scout.sh "llm difficulty routing fallback cascade"`
3. **Canal de Señalización Directa y Compuertas de Agente Autónomo**: `bash scripts/agent/scout.sh "cli signal gate autonomous agent"`

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
  - Denominador de la suite debe mantenerse rigurosamente en **37/37** (0 errores).
- **Alternativas rechazadas y motivos:**
  - Librerías mock de Jest/Node: Incompatibles con el motor de validación en Bash puro y $0 dependencias de Agent OS.

---

### T-156: Experimento empírico de enrutamiento por dificultad (Orca vs. agy)

- **Alternativa detectada:** `@monoes/routing` (v2.24.0, NPM), `@csstools/postcss-cascade-layers` (v6.0.2).
- **Recomendación del agente:** Desarrollo a medida justificado (batería empírica comparativa directa con telemetría local).
- **Decisión del usuario:** Desarrollo a medida justificado — en T-154 se constató que ante planes fuertemente discordantes con el diseño macro (C-04: omisión de tests, C-06: fuga a main/tags, C-07: alteración de contratos), `agy` agotó su ventana de 30s provocando degradación por timeout a `SIN_REVISOR`. El experimento somete estos mismos casos discordantes al worker de inferencia de Orca ADE con presupuesto temporal amplio (60s a 120s) para determinar empíricamente si:
  - *Hipótesis A (Orca resuelve)*: Orca emite veredictos estructurados limpios de rechazo (`ESCALADO_A_HUMANO` o `REVISADO_CON_CAMBIOS`), demostrando que un enrutador por complejidad (planes conformes → agy rápido; planes con alertas léxicas o no conformes → Orca con más presupuesto) aporta valor real.
  - *Hipótesis B (Orca también agota/falla)*: Orca también excede el tiempo o se desorienta, demostrando que los planes complejos o discordantes deben canalizarse directamente a supervisión humana por diseño ($0 cómputo en cascadas infructuosas).
- **Notas de integración:**
  - Ejecutar los casos de prueba C-04, C-06 y C-07 a través del adaptador `scripts/agent/lib/orca-client.sh` con timeout extendido.
  - Documentar latencias, tasas de acierto y calidad del veredicto en `docs/sprints/sprint-28-difficulty-routing-report.md`.
  - Concluir con un dictamen arquitectónico vinculante: `ENRUTADO_DIFICIL_VIABLE` o `ENRUTADO_DIFICIL_DESCARTADO`.
- **Alternativas rechazadas y motivos:**
  - Frameworks semánticos externos (`@monoes/routing`): Añaden capas de abstracción innecesarias frente al stack ya disponible en el core.

---

### T-157: Piloto de autonomía acotada con canal directo Agente-Relé y métricas

- **Alternativa detectada:** `alvin-bot` (v5.165.0, NPM), `@anthropic-ai/claude-agent-sdk` (v0.3.316, NPM), `signal-exit` (v4.1.0, NPM).
- **Recomendación del agente:** Desarrollo a medida justificado (protocolo determinista de señalización en ficheros/JSON con compuertas de seguridad).
- **Decisión del usuario:** Desarrollo a medida justificado — diseñar y pilotar un canal directo agente → relé que permita completar una tarea de desarrollo sin que el usuario tenga que copiar y pegar bloques de texto con informes y veredictos en el chat.
  - *Línea base actual*: ~3 intervenciones manuales por tarea (Fase 3.5 aprobación de plan, reporte de implementación Paso 6, confirmación de merge y cierre).
  - *Objetivo del piloto*: Reducir las intervenciones manuales rutinarias a una simple señalización determinista (ej. aprobación directa estructurada), midiendo que se alcancen 0 degradaciones silenciosas, 0 desviaciones del macro y suite en verde (37/37).
  - *Criterios de aborto rigurosos*: Fallo del canal, veredicto `SIN_REVISOR`, detección de mutación en centinelas o cualquier desviación respecto al diseño macro pactado provocan la interrupción inmediata del flujo autónomo y la vuelta obligatoria al modo clásico de intervención manual paso a paso.
  - *Puertas humanas inmutables*: El diseño macro de planning, el escalado ante anomalías (`ESCALADO_A_HUMANO`), la resolución de `SIN_REVISOR` y la promoción final a `main` se mantienen 100% bajo control humano.
- **Notas de integración:**
  - Diseñar el mecanismo de señalización del canal acordado en planning.
  - Ejecutar el piloto sobre una tarea testigo representativa.
  - Medir empíricamente el recuento de intervenciones del usuario y consolidar los resultados en `docs/sprints/sprint-28-autonomy-pilot-report.md`.
- **Alternativas rechazadas y motivos:**
  - SDKs externos de agentes (`@anthropic-ai/claude-agent-sdk`, bots multi-plataforma): Requieren dependencias foráneas, APIs de mensajería (Telegram/Slack) o entornos de ejecución pesados incompatibles con la portabilidad local y soberana de Agent OS.
