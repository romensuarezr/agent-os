# Research y Prospección Tecnológica — Sprint 26

> **Documento de Respaldo Scout (Fase 2d / 2e del Sprint Planning)**  
> **Tema**: Cierre determinista de sprint y hardening de gobernanza.  
> **Herramienta determinista de prospección**: `scripts/agent/scout.sh` (coste $0 de inferencia).  
> **Fecha de ejecución**: 2026-10-31

---

## Metodología y Ejecución de Búsquedas Scout

Se ejecutaron consultas deterministas sobre el ecosistema open source (GitHub, NPM Registry y Hacker News) mediante `scripts/agent/scout.sh`:
1. `changelog automation release deterministic bash` (T-146)
2. `multi-agent governance review gate approval workflow` (T-147)
3. Prospección de consistencia y linters de shell/nomenclatura (T-148)
4. `skills validator manifest fail closed bash` (T-149)
5. `git commit message fallback bash branch convention` (T-150)

---

## Descubrimientos Scout (por tarea)

### T-146: Cierre de sprint en invocación única determinista y compatible

- **Alternativa detectada:** `@semantic-release/changelog` (v7.0.0, NPM), `@semantic-release/release-notes-generator` (v14.1.1, NPM).
- **Recomendación del agente:** Desarrollo a medida justificado (modificación in-place en Bash).
- **Decisión del usuario:** Desarrollo a medida justificado — el core de Agent OS es un sistema de scripts Bash portables con cero dependencias externas de Node.js/NPM. La orquestación interna entre `close-sprint.sh` y `update-changelog.sh` debe mantenerse en Bash nativo determinista.
- **Notas de integración:** `close-sprint.sh` debe verificar deterministamente si `changelog.md` ya tiene cambios sin commitear o la cabecera correspondiente al sprint. Si no los tiene, invoca internamente `update-changelog.sh <sprint>` de forma desatendida y predecible; si ya viene preparado por el operador o satélite, respeta la entrada sin duplicar. Si `update-changelog.sh` falla, `close-sprint.sh` debe fallar de forma explícita y fail-closed sin corromper el working tree ni mover referencias.
- **Alternativas rechazadas y motivos:**
  - `@semantic-release/changelog` / `@semantic-release/release-notes-generator`: Rechazados por violar el principio de diseño fundamental de Agent OS (scripts universales y portables en Bash puro, sin runtime Node.js impuesto en host o satélites).

---

### T-147: Definición del nuevo flujo de gobernanza (diseño en planning + revisor puerta por tarea)

- **Alternativa detectada:** `eve` (v1.0.0-rc.1, NPM), `smithers-orchestrator` (v0.32.0, NPM), `@kontourai/veritas` (v1.12.1, NPM).
- **Recomendación del agente:** Desarrollo a medida justificado (formalización en Markdown y reglas nativas de Agent OS).
- **Decisión del usuario:** Desarrollo a medida justificado — Agent OS modela su gobernanza mediante flujos declarativos en `.agents/workflows/` y contratos en Markdown, no mediante frameworks propietarios externos.
- **Notas de integración:** Actualizar `.agents/workflows/session-start.md` y `.agents/workflows/sprint-planning.md` delimitando que la validación de arquitectura/diseño se aprueba por el humano en planning, y `deliberate-plan.sh` actúa como puerta técnica de tarea en Fase 3.5.
- **Alternativas rechazadas y motivos:**
  - `smithers-orchestrator` / `eve` / `@kontourai/veritas`: Rechazados por introducir dependencias de runtime JavaScript/Node en la capa de definición de gobernanza del core.

---

### T-148: Corrección de literal CHANGELOG.md a changelog.md en propuesta de audit-repo.sh y test de regresión

