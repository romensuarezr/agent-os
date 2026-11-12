# Task-201: Plantilla AGENTS.md para satélites y regla de boot proactivo del Coordinador

## Objetivo
Implementar el descubrimiento proactivo de Agent OS en repositorios satélite creando la plantilla canónica `templates/root/AGENTS.md` (distribuida vía `install.sh` y `sync.sh`) y la regla global `.agents/rules/global/coordinator-boot.md`, de modo que cuando un agente nuevo (Antigravity, Cursor, etc.) inicie sesión en cualquier proyecto satélite, se presente automáticamente como Coordinador, diagnostique el estado del sprint a coste $0 tokens y ofrezca el menú interactivo de opciones.

## Contexto técnico
- Actualmente, `install.sh` no crea un `AGENTS.md` en la raíz de los satélites. Antigravity o nuevos agentes abren una sesión en blanco y no reconocen el entorno como gestionado por Agent OS.
- Los modelos LLM son reactivos por defecto; sin una regla de bienvenida proactiva, esperan a que el usuario recuerde comandos internos (`/session-start`, `worktree-dispatch.sh`, etc.).
- La infraestructura de diagnóstico a coste $0 ya existe: `scripts/agent/check-session.sh` y `scripts/agent/check-sprint.sh`.

### Research integrado (`docs/sprints/sprint-37-research.md` → `### T-201`)
- **Scout OSS**: Sin alternativas aplicables a nivel de protocolo de arranque en repositorios satélite; Antigravity inyecta jerárquicamente `AGENTS.md` y `.agents/rules/*.md`.
- **Veredicto**: `Desarrollo a medida justificado`.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 37 / 2026-11-12
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - Crear `templates/root/AGENTS.md`: guía agnóstica para proyectos satélite que declara el rol de Coordinador en la terminal principal y enlaza la arquitectura de Agent OS.
  - Modificar `scripts/agent/install.sh` y `scripts/agent/sync.sh` para copiar/sincronizar `AGENTS.md` a la raíz de los proyectos satélite si no existe o si se sincroniza.
  - Crear regla global `.agents/rules/global/coordinator-boot.md`: instruye al agente a ejecutar deterministamente en el turno inicial `check-session.sh` y `check-sprint.sh`, saludar como Coordinador, reportar el estado del sprint y listar las opciones de acción.
  - Sincronización transparente sin alterar personalizaciones locales ni credenciales.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `templates/root/AGENTS.md` (nuevo)
- `.agents/rules/global/coordinator-boot.md` (nuevo)
- `scripts/agent/install.sh`
- `scripts/agent/sync.sh`
- `scripts/agent/assets-manifest.txt`
- `.agents/tasks/task-201.md`

## Criterios de done
- [ ] Plantilla `templates/root/AGENTS.md` creada con instrucciones claras para agentes y desarrolladores.
- [ ] Regla `.agents/rules/global/coordinator-boot.md` creada con trigger de arranque y plantilla de bienvenida estructurada.
- [ ] `install.sh` y `sync.sh` actualizados para distribuir `AGENTS.md` a la raíz de los satélites.
- [ ] `assets-manifest.txt` actualizado con los nuevos activos gestionados.
- [ ] Suite `tests/validate-control-plane.sh` pasando limpia sin regresiones (38/38 checks verdes).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] Rama de trabajo creada
- [ ] Verificación con verify-goal.sh
- [ ] Cierre y merge formalizado
