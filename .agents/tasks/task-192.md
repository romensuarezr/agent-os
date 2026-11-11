# Task-192: Homologación integral de actualización de tooling upstream

## Objetivo
Homologar de forma unificada las 5 herramientas de la flota detectadas con versiones upstream nuevas (OpenCode CLI v2.2.7, Hermes v0.23.1, Orca v1.4.256, Infisical CLI v0.167.8, Glances v4.5.9), impactando directamente los activos vivos del core: skills activas en `.agents/skills/`, perfiles declarativos en `.agents/profiles/` y sondas de diagnóstico deterministas en `scripts/agent/fleet-doctor.sh`.

## Contexto técnico
- La sonda de automejora del Paso 1c detectó 5 versiones upstream disponibles.
- Siguiendo la regla de gobernanza de Agent OS ("Criterio de Valor para Tareas de Actualización de Tooling"), está prohibido el bump cosmético vacío. La actualización debe reflejarse en los activos vivos que los agentes cargan en su prompt de contexto y en las sondas de verificación determinista de la flota.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 35 / 2026-11-11
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - Agrupación integral de las 5 actualizaciones en una única tarea M.
  - Actualización de las skills correspondientes en `.agents/skills/<herramienta>/SKILL.md` documentando nuevas capacidades, subcomandos y sintaxis.
  - Actualización de perfiles declarativos si procede (`.agents/profiles/`).
  - Verificación y ajuste de sondas en `scripts/agent/fleet-doctor.sh` para compatibilidad determinista.
  - Cero paquetes mutados en caliente sin verificación previa; actualización controlada.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/skills/tooling-advisor/SKILL.md`
- `.agents/skills/infisical-secrets/SKILL.md`
- `.agents/skills/coolify-admin/SKILL.md`
- `.agents/skills/remote-admin/SKILL.md`
- `.agents/skills/orchestrator/SKILL.md`
- `.agents/profiles/*.yaml` y `.agents/profiles/*.md`
- `scripts/agent/fleet-doctor.sh`
- `scripts/agent/check-tooling-updates.sh`
- `docs/sprints/sprint-35.md`

## Criterios de done
- [ ] Skills activas de herramientas actualizadas con directivas de uso, flags y patrones vigentes.
- [ ] Sondas de `fleet-doctor.sh` adaptadas para validar las nuevas versiones sin advertencias falsas.
- [ ] Sonda `check-tooling-updates.sh` sincronizada con los nuevos baselines instalados.
- [ ] La suite de validación `tests/validate-control-plane.sh` pasa 38/38 checks verdes.

## Estado de aprobación y deliberación
- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido en planning
- [ ] Rama de trabajo activa
- [ ] Lock activo: —
- [ ] Tarea cerrada y verificada
