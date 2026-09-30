# Sprint 14 — Automejora y Confianza

**Período**: 2026-10-01 → 2026-10-10  
**Objetivo**: Eje doble "Automejora y Confianza":
1. Protocolo determinista de automejora procedimental (*Self-Improvement Distillation*), codificando la regla global de destilación con paso de autoreflexión en `session-close.md`, umbral 3x, captura en vivo (*live-capture*) y edición en caliente de documentos vivos (*retrospective*), asegurando herencia a proyectos satélites vía `install.sh`/`sync.sh`.
2. Escudo de confianza y seguridad en la flota: port de patrones estáticos de NVIDIA SkillSpector (`scripts/agent/inspect-skills.sh` / skill `skill-inspector`) en modo 100% estático determinista sin LLM (cero tokens) ni dependencias pesadas de runtime, blindando el catálogo contra prompt injection, tool poisoning y código peligroso.
3. Calidad y DX del satélite: resolución de asimetría `--path` en `audit-repo.sh`, armonización de encabezados en `roadmap.md` eliminando falsos positivos en repos satélites vírgenes, guidance explícito post-instalación de working tree en `install.sh`, y formalización de la gestión segura de secretos (Infisical) en la plantilla de onboarding de satélites.

---

## Estado
🟡 En curso

---

## Tareas del Sprint

| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| T-091 | Regla de destilación y automejora procedimental (Self-Improvement Distillation) | Gobernanza / Core | M | ✅ Completada | — | [.agents/tasks/task-091.md](.agents/tasks/task-091.md) |
| T-092 | Fix consistencia de secciones en `roadmap.md` y `audit-repo.sh` (HIGH) | Bug del sistema / DX | S | ✅ Completada | — | [.agents/tasks/task-092.md](.agents/tasks/task-092.md) |
| T-093 | Port de patrones estáticos de SkillSpector adaptado a `.agents/skills/` | Seguridad / Confianza | M | 🟡 En curso | — | [.agents/tasks/task-093.md](.agents/tasks/task-093.md) |
| T-094 | Unificación de firma CLI con soporte `--path` en `audit-repo.sh` | DX / Universalización | S | ⬜ Pendiente | — | [.agents/tasks/task-094.md](.agents/tasks/task-094.md) |
| T-095 | Sección de secretos (Infisical) en plantilla de onboarding del satélite | Gobernanza / Seguridad | S | ⬜ Pendiente | — | [.agents/tasks/task-095.md](.agents/tasks/task-095.md) |
| T-096 | Guidance operativo del working tree post-instalación en `install.sh` | DX / Gobernanza | S | ⬜ Pendiente | — | [.agents/tasks/task-096.md](.agents/tasks/task-096.md) |

---

## Requisitos de Implementación y Restricciones Arquitectónicas

1. **Condición Obligatoria para T-093 (DoD Mandatorio)**:
   - El port será **ÚNICAMENTE de patrones estáticos (regex/AST)** a script bash determinista (`scripts/agent/inspect-skills.sh`), siempre en modo estático sin LLM (cero tokens de inferencia).
   - **PROHIBIDO** vendar o empaquetar el paquete Python completo de SkillSpector (requiere Python 3.12+, violando la portabilidad del core).
   - Modelo de referencia: Ejecución CI en modo `--no-llm`, determinista, sin dependencias pesadas y con baseline de supresión de falsos positivos/ruido histórico.
2. **Requisito de Herencia para T-091**:
   - La regla global debe ubicarse en `.agents/rules/` y el gatillo en `.agents/workflows/session-close.md`.
   - Propagación automática garantizada a satélites mediante `install.sh` y `sync.sh`.
   - Integración de los 5 patrones comunitarios: *self-reflection* (3 preguntas al cierre), umbral 3x anti-ruido, *retrospective* en documentos vivos (sin crear silos muertos de "lecciones aprendidas"), *live-capture* durante ejecución y promoción humana (*draft* → validación explícita).
3. **Compatibilidad Estructural en T-092 y T-094**:
   - `audit-repo.sh` debe aceptar sinónimos canónicos (`## En curso`/`## En progreso`, `## Completado`/`## Completado recientemente`, `## Próximo`/`## Backlog`) sin advertencias espurias sobre plantillas estándar.
   - `--path` en `audit-repo.sh` debe ser idempotente y coherente con `audit-child.sh` y `setup-profiles.sh`.
4. **Validación Continua**:
   - Toda tarea debe superar `tests/validate-control-plane.sh` (12/12) y mantener working tree limpio.

---

## Criterios de Cierre del Sprint

- [ ] Las 6 tareas (T-091 a T-096) completadas con task files individuales en `.agents/tasks/`.
- [ ] `tests/validate-control-plane.sh` 12/12 sin regresiones.
- [ ] Regla de automejora y workflow de cierre de sesión probados y documentados.
- [ ] Script determinista de inspección de skills operativo en modo estático (0 tokens).
- [ ] Plantilla de onboarding de satélites con sección de secretos (Infisical).
- [ ] `changelog.md` y `roadmap.md` actualizados atómicamente al cierre.
