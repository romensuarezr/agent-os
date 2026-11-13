# Task-207: Regla global de Priorización por Retorno Económico (ROI-First) y sesgo Anti-Activity Theater en el Coordinador

## Objetivo
Crear la regla global `.agents/rules/global/roi-first-prioritization.md` e incorporar sus directivas en `.agents/profiles/coordinator.md` y `.agents/rules/global/coordinator-boot.md`. El Coordinador debe asumir un perfil proactivo orientado a resultados económicos tangibles (ingresos, facturación, conversión, captación de leads y tracción real), clasificando las tareas en tres tiers de retorno de negocio (Tier 1: Revenue & Conversion, Tier 2: Distribution & Trust, Tier 3: Supporting) y emitiendo proactivamente en el saludo y diagnóstico inicial sugerencias para priorizar el trabajo con mayor retorno comercial frente a la ejecución secuencial plana.

## Contexto técnico
- En proyectos satélite comerciales o de producto (ej. `annascheer-web`), los agentes tienden a incurrir en "Automation Theater": invertir miles de tokens en tareas cosméticas o secundarias (paddings, reescritura de docs, páginas estáticas no transaccionales) antes de implementar los embudos críticos de captación y venta (contacto, reservas, pasarela de pago).
- La comunidad de agentes autónomos y la industria de ingeniería lean recomiendan un **sesgo anti-actividad** (*Anti-Activity Bias*) evaluando la relación Valor de Negocio vs Esfuerzo (BV/E: Business Value vs Effort).
- El Coordinador debe poseer criterio económico para detectar cuándo una tarea desbloquea facturación inmediata y sugerir al operador abordarla de forma prioritaria.

### Research integrado (`docs/sprints/sprint-38-research.md` → `### T-207`)
- **Scout OSS & Industry**: Samuel J. Woods (*Profit Infrastructure*), Mastra AI (*Bounded Workflows*), matrices Value-First y ROI Index.
- **Veredicto**: `Desarrollo a medida justificado` dentro de las reglas y perfiles nativos de Agent OS.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 38 / 2026-11-13
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - Crear regla global `.agents/rules/global/roi-first-prioritization.md` que formaliza:
    - Principio de Infraestructura de Beneficio y sesgo Anti-Actividad (*Anti-Activity Bias*).
    - Matriz de 3 Tiers (Tier 1: Revenue & Conversion, Tier 2: Distribution & Trust, Tier 3: Supporting).
    - Cálculo cualitativo del Índice de Retorno (ROI Index = Impacto × Confianza / Esfuerzo).
  - Actualizar `.agents/profiles/coordinator.md` dotándolo de criterio proactivo de negocio y asesoramiento estratégico de backlog.
  - Actualizar `.agents/rules/global/coordinator-boot.md` para incluir el bloque de "💡 Sugerencia Proactiva de Retorno de Negocio" en el diagnóstico de inicio de sesión.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/rules/global/roi-first-prioritization.md` (nuevo)
- `.agents/rules/global/coordinator-boot.md`
- `.agents/profiles/coordinator.md`
- `scripts/agent/assets-manifest.txt`
- `docs/sprints/sprint-38.md`
- `.agents/tasks/task-207.md`

## Criterios de done
- [x] Regla `roi-first-prioritization.md` creada con principios, tiers y fórmula de priorización económica.
- [x] Perfil `coordinator.md` actualizado con el rol de priorización por valor de negocio y sesgo anti-actividad.
- [x] Regla `coordinator-boot.md` enriquecida con sugerencia proactiva de retorno económico en el diagnóstico inicial.
- [x] `assets-manifest.txt` actualizado para distribuir la nueva regla en `sync.sh`.
- [x] Suite `tests/validate-control-plane.sh` pasando limpia sin regresiones (38/38 checks verdes).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
- [x] Plan presentado al usuario (Fase 3.5)
- [x] Rama de trabajo creada
- [x] Verificación con verify-goal.sh
- [x] Cierre y merge formalizado