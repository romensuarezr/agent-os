# Task-216: Hermes Concierge Bridge y Failover de Cuentas

## Objetivo
Implementar el módulo/skill de conserje para Hermes Agent en `<nodo-inferencia>` que actúe como interlocutor bidireccional entre el operador (en WhatsApp/Telegram) y el Coordinador Antigravity residente en el VPS: traslada prompts, retransmite consultas interactivas y compuertas (`/gate`), inyecta respuestas, gestiona failover automático entre `agy` y `agy2` ante límites de cuota, y entrega el reporte final.

## Contexto técnico
- Hermes Agent corre como servicio systemd continuo con integración de mensajería (WhatsApp bridge en puerto 3001, Telegram DM con Romén).
- Antigravity opera como el motor de ingeniería profunda en el VPS.
- El rol de Hermes es ser un "Conserje" transparente: para Antigravity, el conserje representa al usuario humano en consola; para Romén, Hermes es su asistente en WhatsApp que le consulta solo lo necesario y le entrega el progreso.
- Si la cuenta primaria (`agy`) responde con error de cuota o rate limit (HTTP 429), el conserje conmuta de inmediato a `agy2` y reintenta sin interrumpir la experiencia del usuario.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 40 / 2026-11-14
- **Diseño y arquitectura aprobados por**: Humano (Romén)
- **Decisiones e interfaces selladas**:
  - Implementación de la skill/tool `concierge` en Hermes (`~/.hermes/skills/hermes-concierge/`).
  - Capacidad de ejecutar sesiones de Antigravity en streaming o captura estructurada.
  - Intercepción de eventos de pregunta y compuerta (`/gate`) para reenvío directo a WhatsApp.
  - Lógica determinista de failover `agy` -> `agy2` ante rate limits.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `docs/sprints/sprint-40.md`
- `.agents/skills/orchestrator/SKILL.md` (documentar el conector Concierge)

## Criterios de done
- [x] Skill de conserje desplegada y registrada en Hermes (`~/.hermes/skills/hermes-concierge`).
- [x] Mecanismo de reenvío de preguntas/compuertas a WhatsApp validado.
- [x] Manejador de conmutación por cuota agotada (`agy` -> `agy2`) probado.
- [x] Trazabilidad de logs de sesión en el VPS.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `CONSENSO`
  - **Rol del revisor**: Compuerta técnica determinista (caja de archivos, tests, realidad repo, fidelidad a diseño macro).
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-11-14T09:30:00Z
- [x] Rama creada: `multi-agent`
- [ ] Lock activo: ___
- [x] Sesión cerrada correctamente
