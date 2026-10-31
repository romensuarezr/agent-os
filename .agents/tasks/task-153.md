# Task-153: Guardas de seguridad, aislamiento read-only y certificación git-limpio para agy

## Objetivo
Implementar y certificar mecanismos de contención herméticos para el Revisor Antigravity (`agy`), asegurando que la deliberación opere estrictamente en modo de solo lectura (*read-only*), bloqueando de forma determinista cualquier intento de mutación en el sistema de archivos o alteración del working tree de Git, y abortando fail-closed con alerta visible si se detecta un working tree sucio o residuos untracked tras la revisión.

## Contexto técnico
El Revisor de planes tiene una función técnica de auditoría y arbitraje, no de implementación. Al invocar un agente o modelo vía CLI con permisos de sistema o en modo interactivo, existe el riesgo latente de que la herramienta intente editar ficheros, crear artefactos no autorizados o dejar archivos residuales en el repositorio.
Esta tarea introduce guardarraíles mecánicos de seguridad:
1. Configuración de ejecución en modo no mutante (flags de contención como `--mode plan` o configuración estricta de tools prohibidas).
2. Aislamiento de variables de entorno mediante `env -i` para evitar propagación de secretos o credenciales no deseadas.
3. Centinela de working tree antes y después de la deliberación (`git status --porcelain`). Si el working tree sufre cambios durante la revisión de `agy`, abortar de inmediato de forma fail-closed y restaurar el estado limpio.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 27 / 2026-10-31
- **Diseño y arquitectura aprobados por**: Humano / Relé (Sprint Planning Sprint 27)
- **Decisiones e interfaces selladas**:
  - Guardarraíl de working tree limpio: verificación pre y post invocación de `agy` en `scripts/agent/deliberate-plan.sh`.
  - **Centinela PRE**: Si `git status --porcelain` detecta que el working tree ya está sucio antes de invocar `agy`, aborta inmediatamente de forma fail-closed con código de error sin llegar a ejecutar `agy`.
  - **Centinela POST y Limpieza Acotada**: Si tras la ejecución de `agy` el working tree presenta cambios respecto al snapshot previo, emitir error estructurado (`❌ VIOLACIÓN DE SEGURIDAD: El revisor intentó mutar el working tree`), ejecutar limpieza post exclusivamente sobre los archivos del diff generado entre el estado pre y post de `agy` (sin borrado indiscriminado del árbol), invalidar el veredicto y degradar a `ESCALADO_A_HUMANO` / aborto fail-closed.
  - Aislamiento estricto de variables de entorno: filtrar credenciales ambientales no explícitas.
  - Tests en `tests/validate-control-plane.sh` simulando intentos de mutación y certificando la respuesta de contención.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `agent-os-scripts`: Guardarraíles deterministas en scripts CLI universales.
- `testing-flows`: Creación de aserciones de seguridad y simulación de violaciones en el control plane.

## Caja de archivos
- `scripts/agent/deliberate-plan.sh`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-153.md`

## Criterios de done
- [ ] Centinela PRE implementado en `scripts/agent/deliberate-plan.sh` que aborta sin invocar `agy` si el working tree ya está sucio.
- [ ] Centinela POST y limpieza determinista acotada exclusivamente al diff pre/post generado por `agy` ante mutaciones no autorizadas, con emisión de bloqueo técnico.
- [ ] Aislamiento de entorno en la llamada de `agy`.
- [ ] Test de regresión determinista en `tests/validate-control-plane.sh` verificando la captura y contención ante modificaciones espurias.
- [ ] Suite completa de control plane `tests/validate-control-plane.sh` pasando limpia sin regresiones (37/37).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido
- [ ] Rama creada
- [ ] Cierre y merge autorizado por el relé
