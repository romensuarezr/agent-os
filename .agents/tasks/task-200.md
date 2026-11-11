# Task-200: Skill `idea-validator` con veredicto numérico de viabilidad

## Objetivo
Crear la skill `idea-validator`, filtro de viabilidad objetiva para las ideas de `docs/idea-inbox/` que emita un veredicto numérico 1–10 basado en prospección determinista, neutralizando el sesgo de complacencia (*sycophancy*) antes de abrir un sprint.

## Contexto técnico
- Hoy las ideas entran al planning sin contraste objetivo de demanda, competencia ni alternativas OSS.
- Infraestructura de prospección $0 ya disponible: `scripts/agent/lib/searxng-client.sh` (SearXNG soberano, activo HTTP 200) y `scripts/agent/scout.sh` (GitHub/npm/PyPI).
- No existe `.agents/skills/idea-validator/` (verificado: cero implementación en inventory-check y changelog).
- El veredicto es insumo advisory; la decisión soberana sigue siendo el veredicto del operador en el Paso 7 del planning.

### Research integrado (`## Descubrimientos Scout` → `### T-200` + consultas SearXNG)
- **Scout OSS**: `idea validation viability scoring bias detection skill` → sin repos relevantes; único matiz `@skill-harness/core` (LLM-judge con API de terceros — no adoptable bajo soberanía $0) → `Desarrollo a medida justificado`.
- **SearXNG (T-200)**: metodologías de validación objetiva confirmadas — recogida de evidencia (no opiniones), criterios puntuables de demanda/competencia/alternativas, marcos multi-criterio (desirability/feasibility/viability) usados como guía de criterios, no como dependencia.
- **Constraint clave**: prospección solo con `searxng-client.sh` + `scout.sh` ($0); cero APIs comerciales; veredicto advisory de 4 criterios puntuados 1–10.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 36 / 2026-11-11
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - `.agents/skills/idea-validator/SKILL.md` con criterios fijos de puntuación (demanda, competencia/alternativas, alineación con el hito actual, esfuerzo estimado), cada uno 1–10 → veredicto compuesto 1–10 con justificación en una línea por criterio.
  - Prospección SOLO vía `searxng-client.sh` y `scout.sh` (coste $0, soberanía de datos); cero APIs comerciales, cero scraping de terceros.
  - Salida en Markdown insertable en el informe del Paso 7, con secciones `## Hallazgos`, `## Veredicto` y `## Recomendación` (sprint / backlog / descartar).
  - No sustituye al humano: la skill emite el número; el operador decide en la ventana de aprobación.
  - Registro obligatorio en `.agents/context/skills-inventory.md`.
  - Scout-First: sin alternativa OSS madura adoptable → desarrollo a medida justificado (registrado en research).
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/skills/idea-validator/SKILL.md` (nuevo)
- `.agents/context/skills-inventory.md` (registro de la skill)

## Criterios de done
- [ ] Skill `idea-validator/SKILL.md` creada con criterios de puntuación, fuentes deterministas y formato de salida.
- [ ] Skill registrada en `.agents/context/skills-inventory.md`.
- [ ] Cero dependencias nuevas; cero llamadas a APIs comerciales.
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
