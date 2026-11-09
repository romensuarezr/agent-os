# Task-176: Diagnóstico determinista de inoperatividad de whatsapp-bridge (causa raíz + evidencia)

## Objetivo
Ejecutar una auditoría y diagnóstico determinista, seguro y de solo lectura sobre el daemon `whatsapp-bridge` en el host / nodo de inferencia (`<nodo-inferencia>`), aislando la causa raíz exacta de su inoperatividad actual con evidencia verificable, sin aplicar modificaciones de código ni parches a ciegas. El plan de remediación se decidirá formalmente tras la entrega del reporte de diagnóstico.

## Contexto técnico
El usuario ha comunicado que el servicio `whatsapp-bridge` —componente clave para la comunicación y presencia de Hermes con el operador en el host— no está funcionando en la actualidad.
En lugar de precipitar reinicios destructivos o parches sin aislar el problema, la gobernanza de Agent OS impone una compuerta estricta: diagnosticar primero, aportar evidencia de logs y estado de sockets, identificar la causa raíz (proceso caído, fallo de dependencias Node.js, desconexión de sesión de WhatsApp/Evolution API/Baileys, o error de red) y emitir un reporte con propuestas fundamentadas.
Esta tarea se ejecuta bajo el régimen estándar de **Opción D**.

### Integración de Research Scout (T-129)
- **Alternativas detectadas y analizadas**:
  - Diagnóstico forense en el host/VPS (`systemctl --user status`, `journalctl`, `ss -tulpn`, inspección de sockets y procesos Node.js).
- **Dictamen del Relé**:
  - Directiva estricta de diagnóstico puro de solo lectura: determinar por qué no funciona y reportar causa + evidencia. Prohibido aplicar parches, modificaciones de código o reinicios arbitrarios a ciegas. El arreglo se decidirá tras la entrega del diagnóstico.
- **Notas de integración cumplidas**:
  1. Comprobado el estado del servicio systemd de usuario en el nodo de inferencia.
  2. Auditada la escucha en sockets y puertos locales (puerto `:3000` libre asignado al bridge; `:3001` ocupado por FreeLLMAPI).
  3. Extraídos eventos de log (`hermes-gateway`, `whatsapp-bridge` legacy y `bridge.log`) analizando errores y stack traces.
  4. Diagnosticada la capa de sesión de WhatsApp (`DisconnectReason.loggedOut` / 401).
  5. Publicado el informe de diagnóstico en `docs/runbooks/whatsapp-bridge-diagnostic-report.md`.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 31 / 2026-11-08
- **Diseño y arquitectura aprobados por**: Humano / Relé (Decisión Macro en Planning)
- **Decisiones e interfaces selladas**:
  - **Principio Inviolable: CERO arreglo a ciegas**: Prohibido alterar ficheros de código, editar credenciales, modificar configuraciones arbitrariamente o aplicar parches sin autorización previa del operador.
  - **Alcance estrictamente diagnóstico**: Inspección forense no destructiva de:
    - Estado de la unidad systemd de usuario (`systemctl --user status whatsapp-bridge` o equivalente).
    - Estado de procesos activos en el host (procesos `node` o contenedores asociados).
    - Inspección de sockets y puertos locales de escucha (p. ej. puerto `:3000`, según determine el diagnóstico, y socket relay E2EE).
    - Volcado y análisis de los últimos 100 eventos de logs (`journalctl --user -u whatsapp-bridge -n 100` y logs en disco si existen).
    - Estado de la sesión de mensajería (sesión de autenticación, token, QR no resuelto o error de handshake con upstream).
  - **Artefacto de entrega**: Informe técnico de diagnóstico estructurado en `docs/runbooks/whatsapp-bridge-diagnostic-report.md`.
  - **Denominador de suite**: Inmutable en **38/38** (0 errores).
- **Veredicto de diseño macro**: `APROBADO_EN_PLANNING`

## Skills relevantes
- `remote-admin`: Inspección remota no destructiva en el nodo de inferencia vía SSH/Tailscale.
- `agent-os-scripts`: Utilidades deterministas de Agent OS.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `docs/runbooks/whatsapp-bridge-diagnostic-report.md` (creación del informe técnico)
- `.agents/tasks/task-176.md`

## Criterios de done
- [x] Estado del servicio `systemd --user` y procesos activos de Node.js en el host inspeccionados con evidencia capturada.
- [x] Escucha en sockets y puertos locales (p. ej. puerto `:3000`, según determine el diagnóstico) verificados de forma determinista.
- [x] Logs recientes extraídos y analizados (`journalctl --user -u whatsapp-bridge` y ficheros de logs), documentando errores específicos o stack traces.
- [x] Estado de la sesión de autenticación y conexión con WhatsApp / backend evaluado y clasificado.
- [x] Informe técnico `docs/runbooks/whatsapp-bridge-diagnostic-report.md` publicado conteniendo:
  - Evidencia empírica de los comandos de diagnóstico ejecutados.
  - Causa raíz inequívoca identificada (o taxonomía de fallo acotada).
  - Opciones de remediación técnica y propuesta justificada para decisión del operador.
- [x] Cero mutaciones de código destructivas ejecutadas (principio de cero arreglo a ciegas cumplido).
- [x] Suite de control plane inmutable en **38/38** pasando limpia (0 errores).
- [x] Ejecutada y registrada bajo las reglas de Opción D.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `CONSENSO`
  - **Rol del revisor**: Compuerta técnica determinista (caja de archivos, tests, realidad repo, fidelidad a diseño macro).
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-11-09T18:33:47Z (vía consenso determinista Opción D)
- [x] Rama creada: `feat/T-176-whatsapp-bridge-diagnostic`
- [x] Lock activo: `.agent-session.lock`
- [x] Sesión cerrada correctamente
