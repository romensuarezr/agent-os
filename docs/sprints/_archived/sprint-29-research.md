# Research Sprint 29

> Fuente: Análisis técnico determinista pre-código, Docker Compose v2 specification y auditoría de gobernanza del core
> Fecha: 2026-11-02
> Siguiente sprint: Sprint 29
> Régimen de ejecución: Opción D (Autonomía acotada por defecto)

---

## Descubrimientos Scout (por tarea)

### T-162 — Cierre de Bane (Límites de recursos en docker-compose.yml y .env.example)
- **Alternativa detectada:** Específicación oficial Docker Compose v2 (`deploy.resources.limits` y `reservations`), paquete `docker-compose` en npm (v1.5.0) y librería `dockerode` (v5.0.1).
- **Recomendación del agente:** Desarrollo a medida justificado (especificación declarativa Compose estándar).
- **Decisión del usuario:** Desarrollo a medida justificado — se parametriza la plantilla YAML del core sin añadir dependencias runtime externas.
- **Notas de integración:** Añadir en `templates/bane/docker-compose.yml` las claves estándar `deploy.resources.limits.cpus`, `deploy.resources.limits.memory`, `deploy.resources.reservations.cpus` y `deploy.resources.reservations.memory` con fallbacks deterministas dentro del spec original (<250MB) al no disponer de medición empírica bajo carga (`${BANE_CPU_LIMIT:-1.0}`, `${BANE_MEMORY_LIMIT:-250M}`, `${BANE_CPU_RESERVATION:-0.1}`, `${BANE_MEMORY_RESERVATION:-64M}`). Crear `templates/bane/.env.example` análogo a `templates/freellmapi/.env.example`.
- **Alternativas rechazadas y motivos:**
  - `dockerode` / `docker-compose` npm: Inadecuados por exigir runtime Node.js innecesario para un template YAML declarativo agnóstico.
  - Límites de recursos hardcodeados: Descartados por violar el principio de frontera portable y configurabilidad en nodos VPS heterogéneos.

### T-163 — Higiene de cierre completa (blindaje de rutas personales fuera de repo y re-chequeo post-cierre)
- **Alternativa detectada:** Paquetes `@pinojs/redact` (v0.4.0), `fast-redact` (v3.5.0) y `sanitize-filename` (v1.6.4).
- **Recomendación del agente:** Desarrollo a medida justificado (scripts Bash nativos del core de Agent OS).
- **Decisión del usuario:** Desarrollo a medida justificado — el core mantiene utilidades bash deterministas sin dependencias externas de Node.js o Python en el flujo de cierre.
- **Notas de integración:** 
  1. En `scripts/agent/design-digest.sh`, generalizar la sustitución de rutas personales sustituyendo no solo `${ROOT_DIR}/` sino patrones amplios como `/(home|Users)/[a-zA-Z0-9_-]+/` y esquemas `file:///...` para prevenir fugas de rutas absolutas de host hacia digest o raw json.
  2. En `scripts/agent/close-task.sh`, incorporar verificación de higiene (`locator-hygiene.sh`) antes de mover el ref y re-chequeo post-cierre para atrapar regresiones antes de salir de la tarea.
  3. En `scripts/agent/close-sprint.sh`, asegurar chequeo de higiene / suite determinista.
- **Alternativas rechazadas y motivos:**
  - Librerías npm (`fast-redact`): Descartadas para preservar portabilidad bash nativa con coste 0 de tokens y sin runtime adicional.
  - Saneamiento manual ad-hoc: Descartado por ser propenso a errores humanos y provocar abortos evitables (como el ocurrido en T-160).

