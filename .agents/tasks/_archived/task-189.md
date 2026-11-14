# Task-189: Hardening determinista de sprint-planning.md y unificación del régimen Desatendida

## Objetivo
Transformar `sprint-planning.md` en un workflow ejecutable de forma autónoma por cualquier agente o runtime (incluyendo OpenCode, Hermes o modelos ligeros), eliminando bloqueos y transferencias indebidas de carga al usuario mediante una directiva imperativa de autoejecución, un nuevo Paso 3c de síntesis determinista, bifurcación explícita Core vs Satélite y queries deterministas en Paso 5. Además, unificar la nomenclatura del régimen operativo sustituyendo «Opción D» por «Desatendida» en los workflows vivos y contratos, conservando la referencia histórica.

## Contexto técnico
- Durante el arranque del Sprint 34 con OpenCode, se observaron dos fallos de usabilidad:
  1. OpenCode leyó pasivamente `@.agents/workflows/sprint-planning.md` y preguntó al usuario qué hacer debido al tono descriptivo del frontmatter.
  2. En el Paso 5, al ver que `roadmap.md` no tenía tareas desglosadas con etiqueta "Sprint 34", solicitó al usuario que definiera las tareas (4 opciones abiertas), violando el principio de autonomía asistida.
- La nomenclatura «Opción D» genera confusión terminológica y debe renombrarse a «Desatendida» con compuerta limpia A/B (`A) Desatendida / B) Tarea a tarea (Clásico)`), manteniendo una nota de alias histórico para compatibilidad con la suite de control plane (`grep -q "Opción D"`).

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 34 / 2026-11-11
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - Directiva imperativa de ejecución en cabecera y frontmatter de `sprint-planning.md`.
  - Nuevo Paso 3c determinista: Cosecha y Síntesis de 3–5 tareas candidatas antes de investigación técnica.
  - Distinción explícita de repositorio Core vs Satélite (omisión de MVP tracker en Core, categorías específicas).
  - Queries acotadas y deterministas en Paso 5 con `searxng-client.sh`.
  - Renombre de régimen: «Opción D» → «Desatendida» en `session-start.md`, `session-close.md`, `sprint-planning.md`, `AGENTS.md` y `.agents/templates/sprint-contract-template.md` (o templates relevantes). La compuerta debe ser: `A) Desatendida / B) Tarea a tarea (Clásico)`. Nota de compatibilidad histórica preservada.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/workflows/sprint-planning.md`
- `.agents/workflows/session-start.md`
- `.agents/workflows/session-close.md`
- `AGENTS.md`
- `.agents/templates/sprint-contract-template.md` (o plantillas de acta de sprint equivalentes)
- `docs/sprints/sprint-34.md`

## Criterios de done
- [x] Frontmatter y cabecera de `sprint-planning.md` incluyen directiva imperativa que ordena ejecutar pasos 1 al 7 de inmediato.
- [x] Se implementa el Paso 3c determinista: síntesis autónoma de 3–5 tareas candidatas (S/M/L) previo al Paso 5.
- [x] Se incorpora regla de repositorio Core vs. Satélite para no buscar `MVP-TRACKER.md` en el Core.
- [x] Paso 5 define queries técnicas acotadas para `searxng-client.sh` o declara explícitamente "Investigación web no requerida" si son cambios puramente internos.
- [x] Se renombra «Opción D» a «Desatendida» en los workflows y `AGENTS.md`, con la compuerta limpia A/B y nota de alias histórico.
- [x] La suite de validación `tests/validate-control-plane.sh` pasa las comprobaciones pertinentes sin regresiones.

## Estado de aprobación y deliberación
- [x] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: CONSENSO
  - **Rol del revisor**: Compuerta técnica determinista.
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-11-11 09:55 UTC
- [x] Rama creada: `sprint-34`
- [x] Lock activo: —
- [x] Sesión cerrada correctamente
