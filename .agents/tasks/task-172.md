# Task-172: Matriz de roles y capacidades de CLIs de la flota (OpenCode 2, Claude Code, Aider, Hermes, Antigravity)

## Objetivo
Formalizar la matriz de roles, capacidades, perfiles YAML y guardarraíles de ejecución de los CLIs agénticos presentes en la flota de Agent OS (OpenCode 2, Claude Code, Aider, Hermes y Antigravity), codificando las decisiones macro vinculantes del operador en los perfiles declarativos y documentación de arquitectura.

## Contexto técnico
La flota cuenta con diversos CLIs agénticos distribuidos entre el host local y los nodos remotos. Para evitar solapamientos, riesgos de ejecución descontrolada y pérdida de reproducibilidad, la gobernanza del core exige que cada herramienta tenga asignado un rol específico, guardarraíles claros y límites operativos estrictos.
Esta tarea codifica de forma determinista la distribución de roles aprobada en el sprint planning del Sprint 31.
Esta tarea se ejecuta bajo el régimen estándar de **Opción D**.

### Integración de Research Scout (T-129)
- **Alternativas detectadas y analizadas**:
  - `@opencode/cli` (npm v2.2.6 / repo `anomalyco/opencode`): CLI local agnóstico para tareas de programación rápida.
  - `stablyai/orca` / binario `orca-ide`: Entorno de orquestación y revisión autónoma (Tier 2).
  - `NousResearch/hermes-agent` (v0.22.7): Agente de mensajería e inferencia con WhatsApp bridge propio.
  - `anthropic/claude-code`: CLI agéntico de terminal con flags permisivos.
  - `aider-chat/aider`: Asistente CLI de terminal orientado a commits y edición directa.
  - `Google Antigravity CLI` (`agy`): Motor central de orquestación, planificación y Tier 1 Reviewer.
- **Dictámenes vinculantes del operador**:
  - *OpenCode 2*: Ratificado como Worker/Coder acotado en worktrees efímeros.
  - *Antigravity CLI*: Ratificado como Coder, Planificador y Revisor Tier 1.
  - *Claude Code*: Descartado formalmente como juez (mantenimiento de jerarquía `agy` Tier 1 / Orca ADE Tier 2).
  - *Aider*: Descartado como rescatador de merges (doctrina estricta Sprint 25: solo coordinador o humano fusionan).
  - *Hermes*: Descartado como front door separado (comunicación directa vía su propio puente en host).

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
- [x] Matriz de roles y capacidades formalizada en `docs/architecture/tools/fleet-cli-roles-matrix.md` reflejando con exactitud las decisiones vinculantes selladas.
- [x] Perfiles declarativos en `.agents/profiles/` actualizados con los guardarraíles, permisos y roles definidos para cada CLI.
- [x] Exclusión de Aider en merges, Claude Code como juez y Hermes como front door separado explícitamente documentada con su justificación técnica.
- [x] Compatibilidad estricta con la validación de perfiles (Checks 1, 2 y 10 de `tests/validate-control-plane.sh`).
- [x] Suite de validación de control plane inmutable en **38/38** pasando limpia (0 errores).
- [x] Ejecutada y registrada bajo las reglas de Opción D.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `CONSENSO`
  - **Rol del revisor**: Compuerta técnica determinista (caja de archivos, tests, realidad repo, fidelidad a diseño macro).
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-11-09T09:32:05Z (vía consenso determinista Opción D)
- [x] Rama creada: `feat/T-172-fleet-cli-roles-matrix`
- [x] Lock activo: `.agent-session.lock`
- [x] Sesión cerrada correctamente
