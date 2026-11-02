# Sprint 29 — Cierre de Bane, Higiene de Cierre Completa y Adopción Estándar de Opción D

> **Período**: 2026-11-02 → 2026-11-06  
> **Enfoque**: Culminación de la plantilla de despliegue soberano de Bane con límites de recursos y .env.example (T-162), blindaje generalizado de rutas personales y re-chequeo post-cierre (T-163), y formalización de la Opción D como régimen operativo por defecto en workflows y documentación canónica (T-164).

---

## Estado
🟡 En curso

---

## Tareas

| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :---: | :--: | :--- | :--- |
| T-162 | Cierre de Bane (límites de recursos en docker-compose.yml + templates/bane/.env.example) | Core / Infraestructura | S | ✅ Completada | — | [.agents/tasks/task-162.md](.agents/tasks/_archived/task-162.md) |
| T-163 | Higiene de cierre completa (blindaje de rutas personales fuera de repo y re-chequeo) | Core / Tooling | M | ✅ Completada | T-162 | [.agents/tasks/task-163.md](.agents/tasks/_archived/task-163.md) |
| T-164 | Formalizar Opción D como régimen por defecto (workflows y docs) | Core / Gobernanza | M | ✅ Completada | T-163 | [.agents/tasks/task-164.md](.agents/tasks/_archived/task-164.md) |

---

## Disposición Explícita de Candidatas de Planning

### Candidatas Fuera de Alcance en Sprint 29 (con Motivo)
1. **Migración REA de annascheer.com**:
   - **Motivo**: Excluido explícitamente. Constituye un proyecto nuevo satélite/independiente fuera del repositorio del core de Agent OS.
2. **Dashboard Homepage (track de campo en VPS)**:
   - **Motivo**: Excluido de las tareas del core. Se gestiona como intervención operativa en el host VPS remoto sin alterar la base de código del core.
3. **Bytebox**:
   - **Motivo**: Prioridad posterior de backlog técnico; no entra a sprint sin estabilizar el cierre de Bane y el régimen estándar de autonomía.
4. **Promoción a `main` y tags de release**:
   - **Motivo**: Excluido explícitamente de la agenda del sprint. Se preserva como evento de release desacoplado del trabajo semanal.

---

## Notas de planning

### 1. Régimen de Ejecución: Opción D como Estándar desde la Primera Tarea
Tras la conclusión y certificación empírica del piloto en el Sprint 28 (`PILOTO_OPCION_D_EXITOSO`), el **Sprint 29 se ejecuta íntegramente bajo el régimen de autonomía acotada (Opción D)** a partir de la tarea T-162:
- **Macro Aprobado por el Humano**: El presente documento y el research asociado sellan el diseño macro de las 3 tareas del sprint.
- **Camino Limpio Desatendido**:
  - Mientras el Revisor emita estrictamente `CONSENSO`, la suite de validación esté en verde, el diff esté dentro de la caja de archivos autorizada y no haya desviaciones del diseño sellado, el agente avanza de forma autónoma sin esperar prompts humanos en cada compuerta interactiva.
  - La ejecución autónoma incluye: implementación, pruebas, commits atómicos, publicación de rama y recibo de deliberación en `origin`, merge `--no-ff` a `multi-agent`, push a `origin` y ejecución de `close-task.sh`.
- **Compuertas de Aborto Inmediato (Fail-Closed)**:
  - Ante cualquier condición anómala:
    1. Veredicto distinto de `CONSENSO` (`SIN_REVISOR`, `REVISADO_CON_CAMBIOS`, `ESCALADO_A_HUMANO`, `RECHAZADO`).
    2. Fallo en la suite de validación `tests/validate-control-plane.sh`.
    3. Modificación de archivos fuera de la caja autorizada en el task file.
    4. Desviación del diseño macro aprobado.
    5. Disparo de centinelas de seguridad PRE o POST.
  - **Acción**: El agente detiene inmediatamente la ejecución autónoma, no realiza merge y escala de forma obligatoria al operador humano en el chat.
- **Auditoría *A Posteriori***:
  - Todo el ciclo queda publicado y trazable en `origin` (rama de feat, recibo `.agents/context/deliberation-T-XXX.json` y digest en `docs/sprints/design-decisions/`).

### 2. Guardas Técnicas y Denominador de Suite
- Denominador de la suite de control plane: **38/38** (0 errores) al inicio y durante todo el sprint.
- Cero literales de infraestructura personal ni credenciales en el repositorio (verificado por `locator-hygiene.sh`).
- Sin interacción con la rama `main` y sin creación de git tags.

### 3. Secuencia y Dependencias
- `T-162 → T-163 → T-164`.

---

## Diseño macro detallado por tarea

