---
trigger: pre-flight
---

# Rule: Deterministic Execution & Zero-Improvisation Governance

> Prohibición estricta de improvisar: las decisiones operativas, diagnósticos y herramientas se basan en comprobaciones deterministas a 0 tokens de inferencia, no en asunciones ni código efímero ad-hoc.

---

## 🛡️ Los Tres Principios de Ejecución Determinista

### 1. Prohibición de Código Ad-Hoc y Scripts Huérfanos
- **Queda terminantemente prohibido** crear scripts de prueba o automatizaciones temporales en la raíz o en carpetas de código sin trazabilidad ni versionado.
- Si una operación requiere automatización repetible, debe formalizarse como un script probado en `scripts/` o una skill en `.agents/skills/`.
- No improvises comandos bash opacos o pipelines encadenados no reproducibles cuando exista una herramienta canónica del proyecto.

### 2. Prohibición de Asunción de Servicios sin Comprobación Determinista
- **Nunca asumas** que un servicio, endpoint (Ollama, FreeLLMAPI, Coolify, PostgreSQL), host o CLI de flota está disponible basándote en memoria de contexto o suposiciones.
- **Herramienta canónica de comprobación**: utiliza siempre `bash scripts/agent/fleet-doctor.sh` (con flag opcional `--json` para orquestadores) para auditar la salud de la flota local o remota.
- El diagnóstico determinista devuelve un digest conciso (≤ 20 líneas). El agente debe razonar **exclusivamente sobre el digest devuelto** a 0 coste de tokens de inferencia sobre el estado real, sin inventar ni simular conectividad.

### 3. Pre-Flights Declarativos Obligatorios
- Todo script operativo o de control en `scripts/agent/` u `scripts/ops/` debe incluir comprobaciones pre-flight declarativas al inicio siguiendo el estándar de `scout.sh`:
  ```bash
  for cmd in git jq curl; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "❌ ERROR: Dependencia requerida no encontrada: $cmd" >&2
      echo "Guía: Instala $cmd en tu sistema antes de continuar." >&2
      exit 1
    fi
  done
  ```
- Si una pre-condición falla, la ejecución se aborta de inmediato con una guía clara y accionable.

---

## 🔗 Referencias Cruzadas Canónicas
- Para selección jerárquica de herramientas y scouting, ver `tool-decision-flow.md`.
- Para límites de seguridad y ejecución de comandos destructivos, ver `agent-permissions.md` y `no-destructive-without-audit.md`.
