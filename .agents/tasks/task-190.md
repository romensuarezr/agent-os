# Task-190: Adaptadores estáticos multi-harness con proyección determinista y check fail-closed

## Objetivo
Implementar la proyección determinista de adaptadores estáticos para OpenCode (y futuros harness) en `install.sh` y `sync.sh`, de manera que cada flujo existente o nuevo en `.agents/workflows/*.md` tenga su correspondiente shim ejecutable en `.opencode/commands/<nombre>.md`. Además, añadir un chequeo determinista fail-closed en la suite `validate-control-plane.sh` para verificar que cada flujo tiene su shim activo y conforme.

## Contexto técnico
- En OpenCode, `@fichero` inyecta contexto de forma pasiva, mientras que `/comando` ejecuta la plantilla definida en `.opencode/commands/<comando>.md`.
- Para lograr compatibilidad transparente y zero-friction sin crear detectores dinámicos en caliente, proyectamos adaptadores estáticos: un archivo Markdown ligero por cada workflow.
- Tanto la instalación (`install.sh`, incluyendo `--self`) como la sincronización (`sync.sh`) deben proyectar estos shims automáticamente, garantizando que flujos creados en el Core o en satélites queden sincronizados.
- La suite de tests debe fallar si algún workflow carece de su shim en `.opencode/commands/`.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 34 / 2026-11-11
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - Proyección determinista en `install.sh` y `sync.sh` iterando sobre `.agents/workflows/*.md` para crear `.opencode/commands/<nombre>.md`.
  - Estructura de cada shim: frontmatter con `description` y `agent: plan`, cuerpo imperativo invocando `.agents/workflows/<nombre>.md $ARGUMENTS`.
  - Generación de shims en el propio repo Core en `.opencode/commands/`.
  - Check fail-closed en `tests/validate-control-plane.sh`: cada workflow debe tener su shim en `.opencode/commands/`, no vacío y con referencia al workflow correspondiente.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/install.sh`
- `scripts/agent/sync.sh`
- `scripts/agent/lib/project-harness.sh` (opcional helper si procede)
- `.opencode/commands/*.md`
- `tests/validate-control-plane.sh`
- `docs/sprints/sprint-34.md`

## Criterios de done
- [ ] `scripts/agent/install.sh` y `scripts/agent/sync.sh` proyectan automáticamente shims en `.opencode/commands/` para cada flujo de `.agents/workflows/`.
- [ ] En modo `--self` de `install.sh`, la proyección de shims se ejecuta correctamente.
- [ ] Todos los flujos actuales de `.agents/workflows/` (8 flujos) tienen su correspondiente shim en `.opencode/commands/`.
- [ ] `tests/validate-control-plane.sh` incorpora un check determinista fail-closed que valida la presencia y contenido de los shims.
- [ ] La suite pasa sin errores.

## Estado de aprobación y deliberación
- [x] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: CONSENSO
  - **Rol del revisor**: Compuerta técnica determinista.
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-11-11 09:55 UTC
- [x] Rama creada: `sprint-34`
- [ ] Lock activo: —
- [ ] Sesión cerrada correctamente
