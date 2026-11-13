# Task-212: Desacoplamiento de Build en Worktrees (Fast Verification vs Full Static Merge)

## Objetivo
Optimizar la estrategia de verificación de metas en worktrees efímeros mediante `scripts/agent/verify-goal.sh` y las directivas del perfil `.agents/profiles/coder.md` y `.agents/skills/orchestrator/SKILL.md`. En el entorno aislado del worker, `verify-goal.sh` prioriza la verificación estricta pero rápida (comprobación de tipos `tsc --noEmit`, linters y tests unitarios / integración rápidos), desacoplando la prerenderización estática masiva (`next build` de decenas de páginas estáticas), la cual se delega a la compuerta final del Coordinador previa a la consolidación en `main`.

## Contexto técnico
- Ejecutar `next build` en 3 worktrees concurrentes en el mismo disco compite salvajemente por CPU y memoria, tardando hasta 15-20 minutos por agente para prerenderizar 34 páginas idénticas.
- La verificación de tipos (`tsc --noEmit`) y tests unitarios garantizan el 99% de la corrección sintáctica y funcional en apenas 10-15 segundos.
- La compilación exhaustiva de producción solo necesita ejecutarse una vez en el árbol principal antes del merge o deploy, reduciendo el tiempo total de los lotes paralelos en más de un 60%.

### Research integrado (`docs/sprints/sprint-39-research.md` → `### T-212`)
- **Scout OSS**: Patrones de CI/CD para monorrepos y ramas efímeras.
- **Veredicto**: `Desarrollo a medida justificado` desacoplando la suite de compuerta entre worker y orquestador.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 39 / 2026-11-13
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - Modificar `verify-goal.sh` para soportar flag `--fast` (o auto-detección de perfil worker), permitiendo ejecutar comprobación de tipos y tests sin forzar la compilación estática global pesada.
  - Actualizar directivas en `coder.md` instruyendo el uso de comandos rápidos de verificación en worktree.
  - Actualizar `orchestrator/SKILL.md` documentando que la validación exhaustiva de build de producción recae en la compuerta `/merge` y `/promote` del Coordinador.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/verify-goal.sh`
- `.agents/profiles/coder.md`
- `.agents/skills/orchestrator/SKILL.md`
- `docs/sprints/sprint-39.md`
- `.agents/tasks/task-212.md`

## Criterios de done
- [ ] `verify-goal.sh` actualizado con soporte de verificación rápida para workers efímeros.
- [ ] Perfil `coder.md` actualizado con directiva de verificación ágil.
- [ ] Desacoplamiento documentado en `orchestrator/SKILL.md`.
- [ ] Suite `tests/validate-control-plane.sh` pasando limpia sin regresiones (38/38 checks verdes).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] Rama de trabajo creada
- [ ] Verificación con verify-goal.sh
- [ ] Cierre y merge formalizado
