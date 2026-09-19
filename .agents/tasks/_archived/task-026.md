# Task-026: Universalizar y promover la skill remote-admin al core

## Objetivo
Promover y universalizar la habilidad `remote-admin` al core de `agent-os` para permitir diagnósticos, gestión de contenedores Docker e inspección remota segura contra cualquier host/alias SSH configurado (`datamanager`, `oracle`, etc.), distribuyéndola a los proyectos hijos.

## Contexto técnico
- Identificada previamente en proyectos hijos (`polymarket`, `Agencia_IA`), donde estaba acoplada al host de Oracle.
- En el core debe ser agnóstica de stack y servidor, delegando la resolución de red/credenciales a `~/.ssh/config` o parámetros explícitos.
- Debe incluirse en `scripts/agent/assets-manifest.txt` bajo `[active]` para sincronización automática con `sync.sh`.
- Integrar directrices de seguridad (modo sólo lectura preferente, confirmación para acciones destructivas).

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/skills/remote-admin/SKILL.md`
- `.agents/context/skills-inventory.md`
- `scripts/agent/assets-manifest.txt`
- `docs/sprints/sprint-04-core.md`

## Criterios de done
- [x] `.agents/skills/remote-admin/SKILL.md` implementado con soporte multi-host SSH, ejemplos para `datamanager` y `oracle`, y directrices de seguridad.
- [x] Registrada en `.agents/context/skills-inventory.md` siguiendo el estándar de `creador-habilidades`.
- [x] Registrada en `scripts/agent/assets-manifest.txt` bajo la sección `[active]`.
- [x] Validada la ejecución remota de diagnóstico sobre el alias `datamanager`.
- [x] Tarea T-026 marcada en `docs/sprints/sprint-04-core.md`.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-19T14:29:05+01:00
- [x] Rama creada: feat/T-026-remote-admin-universal
- [x] Lock activo: 2026-09-19T14:29:25+01:00
- [x] Sesión cerrada correctamente
