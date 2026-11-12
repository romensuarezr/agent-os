# Sprint 37 — Research Técnico y Prospección

> Documento de persistencia técnica, prospección OSS y literatura empírica previa al inicio del Sprint 37.
> Cumple el Gate Scout-First (T-129) y el protocolo determinista de investigación soberana SearXNG ($0 tokens).

---

## 1. Contexto e Investigación Empírica

### A. Benchmark Base de Anthropic y Dev Knives
- **Problema de la orquestación descontrolada**: Estudios de Anthropic demuestran que un sistema multi-agente ingenuo ("fan-out" sin límites) puede consumir hasta **15x más tokens** que un agente individual, debido al tráfico de contexto duplicado y transcripciones completas entre subagentes.
- **La Solución ("Plan Big, Execute Small")**:
  Separar estrictamente la **planificación de alto nivel** (modelo *strong*, decisiones de arquitectura, delimitación de contratos) de la **ejecución mecánica** (modelos *cheap* o gratuitos locales, lectura/escritura acotada). Con esto se obtiene el **96% de la calidad reduciendo el coste a menos de la mitad**.
- **La Regla de Umbral (Floor Cost de Delegación)**:
  Toda delegación tiene un coste base en tokens y tiempo de coordinación. En tareas acotadas que tocan **$\le 3$ archivos**, orquestar en subagentes o worktrees paralelos es ineficiente y costoso; deben ejecutarse directamente en la sesión principal (`direct`).

### B. Análisis del Ecosistema: `alethe-orchestrate-skill` (`Kc1t/alethe-orchestrate-skill`)
Inspeccionado localmente en `/tmp/alethe-orchestrate-skill`:
- **Catálogo de Playbooks**: Define estrategias declarativas (`direct`, `scout-then-build`, `plan-big-execute-small`, `parallel-worktrees`, `review-gate`).
- **Aislamiento de contexto (*Anti-Context Rot*)**: Los workers devuelven únicamente respuestas breves, evidencia determinista y diffs (`git diff --stat`), nunca transcripciones crudas.
- **Onboarding y Detección Proactiva (`doctor`)**: Inspecciona qué CLIs y modelos están listos al arrancar, evitando que el usuario deba recordar los comandos internos.

---

## 2. Descubrimientos Scout (por tarea)

### T-201: Plantilla `AGENTS.md` para Satélites y Regla de Boot del Coordinador
- **Keywords**: `agent onboarding greeting protocol`
- **Alternativas OSS evaluadas**:
  - `major-ai-skills` (v2.5.0): Contratos modulares de skills, pero no resuelve el boot inicial a nivel de repo.
  - Reglas nativas de Antigravity (`AGENTS.md`, `.agents/rules/*.md`): Soporte nativo de inyección jerárquica de reglas al abrir el workspace.
- **Veredicto**: `Desarrollo a medida justificado`. Se implementa una plantilla estandarizada en `templates/root/AGENTS.md` (distribuida por `install.sh` y `sync.sh`) y la regla global `coordinator-boot.md` para auto-presentación en el primer turno.

### T-202: Catálogo de Playbooks de Orquestación y Regla $\le 3$ Archivos
- **Keywords**: `orchestration playbooks multi agent`
- **Alternativas OSS evaluadas**:
  - `jjanczur/tyran` (79⭐, Apache-2.0): Gestor de tareas para Claude Code, pero acoplado a un único CLI.
  - `sammyjason39/agent-build-playbook` (11⭐): Playbooks estáticos en Markdown.
  - `@ai-sdk-tools/agents` (v1.2.0): Orquestación programática JS/TS.
- **Veredicto**: `Desarrollo a medida justificado`. Adoptar el esquema declarativo YAML (`.agents/config/orchestration-playbooks.yaml`) con la regla de umbral de $\le 3$ archivos integrada en `session-start.md` y `orchestrator`.

### T-203: Contrato de Retorno Compacto Anti-Context Rot y Telemetría
- **Keywords**: `agent telemetry cost report`
- **Alternativas OSS evaluadas**:
  - `Lowfat` (Show HN, 156 pts): Filtro CLI de tokens en pipelines.
  - `Aireceipts`: Facturación desglosada por tarea.
  - `@microsoft/agents-telemetry`: SDK pesado dependiente de OpenTelemetry.
- **Veredicto**: `Desarrollo a medida justificado`. Implementar `scripts/agent/orchestration-report.sh` en Bash POSIX ($0 tokens) que analiza metadatos de cierre (`dispatched.jsonl`, `close-task.sh`) y emite métricas de tiempo, playbook empleado y ahorro de tokens.

### T-204: Ensayo y Validación E2E en Satélite Real (`annascheer-web`)
- **Alcance**: Validación práctica y protocolo paso a paso para el operador humano sobre `annascheer-web`.
- **Veredicto**: `Desarrollo a medida justificado`. Se valida que `sync.sh` traslada `AGENTS.md`, que el pre-flight del Coordinador responde de forma autónoma y que el operador puede probarlo manualmente.

---

## 3. Pre-flight de Búsqueda Soberana SearXNG

- **Sonda de salud**: `bash scripts/agent/lib/searxng-client.sh --check` → `[ACTIVO]` (HTTP 200).
- **Evidencia bibliográfica extraída**:
  - *Anthropic's Multi-Agent Research System Uses 15x the Tokens* (Nadir / Anthropic Research 2026).
  - *Claude Code Multi-Agent Orchestration: The Cost Math* (BrowseComp evaluation: $18.53 vs $40.56, calidad 86.8% vs 90.8%).
- **Conclusión**: El modelo híbrido de Agent OS (Antigravity Coordinator + OpenCode/Hermes Workers en worktrees efímeros a $0) alcanza el ratio óptimo de eficiencia y coste.
