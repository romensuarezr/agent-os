# Task-077: tool-inventory y repo-onboarding detectan el stack y la realidad

## Objetivo
El inventario de herramientas reconoce CI/CD, IaC, CLIs cloud y el stack del repo; ninguna skill promete detecciones que no implementa.

## Contexto técnico
Auditoría 2026-09-28: `tool-inventory` descubre bien el plano local Linux (SO, gestores de paquetes, CLIs, Tailscale) pero es ciego a CI/CD, IaC y CLIs cloud; promete Firefox en la documentación y no lo implementa; MCPs y servicios cloud son solo config manual sin decirlo. `repo-onboarding`/`audit-repo.sh` auditan el andamiaje de gestión pero no informan del stack del proyecto. Depende de T-074 para la detección de stack.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/discover-fleet.sh`
- `scripts/agent/audit-repo.sh`
- `.agents/skills/tool-inventory/SKILL.md` (y sus scripts, si los tiene)
- `.agents/skills/repo-onboarding/SKILL.md`
- `.agents/tasks/task-077.md`
- `docs/sprints/sprint-11-core.md`

## Criterios de done
- [x] Detecta: `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, `terraform/`/`*.tf`, `docker-compose*.yml`, CLIs `aws`/`gcloud`/`az`, y gestores de paquetes del stack.
- [x] Firefox: implementado o promesa eliminada de la documentación (sin estados intermedios).
- [x] MCPs y servicios cloud documentados honestamente como configuración manual (`fleet.yaml`), no como detección.
- [x] `repo-onboarding`/`audit-repo.sh` informan el stack vía `detect-stack.sh` (T-074), incluyendo el caso `unknown`.
- [x] Verificado sin falsos positivos en 3 repos de prueba (Node, Python, Go): el digest refleja la realidad.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-29T14:25:50+01:00 (APROBADO CON CAMBIOS)
- [x] Rama creada: feat/T-077-tool-inventory-repo-onboarding
- [x] Lock activo: .agent-session.lock
- [ ] Sesión cerrada correctamente
