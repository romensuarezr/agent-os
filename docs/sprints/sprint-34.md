# Sprint 34 — Hardening Determinista de Planning, Proyección Multi-Harness y Automejora

> **Período**: 2026-11-11 → 2026-11-25  
> **Enfoque**: Hardening y clarificación determinista del workflow de planificación de sprints (`sprint-planning.md`), transición canónica de nomenclatura «Opción D» → «Desatendida» con compuerta limpia (A/B), proyección determinista de adaptadores estáticos multi-harness para todos los flujos en `install.sh` y `sync.sh` con check fail-closed, y cableado de la sonda determinista de automejora a coste $0 en el ritual de planning.

---

## Estado
🟡 En curso

---

## Tareas

| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :---: | :--: | :--- | :--- |
| T-189 | Hardening determinista de `sprint-planning.md` y unificación del régimen Desatendida | Core / Workflows & Gobernanza | M | ✅ Hecho | — | [.agents/tasks/task-189.md](.agents/tasks/task-189.md) |
| T-190 | Adaptadores estáticos multi-harness con proyección determinista en `install.sh`/`sync.sh` y check fail-closed | Core / Multi-Harness | S | ✅ Hecho | T-189 | [.agents/tasks/task-190.md](.agents/tasks/task-190.md) |
| T-191 | Sonda de automejora determinista ($0 tokens) en ritual de planning con canalización a `idea-inbox/` | Core / Automejora | M | ⬜ Pendiente | T-189, T-190 | [.agents/tasks/task-191.md](.agents/tasks/task-191.md) |

---

## Régimen Operativo del Sprint
> Declaración vinculante del modo de ejecución y orden de carriles del sprint. Sellado en el inicio del sprint tras aprobación explícita del operador humano.

- **Régimen**: Desatendida (alias histórico «Opción D»)
- **Orden de Carriles (DAG de dependencias)**:
  - Carril 1: [T-189] (Hardening `sprint-planning.md` + unificación nomenclatura Desatendida)
  - Carril 2: [T-190] (Proyección determinista de adaptadores OpenCode en `install.sh`/`sync.sh` + test fail-closed)
  - Carril 3: [T-191] (Sonda de automejora $0 tokens en Paso 1 y cosecha en Paso 3)
- **Sellado en**: 2026-11-11 09:55 UTC por el operador humano.

---

## Notas de Planning y Decisiones Macro
1. **Regla de Oro de Gobernanza**: El agente propone de forma autónoma una propuesta cerrada (3–5 tareas S/M/L) y el operador humano únicamente confirma o enmienda en el Paso 7. Cero preguntas abiertas de definición al usuario.
2. **Nomenclatura Canónica**: Se reemplaza «Opción D» por «Desatendida» en la compuerta y flujos vivos: `A) Desatendida` / `B) Tarea a tarea (Clásico)`. «Opción D» permanece únicamente como nota de alias histórico para compatibilidad y documentación.
3. **Proyección Generalizada de Shims**: T-190 asegura que tanto `install.sh` como `sync.sh` creen/actualicen un archivo en `.opencode/commands/<nombre>.md` por cada workflow en `.agents/workflows/`, permitiendo invocación activa `/comando` en OpenCode sin lecturas pasivas. Se añade un check determinista en `validate-control-plane.sh`.
4. **Cierre de Ciclo de Automejora**: En T-191 se conecta `check-tooling-updates.sh` en el Paso 1 para redactar borradores automáticos en `docs/idea-inbox/` sin consumo de tokens de LLM, consolidando el bucle cerrado con la revisión humana en el Paso 3.
