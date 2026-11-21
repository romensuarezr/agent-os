# T-234 — Actualización de la Skill orca-cli a v1.4.268 (Bots Hermes/OpenCode, Multimodalidad y Browser Remoto)
Sprint: Sprint 44 | Estado: ⬜ Pendiente | Tamaño: S | Rama propuesta: feat/T-234-skill-orca-cli-v1-4-268 | Merge destino: multi-agent

## Diseño macro aprobado en planning
- **Sprint / Fecha**: Sprint 44 — 2026-11-23
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Actualizar `.agents/skills/orca-cli/SKILL.md` desde v1.4.258 hasta v1.4.268.
  - Documentar la gestión nativa de Orca Bots (`orca bot`), el soporte para agentes Hermes, OpenCode 2.x con *standing instructions*, Cursor y Copilot.
  - Documentar la sintaxis de adjuntos multimodales en comentarios de worktree y chats (`orca item comment --attach`).
  - Documentar las anotaciones remotas del navegador embebido sobre hosts de la flota (`orca browser`).
  - Actualizar `.agents/config/skills-manifest.yaml` reflejando la versión y capacidades actualizadas.
- **Veredicto de diseño macro**: [APROBADO_EN_PLANNING]

---

## 1. Objetivo
Dotar a todos los agentes que consulten la skill `orca-cli` de los conocimientos, sintaxis y capacidades operativas de Orca v1.4.268 para interactuar con bots, worktrees multimodales y navegadores remotos.

## 2. Contexto técnico
- Habilidad canónica: `.agents/skills/orca-cli/SKILL.md`.
- Manifiesto de skills: `.agents/config/skills-manifest.yaml`.
- Binario resuelto: `scripts/agent/lib/orca-client.sh`.

## 3. Caja de archivos
- `.agents/skills/orca-cli/SKILL.md`
- `.agents/config/skills-manifest.yaml`
- `.agents/tasks/task-234.md`
- `docs/sprints/sprint-44.md`

## 4. Plan de implementación
1. Analizar los comandos y parámetros incorporados en Orca v1.4.268.
2. Actualizar `SKILL.md` con ejemplos ejecutables deterministas para bots, comentarios multimodales y navegador remoto.
3. Actualizar la descripción y versión en `skills-manifest.yaml`.
4. Ejecutar validaciones estáticas de sintaxis en la skill.

## 5. Criterios de aceptación
- `SKILL.md` documenta con precisión las novedades de v1.4.268 sin referencias obsoletas a v1.4.258.
- `skills-manifest.yaml` queda sincronizado.
