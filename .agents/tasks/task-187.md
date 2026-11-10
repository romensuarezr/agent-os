# Task-187: Formalización de skill ui-critique para auditoría y revisión de interfaces en satélites

## Objetivo
Formalizar la nueva habilidad estándar `.agents/skills/ui-critique/SKILL.md` (en español) orientada a la auditoría heurística y revisión estética, técnica y de accesibilidad de interfaces frontend en proyectos satélites (React / Tailwind / Next.js).

## Contexto técnico
El roadmap contemplaba el protocolo "Impeccable critique: protocolo de auditoría y revisión de interfaces UI para satélites". En el scouting determinista de Sprint 33 se identificaron patrones en herramientas como `designlint-skill` y `overhaul-ui`. Formalizar esta habilidad permite que los agentes que operan en proyectos satélite con interfaces de usuario sigan un checklist determinista y riguroso antes de proponer cambios de diseño o abrir PRs.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 33 / 2026-11-10
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Crear `.agents/skills/ui-critique/SKILL.md` con frontmatter YAML estándar (`name`, `description`).
  - Definir dimensiones de evaluación:
    1. Jerarquía tipográfica y escala modular.
    2. Consistencia espacial y sistema de espaciado (spacing tokens).
    3. Contraste de color y accesibilidad WCAG AA.
    4. Enfoque DRY en componentes UI y variantes reutilizables.
    5. Adaptabilidad responsive y comportamiento en breakpoints.
  - Registrar la skill en `.agents/config/skills-manifest.yaml`.
  - Asegurar que `validate-control-plane.sh` (Check 1 y Check 5) la verifique limpiamente.
  - Denominador de suite inmutable en 38/38.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/skills/ui-critique/SKILL.md`
- `.agents/config/skills-manifest.yaml`
- `.agents/tasks/task-187.md`

## Criterios de done
- [ ] `.agents/skills/ui-critique/SKILL.md` creada siguiendo el estándar de skills.
- [ ] Checklist heurístico de 5 dimensiones documentado con ejemplos.
- [ ] Registrada en `.agents/config/skills-manifest.yaml`.
- [ ] Suite de validación `tests/validate-control-plane.sh` 38/38 en verde.
- [ ] `locator-hygiene.sh` 100% limpio.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
- [ ] Plan presentado al usuario
- [ ] APROBADO recibido
- [ ] Rama creada
- [ ] Lock activo: .agent-session.lock
- [ ] Sesión cerrada correctamente
