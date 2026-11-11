# Task-191: Sonda de automejora determinista ($0 tokens) en ritual de planning con canalización a idea-inbox/

## Objetivo
Conectar la sonda determinista `check-tooling-updates.sh` en el Paso 1 de `sprint-planning.md` para que detecte actualizaciones de herramientas upstream (OpenCode, Hermes, Orca, Infisical, etc.) a coste cero de tokens de LLM y genere borradores estructurados en `docs/idea-inbox/` siguiendo el patrón de la skill `tooling-advisor`, cerrando el bucle de automejora en el Paso 3 del planning mediante la compuerta humana que decide si entra al sprint.

## Contexto técnico
- Agent OS dispone de `scripts/agent/check-tooling-updates.sh` ($0 tokens, determinista) y de la skill `tooling-advisor`, pero antes operaban de forma pasiva o manual.
- Para que Agent OS sea consciente de su propio tooling y se automejore sin alucinaciones ni auto-modificaciones en caliente, la sonda debe correr al inicio del planning (Paso 1).
- Si la sonda detecta una nueva versión o aviso crítico:
  - Redacta de forma determinista un archivo RFC en `docs/idea-inbox/YYYY-MM-DD-<herramienta>-v<version>.md` con el estado `💡 REGISTRADA (NO APROBADA)`.
  - En el Paso 3 de `sprint-planning.md`, `check-inbox.sh` encuentra estas propuestas y las presenta en la cosecha de candidatas.
  - El operador humano en el Paso 7 aprueba o pospone la tarea de actualización para el sprint entrante.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 34 / 2026-11-11
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - Invocación de `bash scripts/agent/check-tooling-updates.sh --json` en el Paso 1 de `sprint-planning.md`.
  - Si hay novedades upstream, generación determinista de la ficha en `docs/idea-inbox/` sin mutación directa del código ni consumo de tokens.
  - Vaciado y clasificación estándar en el Paso 3, presentando las propuestas al humano en el cuadro de tareas candidatas.
  - Respeto del principio estricto de Cero Auto-ejecución (Zero Live Self-Mutation).
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/workflows/sprint-planning.md`
- `scripts/agent/check-tooling-updates.sh` (si se requiere flag `--generate-inbox` o helper determinista)
- `tests/validate-control-plane.sh`
- `docs/sprints/sprint-34.md`

## Criterios de done
- [ ] El Paso 1 de `sprint-planning.md` incluye la ejecución de la sonda de automejora `check-tooling-updates.sh`.
- [ ] La sonda genera fichas estructuradas en `docs/idea-inbox/` cuando detecta versiones upstream desactualizadas.
- [ ] El Paso 3 de `sprint-planning.md` clasifica y presenta estas fichas como candidatas potenciales para aprobación humana.
- [ ] Se verifica determinismo y $0 tokens en la generación del RFC.
- [ ] Validación en `validate-control-plane.sh` pasa sin errores.

## Estado de aprobación y deliberación
- [x] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: CONSENSO
  - **Rol del revisor**: Compuerta técnica determinista.
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-11-11 09:55 UTC
- [x] Rama creada: `sprint-34`
- [ ] Lock activo: —
- [ ] Sesión cerrada correctamente