### T-164 — Formalización de Opción D como régimen operativo por defecto
- **Alternativa detectada:** Framework de aprobación de DeepSeek (`@deepseek-ai/dsh-user-approval`), `@anthropic-ai/claude-agent-sdk`, `GoldstonianConcordanceBible/402` (PONS 402 Governance Before Execution).
- **Recomendación del agente:** Desarrollo a medida justificado (gobernanza y workflows nativos de Agent OS).
- **Decisión del usuario:** Desarrollo a medida justificado — consolidar en los workflows canónicos del core (`session-start.md`, `sprint-planning.md`, `AGENTS.md`) el modelo ya validado empíricamente en el Sprint 28 (informe `sprint-28-autonomy-pilot-report.md`).
- **Notas de integración:**
  1. Formalizar el **Camino Limpio**: ante veredicto `CONSENSO`, suite verde, diff estrictamente en caja y diseño macro respetado, el agente avanza desatendidamente hasta el cierre y push sin solicitar confirmación interactiva en el chat en cada puerta.
  2. Formalizar el **Compuerta de Aborto Inmediato (Fail-Closed)**: cualquier veredicto != `CONSENSO`, fallo en suite, archivo fuera de caja o mutación centinela suspende la autonomía y escala inmediatamente al humano.
  3. Formalizar la **Condición Pre-Merge Refinada y Auditoría A Posteriori**: publicación obligatoria en `origin` de la rama de feat y el informe/notas antes del merge, recibo de deliberación debidamente acreditado (referenciado por veredicto/SHA), y captura persistente del digest y raw json en el commit atómico de cierre de tarea (`close-task.sh`).
- **Alternativas rechazadas y motivos:**
  - Regímenes permisivos con auto-aprobación de `SIN_REVISOR` o `REVISADO_CON_CAMBIOS`: Rechazados por violar el principio fail-closed y arriesgar degradación silenciosa sin auditoría.
  - Retorno al régimen clásico de interacción obligatoria en todas las puertas: Descartado tras comprobarse en el piloto Sprint 28 una reducción del 91.7% de fricción con 100% de apego arquitectónico.

---

## Hallazgos clave

1. **Docker Compose deploy.resources en Docker Compose v2**:
   Docker Compose v2 soporta de forma estándar el bloque `deploy.resources.limits` y `deploy.resources.reservations` sin necesidad de ejecutar en modo Swarm (a diferencia de versiones legacy de Compose v1).
2. **Generalización de Saneamiento de Rutas de Host**:
   Los revisores LLM frecuentemente referencian archivos con prefijos absolutos de entorno (`file:///home/usuario/...` o `/Users/usuario/...`). Un saneamiento basado exclusivamente en `ROOT_DIR` falla si la ruta fue emitida antes de resolver symlinks o si refiere a rutas temporales de home. La sustitución canónica debe contemplar patrones de home de usuario Unix (`/home/[^/]+` y `/Users/[^/]+`) convirtiéndolos a rutas relativas al proyecto o placeholders neutros.
3. **Formalización Contractual de la Opción D**:
   El informe de resultados del piloto (`docs/sprints/sprint-28-autonomy-pilot-report.md`) dictaminó `PILOTO_OPCION_D_EXITOSO` con 4/4 tareas testigo completadas, reduciendo las intervenciones humanas de 12 a 1 (y esta 1 fue un aborto preventivo que protegió la integridad del repo). Su formalización en `session-start.md` elimina la duplicidad y contradicción entre el workflow canónico y las instrucciones ad-hoc de chat.

---

## Decisiones tomadas

- **Decisión 1**: Se añaden límites de CPU y memoria a `templates/bane/docker-compose.yml` parametrizados por variables de entorno con valores por defecto conservadores (`2.0` CPU, `2G` RAM), acompañados de `templates/bane/.env.example`.
- **Decisión 2**: Se centraliza y generaliza la sanitización de rutas personales en `design-digest.sh` y se incorpora un re-chequeo determinista de higiene en `close-task.sh` y `close-sprint.sh`.
- **Decisión 3**: Se actualiza `session-start.md`, `sprint-planning.md` y `AGENTS.md` para reflejar la Opción D como el régimen operativo por defecto del core.
- **Decisión 4**: El denominador de la suite de validación `tests/validate-control-plane.sh` se mantiene inmutable en **38/38** (0 errores).

---

## Descartado

- No se integran paquetes externos de npm para saneamiento de rutas o gestión de compose (0 dependencias externas).
- No se auto-aprueban veredictos de `REVISADO_CON_CAMBIOS` o `SIN_REVISOR` en el régimen Opción D (estrictamente fail-closed ante cualquier estado distinto de `CONSENSO`).
- No se incluye la migración REA de `annascheer.com`, el dashboard de Homepage en VPS, ni Bytebox en este sprint.
