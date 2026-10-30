# Task-138: Corregir y archivar el scout de ciclo de vida Orca (runbooks y guías de arquitectura)

## Objetivo
Corregir los comandos obsoletos e inexactos introducidos en la documentación inicial de orquestación de Orca (`docs/runbooks/orca-multiagent-orchestration.md` y `docs/architecture/tools/llm-routing-selection.md`), alineándolos con la máquina de estados real y los comandos canónicos certificados en host (`orca orchestration worker-start`, `worker-stop`, `worker-release`, aislamiento `env -i`).

## Contexto técnico
Durante las fases tempranas de investigación del Sprint 21 y 22, se generaron documentos de arquitectura y runbooks con asunciones hipotéticas sobre la CLI de Orca que no coincidían con la implementación real del runtime:
1. Comandos no existentes en la CLI real como `orca worktree create --prompt`.
2. Omisión de la necesidad de invocar `orca orchestration worker-stop` antes de `worker-release` cuando un worker se encuentra en estado activo o ejecutando.
3. Falta de especificación del aislamiento estricto de entorno (`env -i`) requerido para evitar la propagación involuntaria de tokens comerciales hacia el worker.
4. Divergencias en la firma de sondas de estado (`orca status --json` vs `orca orchestration run-create`).

En T-133, T-135 y T-136 se implementaron y certificaron los comandos canónicos en `lib/orca-client.sh` y `deliberate-plan.sh`. Esta tarea subsana la divergencia documental para que cualquier agente u operador consulte runbooks técnicamente rigurosos y reproducibles.

## Skills relevantes
- `doc-maintainer`: Mantenimiento y alineación de documentación técnica con la realidad operativa del código.
- `orchestrator`: Ciclo de vida canónico de workers y contratos agénticos multi-proceso.

## Caja de archivos
- `docs/runbooks/orca-multiagent-orchestration.md`
- `docs/architecture/tools/llm-routing-selection.md`
- `.agents/tasks/task-138.md`

## Criterios de done
- [ ] Comandos obsoletos o inventados (`orca worktree create --prompt`, etc.) eliminados o reemplazados por el flujo de aprovisionamiento real de worktrees (`worktree-dispatch.sh` + `orca orchestration worker-start`).
- [ ] Documentada la máquina de estados canónica del worker en Orca ADE: inicio (`worker-start`), monitoreo/lectura (`worker-read`), detención (`worker-stop`) y liberación forzosa/limpieza (`worker-release`).
- [ ] Documentado el requisito de aislamiento de entorno `env -i` con whitelist explícita de variables (`HOME`, `PATH`, `USER`, etc.) para prevenir contaminación de credenciales.
- [ ] Sondas de disponibilidad actualizadas para reflejar el uso primario de `orca status --json`.
- [ ] Plan de la tarea deliberado en Fase 3.5 con el Revisor Ejecutor vivo en host.
- [ ] Suite completa de control plane `tests/validate-control-plane.sh` pasando limpia (37/37) y cero violaciones de higiene de secretos/rutas.
