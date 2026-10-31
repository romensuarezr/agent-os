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
