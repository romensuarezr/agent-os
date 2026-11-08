# Task-172: Matriz de roles y capacidades de CLIs de la flota (OpenCode 2, Claude Code, Aider, Hermes, Antigravity)

## Objetivo
Formalizar la matriz de roles, capacidades, perfiles YAML y guardarraíles de ejecución de los CLIs agénticos presentes en la flota de Agent OS (OpenCode 2, Claude Code, Aider, Hermes y Antigravity), codificando las decisiones macro vinculantes del operador en los perfiles declarativos y documentación de arquitectura.

## Contexto técnico
La flota cuenta con diversos CLIs agénticos distribuidos entre el host local y los nodos remotos. Para evitar solapamientos, riesgos de ejecución descontrolada y pérdida de reproducibilidad, la gobernanza del core exige que cada herramienta tenga asignado un rol específico, guardarraíles claros y límites operativos estrictos.
Esta tarea codifica de forma determinista la distribución de roles aprobada en el sprint planning del Sprint 31.
Esta tarea se ejecuta bajo el régimen estándar de **Opción D**.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 31 / 2026-11-08
- **Diseño y arquitectura aprobados por**: Humano / Relé (Decisiones Macro Vinculantes)
- **Decisiones e interfaces selladas**:
  - **OpenCode 2 (`@opencode/cli` npm v2.2.6)**: Rol ratificado como Worker / Coder acotado en sandbox / worktrees efímeros. Prohibida su elevación a coordinador o fusión desatendida hacia ramas troncales.
  - **Claude Code**: **DESCARTADO** formalmente como juez. Se ratifica la jerarquía actual de revisión técnica determinista: `agy` (Tier 1) / Orca ADE (Tier 2).
  - **Aider**: **DESCARTADO** formalmente como rescatador de merges entre worktrees. Se ratifica sin excepciones la doctrina estricta de Sprint 25: solo el coordinador o el humano fusionan ramas de trabajo.
  - **Hermes**: **DESCARTADO** como front door separado. El daemon `whatsapp-bridge` fue construido por Hermes para comunicarse con el usuario en el host; Hermes opera a través de su propio puente y no se crea un gateway redundante.
  - **Antigravity CLI (`agy`)**: Agente principal de orquestación, planificación y deliberación arquitectónica.
  - **Perfiles YAML**: Actualizar y añadir los perfiles pertinentes en `.agents/profiles/` respetando los campos mínimos validados por el Check 2 del control plane.
  - **Matriz de Arquitectura**: Documentar formalmente la matriz en `docs/architecture/tools/fleet-cli-roles-matrix.md`.
  - **Denominador de suite**: Inmutable en **38/38** (0 errores).
- **Veredicto de diseño macro**: `APROBADO_EN_PLANNING`

## Skills relevantes
- `agent-os-scripts`: Integración con utilidades y reglas de Agent OS.
- `tool-inventory`: Consulta del inventario de flota y perfiles agénticos.

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/profiles/` (perfiles YAML / MD de agentes)
- `.agents/config/agent-registry.yaml`
- `.agents/config/fleet.example.yaml`
- `docs/architecture/tools/fleet-cli-roles-matrix.md`
- `.agents/tasks/task-172.md`

## Criterios de done
- [ ] Matriz de roles y capacidades formalizada en `docs/architecture/tools/fleet-cli-roles-matrix.md` reflejando con exactitud las decisiones vinculantes selladas.
- [ ] Perfiles declarativos en `.agents/profiles/` actualizados con los guardarraíles, permisos y roles definidos para cada CLI.
- [ ] Exclusión de Aider en merges, Claude Code como juez y Hermes como front door separado explícitamente documentada con su justificación técnica.
- [ ] Compatibilidad estricta con la validación de perfiles (Checks 1, 2 y 10 de `tests/validate-control-plane.sh`).
- [ ] Suite de validación de control plane inmutable en **38/38** pasando limpia (0 errores).
- [ ] Ejecutada y registrada bajo las reglas de Opción D.

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
