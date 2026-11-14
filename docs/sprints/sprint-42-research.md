# Research Sprint 42 — Hermes VPS Autonomía, Sincronización Proactiva del Core y Contratos Operativos

> **Fecha**: 2026-11-14  
> **Objetivo**: Investigación técnica determinista de la documentación oficial y código fuente de Hermes Agent (Nous Research), validación empírica en el VPS (`<nodo-inferencia>`) y prospección OSS ($0 tokens de inferencia) para evitar reinventar la rueda en la auto-sincronización del Core, gestión de skills, cronjobs `no_agent` y contratos `AGENTS.md`.

---

## 1. Hallazgos Clave de la Documentación Oficial y Código Fuente de Hermes

### 1.1. Gestión de Skills y Enlaces Simbólicos
- **Ubicación Canónica**: `~/.hermes/skills/` es el directorio raíz de habilidades de Hermes.
- **Soporte de Symlinks**: Hermes soporta symlinks de primer nivel y directorios de habilidades (`hermes-agent/tools/skills_tool.py`). Los symlinks existentes en `~/.hermes/skills/agent-os/*` apuntan a `/home/ubuntu/projects/agent-os/.agents/skills/*`.
- **Propagación en Caliente**: Las modificaciones en archivos existentes dentro de una habilidad (código Python, bash o `SKILL.md`) son leídas en caliente por Hermes en el siguiente turno de ejecución sin necesidad de reiniciar el servicio.
- **Comando `/reload-skills`**: Descubierto en `tests/gateway/test_reload_skills_command.py`: Hermes cuenta con el comando de barra `/reload-skills` (y alias `/reload_skills`) en el gateway de WhatsApp/Telegram y TUI. Invoca `agent.skill_commands.reload_skills`, refresca la lista de herramientas, reconstruye el índice de slash commands y emite un diff legible sin romper el transcript de la sesión.

### 1.2. Automatizaciones y Tareas Programadas (Cronjobs `no_agent: true`)
- **Modo Script-Only (Coste Cero)**: La documentación oficial (`docs/guides/cron-script-only.md`) estipula que para tareas deterministas (como sincronizar un repositorio git, verificar salud de servicios o rotar logs), no se debe involucrar al LLM.
- **Configuración `no_agent: true`**: En `~/.hermes/cron/jobs.json`, los trabajos configurados con `no_agent: true` ejecutan scripts en `/home/ubuntu/` y entregan su salida `stdout` directamente a la plataforma configurada (ej. `deliver: "whatsapp:<USER_PHONE>@lid"`).
- **Operación sin Gateway**: Para plataformas basadas en tokens de bot o webhooks (WhatsApp/Telegram), el despachador de cron puede entregar alertas directamente usando las credenciales en `~/.hermes/.env` sin depender del estado del bucle del agente.

