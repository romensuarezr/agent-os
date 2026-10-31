# Task-152: Cableado del Revisor Antigravity CLI (agy) como Tier 1 en deliberate-plan.sh

## Objetivo
Integrar la herramienta de inferencia nativa Antigravity CLI (`agy`) como Tier 1 prioritario dentro del motor determinista de arbitraje Coder-Reviewer (`scripts/agent/deliberate-plan.sh`), estableciendo una cascada de degradación resiliente: `agy` → `Orca ADE` → `HTTP Cascade` → `SIN_REVISOR`. Implementar el wrapper de timeout portátil, validación del delimitador ante el comportamiento de `exit 0` en timeout de `agy`, y sonda previa de autenticación y flags disponibles.

## Contexto técnico
Actualmente, `deliberate-plan.sh` intenta despachar la revisión en Tier 1 a Orca ADE (`orca orchestration worker-dispatch`), pasando a cascada HTTP y finalmente a `SIN_REVISOR`.
En el entorno local, se cuenta con la CLI oficial de Antigravity (`agy`, versión 1.4.12 instalada en `~/.local/bin/agy`), capaz de ejecutar prompts con `--print`, `--output-format json` y validación estructurada `--json-schema`.
Sin embargo, `agy` presenta un comportamiento particular: ante un timeout durante el turn de impresión, puede retornar con código de salida `0` emitiendo salida parcial o truncada. Para que el core opere con $0 tokens de incertidumbre, se requiere un delimitador estricto de bloque JSON estructurado y validación sintáctica fail-closed antes de dar por buena la revisión.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 27 / 2026-10-31
- **Diseño y arquitectura aprobados por**: Humano / Relé (Sprint Planning Sprint 27)
- **Decisiones e interfaces selladas**:
  - Incorporar Tier 0 / Tier 1 prioritario para `agy` en `scripts/agent/deliberate-plan.sh` si `command -v agy` está disponible en el entorno y la sonda de autenticación es positiva.
  - Invocación no interactiva con banderas acotadas: `agy --print --output-format json --mode plan --settings ...` (o esquema estructurado de revisión).
  - Wrapper de timeout estricto mediante `scripts/agent/lib/portable-timeout.sh` reutilizado tal cual sin modificación; en caso de requerir cualquier ajuste o cambio, se añadirá explícitamente a la caja de archivos antes de tocarlo.
  - Validación de delimitador y extracción robusta: no confiar ciegamente en `exit 0`; exigir que la salida contenga un bloque JSON completo y válido con los campos canónicos (`verdict`, `objections`, `corrections`, `skills_evaluation`, `design_summary`). Si la salida es parcial, nula o carece de campos, degradar inmediatamente a Tier 2 (Orca ADE) o fallback subsiguiente.
  - Mantener intacta la jerarquía posterior: si `agy` falla o excede timeout → Orca ADE → Cascada HTTP → `SIN_REVISOR`.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `agent-os-scripts`: Mantenimiento y evolución de scripts deterministas del core (`deliberate-plan.sh`).
- `antigravity-guide`: Referencia técnica de flags, configuración y modos de Antigravity CLI (`agy`).
- `testing-flows`: Cobertura de pruebas con mocks y validación de degradación en cascada.

## Caja de archivos
- `scripts/agent/deliberate-plan.sh`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-152.md`

## Criterios de done
- [ ] Función de sonda determinista (`probe_agy_reviewer`) que comprueba binario `agy`, flags admitidos y conectividad básica sin bloquear.
- [ ] Adaptador de invocación de `agy` como Tier 1 en `deliberate-plan.sh` con wrapper de timeout.
- [ ] Extracción de veredicto estructurado protegida contra `exit 0` en timeout (validación de delimitador y parser JSON).
- [ ] Fallback en cascada certificado: fallo o timeout de `agy` transfiere limpiamente la ejecución a Orca ADE / HTTP / `SIN_REVISOR`.
- [ ] Test de regresión incorporado en `tests/validate-control-plane.sh` validando el cableado de `agy` y su degradación.
- [ ] Suite completa de control plane `tests/validate-control-plane.sh` pasando limpia sin regresiones (37/37).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido
- [ ] Rama creada
- [ ] Cierre y merge autorizado por el relé
