# Research y Prospección Tecnológica — Sprint 22

> **Documento de Respaldo Scout (Fase 2d / 2e del Sprint Planning)**  
> **Tema**: Resiliencia de Orquestación Multi-Agente, Puentes de Estado y Flujos Autónomos  
> **Herramienta determinista de prospección**: `scripts/agent/scout.sh` (coste $0 de inferencia).  
> **Fecha de ejecución**: 2026-10-29

---

## Metodología y Ejecución de Búsquedas Scout

Se ejecutaron consultas deterministas sobre el ecosistema open source (GitHub, NPM Registry y Hacker News) mediante `scripts/agent/scout.sh`:
1. `git worktree preserve untracked state merge`
2. `planning research scout enforcement automated check`
3. `llm inference fallback cascade routing policy`
4. `multi agent end to end integration test harness`

---

## Descubrimientos Scout (por tarea)

### T-128: Puente de Deliberación Worktree → Principal (Preservación de Estado en Desmontaje)

- **Alternativas detectadas**:
  - `@deepseek-ai/dsh-experimental-worktree` (v0.2.1-alpha.2, NPM): Utilidad que gestiona Git worktrees mutando el directorio de la sesión activa (`https://www.npmjs.com/package/@deepseek-ai/dsh-experimental-worktree`).
  - `@linxin666/dsh-client-ui-git-graph` (v0.4.12, NPM): Plugin visual de Git graph para sesiones de trabajo (`https://www.npmjs.com/package/@linxin666/dsh-client-ui-git-graph`).
  - `supports-preserve-symlinks-flag` (v1.0.0, NPM): Utilidad técnica para banderas de symlinks en Node.js (`https://www.npmjs.com/package/supports-preserve-symlinks-flag`).
- **Recomendación del agente**: Construir. Enriquecer `scripts/agent/worktree-merge.sh` para rescatar `.agents/context/deliberation-${TASK_ID}.json` desde el worktree efímero hacia el checkout principal antes de ejecutar `git worktree remove --force`.
- **Decisión vigente**: Construcción interna (acordada en planning). Permite que el checkout principal mantenga la deliberación real del worker sin degradar a `N/A` en `close-task.sh`, respetando el aislamiento gitignored.
- **Notas de integración**: Se implementa como paso determinista en `worktree-merge.sh` (paso 3b de merge), verificando existencia del fichero de deliberación antes de la purga del directorio hermano.
- **Alternativas rechazadas y motivos**:
  - `@deepseek-ai/dsh-experimental-worktree`: Rechazado. Muta el directorio del proceso llamante y carece de soporte para rescate de artefactos de contexto no versionados; incompatible con el aislamiento de subprocesos y la convención de worktrees fuera del árbol (T-107 / ADR 004).
  - `@linxin666/dsh-client-ui-git-graph`: Rechazado. Interfaz gráfica web innecesaria para un flujo headless y desatendido de integración CLI.
  - `supports-preserve-symlinks-flag`: Rechazado. Paquete micro-utilidad de Node.js ajeno a la gestión del ciclo de vida de Git worktrees.

---

### T-129: Enforcement Scout y Auditoría de Completitud en Workflow de Planning

- **Alternativas detectadas**:
  - `@pipedream/yutori` (v0.1.1, NPM): Componentes de automatización de flujos Pipedream (`https://www.npmjs.com/package/@pipedream/yutori`).
  - `deepthink-js` (v2.1.0, NPM): Módulo de procesos agénticos para LLMs locales o cloud (`https://www.npmjs.com/package/deepthink-js`).
  - `bn.js` (v5.2.5, NPM): Librería matemática de números grandes (resultado espurio de búsqueda de NPM).
- **Recomendación del agente**: Construir. Implementar compuertas obligatorias de scout en `.agents/workflows/sprint-planning.md` y un validador determinista de completitud en `design-digest.sh` (campo scout verificado en planning).
- **Decisión vigente**: Construcción interna (acordada en planning tras la lección operativa del Sprint 21). Garantiza que ningún sprint se publique sin su correspondiente `sprint-XX-research.md` estructurado y sin deliberación.
- **Notas de integración**: Añade al pre-flight de planning y a `design-digest.sh` la aserción de que exista la sección `## Descubrimientos Scout (por tarea)` con subsecciones completas para cada tarea planificada.
- **Alternativas rechazadas y motivos**:
  - `@pipedream/yutori`: Rechazado. Plataforma SaaS de integración que introduce dependencia de un servicio de suscripción externo; viola el principio de soberanía y ejecución local a coste $0.
  - `deepthink-js`: Rechazado. Framework en Node.js enfocado en loops de razonamiento conversacional, no en validación de políticas de archivo ni gobernanza de repositorios de software.
  - `bn.js`: Rechazado. Librería de aritmética matemática totalmente ajena al propósito.

