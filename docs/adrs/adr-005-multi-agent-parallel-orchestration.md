# ADR 005: Motor de Orquestación Paralela Multi-Agente, Metas Deterministas y Aislamiento por Git Worktrees

**Estado:** Accepted  
**Fecha:** 2026-09-27  
**Contexto:** Sprint 09 — Core / Multi-Agent Parallel Orchestration  

---

## 1. Contexto y Problema

A medida que el ecosistema de Agent OS madura hacia la orquestación de swarms de agentes (Antigravity CLI, Hermes 24/7, Orca ADE, OpenCode), surge la necesidad de paralelizar tareas de implementación, investigación y aseguramiento de calidad sobre una misma base de código.

Los modelos tradicionales de trabajo secuencial o concurrencia sobre un único working tree presentaban riesgos críticos:
- **Colisiones en working tree**: Agentes concurrentes sobrescribiendo archivos no commiteados o interfiriendo en el staging de Git (`git add`/`git status`).
- **Falta de verificabilidad determinista**: Las evaluaciones de cumplimiento de metas dependían frecuentemente del juicio subjetivo del propio modelo que generó el código, quemando tokens y aumentando el riesgo de alucinaciones.
- **Riesgo para nodos de infraestructura crítica**: En entornos con restricciones de almacenamiento —específicamente el VPS de producción `oracle` (`vnic-rsr`), que mantiene un 72% de disco en uso— la creación descontrolada de clones o carpetas de trabajo efímeras podría inducir un agotamiento fatal de inodos o espacio disponible.

---

## 2. Decisiones Arquitectónicas Fundamentales

### 2.1 Aislamiento Efímero mediante Git Worktrees (`scripts/agent/worktree-dispatch.sh` & `worktree-merge.sh`)
Para garantizar un aislamiento perfecto entre agentes concurrentes sin duplicar el repositorio:
- Cada tarea o submeta se despacha en un entorno aislado bajo `.worktrees/<task-id>`, asociado a una rama de feature atómica `feat/<task-id>-<profile>`.
- `worktree-dispatch.sh` ejecuta preventivamente `git worktree prune` para sanear referencias huérfanas antes de la creación, e inyecta la variable de entorno `AGENT_OS_ROOT` en `.agents/context/worktree.env`.
- `worktree-merge.sh` gestiona la integración mediante fast-forward (`--ff-only`) y garantiza la purga atómica de inodos ejecutando `git worktree remove --force ".worktrees/<task-id>"` seguido de `git worktree prune`.
- Se establece una exclusión universal en `.gitignore` (`.worktrees/`, `worktrees/`, `*.worktree`) para asegurar que los entornos efímeros jamás contaminen el working tree principal.

### 2.2 Motor de Metas Deterministas y Quality Gates (`scripts/agent/verify-goal.sh`)
Para validar el éxito de una tarea con coste 0 de tokens de inferencia:
- Se define un contrato declarativo estricto en `templates/goals/goal.schema.md` que exige la definición de una allowlist de archivos autorizados y comandos de validación obligatorios.
- `verify-goal.sh` valida que ningún archivo fuera de la lista autorizada haya sido modificado o creado, y ejecuta los tests y linters requeridos.
- Proporciona un modo determinista `--json` que separa los logs humanos (enviados a stderr) del digest JSON estructurado (enviado a stdout: `{"task_id": "...", "status": "PASS|FAIL", "allowlist_pass": bool, "tests_pass": bool, "violations": [...]}`), permitiendo su consumo sin fricción por orchestrators y herramientas CLI.

### 2.3 Desacoplamiento Evaluador-Trabajador (Ralph Loop & Rol `qa-judge`)
Para eliminar el sesgo de auto-evaluación:
- El agente implementador (`coder`) trabaja confinado en su worktree con su allowlist asignada. No posee herramientas de merge (`worktree-merge.sh`) ni cierre de sprint.
- Un evaluador independiente (`qa-judge`) ejecuta `verify-goal.sh --strict --json` y audita los diffs de forma desacoplada (patrón Ralph Loop).
- Si la verificación falla, se registra la retroalimentación técnica con un límite estricto de 3 iteraciones antes de activar la compuerta de escalado a humano (`/gate reject`).

### 2.4 Salvaguarda de Flota y Cumplimiento con ADR 004
En cumplimiento estricto con las directrices de ADR 004 (Control Plane de Agentes 24/7):
- La ejecución paralela de worktrees queda **restringida a la estación de trabajo local (`inteligencia-colectiva`) o nodos de trabajo dedicados**.
- Queda **estrictamente prohibido aprovisionar lotes de worktrees en el VPS de producción `oracle` (`vnic-rsr`)**, preservando su almacenamiento crítico (72% en uso) para bases de datos y servicios en producción.

---

## 3. Trade-offs y Mitigaciones

| Decisión | Trade-off | Mitigación |
|---|---|---|
| **Git Worktrees vs. Carpetas/Clones completos** | Los worktrees comparten el almacén `.git/objects/`, por lo que una corrupción en el almacén de objetos afectaría a todos. | No se permite manipulación de `.git` directo; todos los scripts invocan comandos de alto nivel de Git con saneamiento (`prune`). El ahorro de disco y rapidez de creación es de 10x frente a clones completos. |
| **Allowlist estricta de archivos** | Si un agente detecta un bug colateral legítimo fuera de su allowlist, no puede corregirlo en el mismo paso. | Se mantiene la trazabilidad atómica: el agente debe reportar el hallazgo o solicitar una compuerta `/gate` de ampliación de alcance, evitando "feature creeps" no auditados. |
| **Evaluador desacoplado (Ralph Loop)** | Introduce un paso adicional en el flujo de integración frente a merges automáticos directos. | Previene regresiones silenciosas y código no probado en la rama principal. Dado que la verificación determinista tarda <2 segundos y tiene coste 0 tokens, el overhead temporal es despreciable. |

---

## 4. Consecuencias y Criterios de Éxito

- **Escalabilidad horizontal**: Posibilidad de paralelizar $N$ tareas de desarrollo simultáneas sobre el core y proyectos hijos sin interferencia.
- **Distribución uniforme**: Las capacidades de metas y worktrees se distribuyen automáticamente a proyectos hijos vía `sync.sh` e `install.sh`.
- **Suite de pruebas reforzada**: El control plane de Agent OS valida permanentemente (10/10 checks) la sintaxis y ejecutabilidad de las herramientas y la conformidad YAML de los perfiles declarativos.
