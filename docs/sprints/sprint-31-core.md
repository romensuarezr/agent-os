# Sprint 31 — Gobernanza de Flota, Tooling Autónomo, Saneamiento de Motores & Diagnóstico de WhatsApp Bridge

> **Período**: 2026-11-08 → 2026-11-22  
> **Enfoque**: Consolidación de la gobernanza de herramientas de la flota de Agent OS y saneamiento técnico del core: matriz de roles y capacidades de CLIs con exclusiones vinculantes (T-172), sonda determinista CLI de actualización de herramientas multi-registro `check-tooling-updates.sh` (T-173), skill canónica `tooling-advisor` para prospección pasiva de flota (T-174), saneamiento integral de residuos del motor fantasma Bane y adaptación de checks a SearXNG (T-175) y diagnóstico forense determinista de la inoperatividad de `whatsapp-bridge` sin arreglos a ciegas (T-176).

---

## Estado
🟡 En curso

---

## Tareas

| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :---: | :--: | :--- | :--- |
| T-172 | Matriz de roles y capacidades de CLIs de la flota (OpenCode 2, Claude Code, Aider, Hermes, Antigravity) | Core / Gobernanza & Flota | M | ✅ Hecho | — | [.agents/tasks/task-172.md](.agents/tasks/_archived/task-172.md) |
| T-173 | Sonda determinista de actualización de herramientas (`check-tooling-updates.sh`) multi-registro | Core / Tooling & Observabilidad | M | ✅ Hecho | T-172 | [.agents/tasks/task-173.md](.agents/tasks/_archived/task-173.md) |
| T-174 | Skill canónica `tooling-advisor` para prospección pasiva de flota y propuestas a `idea-inbox/` | Core / Skills & Evolución | M | ✅ Hecho | T-173 | [.agents/tasks/task-174.md](.agents/tasks/_archived/task-174.md) |
| T-175 | Saneamiento integral del fantasma Bane (purga de wrapper, plantillas y runbook; migración a SearXNG; 38/38) | Core / Motores & Control Plane | S | ⬜ Pendiente | — | [.agents/tasks/task-175.md](.agents/tasks/task-175.md) |
| T-176 | Diagnóstico determinista de inoperatividad de `whatsapp-bridge` (causa raíz + evidencia, cero arreglo a ciegas) | Core / Infraestructura & Diagnóstico | S | ✅ Hecho | — | [.agents/tasks/task-176.md](.agents/tasks/_archived/task-176.md) |

---

## Disposición Explícita de Candidatas de Planning

### Candidatas Fuera de Alcance en Sprint 31 (con Motivo)
1. **Promoción a `main` de v1.15 a v1.26 y tags de release**:
   - **Motivo**: Excluido explícitamente en el planning. Pendiente de ventana de release tras estabilización de flota.
2. **Rotación de las 15 credenciales revocadas en bóveda**:
   - **Motivo**: ⛔ Bloqueado hasta decisión del usuario sobre alcance por zona de `CLOUDFLARE_API_TOKEN`.
3. **ByteBox CLI Curator**:
   - **Motivo**: Backlog técnico posterior; no entra a sprint sin consolidar la gobernanza de herramientas.
4. **Sincronización masiva de satélites (`sync.sh`)**:
   - **Motivo**: Pospuesto a la siguiente ventana de releases tras consolidación del core.

---

## Notas de planning

### 1. Régimen Operativo Estándar: Opción D (Autonomía Acotada)
Aprobado por el usuario y formalizado en los workflows canónicos (`session-start.md`, `sprint-planning.md`, `AGENTS.md`):
- **Nivel Macro**: Esta sección constituye la **única autorización habilitante** para la autonomía desatendida en cada tarea.
- **Nivel Micro (Camino Limpio)**: Si `deliberate-plan.sh` emite veredicto estrictamente `CONSENSO`, la suite de control plane se mantiene en verde (38/38), los cambios están dentro de la caja autorizada, no hay desvíos frente al macro y los centinelas están intactos, el agente avanza de forma 100% desatendida hasta el merge y cierre inclusive.
- **Compuertas de Aborto Fail-Closed**: Ante cualquier veredicto != `CONSENSO`, fallo en suite, archivo fuera de caja o mutación centinela, el agente detiene de inmediato el avance y escala al operador en el chat presentando el Executive Design Digest.
- **Protocolo Pre-Merge**: Publicación previa en `origin` de la rama de feat y el informe/notas acreditando el recibo de deliberación, captura atómica del digest y raw json en el commit de cierre con `close-task.sh`.

### 2. Cumplimiento de Compuerta Scout-First (T-129)
Las 5 tareas cuentan con su respectiva prospección determinista registrada en [docs/sprints/sprint-31-research.md](sprint-31-research.md), garantizando 0 dependencias runtime ajenas, coste $0 en prospección y justificación técnica para cada decisión de adopción vs. desarrollo a medida.

### 3. Decisiones Macro Humana Vinculantes (Selladas en Planning — 2026-11-08)
1. **Hermes**: **DESCARTADO** como front door separado. El `whatsapp-bridge` lo hizo Hermes mismo para comunicarse con el usuario en el host; Hermes ya opera a través de su propio puente. No se crea otro gateway ni capa intermedia.
2. **Aider**: **DESCARTADO** como rescate de merges. Se ratifica sin excepciones la doctrina estricta de Sprint 25: solo coordinador o humano fusionan.
3. **Claude Code como Juez**: **DESCARTADO**. Se mantiene rígidamente la cadena actual de deliberación: `agy` (Tier 1) / Orca ADE (Tier 2).
4. **T-175 Aprobada con Alcance Verificado**: Reconocimiento de `searxng-client.sh` como cliente soberano primario activo existente. Cero duplicación de cliente SearXNG. Purga integral de wrapper, plantillas y runbook de Bane. Adaptación de checks 34 y 38 en control plane preservando denominador 38/38.
5. **T-176 Diagnóstico de WhatsApp Bridge (Cero Arreglo a Ciegas)**: Diagnóstico determinista puro (inspección de systemd, procesos, sockets y puertos locales —p. ej. puerto `:3000`, según determine el diagnóstico— y logs forenses) para reportar causa raíz y evidencia verificable. Queda estrictamente prohibido aplicar arreglos o parches a ciegas; el plan de remediación se decide tras la entrega del diagnóstico.

### 4. Denominador de Suite Inmutable
- El denominador de la suite `tests/validate-control-plane.sh` permanece rígidamente inmutable en **38/38** (0 errores).
