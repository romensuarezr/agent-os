# Task-138: Corregir y archivar el scout de ciclo de vida Orca (runbooks y guías de arquitectura)

## Objetivo
Corregir los comandos obsoletos e inexactos introducidos en la documentación inicial de orquestación de Orca (`docs/runbooks/orca-multiagent-orchestration.md` y `docs/architecture/tools/llm-routing-selection.md`), alineándolos con la máquina de estados real y los comandos canónicos certificados en host (`orca orchestration worker-start`, `worker-stop`, `worker-release`, aislamiento `env -i`).

## Contexto técnico
Durante las fases tempranas de investigación del Sprint 21 y 22, se generaron documentos de arquitectura y runbooks con asunciones sobre la CLI de Orca que requerían precisión respecto a la implementación real del runtime:
1. Distinción entre el modo interactivo de GUI (`orca worktree create --agent ... --prompt ...` y `orca worktree ps`) y el flujo automatizado/desacoplado del core (`worktree-dispatch.sh` + `orca orchestration worker-start`).
2. Omisión de la fase de detención de procesos (`worker-stop`) previa a la liberación de terminales (`worker-release`) cuando un worker se encuentra en estado activo.
3. Falta de especificación del aislamiento estricto de entorno (`env -i`) requerido para evitar la propagación involuntaria de tokens comerciales hacia el worker.
4. Divergencias en la firma de sondas de estado (`orca status --json` verificando `.result.runtime.state == "ready"` de forma fail-fast).

En T-133, T-135 y T-136 se implementaron y certificaron los comandos canónicos en `lib/orca-client.sh` y `deliberate-plan.sh`. Esta tarea subsana la divergencia documental para que cualquier agente u operador consulte runbooks técnicamente rigurosos y reproducibles.

## Decisión de Backlog — Nota Scout Exhaustiva
Se formaliza la decisión de diferir el archivado de una nota scout retrospectiva e independiente (bibliografía completa y volcados `--help` exhaustivos de la CLI de Orca) al **backlog futuro (Sprint 26+ / gobernanza documental)**. La tarea **T-140** arrastrará expresamente este ítem abierto en su informe analítico de observación del ciclo.

## Skills relevantes
- `doc-maintainer`: Mantenimiento y alineación de documentación técnica con la realidad operativa del código.
- `orchestrator`: Ciclo de vida canónico de workers y contratos agénticos multi-proceso.

## Caja de archivos
- `docs/runbooks/orca-multiagent-orchestration.md`
- `docs/architecture/tools/llm-routing-selection.md`
- `.agents/tasks/task-138.md`

## Criterios de done
- [x] Comandos de despacho documentados con precisión: eliminado el uso informal de --prompt en ejemplos de orquestación, aportada evidencia de orca worktree create --help, y distinguiendo el modo interactivo (worktree create, worktree ps, worktree list) del flujo desacoplado (worktree-dispatch.sh + worker-start con directiva estructurada).
- [x] Documentada la máquina de estados canónica del worker en Orca ADE: inicio (`worker-start`), monitoreo/lectura (`worker-read`), detención (`worker-stop`) y liberación forzosa/limpieza (`worker-release`).
- [x] Documentado el requisito de aislamiento de entorno `env -i` con la whitelist canónica exacta de 10 variables de `orca-client.sh` (`HOME`, `PATH`, `USER`, `SHELL`, `LANG`, `LC_ALL`, `TMPDIR`, `ORCA_USER_DATA_PATH`, `ORCA_TERMINAL_HANDLE`, `ORCA_CALLS_LOG`).
- [x] Sondas de disponibilidad actualizadas para reflejar el uso primario de `orca status --json` con verificación de `.result.runtime.state == "ready"`.
- [x] Decisión de diferir la nota scout exhaustiva al backlog de Sprint 26+ registrada, con constancia de arrastre en T-140.
- [x] Plan de la tarea deliberado en Fase 3.5 con el Revisor Ejecutor vivo en host (CONSENSO, tier orca).
- [x] Suite completa de control plane `tests/validate-control-plane.sh` pasando limpia (37/37) y cero violaciones de higiene de secretos/rutas.