### T-162: Cierre de Bane (límites de recursos en docker-compose.yml + templates/bane/.env.example)
- **Objetivo**: Incorporar directivas de control de recursos en la plantilla Compose de Bane y proporcionar la plantilla de configuración `.env.example` con fallbacks portables.
- **Interfaces y decisiones selladas**:
  - En `templates/bane/docker-compose.yml`:
    - Ajuste vinculante de memoria (Precision 1 relé): al no haber medición empírica en caliente de Bane en el core, los defaults se mantienen estrictamente dentro del spec original (<250MB):
      - Bloque `deploy.resources.limits`: `cpus: "${BANE_CPU_LIMIT:-1.0}"`, `memory: "${BANE_MEMORY_LIMIT:-250M}"`.
      - Bloque `deploy.resources.reservations`: `cpus: "${BANE_CPU_RESERVATION:-0.1}"`, `memory: "${BANE_MEMORY_RESERVATION:-64M}"`.
  - Crear `templates/bane/.env.example` conteniendo todas las variables parametrizadas con valores seguros y descriptivos (`HOST_BIND_IP`, `BANE_PORT`, `BANE_INFERENCE_URL`, `BANE_API_KEY`, `BANE_SEARCH_URL`, `BANE_CPU_LIMIT`, `BANE_MEMORY_LIMIT`, `BANE_CPU_RESERVATION`, `BANE_MEMORY_RESERVATION`).
  - Documentar las variables y directivas de límites en `docs/runbooks/bane-deep-research-service.md`.
  - Caja de archivos: `templates/bane/docker-compose.yml`, `templates/bane/.env.example`, `docs/runbooks/bane-deep-research-service.md`, `.agents/tasks/task-162.md`.
  - Veredicto de diseño: `[APROBADO_EN_PLANNING]`.

### T-163: Higiene de cierre completa (blindaje de rutas personales fuera de repo y re-chequeo post-cierre)
- **Objetivo**: Generalizar el saneamiento de rutas personales en `design-digest.sh` para abarcar rutas fuera de `${ROOT_DIR}` e incorporar re-chequeo determinista de higiene tras el cierre de tareas y sprints.
- **Interfaces y decisiones selladas**:
  - En `scripts/agent/design-digest.sh`:
    - Reemplazar el saneamiento puntual de `${ROOT_DIR}` por un filtro robusto que sanee rutas absolutas Unix/macOS (`/(home|Users)/[a-zA-Z0-9_-]+/` y esquemas `file:///...`) convirtiéndolas a rutas relativas al repo o a marcadores neutros/relativos (`.agents/tasks/...`).
  - En `scripts/agent/close-task.sh`:
    - Invocar `locator-hygiene.sh` sobre el staging antes de realizar el commit y realizar un re-chequeo determinista post-cierre para atrapar fugas antes de la integración.
  - En `scripts/agent/close-sprint.sh`:
    - Incorporar validación de higiene determinista en el staging acotado del sprint.
  - En `tests/validate-control-plane.sh`:
    - Actualizar o verificar Check 18, Check 19 y Check 34 para reflejar las nuevas garantías deterministas sin alterar el denominador (38/38).
  - Caja de archivos: `scripts/agent/design-digest.sh`, `scripts/agent/close-task.sh`, `scripts/agent/close-sprint.sh`, `tests/validate-control-plane.sh`, `.agents/tasks/task-163.md`.
  - Veredicto de diseño: `[APROBADO_EN_PLANNING]`.

### T-164: Formalizar Opción D como régimen por defecto (workflows y docs)
- **Objetivo**: Consolidar en la documentación canónica y workflows del core el régimen operativo de autonomía acotada (Opción D) adoptado como estándar.
- **Interfaces y decisiones selladas**:
  - En `.agents/workflows/session-start.md`:
    - Actualizar Fase 3.4 y Fase 3.5 para formalizar que, ante veredicto `CONSENSO` con suite en verde y sin desviaciones del diseño macro, el agente ejecuta el camino limpio de forma desatendida.
    - Formalizar la regla pre-merge refinada (Precision 2 relé): condición pre-merge = rama + informe/notas publicados en origin ANTES del merge, y recibo de deliberación debidamente acreditado (referenciado con su veredicto/SHA); la persistencia del digest y del raw JSON de deliberación se captura formalmente en el cierre (`close-task.sh` vía `design-digest.sh`), sin exigir publicación literal aislada del archivo de recibo en origin previa al merge.
    - Mantener compuertas de aborto fail-closed ante cualquier anomalía (`SIN_REVISOR`, `REVISADO_CON_CAMBIOS`, `ESCALADO_A_HUMANO`, mutaciones o fallos de suite).
  - En `.agents/workflows/sprint-planning.md`:
    - Actualizar el workflow para estipular que el sprint planning es el ritual exclusivo donde el humano aprueba y sella el diseño macro que habilita la autonomía en las sesiones.
  - En `AGENTS.md`:
    - Incorporar la descripción del régimen Opción D en la sección de principios de diseño y flujo de trabajo sobre el core.
  - En `tests/validate-control-plane.sh`:
    - Adaptar las comprobaciones de consistencia de workflows en Check 34/35.
  - Caja de archivos: `.agents/workflows/session-start.md`, `.agents/workflows/sprint-planning.md`, `AGENTS.md`, `tests/validate-control-plane.sh`, `.agents/tasks/task-164.md`.
  - Veredicto de diseño: `[APROBADO_EN_PLANNING]`.
