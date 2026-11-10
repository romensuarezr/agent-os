# Sprint 32 — Saneamiento Final de Motores, Soporte MCP Remoto, Integración DeepWiki & Rotación Hermes FreeLLMAPI

> **Período**: 2026-11-10 → 2026-11-24  
> **Enfoque**: Consolidación técnica de la flota y gobernanza agéntica: saneamiento definitivo de residuos fantasma de Bane en la flota y cliente SearXNG (T-178), ampliación declarativa del esquema de Fleet para servidores MCP remotos HTTP/SSE (T-179), integración de DeepWiki MCP como fuente secundaria de comprensión estructural profunda en `tooling-advisor` (T-180), actualización y automatización atómica de `last-sync.md` (T-181) y remediación formal planificada con rotación segura de FreeLLMAPI en pasarela Hermes bajo gate HITL (T-182).

---

## Estado
🟡 En curso

---

## Tareas

| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :---: | :--: | :--- | :--- |
| T-178 | Purga definitiva de residuos Bane (`fleet.example.yaml`, `searxng-client.sh`, Check 34 §18) | Core / Control Plane | S | ⬜ Pendiente | — | [.agents/tasks/task-178.md](.agents/tasks/task-178.md) |
| T-179 | Soporte declarativo de servidores MCP remotos HTTP/SSE en Fleet (`fleet.yaml`, `fleet-doctor.sh`) | Core / Fleet & Tooling | M | ⬜ Pendiente | — | [.agents/tasks/task-179.md](.agents/tasks/task-179.md) |
| T-180 | DeepWiki MCP como fuente secundaria de comprensión estructural profunda post-scout en `tooling-advisor` | Core / Skills & Prospección | M | ⬜ Pendiente | T-179 | [.agents/tasks/task-180.md](.agents/tasks/task-180.md) |
| T-181 | Sincronización y automatización de `last-sync.md` en el cierre de sprint (`close-sprint.sh`) | Core / DX & Trazabilidad | S | ⬜ Pendiente | — | [.agents/tasks/task-181.md](.agents/tasks/task-181.md) |
| T-182 | Remediación planificada y rotación de FreeLLMAPI en Hermes (solo scripts, sin valores, gate HITL) | Infraestructura / Inferencia | M | ⬜ Pendiente | — | [.agents/tasks/task-182.md](.agents/tasks/task-182.md) |

---

## Régimen Operativo del Sprint
> Declaración vinculante del modo de ejecución y orden de carriles del sprint. Se sella en el arranque del sprint tras consulta proactiva única al operador en /session-start.

- **Régimen**: [PENDIENTE_ARRANQUE — Desatendida (Opción D) | Tarea a tarea (Clásico)]
- **Orden de Carriles (DAG de dependencias)**:
  - Carril 1: [T-178] (Saneamiento Bane en control plane)
  - Carril 2: [T-179 → T-180] (Soporte MCP remoto + DeepWiki en tooling-advisor)
  - Carril 3: [T-181] (Automatización last-sync.md)
  - Carril 4: [T-182] (Rotación FreeLLMAPI Hermes bajo gate HITL)
- **Sellado en**: [PENDIENTE]

---

## Disposición Explícita de Candidatas de Planning

### Candidatas Fuera de Alcance en Sprint 32 (con Motivo)
1. **Promoción a `main` de v1.15 a v1.27 y tags de release**:
   - **Motivo**: Excluido de la ventana operativa actual; pospuesto a ventana de estabilización post-Sprint 32.
2. **Rotación de las 15 credenciales revocadas en bóveda**:
   - **Motivo**: ⛔ Bloqueado hasta decisión del usuario sobre alcance por zona de `CLOUDFLARE_API_TOKEN`.
3. **Sincronización masiva de proyectos satélites (`sync.sh`)**:
   - **Motivo**: Priorizado el soporte de MCP remoto y DeepWiki antes de sincronizar satélites.

---

## Notas de planning

### 1. Régimen Operativo Estándar: Opción D vs. Tarea a Tarea
El nuevo flujo inteligente formalizado en T-177 interrogará proactivamente al operador en el primer `/session-start` para sellar el régimen y confirmar el camino de carriles. Si se sella Opción D:
- **Nivel Macro**: Esta acta constituye la **única autorización habilitante** para la autonomía desatendida.
- **Nivel Micro (Camino Limpio)**: Si `deliberate-plan.sh` emite veredicto `CONSENSO`, la suite de control plane se mantiene en verde (38/38), los cambios están dentro de la caja autorizada y no hay desvíos frente al macro, el avance es desatendido.
- **Compuerta Fail-Closed Crítica**: Si la verificación del relé o la suite de la tarea recién cerrada falla, el sistema **ABORTA INMEDIATAMENTE A HUMANO**.

### 2. Cumplimiento de Compuerta Scout-First (T-129)
Las 5 tareas cuentan con su respectiva prospección determinista registrada en [docs/sprints/sprint-32-research.md](sprint-32-research.md), garantizando coste $0 de tokens en prospección y justificación técnica de cada componente.

### 3. Decisiones Macro Humanas Vinculantes (Selladas en Planning — 2026-11-10)
1. **T-178 (Corrección Check 34 §18)**: Se ratifica que las comprobaciones de erradicación de Bane viven en `tests/validate-control-plane.sh` **Check 34 (§18)** y NO en Check 18. Se purgan `bane:` de `fleet.example.yaml` y el fallback `BANE_API_URL` / `svcs['bane']` de `searxng-client.sh`.
2. **T-179 (Soporte MCP Remoto)**: Extensión declarativa de Fleet para soportar transporte Streamable HTTP / SSE (`url`) además de `stdio` (`command`).
3. **T-180 (Absorción de Idea DeepWiki)**: Queda archivada la propuesta `docs/idea-inbox/2026-11-09-deepwiki-complemento-scout.md`. DeepWiki opera como fuente secundaria post-scout y sus respuestas deben contrastarse obligatoriamente contra el HEAD real del repositorio.
4. **T-181 (Trazabilidad last-sync.md)**: Sincronización inmediata a `v1.27.0` y cableado determinista en `close-sprint.sh`.
5. **T-182 (Condición HITL en Rotación FreeLLMAPI Hermes)**: La rotación debe ejecutarse **exclusivamente mediante maquinaria de scripts deterministas, sin imprimir valores de secretos en pantalla ni en logs, y mediada por una compuerta HITL del operador (solicitud de ventana + confirmación OK explícita del operador antes de aplicar cambios en la bóveda o reiniciar servicios)**.

### 4. Denominador de Suite Inmutable
- El denominador de la suite `tests/validate-control-plane.sh` permanece rígidamente inmutable en **38/38** (0 errores).
