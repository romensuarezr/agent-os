# Task-182: Remediación planificada y rotación de FreeLLMAPI en Hermes (solo scripts, sin valores, gate HITL)

## Objetivo
Ejecutar la rotación programada y formal de credenciales de FreeLLMAPI en la pasarela de inferencia de Hermes (Opción B acordada tras la remediación provisional del incidente 401), implementando un procedimiento determinista basado estrictamente en scripts, sin imprimir valores de secretos en pantalla ni logs, y supeditado a una compuerta HITL con confirmación humana explícita previa al reinicio del servicio.

## Contexto técnico
El incidente 401 en Hermes (`docs/runbooks/incident-hermes-401-remediation.md`) requirió la reversión provisional de la raíz `model:` de `~/.hermes/config.yaml` hacia OmniRoute para restablecer el servicio de mensajería de forma inmediata. Se acordó diferir la rotación formal del proveedor FreeLLMAPI al Sprint 32 como una tarea planificada con guardarraíles estrictos de seguridad.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 32 / 2026-11-10
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - **Maquinaria de scripts**: La rotación de la clave/token en la base de datos de FreeLLMAPI y la configuración de Hermes debe ejecutarse exclusivamente mediante scripts deterministas que lean valores vía stdin o ficheros efímeros con permisos 600.
  - **Frontera portable y secreto cero**: Queda terminantemente prohibido imprimir o reflejar claves o tokens en stdout, stderr, logs, commits, tareas o runbooks.
  - **Compuerta HITL obligatoria**: El agente DEBE detenerse y solicitar la ventana operativa al operador, requiriendo su "OK" explícito antes de aplicar modificaciones destructivas en la configuración o reiniciar `hermes-gateway.service`.
  - **Verificación rigurosa de liveness**:
    1. Ejecución de `hermes -z ping` respondiendo `pong`.
    2. Llamada real de inferencia completada exitosamente sin códigos 401 ni excepciones de autenticación.
    3. Inspección forense de logs de `hermes-gateway.service` acreditando operatividad sostenida y conexión estable con WhatsApp bridge y Telegram.
  - **Documentación de cierre**: Actualizar `docs/runbooks/incident-hermes-401-remediation.md` reflejando la resolución definitiva de la Opción B con fecha, evidencia y hashes redactados.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Caja de archivos
Archivos autorizados para modificación:
- `docs/runbooks/incident-hermes-401-remediation.md`
- `scripts/agent/lib/` (scripts deterministas de remediación de secretos sin valores)
- `.agents/tasks/task-182.md`

## Criterios de done
- [x] Script determinista de rotación de token de FreeLLMAPI operativo sin fugas de secretos en salida estándar (`scripts/agent/lib/rotate-freellmapi-token.sh`).
- [x] Compuerta HITL ejecutada en el chat con solicitud de ventana y aprobación humana explícita antes de reiniciar el gateway.
- [x] Configuración de Hermes actualizada apuntando al proveedor verificado sin incidencias de autenticación 401.
- [x] Verificación de liveness (`hermes -z ping` y llamada real de inferencia) 100% exitosa.
- [x] Runbook `docs/runbooks/incident-hermes-401-remediation.md` actualizado con evidencia técnica y redacción determinista.
- [x] Suite `tests/validate-control-plane.sh` 38/38 en verde y `locator-hygiene.sh` limpio.

## Diagnóstico determinista y mapeo de consumidores
> Registro técnico verificado vía sonda determinista en `<nodo-inferencia>` (2026-11-10 19:30 UTC):

1. **Estado de Claves**:
   - `freeapi.db` (tabla `settings`): `unified_api_key` presente (longitud 59, prefijo `freellmapi-***`).
   - `~/.hermes/config.yaml` (`custom_providers`): `api_key` presente con valor truncado de longitud 7 (`free***`), detonante directo del error HTTP 401 al invocar el proveedor.
   - `~/.hermes/config.yaml` (`model` raíz): `provider: custom:omniroute`, `default: auto/best-coding` (estable, operativo).

2. **Consumidores activos de la `unified_api_key`**:
   - **OpenCode** (estación de trabajo local): Configurado con `model: freellmapi/auto` y `options.apiKey` vinculada a la clave activa de 59 caracteres en `~/.config/opencode/opencode.json`.
   - **Hermes Agent** (`<nodo-inferencia>`): Declarado en `custom_providers.freellmapi`.
   - **Bóveda Infisical**: Variable `FREELLMAPI_API_KEY` registrada en `/shared` (entorno dev).
   - **Agent OS Fleet**: Inventariado formalmente en `.agents/config/fleet.yaml` con consumidores `[opencode, hermes-agent]`.

3. **Estrategia acordada para la Ventana HITL**:
   - Modalidad B: Generación de clave unificada nueva (`freellmapi-<hex48>`).
   - Conexión y sincronización de `custom_providers.freellmapi` en Hermes sin conmutar la raíz `model:` (OmniRoute se mantiene por defecto).
   - Puerta de control: Publicación de la rama `feat/T-182-rotacion-freellmapi-hermes-hitl` para auditoría previa del relé antes de otorgar el OK y abrir la ventana.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `CONSENSO`
  - **Rol del revisor**: Compuerta técnica determinista (caja de archivos, tests, realidad repo, fidelidad a diseño macro).
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-11-10T19:22:59Z (Opción D - Desatendida, Aprobado en Planning Sprint 32 con condición de Gate HITL)
- [x] Rama creada: feat/T-182-rotacion-freellmapi-hermes-hitl
- [x] Lock activo: .agent-session.lock
- [ ] Sesión cerrada correctamente
