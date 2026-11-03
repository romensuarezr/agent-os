# Sprint 30 — Validación de Ejecución Autónoma sobre Trabajo Real: Bane en Vivo, Nango OAuth y Remediación Homepage

> **Período**: 2026-11-03 → 2026-11-07  
> **Enfoque**: Validación empírica de la autonomía desatendida sobre casos de uso reales de infraestructura de la flota antes de la promoción a `main`: puesta en producción viva de Bane en el nodo de inferencia (T-165), plantilla Compose soberana y runbook de integración de Nango OAuth en VPS (T-166), y remediación determinista de compatibilidad en `generate-homepage-config.sh` junto con saneamiento de plantillas de Homepage Dashboard (T-167).

---

## Estado
🟡 En curso

---

## Tareas

| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :---: | :--: | :--- | :--- |
| T-165 | Despliegue en vivo y validación operativa de Bane en la flota | Core / Infraestructura & Ops | M | ⬜ Pendiente | — | [.agents/tasks/task-165.md](.agents/tasks/task-165.md) |
| T-166 | Plantilla de despliegue soberano de Nango en VPS y runbook de integración | Core / Infraestructura & Auth | M | ⬜ Pendiente | — | [.agents/tasks/task-166.md](.agents/tasks/task-166.md) |
| T-167 | Remediación determinista de compatibilidad en `generate-homepage-config.sh` y Homepage Dashboard | Core / Tooling & Observabilidad | M | ⬜ Pendiente | — | [.agents/tasks/task-167.md](.agents/tasks/task-167.md) |

---

## Disposición Explícita de Candidatas de Planning

### Candidatas Fuera de Alcance en Sprint 30 (con Motivo)
1. **Promoción a `main` de v1.15 a v1.25 y tags de release**:
   - **Motivo**: Excluido explícitamente. Se realiza tras validar empíricamente la ejecución autónoma desatendida en este sprint de trabajo real.
2. **Rotación de las 15 credenciales revocadas en bóveda**:
   - **Motivo**: Bloqueado hasta decisión del usuario sobre alcance por zona de `CLOUDFLARE_API_TOKEN`.
3. **ByteBox CLI Curator**:
   - **Motivo**: Backlog técnico posterior; no entra a sprint sin consolidar la infraestructura de auth (Nango) y observabilidad (Homepage).
4. **Sincronización masiva de satélites (`sync.sh`)**:
   - **Motivo**: Pospuesto a la siguiente ventana de releases tras la promoción a `main`.

---

## Notas de planning

### 1. Régimen Operativo Estándar: Opción D (Autonomía Acotada)
Aprobado por el usuario y formalizado en los workflows canónicos (`session-start.md`, `sprint-planning.md`, `AGENTS.md`) en T-164:
- **Nivel Macro**: Esta sección y la aprobación humana de este sprint planning constituyen la **única autorización habilitante** para la autonomía desatendida en cada tarea.
- **Nivel Micro (Camino Limpio)**: Si `deliberate-plan.sh` emite veredicto estrictamente `CONSENSO`, la suite de control plane se mantiene en verde, los cambios están dentro de la caja autorizada, no hay desvíos frente al macro y los centinelas están intactos, el agente avanza de forma 100% desatendida hasta el merge y cierre inclusive.
- **Compuertas de Aborto Fail-Closed**: Ante cualquier veredicto != `CONSENSO`, fallo en suite, archivo fuera de caja o mutación centinela, el agente detiene de inmediato el avance y escala al operador en el chat presentando el Executive Design Digest.
- **Protocolo Pre-Merge Refinado**: Publicación previa en `origin` de la rama de feat y el informe/notas acreditando el recibo de deliberación, captura atómica del digest y raw json en el commit de cierre con `close-task.sh`.

### 2. Cumplimiento de Compuerta Scout-First (T-129)
Las 3 tareas cuentan con su respectiva prospección determinista registrada en [docs/sprints/sprint-30-research.md](sprint-30-research.md), garantizando 0 dependencias runtime ajenas, coste $0 en prospección y justificación técnica para cada decisión de adopción vs. desarrollo a medida.
