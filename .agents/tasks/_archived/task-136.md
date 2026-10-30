# Task-136: Check 37 en `validate-control-plane.sh` (Certificación E2E de Revisor Ejecutor y Denominador 36→37)

## Objetivo
Implementar el **Check 37** en la suite canónica de control plane `tests/validate-control-plane.sh`, actualizando el denominador de `[X/36]` a `[X/37]` en todas sus ocurrencias, certificando de forma determinista y sin red el ciclo de arbitraje del Revisor Ejecutor de Orca, el aislamiento de entorno (`env -i`), la cascada de 3 niveles y la ausencia total de secretos en argv o rutas personales.

## Contexto técnico
El control plane requiere validar que la integración del Revisor Ejecutor en `deliberate-plan.sh` y `lib/orca-client.sh` es 100% portable y segura:
1. **Mock genérico offline**: Se simula un entorno CLI de Orca (`status --json` exit 0, `run-create`/`run-current`, `worker-start`, `worker-read`, `worker-stop`, `worker-release`) sin requerir conectividad de red ni dependencias de servicios externos, resolviendo logs desde `$(dirname "$0")` bajo `env -i`.
2. **Aislamiento de entorno**: Se asegura que `env -i` se aplica en el despacho y no se filtran credenciales del coordinador (trampa de secretos ausente, whitelist de 10 variables preservada).
3. **Contrato de veredicto y clave `role`**: `worker-read` emite terminal tail `[delimitador, JSON, delimitador]` y el veredicto contiene la clave `role` (no `profile`).
4. **Presupuesto no obsoleto**: La spec del worker exige evaluación estática concisa con `PRESUPUESTO 60s` y prohíbe el valor obsoleto `PRESUPUESTO 15s`.
5. **Cascada de 3 niveles y fallback rápido**: Se comprueba el paso ordenado de Orca a fallback seguro `SIN_REVISOR` (`evaluator_tier: fallback_safe`, `role: none`) con `--orca-timeout 2` en <~10s, manteniendo `INFERENCE_BASE_URL` offline.
6. **Denominador**: Se actualizan las 36 ocurrencias de `[X/36]` a `[X/37]` de forma exhaustiva y verificable (`/36]` = 0, `/37]` = 37).
7. **Higiene de árbol**: Árbol de trabajo 100% limpio y sin residuos tras la ejecución.

## Skills relevantes
- `testing-flows`: Regla aplicada: arneses de prueba deterministas para bucles multi-agente y aislamiento de fixtures.
- `agent-os-scripts`: Regla aplicada: portabilidad POSIX y verificación estricta de códigos de salida.

## Caja de archivos
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-136.md`

## Criterios de done
- [x] Ocurrencias del denominador actualizadas exhaustivamente de `[X/36]` a `[X/37]` (`/36]` = 0 y `/37]` = 37).
- [x] Check 37 implementado certificando la detección de Orca, la inyección de spec con presupuesto 60s, la cascada de 3 niveles y la limpieza de terminales.
- [x] Validación de aislamiento estricto `env -i` con whitelist de 10 variables y trampa de secretos ausente.
- [x] Contrato de veredicto verificado con clave `role` (`qa-judge`) y sin clave `profile`.
- [x] Fallback rápido certificado con `--orca-timeout 2` degradando a `SIN_REVISOR/fallback_safe/none` en <10s.
- [x] Suite completa ejecutando exitosamente los 37 checks (37/37) con 0 errores y working tree 100% limpio.