- **Alternativa detectada:** Sin alternativa OSS aplicable (fix literal in-place de deuda técnica interna y consistencia semántica en scripts de Agent OS).
- **Recomendación del agente:** Corrección puntual in-place en `scripts/agent/audit-repo.sh` y adición de test de regresión determinista en `tests/validate-control-plane.sh`.
- **Decisión del usuario:** Desarrollo a medida justificado — se trata de corregir una errata en una cadena literal de texto dentro de una propuesta generada por `audit-repo.sh:664` (`CHANGELOG.md` → `changelog.md`), que contradice la propia migración a minúsculas que realiza el script en sus líneas 195-201. No procede delegar ni añadir librerías externas para sustitución de un literal interno.
- **Notas de integración:**
  - Sustituir la propuesta de la línea 664 para emitir `- [ ] Actualizar changelog.md con los hitos históricos identificados en el Sprint 00`.
  - Asegurar que la lógica de migración (`CHANGELOG.md` → `changelog.md`) permanezca idéntica y no sufra regresiones.
  - Añadir verificación automatizada en la suite del control plane (`tests/validate-control-plane.sh`) que asegure que `audit-repo.sh` no propone archivos en mayúsculas contrarios a la convención.
- **Alternativas rechazadas y motivos:**
  - Herramientas o linters externos de Markdown: Innecesarios y desproporcionados para la corrección de un literal de una línea en Bash.

---

### T-149: Gate mecánico fail-closed de skills declaradas en plan contra .agents/skills/

- **Alternativa detectada:** `ajv` (v8.20.0, NPM), `@deepseek-ai/dsh-sandbox` (v0.0.1-rc.1, NPM).
- **Recomendación del agente:** Desarrollo a medida justificado (validación estática fail-closed en Bash nativo).
- **Decisión del usuario:** Desarrollo a medida justificado — la verificación de skills debe ser determinista, instantánea y con $0 tokens, sin añadir dependencias del ecosistema Node/NPM. Una comprobación directa de la existencia del directorio `.agents/skills/<skill>` y su `SKILL.md` es completamente análoga a la comprobación de la caja de archivos.
- **Notas de integración:**
  - Integrar en `scripts/agent/deliberate-plan.sh` una función de parsing de la sección de skills del plan antes de iniciar cualquier llamada de arbitraje.
  - Comprobar que cada skill declarada existe físicamente en `.agents/skills/<skill>/SKILL.md`.
  - Abortar fail-closed con mensaje descriptivo y código != 0 si alguna skill no existe.
  - Añadir aserción de regresión en `tests/validate-control-plane.sh` comprobando el rechazo de planes con skills fantasma (ej: `modern-web-guidance`).
- **Alternativas rechazadas y motivos:**
  - `ajv`: Rechazado por requerir runtime de JavaScript y esquemas JSON ajenos a la estructura Markdown/Bash de Agent OS.

---

### T-150: Fallback determinista de mensaje de commit en close-task.sh en ramas no-feat

- **Alternativa detectada:** `conventional-changelog` (v8.1.3, NPM), `@currents/commit-info` (v2.0.0, NPM), `@semantic-release/git` (v11.0.1, NPM).
- **Recomendación del agente:** Desarrollo a medida justificado (guardia de rama en Bash nativo en `close-task.sh`).
- **Decisión del usuario:** Desarrollo a medida justificado — el core actual ya gestiona el argumento `$1` para el ID de la tarea (`EXPLICIT_TASK_ID`). Esta tarea se limita a corregir la derivación del mensaje de commit cuando no se especifica `--message` y la rama activa no es una rama de feature (`tipo/T-XXX-descripcion`).
- **Notas de integración:**
  - Comprobar si `$BRANCH` cumple el formato de rama de tarea `^[a-zA-Z0-9_-]+/T-[0-9]+`.
  - Si es una rama no-feat (como `multi-agent`), emitir directamente `feat(${TASK_ID}): cierre de tarea` sin procesar el nombre de la rama.
  - Mantener intacto el soporte de `$1` (`EXPLICIT_TASK_ID`) y los mensajes explícitos `--message`.
  - Añadir aserción de regresión en `tests/validate-control-plane.sh` (Check 18) verificando el mensaje generado en ramas no-feat.
- **Alternativas rechazadas y motivos:**
  - `conventional-changelog` / `@semantic-release/git`: Rechazados por añadir dependencias externas de NodeJS innecesarias para una guarda de branch en Bash puro.
