# Task-146: Cierre de sprint en invocación única concatenada y determinista

## Objetivo
Transformar el cierre de sprint en una única invocación concatenada y determinista (`bash scripts/agent/close-sprint.sh <sprint>`). `close-sprint.sh` debe encargarse de que la entrada correspondiente en `changelog.md` exista —llamando internamente a `update-changelog.sh` o fallando de forma explícita si falta— sin depender de ningún paso manual previo por parte del operador o agente. El bump de versión resultante debe ser determinista y sin selección interactiva, preservando total compatibilidad con los satélites que ya utilizan `close-sprint.sh` (evitando duplicar entradas si el changelog ya viene modificado).

## Contexto técnico
Actualmente, el ritual de cierre de un sprint requería un paso previo manual o desacoplado (`bash scripts/agent/update-changelog.sh <sprint>`) antes de invocar `close-sprint.sh`. Si dicho paso se omitía, `close-sprint.sh` archivaba el sprint sin actualizar `changelog.md` ni incrementar `VERSION`.
Para garantizar la robustez operativa, trazabilidad y automatización desatendida del core:
1. `close-sprint.sh` debe asumir la responsabilidad de coordinar deterministamente `update-changelog.sh`.
2. Si `changelog.md` ya tiene cambios preparados (en stage o modificados en working tree por satélites o edición humana previa), se respeta íntegramente sin re-generar ni duplicar la sección.
3. Si `changelog.md` no tiene cambios, se ejecuta `update-changelog.sh <sprint>` de manera desatendida, capturando errores y abortando de forma fail-closed si la generación no tiene éxito.
4. El cálculo de semver debe ser puramente determinista, sin preguntas interactivas ni dependencias de runtime externo.

## Skills relevantes
- `agent-os-scripts`: Dominio y orquestación de las herramientas nativas del core (`close-sprint.sh`, `update-changelog.sh`, `install.sh`, `sync.sh`).
- `testing-flows`: Diseño de fixtures no destructivas y pruebas de regresión en Bash para la suite de control plane.

## Caja de archivos
- `scripts/agent/close-sprint.sh`
- `scripts/agent/update-changelog.sh`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-146.md`

## Criterios de done
- [ ] `close-sprint.sh` orquesta de forma interna y determinista la presencia de la entrada en `changelog.md`, invocando `update-changelog.sh` si no hay cambios previos sin requerir ejecución manual separada.
- [ ] Compatibilidad estricta con satélites: si el changelog ya viene modificado o preparado en stage/working tree, no duplica la entrada ni sobreescribe el contenido manual.
- [ ] Comportamiento fail-closed explícito: si `update-changelog.sh` falla o no puede generar la entrada, `close-sprint.sh` aborta con diagnóstico claro sin corromper el árbol ni mover ramas.
- [ ] El bump de versión resultante es 100% determinista y desatendido, sin menús interactivos.
- [ ] Prueba del flujo completo de cierre sobre un sprint de prueba o fixture en seco ejecutada con éxito, demostrando que ya no hace falta el paso manual previo.
- [ ] Plan previo legible presentado en `.agents/context/plan-draft.md` y deliberado mediante `deliberate-plan.sh` con timeout default de 60s.
- [ ] Suite completa de control plane `tests/validate-control-plane.sh` pasando limpia (37/37) sin regresiones.
