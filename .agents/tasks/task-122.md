# Task-122: Extensión de suite con Check 34 para deliberación y digests

## Objetivo
Extender la suite canónica de validación `tests/validate-control-plane.sh` implementando el **Check 34**, actualizando el denominador de la suite de `[X/33]` a `[X/34]` (33 ocurrencias existentes + el nuevo check 34), y certificando de forma determinista y sin red las garantías operativas de Sprint 20: mock/offline safety en deliberación, inventario acotado, redacción obligatoria en digests, integración en `close-task.sh`, y frontera portable (cero secretos o literales de infraestructura).

## Contexto técnico
Sprint 20 ha introducido dos nuevos scripts y modificaciones de flujo clave:
1. `scripts/agent/deliberate-plan.sh`: Motor de deliberación determinista entre Coder y Revisor.
2. `scripts/agent/design-digest.sh`: Generador histórico de decisiones de diseño con redacción obligatoria.
3. `scripts/agent/close-task.sh`: Integración de `design-digest.sh` en el cierre de tareas (fail-closed).
4. `.agents/workflows/session-start.md`: Fase 3.4 y 3.5 con Executive Design Digest y preservación de autorización humana obligatoria.

El Check 34 debe validar deterministamente y sin red:
- **`deliberate-plan.sh`**:
  - CLI `--help` conforme.
  - Comportamiento offline/pasarela caída: ante un endpoint inaccesible degrada inmediatamente a veredicto `SIN_REVISOR` con exit code 0.
  - Honestidad: un mock/offline nunca emite `CONSENSO` de forma simulada en una sesión real.
  - Inventario acotado: la carga enviada a deliberación no excede los límites previstos (< 4KB).
  - Configuración de routing: `.agents/config/routing-policy.yaml` tiene configurado `timeout: 5` y `max_correction_rounds: 1`.
- **`design-digest.sh`**:
  - CLI `--help` conforme.
  - Generación de estructura markdown estándar con las 5 secciones requeridas (Objetivo, Decisiones, Ajustes/Arbitraje, Ficheros, Skills).
  - Fallback en frío determinista cuando no existe sesión caliente previa (`git diff HEAD~1` y `git log -1`).
  - Redacción obligatoria vía `scripts/agent/lib/redact.sh`: cualquier secreto inyectado en el digest resulta redactado en el archivo final.
  - Semántica fail-closed: argumentos incorrectos o fallos en el pipeline abortan con código > 0 sin persistir artefactos corruptos.
- **`close-task.sh`**:
  - Presencia del bloque de invocación a `design-digest.sh` y staging atómico del digest generado.
- **`session-start.md`**:
  - Presencia de la fase de deliberación y el Executive Design Digest en Fase 3.5, con la regla estricta de que la única autorización de ejecución es el `APROBADO` o `Y` del operador humano.
- **Frontera portable y regla de alcance**:
  - Cero credenciales, rutas personales o IPs fijas en los nuevos componentes (cumplimiento Check 22).
  - Cualquier defecto detectado por el check fuera de la caja autorizada debe reportarse como tarea nueva, sin mutaciones fuera de scope.

## Skills relevantes
- `testing-flows`: Arquitectura de pruebas deterministas no destructivas para la suite de control plane.
- `agent-os-scripts`: Convención CLI estándar (`lib/cli-help.sh`), estándares POSIX y robustez en bash.
- `infisical-secrets`: Validación de redacción obligatoria (`lib/redact.sh`) y frontera portable.

## Caja de archivos
Archivos autorizados para modificación:
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-122.md`

## Criterios de done
- [ ] Ocurrencias del denominador en `tests/validate-control-plane.sh` actualizadas de `[X/33]` a `[X/34]` (33 ocurrencias existentes).
- [ ] Check 34 implementado validando deterministamente `deliberate-plan.sh`, `design-digest.sh`, `close-task.sh` y `session-start.md`.
- [ ] Validación de que la invocación offline o con pasarela caída degrada a `SIN_REVISOR` con exit code 0.
- [ ] Validación de redacción obligatoria probada mediante inyección de credencial simulada procesada por `design-digest.sh`.
- [ ] Suite completa `bash tests/validate-control-plane.sh` ejecutada pasando 34/34 checks exitosamente (0 errores).
- [ ] Cero regresiones y frontera portable (Check 22) intacta.
