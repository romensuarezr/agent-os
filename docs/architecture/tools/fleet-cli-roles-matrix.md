# 🗺️ Matriz de Roles y Capacidades de CLIs Agénticos de la Flota

> **Documento de Arquitectura y Gobernanza del Core**  
> **Área**: Gobernanza de Flota / Tooling Agéntico / Control Plane  
> **Fecha**: 2026-11-09  
> **Estado**: Vigente (Aprobado en Sprint 31 — T-172)  

---

## 1. Propósito y Principios de Gobernanza

La flota de Agent OS incorpora diversos CLIs agénticos y motores de ejecución distribuidos entre el entorno local (`host: local`) y nodos remotos (`<nodo-inferencia>`, `<nodo-orquestacion>`). Para evitar solapamientos, carreras de concurrencia, pérdida de trazabilidad en el repositorio y mutaciones fuera de control, la gobernanza del core impone una **delimitación estricta de roles, capacidades y guardarraíles**.

### Principios Inviolables:
1. **Soberanía Unificada de Git (Doctrina Sprint 25)**: Únicamente el Coordinador principal (`agy` bajo sesión autorizada) o el operador humano tienen potestad para fusionar ramas de trabajo hacia ramas troncales (`multi-agent`, `main`). Queda terminantemente prohibido delegar la resolución o fusión desatendida de merges a herramientas externas.
2. **Jerarquía Determinista de Deliberación**: El arbitraje técnico y deliberación de planes de desarrollo se resuelve de forma determinista mediante la cadena oficial del core:
   - **Tier 1**: Google Antigravity CLI (`agy`).
   - **Tier 2**: Orca ADE (`stablyai/orca`).
   - **Tier 3**: Cascada HTTP determinista / degradación segura a `SIN_REVISOR` ($0 tokens).
3. **Canal de Mensajería Nativo**: Los agentes especializados de mensajería (Hermes) operan a través de sus canales y puentes directos integrados con el usuario en el host; no se construyen pasarelas redundantes ni front doors intermedios adicionales.

---

## 2. Matriz Canónica de CLIs de la Flota

| CLI / Motor | Versión / Registro Canónico | Ubicación / Host | Rol Primario | Nivel de Autonomía | Potestad de Merge / Commit |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Antigravity CLI (`agy`)** | Binario oficial `agy` | `local` | **Coordinador, Planificador & Tier 1 Reviewer** | Supervisada / Opción D | Autorizado para orquestar ramas y merges controlados |
| **Orca ADE (`orca-ide`)** | `stablyai/orca` (vía `orca-orchestrate.sh`) | `local` / `<nodo-orquestacion>` | **Plano de Ejecución & Tier 2 Reviewer** | Supervisada en sandbox | Ejecución en worktrees; emisión de veredictos estructurados |
| **OpenCode 2 (`opencode`)** | `@opencode/cli` (npm v2.2.6) | `local` / `<nodo-inferencia>` | **Worker / Coder acotado** | Autonomía acotada en worktree | Restringido a commits en rama de trabajo efímera; **Merge Prohibido** |
| **Claude Code** | `anthropic/claude-code` | Entorno CLI experimental | *Descartado como Juez* | — | **Descartado del Control Plane** |
| **Aider CLI** | `aider-chat/aider` | Entorno CLI experimental | *Descartado para Merges* | — | **Prohibido para resolución de merges** |
| **Hermes Agent** | `NousResearch/hermes-agent` (v0.22.7) | `<nodo-inferencia>` / host | **Agente de Mensajería & Triage** | Autónomo en canal propio | Opera sobre su propio bridge; **Descartado como front door separado** |

---

## 3. Especificación Detallada y Guardarraíles por Herramienta

### 3.1. Antigravity CLI (`agy`)
- **Rol**: Agente principal de desarrollo, planificación, descomposición arquitectónica y arbitraje primario.
- **Capacidades**:
  - Gestión de sesiones interactivas (`session-start.md`, `close-task.sh`, `close-sprint.sh`).
  - Deliberación y revisión técnica como Tier 1 en `scripts/agent/deliberate-plan.sh`.
  - Orquestación y verificación de la suite de validación (`tests/validate-control-plane.sh`).