---

### T-130: Cascada de Inferencia y Fallback Resiliente en Routing Policy

- **Alternativas detectadas**:
  - `crzyc0d3r/llm-router-ranking-engine` (0⭐, No lic, GitHub): Enrutador de inferencia con resolución de intenciones y ranking de latencia/coste (`https://github.com/crzyc0d3r/llm-router-ranking-engine`).
  - `@kortix/llm-catalog` (v0.14.8, NPM): Catálogo de modelos y pasarelas Kortix (`https://www.npmjs.com/package/@kortix/llm-catalog`).
  - `@oh-my-pi/pi-catalog` (v18.13.3, NPM): Base de datos de modelos y descriptores de proveedores (`https://www.npmjs.com/package/@oh-my-pi/pi-catalog`).
  - `@mlc-ai/web-llm` (v0.2.86, NPM): Motor de chat en navegador con aceleración hardware (`https://www.npmjs.com/package/@mlc-ai/web-llm`).
- **Recomendación del agente**: Construir. Extender `.agents/config/routing-policy.yaml` con lista de fallback ordenada (`fallback_cascade: [primary-reliable, freellmapi, offline_fallback]`) y soporte en `scripts/agent/deliberate-plan.sh`.
- **Decisión vigente**: Construcción interna (derivada de las ideas de vídeo de routing-policy evaluadas en planning). Ofrece tolerancia a fallos escalonada sin bloquear al agente.
- **Notas de integración**: Si el endpoint primario excede el timeout de 5s, el motor intenta de forma determinista el siguiente tier configurado antes de degradar limpiamente a `SIN_REVISOR`.
- **Alternativas rechazadas y motivos**:
  - `crzyc0d3r/llm-router-ranking-engine`: Rechazado. Repositorio sin licencia de código abierto (No lic), no verificable y dependiente de rankings de precios comerciales dinámicos que consumen ancho de banda de red.
  - `@kortix/llm-catalog` y `@oh-my-pi/pi-catalog`: Rechazados. Paquetes NPM de catálogos masivos de modelos con dependencias de actualización continua; sobredimensionados para la política declarativa YAML ligera de agent-os.
  - `@mlc-ai/web-llm`: Rechazado. Solución orientada a navegadores web con WebGPU, no aplicable al plano de control en servidor y CLI.

---

### T-131: Ensayo End-to-End del Bucle Multi-Agente con Check 36 en Validate Control Plane

- **Alternativas detectadas**:
  - `agentic-flow` (v2.1.5, NPM): Meta-harness agéntico de runtime abierto (`https://www.npmjs.com/package/agentic-flow`).
  - `@deepseek-ai/dsh-compaction` (v0.0.1-rc.5, NPM): Servicio abstracto de compactación de contexto para arneses DeepSeek (`https://www.npmjs.com/package/@deepseek-ai/dsh-compaction`).
  - `statsig-node` (v6.5.2, NPM): SDK de feature flags y pruebas A/B para Node.js (`https://www.npmjs.com/package/statsig-node`).
  - Discusión Hacker News: *A three-layer memory architecture for long-running agents* (HN:46097759).
- **Recomendación del agente**: Construir. Integrar el Check 36 en `tests/validate-control-plane.sh` ejecutando el ciclo de vida completo en un fixture aislado y actualizando el denominador de la suite de 35 a 36.
- **Decisión vigente**: Construcción interna (acordada en planning para certificar que el puente T-128, el enforcement T-129 y la cascada T-130 funcionan integrados de forma armónica).
- **Notas de integración**: El ensayo simula: despacho a worktree con `worktree-dispatch.sh` → generación de plan y deliberación determinista → auto-verificación preliminar → integración con `worktree-merge.sh` y rescate de deliberación → generación de digest histórico en `close-task.sh` con veredicto persistido → verificación de purga con `worktree-gc.sh`.
- **Alternativas rechazadas y motivos**:
  - `agentic-flow`: Rechazado. Framework de ejecución que impone su propio runtime demonizado y formato de mensajes; incompatible con las suites deterministas en Bash/POSIX de agent-os.
  - `@deepseek-ai/dsh-compaction`: Rechazado. Módulo experimental específico de compactación de memoria para DeepSeek; no aborda la validación end-to-end del ciclo de vida git.
  - `statsig-node`: Rechazado. Plataforma de analítica y feature flags SaaS, fuera del ámbito de testing de un sistema operativo para agentes.
