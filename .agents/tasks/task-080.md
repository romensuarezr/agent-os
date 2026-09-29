# Task-080: Purga extendida de infraestructura personal en Workflows, Skills, Scripts y Templates

## Objetivo
Eliminar las referencias personales residuales detectadas en la auditoría post-Sprint 11 en workflows, skills, scripts, templates y en el registro declarativo de agentes, consolidando la portabilidad universal del core.

## Contexto técnico
La auditoría triaje post-Sprint 11 identificó referencias personales fuera de la caja de T-072/T-073:
- `.agents/workflows/parallel-orchestration.md` (menciones a máquinas `inteligencia-colectiva` y `oracle vnic-rsr`).
- `.agents/skills/coolify-admin/SKILL.md` (ruta `api_keys.env` y dominio personal).
- `.agents/skills/orchestrator/SKILL.md` (ruta `/home/romen/Proyectos/agent-os`).
- `.agents/skills/remote-admin/scripts/list-hosts.sh` (ruta `/home/romen/.ssh/config`).
- `scripts/agent/import-secrets.sh` (resolución de Infisical cableada a `nodes.oracle`).
- `templates/homepage/glances-compose.yml` (binding fijo y comentarios con IP/host personal).
- `templates/bytebox/docker-compose.yml` (repositorio personal en context).
- `config/agent-registry.yaml` (Decisión 1 confirmada: conversión a plantilla agnóstica con placeholders).

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/workflows/parallel-orchestration.md`
- `.agents/skills/coolify-admin/SKILL.md`
- `.agents/skills/orchestrator/SKILL.md`
- `.agents/skills/remote-admin/scripts/list-hosts.sh`
- `scripts/agent/import-secrets.sh`
- `templates/homepage/glances-compose.yml`
- `templates/bytebox/docker-compose.yml`
- `config/agent-registry.yaml`
- `.agents/tasks/task-080.md`
- `docs/sprints/sprint-12-core.md`

## Criterios de done
- [x] `parallel-orchestration.md`: hosts `inteligencia-colectiva` y `oracle` sustituidos por `<control-node>`, `<worker-node>` y referencias a `fleet.yaml`.
- [x] `coolify-admin/SKILL.md`: ruta `api_keys.env` y dominio personal sustituidos por variables de entorno `${COOLIFY_ENV_FILE}` y `${COOLIFY_BASE_URL}`.
- [x] `orchestrator/SKILL.md`: ruta `/home/romen/Proyectos/agent-os` sustituida por `<project-root>`.
- [x] `remote-admin/scripts/list-hosts.sh`: `"/home/romen/.ssh/config"` sustituido por `"$HOME/.ssh/config"`.
- [x] `import-secrets.sh`: resolución de Infisical desacoplada del host `oracle`.
- [x] `glances-compose.yml`: binding y comentarios parametrizados (`${GLANCES_BIND_IP:-127.0.0.1}`, `<worker-node>`).
- [x] `bytebox/docker-compose.yml`: context parametrizado con fallback a variable de entorno / imagen oficial.
- [x] `config/agent-registry.yaml`: convertido en plantilla agnóstica portable con placeholders.
- [x] `grep -rn "/home/romen" .agents/ templates/ scripts/ config/` → 0 ocurrencias en los ficheros modificados.
- [x] `tests/validate-control-plane.sh` pasa 12/12 sin regresiones.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-29T20:36:30+01:00 (APROBADO CON CAMBIOS)
- [x] Rama creada: feat/T-080-purga-personal
- [x] Lock activo: .agent-session.lock
- [ ] Sesión cerrada correctamente
