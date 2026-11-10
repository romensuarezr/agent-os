# Task-174: Skill canónica tooling-advisor para prospección pasiva de flota

## Objetivo
Implementar la habilidad canónica `.agents/skills/tooling-advisor/SKILL.md` para la prospección pasiva y periódica de herramientas de la flota, consumiendo de forma determinista la sonda `check-tooling-updates.sh` y generando propuestas estructuradas y redactadas en `docs/idea-inbox/`, bajo el principio inviolable de **cero auto-ejecución**.

## Contexto técnico
La evolución de herramientas de la flota debe ser continua pero gobernada. La skill `tool-inventory` actual mantiene un catálogo de herramientas activas pero no cuenta con un procedimiento estandarizado para evaluar novedades y plantear mejoras al roadmap.
La nueva skill `tooling-advisor` automatiza la formulación de propuestas técnicas ante nuevas versiones o capacidades relevantes, depositándolas como ideas en el buzón canónico `docs/idea-inbox/` para que el operador humano o el ritual de sprint planning las evalúe, sin modificar nunca el sistema de forma autónoma.
Esta tarea se ejecuta bajo el régimen estándar de **Opción D** y depende de **T-173**.

### Integración de Research Scout (T-129)
- **Alternativas detectadas y analizadas**:
  - Habilidad preexistente `tool-inventory`: Catálogo estático de herramientas; no incluye prospección de versiones upstream.
  - Propuesta inicial en idea-inbox (2026-11-07): Aprobada para formalización como skill canónica consultiva.
- **Dictamen del Relé**:
  - Desarrollo de `.agents/skills/tooling-advisor/SKILL.md` como agente de prospección pasiva.
  - **Principio Inviolable: CERO auto-ejecución**. La skill solo genera propuestas redactadas en `docs/idea-inbox/`; nunca aplica updates desatendidos ni muta binarios.
  - Consumo determinista estructurado mediante `check-tooling-updates.sh --json`.
  - Filtrado de changelogs obligatorio para evitar volcados crudos extensos en las propuestas.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 31 / 2026-11-08
- **Diseño y arquitectura aprobados por**: Humano / Relé (Decisión Macro en Planning)
- **Decisiones e interfaces selladas**:
  - **Ubicación canónica**: `.agents/skills/tooling-advisor/SKILL.md`.
  - **Principio Inviolable**: CERO auto-ejecución de actualizaciones de herramientas. La skill es estrictamente consultiva y propositiva.
  - **Consumo determinista**: Utiliza `scripts/agent/check-tooling-updates.sh --json` para obtener el estado verídico de versiones.
  - **Formato de propuesta en `docs/idea-inbox/`**: Alineado con la convención canónica del buzón (`YYYY-MM-DD-<slug>.md`), con secciones QUÉ, Por qué, Impacto, Hechos verificados y Descartado con motivo.
  - **Filtrado de changelogs**: Prohibido volcar el texto completo del changelog o releases en crudo; la propuesta debe contener una síntesis redactada de las capacidades o fixes relevantes para Agent OS.
  - **Denominador de suite**: Inmutable en **38/38** (0 errores).
- **Veredicto de diseño macro**: `APROBADO_EN_PLANNING`

## Skills relevantes
- `tool-inventory`: Conexión con el catálogo de herramientas y servicios de flota.
- `creador-habilidades`: Estándares de creación de habilidades en Agent OS.

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/skills/tooling-advisor/` (SKILL.md y referencias)
- `tests/validate-control-plane.sh` (integridad de skills en Check 5)
- `.agents/tasks/task-174.md`

## Criterios de done
- [x] Skill canónica `.agents/skills/tooling-advisor/SKILL.md` creada con frontmatter YAML válido, protocolo de prospección pasiva y directivas claras.
- [x] Principio de no auto-ejecución y límite de proposición formalizado como guardarraíl estricto.
- [x] Protocolo de generación de propuestas en `docs/idea-inbox/` documentado con plantilla y filtro anti-volcados crudos.
- [x] Verificación de integridad de skills pasando limpia en Check 5 de `tests/validate-control-plane.sh` (26/26).
- [x] Suite de control plane inmutable en **38/38** pasando limpia (0 errores).
- [x] Ejecutada y registrada bajo las reglas de Opción D.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `CONSENSO`
  - **Rol del revisor**: Compuerta técnica determinista (caja de archivos, tests, realidad repo, fidelidad a diseño macro).
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-11-10T10:26:43Z (vía consenso determinista Opción D)
- [x] Rama creada: `feat/T-174-tooling-advisor-skill`
- [x] Lock activo: `.agent-session.lock`
- [ ] Sesión cerrada correctamente
