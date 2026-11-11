# Task-196: Jerarquía de conocimiento y comunicación natural

## Objetivo
Crear dos reglas globales agnósticas que separen canónicamente las directrices inmutables del operador humano de los resúmenes sintéticos de máquina, e imponer un estilo de prosa denso y técnico libre de relleno (anti-AI-slop).

## Contexto técnico
- Los agentes consumen digests de diseño generados por IA (`docs/sprints/design-decisions/`) y pueden asumirlos como restricciones humanas, derivando en sesgo acumulativo.
- La prosa corporativa inflada (*AI slop*) incrementa el consumo de tokens y reduce la precisión operativa.
- Las reglas del core residen en `.agents/rules/global/` como ficheros `.md` independientes, cargados por convención (sin manifiesto central), sin frontmatter obligatorio ni dependencias de stack.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 36 / 2026-11-11
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - Dos ficheros nuevos, responsabilidad única cada uno: `.agents/rules/global/knowledge-hierarchy.md` (jerarquía de procedencia: directrices humanas > reglas del core > digests/digests sintéticos de máquina, con marca explícita de procedencia sintética) y `.agents/rules/global/anti-ai-slop.md` (lenguaje denso, conciso, técnico; proyección de relleno corporativo).
  - Sin dependencias externas, sin scripts nuevos, agnóstico de stack y con cero literales de infraestructura (política `docs/critical-flows.md`).
  - No modifican reglas existentes; se limitan a declarar jerarquía y estilo, sin alterar el comportamiento de otros workflows.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/rules/global/knowledge-hierarchy.md` (nuevo)
- `.agents/rules/global/anti-ai-slop.md` (nuevo)

## Criterios de done
- [ ] Ambos ficheros creados con la convención de formato de `.agents/rules/global/` (título + contenido denso, sin relleno).
- [ ] `knowledge-hierarchy.md` define la jerarquía de procedencia con ejemplos de aplicación a digests de diseño.
- [ ] `anti-ai-slop.md` impone lenguaje denso/conciso/técnico con ejemplos de transformación.
- [ ] Cero literales de hostnames/infraestructura; cero dependencias de stack.
- [ ] Suite `tests/validate-control-plane.sh` en verde sin regresiones.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `[CONSENSO | REVISADO_CON_CAMBIOS | ESCALADO_A_HUMANO | SIN_REVISOR]`
  - **Rol del revisor**: Compuerta técnica determinista (caja de archivos, tests, realidad repo, fidelidad a diseño macro).
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
