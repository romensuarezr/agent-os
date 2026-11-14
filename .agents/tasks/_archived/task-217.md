# Task-217: Cronjobs de Monitoreo Proactivo y Briefing Matutino en WhatsApp

## Objetivo
Reparar el subsistema de cronjobs en Hermes (`~/.hermes/cron/jobs.json`) reconfigurando el modelo obsoleto hacia OmniRoute a coste $0, e implementar los cronjobs deterministas de observabilidad para la flota: briefing matutino a las 08:30 AM en WhatsApp (salud de Coolify en `<nodo-orquestacion>` y telemetría de recursos) más alertas inmediatas por excepción ante caídas de servicios críticos.

## Contexto técnico
- En la auditoría de `<nodo-inferencia>` se descubrió un job activo (`Newsletter Weekly Audit`) que falla semanalmente con `RuntimeError: HTTP 400: llama3.1:8b is not a valid model ID`.
- Hermes posee un planificador cron nativo en SQLite que soporta entrega directa al canal de mensajería (`deliver: "whatsapp"`).
- Se requiere monitorizar el estado de los 56 contenedores en `<nodo-orquestacion>` y los endpoints públicos (`romensuarez.com`, etc.) sin quemar tokens innecesarios, usando un script Bash determinista que solo envíe mensajes de texto limpios.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 40 / 2026-11-14
- **Diseño y arquitectura aprobados por**: Humano (Romén)
- **Decisiones e interfaces selladas**:
  - Corrección de `jobs.json` para usar el endpoint de OmniRoute o prompts deterministas de shell.
  - Canal oficial de entrega: WhatsApp (al chat personal de Romén).
  - Horario del briefing matutino: 08:30 AM.
  - Política por excepción: solo avisa durante el día si una web o contenedor crítico pasa a estado down/unhealthy.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `docs/sprints/sprint-40.md`
- `scripts/agent/fleet-doctor.sh` (si requiere extensión para métricas de WhatsApp)

## Criterios de done
- [x] `~/.hermes/cron/jobs.json` libre de modelos erróneos o fallidos.
- [x] Script de diagnóstico matutino de flota verificado ($0 tokens).
- [x] Job de briefing diario 08:30 AM registrado y activo en Hermes con entrega a WhatsApp.
- [x] Job de verificación de caídas críticas por excepción activo.

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
