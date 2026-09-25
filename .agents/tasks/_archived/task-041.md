# Task-041: Orquestación Multi-Agente en Orca ADE: Coordinador, despacho paralelo y enrutamiento dinámico de LLMs

## Objetivo
Diseñar e implementar el protocolo operativo y la herramienta determinista `scripts/agent/orca-orchestrate.sh` para Orca ADE, permitiendo que un agente Coordinador trocee una tarea compleja, determine el LLM/proveedor idóneo para cada subtarea según la política de enrutamiento y coste, y despache múltiples agentes especializados (`developer`, `reviewer`, etc.) concurrentemente sobre worktrees aislados de Orca hasta su verificación.

## Contexto técnico
- Orca Desktop (v1.4.210 activo) dispone de un motor de orquestación nativo (`orca orchestration run-create`, `worker-start`, `check --wait`) y gestión de worktrees git independientes (`orca worktree create`).
- Los 7 perfiles de Agent OS en `.agents/profiles/` (`coordinator`, `developer`, `reviewer`, `ops-auditor`, `researcher`, `marketing`, `seo`) estipulan qué herramientas y tiers de modelos corresponden a cada rol.
- La matriz de enrutamiento en `config/routing-policy.yaml` define la asignación de modelos: modelos premium (`primary-reliable`) para tareas críticas, inferencia $0 (`freellmapi` / `omniroute`) para código y tests, y computación local (`ollama`) para datos privados.
- La prospección técnica identificó marcos de referencia relevantes como RouteLLM (`lm-sys/RouteLLM`) para balanceo coste/calidad y `claude-swarm` para descomposición de tareas.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `docs/sprints/sprint-07-core.md`
- `.agents/tasks/task-041.md`
- `scripts/agent/orca-orchestrate.sh`
- `docs/runbooks/orca-multiagent-orchestration.md`
- `docs/architecture/tools/llm-routing-selection.md`
- `tests/validate-control-plane.sh`

## Criterios de done
- [x] Documento de prospección y arquitectura en `docs/architecture/tools/llm-routing-selection.md` evaluando la toma de decisiones de modelos/proveedores (RouteLLM, matriz declarativa de Agent OS, selección semántica del Coordinador).
- [x] Script CLI determinista `scripts/agent/orca-orchestrate.sh` que interactúe con el runtime de Orca para inicializar Runs, despachar workers paralelos con perfiles de Agent OS y supervisar su estado (`worker_done`, preguntas, compuertas).
- [x] Runbook operativo maestro en `docs/runbooks/orca-multiagent-orchestration.md` detallando: diferencias entre Proyectos y Worktrees, ciclo de vida del Coordinador, protocolo `ask/reply` entre agentes y resolución de Decision Gates.
- [x] **Prueba de éxito verificada**: Ejecución y reporte de múltiples agentes concurrentes en Orca resolviendo una tarea troceada y supervisada en worktrees aislados.
- [x] Validación de la suite `tests/validate-control-plane.sh` pasando con 0 errores.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-25T15:51:47+01:00
- [x] Rama creada: feat/T-041-orca-multiagent-orchestration
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
