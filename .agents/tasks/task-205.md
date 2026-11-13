# Task-205: Protocolo dinámico de modelos/cuotas, matriz de esfuerzo y reporte de rendición de cuentas

## Objetivo
Instruir formalmente al Coordinador en `.agents/profiles/coordinator.md`, `.agents/rules/global/coordinator-boot.md` y `.agents/skills/orchestrator/SKILL.md` para que descubra dinámicamente los modelos, niveles de esfuerzo y cuotas vivas del entorno en tiempo de ejecución (eliminando listas estáticas obsoletas), aplique la matriz de enrutamiento por dificultad × cuota y emita obligatoriamente un informe transparente de rendición de cuentas de modelos y arneses al consolidar el trabajo.

## Contexto técnico
- En entornos multi-modelo como Antigravity u OpenCode, los catálogos y nombres comerciales cambian con frecuencia (ej. niveles de esfuerzo en familias Flash o modos de Thinking en Sonnet/Opus).
- Asumir nombres estáticos en prompts provoca llamadas fallidas o desperdicio de cuotas caras en código mecánico.
- El Coordinador debe inspeccionar activamente las capacidades del entorno (`swarm action: models`, configuraciones de pasarelas locales o proveedores) y cruzar la dificultad de la tarea con las cuotas restantes para elegir el nivel de esfuerzo óptimo.

### Research integrado (`docs/sprints/sprint-38-research.md` → `### T-205`)
- **Scout OSS**: Desacoplamiento dinámico de catálogos y patrones de iniciador de agentes (`@oh-my-pi/pi-catalog`).
- **Veredicto**: `Desarrollo a medida justificado`.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 38 / 2026-11-13
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - Actualizar `.agents/profiles/coordinator.md` con la cláusula de "Descubrimiento Dinámico de Capacidades": prohibido asumir listas fijas; obligación de consultar capacidades y cuotas vivas del arnés.
  - Definir la matriz de enrutamiento por Dificultad × Cuota:
    - Baja (mecánica/boilerplate/JSON/tests unitarios): modelo de menor esfuerzo y mayor cuota disponible (`low` effort).
    - Media (integración/server actions/rutas dinámicas): modelo de esfuerzo medio (`medium` effort).
    - Alta (arquitectura/seguridad/refactors): modelo de razonamiento profundo (`thinking` / `pro` / `high`).
  - Actualizar `.agents/rules/global/coordinator-boot.md` y `.agents/skills/orchestrator/SKILL.md` incorporando la obligación de emitir el "Informe de Enrutamiento de Modelos y Arneses" en la consolidación de tareas.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/profiles/coordinator.md`
- `.agents/rules/global/coordinator-boot.md`
- `.agents/skills/orchestrator/SKILL.md`
- `.agents/config/orchestration-playbooks.yaml`
- `.agents/tasks/task-205.md`

## Criterios de done
- [ ] Perfil `coordinator.md` actualizado con cláusula de descubrimiento dinámico y matriz de dificultad × cuota.
- [ ] Regla `coordinator-boot.md` y skill `orchestrator` actualizadas con el protocolo de sondeo dinámico y emisión del informe de rendición de cuentas.
- [ ] Catálogo `orchestration-playbooks.yaml` enriquecido con la directiva de selección dinámica de esfuerzo.
- [ ] Suite `tests/validate-control-plane.sh` pasando limpia sin regresiones (38/38 checks verdes).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] Rama de trabajo creada
- [ ] Verificación con verify-goal.sh
- [ ] Cierre y merge formalizado
