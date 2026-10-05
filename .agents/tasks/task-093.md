# Task-093: Port de patrones estáticos de SkillSpector adaptado a .agents/skills/

## Objetivo
Implementar un escáner estático determinista (`scripts/agent/inspect-skills.sh`) y su habilidad complementaria (`.agents/skills/skill-inspector/`), portando y adaptando las familias de reglas estáticas de alta señal de NVIDIA SkillSpector (Stage 1) para auditoría de seguridad y confianza en las skills del catálogo de Agent OS. El escáner debe operar 100% offline, con cero consumo de tokens (sin LLM) y sin dependencias pesadas de runtime (prohibido Python 3.12+), con un sistema de puntuación 0–100, soporte de baseline de supresión de falsos positivos/ruido histórico, un gate de severidad explícito por defecto (bloqueante para CRITICAL/HIGH no suprimidos, no bloqueante para LOW/MED) y validación de frontmatter como higiene de catálogo separada.

## Contexto técnico
- **Sprint**: Sprint 14 ("Automejora y Confianza").
- **Research integrado (`docs/sprints/sprint-14-core-research.md`)**:
  - *NVIDIA SkillSpector Stage 1 (Estático determinista)*: Reglas de detección rápida orientadas a skills compuestas por Markdown (`SKILL.md`) y scripts ejecutables (Bash/Python).
  - *Evidencia empírica (Liu et al., 2026)*: Skills con ejecutables presentan 2.12x más probabilidad de vulnerabilidades.
  - *4 Familias de Patrones Estáticos de Alta Señal*:
    1. **Prompt Injection / System Prompt Override**: Delimitadores falsos, directivas para ignorar instrucciones de seguridad previas, evasión de restricciones ("ignore previous instructions", "system override", "you are now in developer mode"). Severidad: HIGH / CRITICAL.
    2. **Data Exfiltration**: Envíos no autorizados a endpoints arbitrarios (`curl`/`wget` con payloads de variables de entorno o tokens, webhooks sospechosos, dumping de memoria o credenciales hacia el exterior). Severidad: HIGH / CRITICAL.
    3. **Dangerous Code / Subprocess Abuse**: Ejecución arbitraria insegura (`eval`, `exec` ciegos, `rm -rf /`, piping desde la red `curl | sh`, llamadas a shells sin desinfección, bypass de permisos). Severidad: HIGH / CRITICAL.
    4. **MCP Tool Poisoning / Privilege Abuse**: Manipulación de parámetros de herramientas MCP, spoofing de identidades de tools o elusión de confirmaciones de usuario. Severidad: HIGH / CRITICAL.
  - *Higiene y Metadatos de Catálogo (separada de las 4 familias)*:
    - Validación de frontmatter YAML en `SKILL.md` (campos requeridos: `name`, `description`). Severidad: LOW (no bloqueante).
  - *Scoring 0–100 y Gate de Severidad*:
    - Puntuación base 100 (catálogo/skill impecable). Deducciones: CRITICAL (-40), HIGH (-20), MED (-10), LOW (-5). Puntuación mínima acotada en 0.
    - Gate por defecto: Exit code 1 si existe ≥1 hallazgo CRITICAL o HIGH no suprimido. Hallazgos LOW o MED nunca bloquean por defecto (exit code 0).
    - Códigos de salida estándar:
      - `0`: Limpio o solo hallazgos LOW/MED (o hallazgos HIGH/CRITICAL debidamente suprimidos en el baseline).
      - `1`: Gate bloqueante disparado (al menos un hallazgo CRITICAL o HIGH activo y no suprimido).
      - `2`: Error de sintaxis de argumentos o directorio de skills inválido/inexistente.
  - *Baseline de Supresión*:
    - Archivo JSON (`.agents/skills/skill-inspector/baseline.json`) para registrar hallazgos conocidos, justificados o revisados.
    - Los hallazgos incluidos en el baseline se marcan como `SUPPRESSED`: no penalizan la puntuación ni activan el gate bloqueante.
    - Esto permite escaneos en CI / pre-commit donde solo se alertan y bloquean regresiones o nuevos riesgos no triados.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `scripts/agent/inspect-skills.sh` (nuevo)
- `.agents/skills/skill-inspector/SKILL.md` (nuevo)
- `.agents/skills/skill-inspector/baseline.json` (nuevo)
- `.agents/config/skills-manifest.yaml`
- `scripts/agent/assets-manifest.txt`
- `docs/sprints/sprint-14-core.md`
- `.agents/tasks/task-093.md` (nuevo)

## Criterios de done
- [x] `scripts/agent/inspect-skills.sh` implementado en Bash puro POSIX compatible, determinista, offline y sin dependencias externas pesadas ni llamadas LLM (0 tokens).
- [x] Soporte de CLI en `inspect-skills.sh`: `--path <dir>`, `--baseline <file>`, `--json`, `--human`, `--help`.
- [x] Analizadores estáticos implementados cubriendo las 4 familias prioritarias de patrones (Prompt Injection, Data Exfiltration, Dangerous Code, MCP Tool Poisoning) y la categoría de higiene de frontmatter.
- [x] Gate de severidad explícito: exit 1 ante CRITICAL o HIGH no suprimido; exit 0 si solo hay LOW/MED o todo está suprimido.
- [x] Algoritmo de scoring 0–100 determinista implementado.
- [x] Mecanismo de supresión por baseline funcional y probado.
- [x] Habilidad `.agents/skills/skill-inspector/SKILL.md` redactada documentando parámetros, familias de patrones, scoring, gate de severidad, códigos de salida y gestión del baseline.
- [x] Archivo inicial `.agents/skills/skill-inspector/baseline.json` creado y validado para el catálogo actual de Agent OS.
- [x] Registro en manifiestos: `inspect-skills.sh` en `scripts/agent/assets-manifest.txt` y `skill-inspector` en `.agents/config/skills-manifest.yaml`.
- [x] Verificación empírica completa (3 casos reproducibles):
  - [x] Caso A: Escaneo de `.agents/skills/` con baseline (pasa con exit 0 y 0 hallazgos CRITICAL/HIGH no suprimidos).
  - [x] Caso B: Escaneo de skill sintética vulnerable/maliciosa (falla con exit 1, detecta patrones y reduce score).
  - [x] Caso C: Supresión efectiva (añadir hallazgo sintético a baseline y verificar que pasa con exit 0).
- [x] `tests/validate-control-plane.sh` ejecutado con éxito (12/12 ✅).
- [x] Working tree limpio tras la ejecución.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO CON CAMBIOS recibido — fecha/hora: 2026-09-30 12:17:27+01:00
- [x] Rama creada: feat/T-093-skill-inspector-static-port
- [x] Lock activo: 2026-09-30T12:18:20+01:00
- [x] Sesión cerrada correctamente
