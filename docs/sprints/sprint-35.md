# Sprint 35 — 2026-11-11 → 2026-11-25

## Estado
🟡 En curso

## Tareas

| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
|---|---|---|:---:|:---:|---|---|
| T-192 | Homologación integral de actualización de tooling upstream (glances, hermes, infisical, opencode, orca) | Core / Tooling & Flota | M | ✅ Completada | — | [.agents/tasks/task-192.md](.agents/tasks/_archived/task-192.md) |
| T-193 | Actualización asistida de Agent OS en proyectos satélite (dry-run, plan de impacto y compuerta de sincronización) | Core / Satélites & DX | M | ✅ Completada | T-192 | [.agents/tasks/task-193.md](.agents/tasks/_archived/task-193.md) |
| T-194 | Estandarización de Changelog, GitHub Releases y archivo VERSION universal para satélites | Core / Releases & Gobernanza | M | ✅ Completada | T-193 | [.agents/tasks/task-194.md](.agents/tasks/_archived/task-194.md) |
| T-195 | Desbloqueo y rotación de credenciales (Cloudflare API Token / Infisical) | Core / Seguridad & Secretos | L | ⬜ Pendiente | — | [.agents/tasks/task-195.md](.agents/tasks/task-195.md) |

## Régimen Operativo del Sprint
> Declaración vinculante del modo de ejecución y orden de carriles del sprint. Sellado en el inicio del sprint tras aprobación explícita del operador humano.

- **Régimen**: Desatendida (alias histórico «Opción D»)
- **Orden de Carriles (DAG de dependencias)**:
  - Carril 1: [T-192 → T-193 → T-194]
  - Carril 2: [T-195]
- **Sellado en**: 2026-11-11 13:10 UTC por el operador humano.

## Notas de planning
1. **Regla de Oro de Gobernanza**: El agente propone de forma autónoma una propuesta cerrada (3–5 tareas S/M/L) y el operador humano confirma o enmienda en el Paso 7.
2. **Criterio de Valor para Tooling (T-192)**: Agrupación en una única tarea integral que actualiza componentes que los agentes ejecutan en su contexto activo (.agents/skills/<tool>/SKILL.md, .agents/profiles/, fleet-doctor.sh), prohibiendo el bump cosmético vacío.
3. **Actualización Asistida de Satélites (T-193)**: Resuelve la limitación del timeout de 10s en `check-session.sh` y la recomendación pasiva de `sync.sh`. Implementa pre-visualización `--dry-run`, extracción determinista de novedades de `changelog.md` y generación del plan de impacto estructurado previo al inicio del sprint en satélites.
4. **Estandarización de Releases y Fuente Única de Versión (T-194)**: Publicación de releases oficiales con `gh release create` en `promote-to-main.sh`, enlaces de comparación SemVer en `update-changelog.sh` y patrón de consumo de `VERSION` universal para apps satélite (Next.js, Node, Python, Docker).
5. **Gobernanza de Secretos (T-195)**: Resolución del bloqueo de `CLOUDFLARE_API_TOKEN` mediante delimitación de alcance acordada y rotación de credenciales en Infisical.
