# Task-121: Generador de registro histórico de diseño (`design-digest.sh`)

## Objetivo
Implementar `scripts/agent/design-digest.sh` e integrarlo en el flujo de cierre de tarea `scripts/agent/close-task.sh`, generando automáticamente un artefacto de decisiones de diseño en `docs/sprints/design-decisions/T-XXX-digest.md` cuya salida sea canalizada de forma obligatoria por `scripts/agent/lib/redact.sh` (T-118) para garantizar 0 fugas de secretos y preservar el contexto arquitectónico sin sorpresas en sprints futuros.

## Contexto técnico
Uno de los dolores centrales expresados por el operador es encontrarse dos sprints después con código que no recuerda por qué se hizo así o que diverge de los objetivos iniciales. `design-digest.sh`:
1. Lee los artefactos de la sesión en `.agents/context/` (`plan-draft.md`, `plan-deliberation.json`) y el diff de cambios de la tarea.
2. Extrae:
   - Objetivo de la tarea.
   - Decisiones y correcciones acordadas en la deliberación (Coder vs Revisor).
   - Patrones de diseño y principios aplicados (ej. POSIX, determinismo, fallback fail-safe).
   - Ficheros tocados y dependencias nuevas introducidas.
   - Skills declaradas y aplicadas.
3. Canaliza todo el contenido generado a través de `scripts/agent/lib/redact.sh` antes de persistir en disco.
4. Escribe el resultado en `docs/sprints/design-decisions/T-XXX-digest.md`.
5. Se integra en `scripts/agent/close-task.sh` para que se invoque de forma automática durante el cierre de la tarea, asegurando que el commit de cierre incluya el digest en el mismo commit atómico.

## Skills relevantes
- `doc-maintainer`: Estándares de documentación, análisis de ubicación y consistencia de histórico.
- `infisical-secrets`: Redacción obligatoria con `lib/redact.sh` sobre artefactos generados.
- `agent-os-scripts`: Convención CLI estándar (`lib/cli-help.sh`, `--help`, POSIX awk/sed).

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/design-digest.sh` (nuevo)
- `scripts/agent/close-task.sh`
- `.agents/tasks/task-121.md`

## Criterios de done
- [ ] `scripts/agent/design-digest.sh` ejecutable con `--help`, `--task-id <id>`, `--output <path>` y soporte `--json`.
- [ ] El script lee `.agents/context/plan-deliberation.json` si existe, o degrada elegantemente extrayendo la información del task file archivado y `git log`/`git diff`.
- [ ] Todo el contenido pasa obligatoriamente por `scripts/agent/lib/redact.sh` antes de guardarse en `docs/sprints/design-decisions/`.
- [ ] `scripts/agent/close-task.sh` invoca `design-digest.sh` antes del commit de cierre e incluye el digest en el commit atómico.
- [ ] Verificación de 0 secretos o credenciales en los archivos de digest generados.
- [ ] Suite `validate-control-plane.sh` ejecutada pasando 33/33 checks sin regresiones.
