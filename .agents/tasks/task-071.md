# Task-071: Reparación del descubrimiento 0-contexto

## Objetivo
Que un agente arrancando con 0 contexto sepa dónde encontrar lo que necesita sin alucinar ni reinventar: inventario de skills completo y generado, 0 referencias fantasma, ruta canónica única para el inbox, y `.agents/AGENT_ONBOARDING.md` reescrito como **secuencia de boot determinista** (incluye el paso a paso de setup de herramientas) e instalado por `install.sh`.

## Contexto técnico
Auditoría 2026-09-28 — la capa de descubrimiento está rota en 5 puntos:
1. `.agents/context/skills-inventory.md` (12 líneas) lista 1 de 24 skills.
2. 6 referencias a skills inexistentes: `whatsapp-bridge`, `rag-query`, `coolify-mcp`, `a11y-debugging`, `read_url_content`, `idea-capture`; `sprint-planning` citada como skill cuando es workflow.
3. `external-inbox/` con 3 rutas distintas: `sprint-planning.md` dice raíz, `external-inbox.md`/AGENTS.md dicen `docs/external-inbox/`, `check-inbox.sh` busca en otro sitio. Flujo roto en instalaciones frescas.
4. `.agents/AGENT_ONBOARDING.md` es exigido por 4 skills pero `install.sh` nunca lo instala; además el template actual (`.agents/templates/AGENT_ONBOARDING.md`) describe el stack de un proyecto hijo, no la secuencia de arranque del core.
5. El árbol de `AGENTS.md` no coincide con el código real (dice `.agents/templates/` para plantillas que viven en `templates/` raíz; omite scripts que existen).

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/AGENT_ONBOARDING.md` (nuevo — secuencia de boot del core)
- `.agents/templates/AGENT_ONBOARDING.project.md` (renombrado del actual; template por proyecto hijo)
- `.agents/context/skills-inventory.md`
- `AGENTS.md` (árbol fiel al código)
- `.agents/workflows/sprint-planning.md` (ruta canónica del inbox)
- `.agents/skills/external-inbox.md`
- `.agents/skills/agent-os-scripts/SKILL.md`
- `.agents/skills/repo-onboarding/SKILL.md`
- `scripts/agent/check-inbox.sh`
- `scripts/agent/install.sh` (instalar el onboarding — coordinar con T-069)

## Criterios de done
- [x] `skills-inventory.md` lista las 24 skills con una línea de "cuándo usarla" cada una; hay un procedimiento documentado (script o checklist) para regenerarlo al añadir skills.
- [x] `grep -r` de los 6 nombres fantasma devuelve 0 resultados fuera de este task file.
- [x] Ruta canónica única: `docs/external-inbox/` en `sprint-planning.md`, `external-inbox.md`, `agent-os-scripts/SKILL.md`, `repo-onboarding/SKILL.md`, `check-inbox.sh` y AGENTS.md. `install.sh` crea la carpeta.
- [x] `.agents/AGENT_ONBOARDING.md` contiene la secuencia de boot numerada: 1) leer `AGENTS.md`, 2) ejecutar `check-session.sh`, 3) descubrir skills vía `skills-inventory.md`, 4) pre-flights de herramientas paso a paso con comandos exactos (`gh auth status`, `infisical` login, `tailscale status`, `docker info`) y qué hacer si cada uno falla, 5) mapa "dónde está cada cosa" (reglas / skills / workflows / scripts / inbox). Sin comandos que se pudran: referencia scripts, no pega instrucciones efímeras.
- [x] `AGENTS.md`: el árbol de "Estructura del repositorio" coincide con `ls` real; las rutas de inbox son la canónica.
- [x] Test ciego: un agente sin contexto previo localiza una skill, el inbox, un workflow y un script siguiendo solo el onboarding (registrar el resultado en el PR).

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-28T10:07:59+01:00 (APROBADO CON CAMBIOS)
- [x] Rama creada: feat/T-071-zero-context-discovery
- [x] Lock activo: .agent-session.lock
- [ ] Sesión cerrada correctamente

