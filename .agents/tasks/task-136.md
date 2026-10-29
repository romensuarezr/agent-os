# Task-136: Check 37 en `validate-control-plane.sh` (Certificación E2E de Revisor Ejecutor y Denominador 36→37)

## Objetivo
Implementar el **Check 37** en la suite canónica de control plane `tests/validate-control-plane.sh`, actualizando el denominador de `[X/36]` a `[X/37]` en todas sus ocurrencias, certificando de forma determinista y sin red el ciclo de arbitraje del Revisor Ejecutor de Orca, el aislamiento de entorno (`env -i`), la cascada de 3 niveles y la ausencia total de secretos en argv o rutas personales.

## Contexto técnico
El control plane requiere validar que la integración del Revisor Ejecutor en `deliberate-plan.sh` y `lib/orca-client.sh` es 100% portable y segura:
1. **Mock genérico offline**: Se simula un entorno CLI de Orca sin requerir conectividad de red ni dependencias de servicios externos.
2. **Aislamiento de entorno**: Se asegura que `env -i` se aplica en el despacho y no se filtran credenciales del coordinador.
3. **Cascada de 3 niveles**: Se comprueba el paso ordenado de Orca → HTTP → `SIN_REVISOR`.
4. **Higiene de argv y rutas**: Ningún comando expone secretos ni rutas personales hardcodeadas.
5. **Denominador**: Se actualizan las 36 ocurrencias de `[X/36]` a `[X/37]` de forma exhaustiva y verificable.

## Skills relevantes
- `testing-flows`: Regla aplicada: arneses de prueba deterministas para bucles multi-agente y aislamiento de fixtures.
- `agent-os-scripts`: Regla aplicada: portabilidad POSIX y verificación estricta de códigos de salida.

## Caja de archivos
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-136.md`

## Criterios de done
- [ ] Ocurrencias del denominador actualizadas exhaustivamente de `[X/36]` a `[X/37]`.
- [ ] Check 37 implementado certificando la detección de Orca, la inyección de spec, la cascada de 3 niveles y la limpieza de terminales.
- [ ] Validación de ausencia de secretos y rutas no portables.
- [ ] Suite completa ejecutando exitosamente los 37 checks (37/37) con 0 errores y working tree 100% limpio.
