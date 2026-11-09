# Task-176: Diagnóstico determinista de inoperatividad de whatsapp-bridge (causa raíz + evidencia)

## Objetivo
Ejecutar una auditoría y diagnóstico determinista, seguro y de solo lectura sobre el daemon `whatsapp-bridge` en el host / nodo de inferencia (`<nodo-inferencia>`), aislando la causa raíz exacta de su inoperatividad actual con evidencia verificable, sin aplicar modificaciones de código ni parches a ciegas. El plan de remediación se decidirá formalmente tras la entrega del reporte de diagnóstico.

## Contexto técnico
El usuario ha comunicado que el servicio `whatsapp-bridge` —componente clave para la comunicación y presencia de Hermes con el operador en el host— no está funcionando en la actualidad.
En lugar de precipitar reinicios destructivos o parches sin aislar el problema, la gobernanza de Agent OS impone una compuerta estricta: diagnosticar primero, aportar evidencia de logs y estado de sockets, identificar la causa raíz (proceso caído, fallo de dependencias Node.js, desconexión de sesión de WhatsApp/Evolution API/Baileys, o error de red) y emitir un reporte con propuestas fundamentadas.
Esta tarea se ejecuta bajo el régimen estándar de **Opción D**.

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
- [ ] Estado del servicio `systemd --user` y procesos activos de Node.js en el host inspeccionados con evidencia capturada.
- [ ] Escucha en sockets y puertos locales (p. ej. puerto `:3000`, según determine el diagnóstico) verificados de forma determinista.
- [ ] Logs recientes extraídos y analizados (`journalctl --user -u whatsapp-bridge` y ficheros de logs), documentando errores específicos o stack traces.
- [ ] Estado de la sesión de autenticación y conexión con WhatsApp / backend evaluado y clasificado.
- [ ] Informe técnico `docs/runbooks/whatsapp-bridge-diagnostic-report.md` publicado conteniendo:
  - Evidencia empírica de los comandos de diagnóstico ejecutados.
  - Causa raíz inequívoca identificada (o taxonomía de fallo acotada).
  - Opciones de remediación técnica y propuesta justificada para decisión del operador.
- [ ] Cero mutaciones de código destructivas ejecutadas (principio de cero arreglo a ciegas cumplido).
- [ ] Suite de control plane inmutable en **38/38** (0 errores).
- [ ] Ejecutada y registrada bajo las reglas de Opción D.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `[CONSENSO | REVISADO_CON_CAMBIOS | ESCALADO_A_HUMANO | SIN_REVISOR]`
  - **Rol del revisor**: Compuerta técnica determinista (caja de archivos, tests, realidad repo, fidelidad a diseño macro).
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