### 1.3. Diferenciación Arquitectónica: `SOUL.md` vs. `AGENTS.md`
- **`SOUL.md` (Slot #1 del System Prompt)**:
  - Reside exclusivamente en `~/.hermes/SOUL.md`.
  - Define la personalidad inmutable, el tono y estilo (directo, conciso, estilo caveman, sin relleno ni politeness theater, anti-sycophancy).
  - La documentación de Nous Research advierte explícitamente: *"Move project instructions into AGENTS.md and keep SOUL.md focused on identity and style"*.
- **`AGENTS.md` (Contexto Operativo del Directorio de Trabajo)**:
  - Se resuelve dinámicamente según el `TERMINAL_CWD` o directorio de trabajo de la sesión (`/home/ubuntu`).
  - Es el lugar estándar para definir las instrucciones de operación, mapa de herramientas, roles de conserje y protocolos de delegación al Coordinador Antigravity.

---

## 2. Decisiones de Arquitectura Selladas

1. **Sincronizador Determinista de Core (`sync_agent_os_core.sh`)**:
   - Crear un script bash determinista en `/home/ubuntu/scripts/sync_agent_os_core.sh`.
   - Realiza `git fetch` y `git pull --ff-only origin multi-agent` en `/home/ubuntu/projects/agent-os`.
   - Escanea `/home/ubuntu/projects/agent-os/.agents/skills/` y crea de forma idempotente symlinks en `~/.hermes/skills/agent-os/` para cualquier skill nueva que no exista (ej. `orca-cli`).
   - Aplica `chmod +x` a scripts en `scripts/agent/*.sh` y `scripts/ops/*.sh`.
   - Si detecta actualización de versión, escribe una marca en `~/.hermes/runtime/last_core_update.json`.
2. **Cronjob `no_agent` Integrado en Hermes**:
   - Registrar en `~/.hermes/cron/jobs.json` una tarea programada `Agent OS Core Sync` con `no_agent: true` programada para ejecutarse a las `06:00 AM` (o cada 12 horas).
   - El script `fleet_morning_briefing.py` (que corre a las 08:30 AM) leerá `last_core_update.json` y reportará la actualización en el briefing matutino de WhatsApp.
3. **Contrato `AGENTS.md` para el Conserje en `/home/ubuntu/AGENTS.md`**:
   - Desplegar en el home de Hermes un archivo `AGENTS.md` que estructure las responsabilidades:
     - Rol: Conserje de la Flota (Hermes Concierge).
     - Delegación de código y desarrollo: Coordinador Antigravity VPS vía `hermes-concierge` (`concierge_bridge.py` con failover Google Pro `agy`/`agy2`).
     - Gestión de infraestructura y contenedores: `remote-admin` / `coolify-admin` / scripts ops.
     - Operaciones deterministas: Coste $0 tokens mediante utilidades locales.
4. **Hardening de `hermes-concierge` con Recarga en Caliente**:
   - Añadir soporte para invocar `/reload-skills` o refrescar las skills tras una sincronización de Core.

---

## 3. Descubrimientos Scout (por tarea)

### T-224: Script Determinista de Sincronización del Core y Regeneración Atómica de Symlinks
- **Búsqueda**: `git sync cron` / `git-syncer` / `github-sync`.
- **Hallazgo OSS**: Proyectos como `git-syncer` (MIT) o `github-sync` utilizan wrappers bash simples con `git pull --ff-only` y hooks de post-merge.
- **Veredicto**: *Desarrollo a medida justificado*. Un script bash determinista y ligero (~40 líneas) sin dependencias externas es 100% portable y seguro para el host Ubuntu.

### T-225: Cronjob Headless `no_agent: true` en Hermes y Notificación Matutina
- **Búsqueda**: `nousresearch hermes-agent cron headless script no_agent`.
- **Hallazgo OSS**: Documentación canónica de Hermes Agent (`docs/guides/cron-script-only.md`). La propiedad `"no_agent": true` y `"script": "..."` en `jobs.json` evita llamadas al LLM y despacha `stdout` a WhatsApp.
- **Veredicto**: *Adopción nativa*. Usar la especificación nativa de Hermes `jobs.json` respetando el formato validado en T-217.

### T-226: Despliegue de `AGENTS.md` de Conserje en `/home/ubuntu`
- **Búsqueda**: `nousresearch hermes-agent SOUL.md AGENTS.md personality system prompt`.
- **Hallazgo OSS**: El equipo de Nous Research recomienda formalmente separar personalidad (`SOUL.md` global) de directivas operativas (`AGENTS.md` por directorio de trabajo).
- **Veredicto**: *Adopción estándar*. Crear `/home/ubuntu/AGENTS.md` alineado con la topología de la flota y el conserje.

### T-227: Documentación Operativa y Comando `/reload-skills` en Runbook
- **Búsqueda**: `nousresearch hermes-agent custom skills symlink reload`.
- **Hallazgo OSS**: `/reload-skills` refresca el índice de comandos del gateway en caliente (`test_reload_skills_command.py`).
- **Veredicto**: *Documentación e integración en runbook*. Incorporar el procedimiento en `docs/runbooks/hermes-vps-runbook.md`.
