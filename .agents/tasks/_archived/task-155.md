# Task-155: Batería de tests de hueco del Revisor Dual en Check 34 (binario ausente, kill y handoff)

## Objetivo
Implementar los 3 tests unitarios y de integración pendientes en Check 34 de `tests/validate-control-plane.sh` para blindar la cascada y robustez del Revisor Dual (`agy` Tier 1 → `Orca ADE` Tier 2): salto instantáneo 0s ante binario de agy ausente, terminación forzosa con `SIGKILL` ante timeout real, y captura exitosa de veredicto en handoff hacia Orca, manteniendo el denominador de la suite estrictamente en 37/37.

## Contexto técnico
Durante el desarrollo del cableado de `agy` (T-152) y sus guardas de seguridad (T-153), se identificaron tres casos de borde en la cascada de deliberación que quedaron pendientes como carry-over formal para Sprint 28 (Decisión de Gobernanza Opción A ratificada en T-154).
Estos tres escenarios son:
1. **Binario ausente**: Si `agy` no está instalado en PATH ni en `~/.local/bin/agy`, la sonda preliminar de `deliberate-plan.sh` debe saltar de forma determinista e inmediata (0s de retardo) a Orca ADE sin intentar invocar el ejecutable.
2. **Timeout real con kill**: Si un proceso del revisor queda colgado o consumiendo cómputo más allá de la cota de tiempo, el centinela de timeout debe emitir una señal de terminación contundente (`SIGKILL`) garantizando que no queden procesos huérfanos o zombies bloqueando descriptores.
3. **Handoff agy → Orca**: Si agy falla o degrada pero Orca está operativo, el motor debe transicionar de forma transparente capturando el veredicto estructurado emitido por el Tier 2 (`evaluator_tier=orca`).

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 28 / 2026-11-02
- **Diseño y arquitectura aprobados por**: Humano / Relé (Sprint Planning Sprint 28)
- **Decisiones e interfaces selladas**:
  - Incorporar en Check 34 de `tests/validate-control-plane.sh` tres sub-checks específicos:
    1. *Mock agy ausente* (`AGY_BIN_OVERRIDE=/bin/nonexistent`): Assertar que la deliberación no falla con error fatal, no tarda >1s y transiciona a Orca/fallback con `evaluator_tier != agy`.
    2. *Mock agy colgado* (script que ignora SIGTERM / trampa `trap '' TERM` y duerme): Assertar que el wrapper de timeout termina el proceso con `SIGKILL` en la cota de tiempo sin dejar procesos residuales en ejecución.
    3. *Mock handoff agy → Orca*: agy corrupto/timeout pero mock de Orca emitiendo `CONSENSO` válido; assertar que el resultado final adopta el veredicto de Orca con `evaluator_tier=orca`.
  - Refactorizar en `scripts/agent/deliberate-plan.sh` únicamente si fuera estrictamente necesario para satisfacer los contratos de terminación limpia.
  - La suite de control plane `tests/validate-control-plane.sh` debe mantenerse fija en **37/37** (0 errores).
  - Cero modificaciones a `main`, sin creación de tags de Git.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `agent-os-scripts`: Mantenimiento y evolución de deliberate-plan.sh y scripts del core.
- `testing-flows`: Diseño de tests de integración con mocks deterministas y aserciones de señales.

## Caja de archivos
- `scripts/agent/lib/portable-timeout.sh`
- `scripts/agent/deliberate-plan.sh`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-155.md`

## Criterios de done
- [x] Sub-test 1 (binario ausente): validado en Check 34 para los dos casos: PATH sin agy sin override (salto <1s, tier != agy) Y override a fichero inexistente/no ejecutable (fail-fast sin fallback a sistema).
- [x] Sub-test 2 (timeout con kill): validado en Check 34 con escalado SIGKILL (TERM → gracia → KILL) certificando muerte dentro de timeout+gracia y 0 huérfanos.
- [x] Sub-test 3 (handoff agy → Orca): validado en Check 34 con inyección ORCA_BIN_OVERRIDE y mock Orca con veredicto spec completo (5 campos canónicos) y evaluator_tier=orca.
- [x] Escalado SIGKILL implementado en `scripts/agent/lib/portable-timeout.sh` para GNU timeout (`--kill-after`) y wrapper Python (`SIGTERM` + gracia + `SIGKILL`).
- [x] Suite completa de control plane pasando limpia (37/37) con 0 errores.
- [x] Cero residuos de procesos en segundo plano tras la ejecución de la suite.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido
- [x] Rama creada
- [ ] Cierre y merge autorizado por el relé