- **Guardarraíles**:
  - Respeto riguroso de la Caja de Archivos autorizada en el task file.
  - Ejecución bajo el régimen estándar de **Opción D** (autonomía acotada condicionada a consenso).

### 3.2. OpenCode 2 (`@opencode/cli`)
- **Rol**: Worker / Coder acotado para implementación de código y refactorizaciones mecánicas.
- **Capacidades**:
  - Ejecución en worktrees efímeros o sandboxes aislados.
  - Modificación de código fuente dentro de la caja autorizada y ejecución de linters o pruebas unitarias locales.
- **Guardarraíles y Prohibiciones Estrictas**:
  - ❌ **Prohibida su elevación a Coordinador**: OpenCode no planifica sprints ni aprueba planes.
  - ❌ **Prohibido el merge desatendido**: No puede ejecutar `git merge` hacia ramas troncales (`multi-agent`, `main`).
  - ❌ **Prohibida la mutación de secretos o configuraciones de red de la flota**.

### 3.3. Orca ADE (`stablyai/orca`)
- **Rol**: Plano supervisado de ejecución de tareas complejas y Revisor Ejecutor determinista (Tier 2).
- **Capacidades**:
  - Aislamiento estricto de variables de entorno (`env -i`) con presupuesto temporal acotado (máx 60s).
  - Emisión de fallbacks seguros sin residuos en caso de timeout o degradación.
- **Guardarraíles**:
  - Operación confinada a las políticas declaradas en `.agents/config/routing-policy.yaml`.

---

## 4. Decisiones Macro de Exclusión y Justificación Técnica

### 4.1. Descarte Formal de Claude Code como Juez / Árbitro
- **Decisión**: Claude Code queda **terminantemente excluido** de la cadena de deliberación de planes y arbitraje técnico de Agent OS.
- **Justificación**:
  - La cadena determinista del core ya cuenta con redundancia y resiliencia probada: Antigravity CLI (`agy`, Tier 1) y Orca ADE (Tier 2), con degradación segura a $0 tokens.
  - Integrar Claude Code como árbitro introduciría opacidad, dispersión de dependencias de API comercial y riesgo de alucinaciones en compuertas de seguridad críticas sin aportar garantías de reproducibilidad.

### 4.2. Descarte Formal de Aider para Rescate de Merges
- **Decisión**: Aider queda **terminantemente excluido** como mecanismo automatizado de resolución de conflictos de merge entre worktrees o satélites.
- **Justificación**:
  - La doctrina de gobierno de Git establecida en el Sprint 25 consagra que los conflictos de integración deben resolverse exclusivamente por el Coordinador responsable o escalarse al operador humano.
  - Los scripts deterministas `worktree-dispatch.sh` y `worktree-merge.sh` aplican políticas seguras `fast-forward` o fallan de inmediato (*fail-closed*). Ceder la resolución de código en conflicto a heurísticas de Aider vulnera la trazabilidad y la integridad de los contratos de tarea.

### 4.3. Descarte de Hermes como Front Door Separado Universal
- **Decisión**: Hermes no actuará como una pasarela o front door redundante universal frente a la flota.
- **Justificación**:
  - Hermes fue desplegado en `<nodo-inferencia>` con su propio puente de mensajería (`whatsapp-bridge`) para interactuar con el usuario.
  - Crear una capa adicional de front door añadiría latencia y puntos de fallo innecesarios; Hermes mantiene su propósito especializado de mensajería mientras el control plane de tareas reside en el core de Agent OS.

---

## 5. Mapeo con Perfiles Declarativos (`.agents/profiles/`)

Cada rol definido se corresponde con un perfil declarativo validado por el control plane:

- **`coordinator.yaml`**: Perfil de orquestación, gobernanza y gestión de sesión (asignado a `agy` / operador).
- **`developer.yaml`**: Perfil de implementación técnica y desarrollo DRY/TDD (asignado a `agy` / `opencode` en worktree).
- **`reviewer.yaml`**: Perfil de compuerta técnica y deliberación (asignado al evaluador de `deliberate-plan.sh`).
- **`ops-auditor.yaml`**: Perfil de supervisión de infraestructura y control de caja (asignado a Orca ADE).

Todos los perfiles garantizan la presencia de los 9 campos obligatorios del Check 2 y se mantienen 100% agnósticos de infraestructura personal.
