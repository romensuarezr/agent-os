# Task-157: Piloto de autonomía acotada con canal directo Agente-Relé y medición de intervenciones

## Objetivo
Implementar y ejecutar un piloto de autonomía acotada sobre una tarea testigo representativa utilizando un canal directo agente → relé (eliminando la necesidad de que el operador humano copie y pegue informes o veredictos de texto), con compuertas estrictas de aborto fail-closed (vuelta obligatoria al modo manual ante fallos del canal, `SIN_REVISOR` o desviaciones del macro) y medición cuantitativa de las intervenciones humanas frente a la línea base actual (~3 por tarea), documentando el informe formal en `docs/sprints/sprint-28-autonomy-pilot-report.md`.

## Contexto técnico
El flujo operativo tradicional de Agent OS exige que el operador humano intervenga manualmente aproximadamente 3 veces por cada tarea:
1. **Fase 3.5**: El usuario recibe el resumen de plan, revisa el veredicto del revisor y escribe/pega `T-XXX: APROBADO...`.
2. **Paso 6 (Pre-Merge)**: El agente genera el reporte de implementación y diffstat; el usuario escribe/pega `T-XXX: APROBADO por el relé (Paso 6)...`.
3. **Cierre**: Autorización para merge a `multi-agent`, borrado de rama y ejecución de `close-task.sh`.

Bajo el modelo de gobernanza de dos niveles (T-147), el diseño macro queda sellado en planning. Para reducir la sobrecarga cognitiva sin comprometer la seguridad del control plane:
- Se implementa un canal directo y determinista Agente → Relé (diseñado en planning con opciones de fichero marcador/señal local o interacción estructurada en UI).
- Se establecen compuertas de aborto inmediatas: si el canal no responde, si la pasarela degrada a `SIN_REVISOR`, si los centinelas detectan mutación o si el plan diverge del diseño macro aprobado en planning, el sistema aborta de inmediato la autonomía y regresa al protocolo interactivo clásico.
- Se evalúa de forma estricta en 1 sola tarea antes de cualquier consideración de generalizar a sprints completos.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 28 / 2026-11-02
- **Diseño y arquitectura aprobados por**: Humano / Relé (Sprint Planning Sprint 28)
- **Decisiones e interfaces selladas**:
  - Implementar el mecanismo de canal directo seleccionado en planning (ej: helper determinista `scripts/agent/rele-signal.sh` con fichero de señal en `.agents/context/` o consulta asistida sin copiado manual de informes).
  - Criterios de aborto rigurosos e inviolables:
    - Fallo de lectura del canal o timeout de señal → ABORTO INMEDIATO.
    - Veredicto `SIN_REVISOR` del revisor → ESCALADO OBLIGATORIO A HUMANO (jamás auto-aprobado).
    - Detección de mutación en árbol por centinelas PRE/POST → REVERSIÓN Y ESCALADO A HUMANO.
    - Desviación de la caja de archivos o diseño macro pactado → ABORTO.
  - Puertas humanas preservadas intactas:
    - Diseño macro en sprint planning (sellado previo).
    - `ESCALADO_A_HUMANO` (siempre interactivo).
    - Promoción a `main` (exclusivamente manual).
  - Medición cuantitativa: registrar número exacto de intervenciones del usuario (reducción vs. baseline ~3), comprobando 0 degradaciones silenciosas, 0 fugas de alcance y suite en verde (37/37).
  - Elaboración de informe en `docs/sprints/sprint-28-autonomy-pilot-report.md`.
  - Aserción en Check 34 de `tests/validate-control-plane.sh`.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `agent-os-scripts`: Integración con workflows de sesión y scripts de gobernanza.
- `orchestrator`: Gestión de compuertas y señalización multi-agente / relé.
- `testing-flows`: Aserciones de control plane y verificación de compuertas de seguridad.

## Caja de archivos
- `scripts/agent/rele-signal.sh` (si aplica al canal elegido)
- `.agents/workflows/session-start.md`
- `docs/sprints/sprint-28-autonomy-pilot-report.md`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-157.md`

## Criterios de done
- [ ] Canal directo Agente → Relé implementado y probado con compuertas deterministas.
- [ ] Protocolo de aborto fail-closed verificado ante fallos, `SIN_REVISOR` y desviaciones.
- [ ] Tarea testigo completada bajo el canal directo sin copiado manual de informes ni veredictos por el usuario.
- [ ] Métrica de intervenciones calculada y comparada cuantitativamente contra la línea base (~3 por tarea).
- [ ] Informe formal documentado en `docs/sprints/sprint-28-autonomy-pilot-report.md`.
- [ ] Suite de control plane pasando limpia (37/37) con 0 errores.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido
- [ ] Rama creada
- [ ] Cierre y merge autorizado por el relé
