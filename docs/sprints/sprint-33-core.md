# Sprint 33 — Estandarización Ops, Auditoría de Satélites, Hardening de Gobernanza & UI Critique

> **Período**: 2026-11-10 → 2026-11-24  
> **Enfoque**: Consolidación técnica de operaciones, satélites y gobernanza: estandarización de `coolify.sh` y la skill `coolify-admin` con resolución de endpoints desde Fleet y pre-flights estándar (T-183), auditoría determinista de integridad de scripts en repositorios satélite con `audit-satellites.sh` (T-184), refinamiento y paridad de `session-close.md` con el estándar de Opción D y encadenamiento autónomo (T-185), cobertura de control plane y hardening de `rotate-freellmapi-token.sh` (T-186), y formalización de la skill `ui-critique` para evaluación heurística de interfaces en satélites (T-187).

---

## Estado
🟡 En curso

---

## Tareas

| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :---: | :--: | :--- | :--- |
| T-183 | Estandarización de variables, endpoints y pre-flights en `coolify.sh` y `coolify-admin` | Core / Ops & Fleet | S | ⬜ Pendiente | — | [.agents/tasks/task-183.md](.agents/tasks/task-183.md) |
| T-184 | Auditoría determinista de integridad y salud de scripts en satélites (`audit-satellites.sh`) | Core / Satélites | M | ⬜ Pendiente | — | [.agents/tasks/task-184.md](.agents/tasks/task-184.md) |
| T-185 | Refinamiento y paridad de `session-close.md` con régimen Opción D y encadenamiento | Core / Workflows | S | ⬜ Pendiente | — | [.agents/tasks/task-185.md](.agents/tasks/task-185.md) |
| T-186 | Cobertura de control plane y hardening determinista de `rotate-freellmapi-token.sh` | Core / Control Plane | S | ⬜ Pendiente | — | [.agents/tasks/task-186.md](.agents/tasks/task-186.md) |
| T-187 | Formalización de skill `ui-critique` para auditoría y revisión de interfaces en satélites | Core / Skills | M | ⬜ Pendiente | — | [.agents/tasks/task-187.md](.agents/tasks/task-187.md) |

---

## Régimen Operativo del Sprint
> Declaración vinculante del modo de ejecución y orden de carriles del sprint. Se sella en el arranque del sprint tras consulta proactiva única al operador en /session-start.

- **Régimen**: [PENDIENTE_ARRANQUE — Desatendida (Opción D) | Tarea a tarea (Clásico)]
- **Orden de Carriles (DAG de dependencias)**:
  - Carril 1: [T-183] (Estandarización Coolify)
  - Carril 2: [T-184] (Auditoría de scripts en satélites)
  - Carril 3: [T-185] (Refinamiento session-close Opción D)
  - Carril 4: [T-186] (Hardening y tests de rotate-freellmapi-token.sh)
  - Carril 5: [T-187] (Skill de auditoría UI critique)
- **Sellado en**: [PENDIENTE]

---

## Disposición Explícita de Candidatas de Planning

### Candidatas Fuera de Alcance en Sprint 33 (con Motivo)
1. **Rotación de las 15 credenciales revocadas en bóveda**:
   - **Motivo**: ⛔ Bloqueado hasta decisión explícita del usuario sobre alcance por zona de `CLOUDFLARE_API_TOKEN`.
2. **Promoción masiva a `main` y tags de release**:
   - **Motivo**: Excluido de la ventana operativa actual; pospuesto a ciclo de estabilización específico.
3. **[T-043] Prospección periódica automatizada de herramientas Freemium / OSS**:
   - **Motivo**: Considerada resuelta y superada por `check-tooling-updates.sh` (T-174) y la skill `tooling-advisor` (T-173, T-180).

---

## Notas de planning

### 1. Régimen Operativo Estándar: Opción D vs. Tarea a Tarea
El flujo inteligente formalizado en T-177 interrogará proactivamente al operador en el primer `/session-start` de este sprint para sellar el régimen y confirmar el camino de carriles. Si se sella Opción D:
- **Nivel Macro**: Esta acta constituye la **única autorización habilitante** para la autonomía desatendida.
- **Nivel Micro (Camino Limpio)**: Si `deliberate-plan.sh` emite veredicto `CONSENSO`, la suite de control plane se mantiene en verde (38/38), los cambios están dentro de la caja autorizada y no hay desvíos frente al macro, el avance es desatendido.
- **Compuerta Fail-Closed Crítica**: Si la verificación del relé o la suite de la tarea recién cerrada falla, el sistema **ABORTA INMEDIATAMENTE A HUMANO**.

### 2. Cumplimiento de Compuerta Scout-First (T-129)
Las 5 tareas cuentan con su respectiva prospección determinista registrada en [docs/sprints/sprint-33-research.md](sprint-33-research.md), garantizando coste $0 de tokens en prospección y justificación técnica de cada componente.

### 3. Decisiones Macro Propuestas
1. **T-183 (Coolify)**: Mantener el wrapper propio `scripts/ops/coolify.sh`, eliminando el fallback hardcodeado `https://coolify.example.com/api/v1` a favor de la lectura de `fleet.yaml` o entorno, integrando `lib/cli-help.sh`.
2. **T-184 (Satélites)**: Crear `scripts/agent/audit-satellites.sh` como utilidad determinista de diagnóstico de salud (hashes sha256 de scripts, permisos, sincronización) sin tocar git ni hacer peticiones de red.
3. **T-185 (Gobernanza)**: Sincronizar `.agents/workflows/session-close.md` con las reglas de Opción D, cierre con `close-task.sh`, y aborto fail-closed si la verificación del relé falla.
4. **T-186 (Control Plane)**: Proteger `scripts/agent/lib/rotate-freellmapi-token.sh` en la suite de validación determinista (`tests/validate-control-plane.sh`) manteniendo el denominador estricto de 38/38.
5. **T-187 (UI Critique)**: Formalizar `.agents/skills/ui-critique/SKILL.md` como guía heurística de auditoría para proyectos frontend satélite (Next.js / Tailwind).

### 4. Denominador de Suite Inmutable
- El denominador de la suite `tests/validate-control-plane.sh` permanece rígidamente inmutable en **38/38** (0 errores).
