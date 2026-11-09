# Executive Design Digest — T-172

## 🎯 Objetivo
Formalizar la matriz de roles, capacidades, perfiles YAML y guardarraíles de ejecución de los CLIs agénticos presentes en la flota de Agent OS (OpenCode 2, Claude Code, Aider, Hermes y Antigravity), codificando las decisiones macro vinculantes del operador en los perfiles declarativos y documentación de arquitectura.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico de T-172 codifica con máxima fidelidad las directivas macro vinculantes del operador para la gobernanza de la flota (OpenCode 2 como worker acotado en sandbox, agy/Orca ADE en orquestación y arbitraje, y los descartes formales de Claude Code como juez, Aider como rescatador de merges y Hermes como front-door separado). La delimitación de la caja de archivos autorizada es precisa y no presenta riesgo de fuga de credenciales ni acoplamiento indebido.

El enfoque garantiza la preservación estricta del denominador 38/38 en tests/validate-control-plane.sh, prestando especial atención a los esquemas obligatorios de .agents/profiles/ (Check 2) y a la política de frontera portable (Check 22) mediante marcadores agnósticos. El plan cumple íntegramente con los criterios de Opción D para proceder a la fase de implementación por el worker.
- **Prospección Scout**: `CONFORME (sprint-31-research.md)`
  - Alternativa detectada:** CLIs de agentes en ecosistema OSS y comercial (`@opencode/cli` npm v2.2.6 / repo `anomalyco/opencode`, `stablyai/orca` / binario `orca-ide`, `NousResearch/hermes-agent` v0.22.7, Anthropic Claude Code CLI con flag `--dangerously-skip-permissions`, Aider CLI con `--yes-always`, Google Antigravity CLI `agy`).
  - Recomendación del agente:** Formalizar la gobernanza de herramientas mediante una matriz declarativa de roles y perfiles YAML en `.agents/profiles/`, acotando el radio de impacto de cada CLI y delimitando claramente qué herramientas actúan como workers, jueces, coordinadores o deliberadores.
  - Dictamen del Relé (Decisiones Macro Vinculantes del Usuario):**
  - OpenCode 2:** Rol ratificado como Worker / Coder acotado en sandbox / worktrees efímeros.
- **Mensaje de Cierre**: `Merge branch 'feat/T-172-fleet-cli-roles-matrix' into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/config/agent-registry.yaml`
- `.agents/config/fleet.example.yaml`
- `.agents/profiles/coordinator.yaml`
- `.agents/profiles/developer.yaml`
- `.agents/tasks/_archived/task-172.md`
- `docs/architecture/tools/fleet-cli-roles-matrix.md`
- `docs/sprints/sprint-31-core.md`

## 🧠 Skills Declaradas y Aplicadas
- `agent-os-scripts`
- `tool-inventory`
