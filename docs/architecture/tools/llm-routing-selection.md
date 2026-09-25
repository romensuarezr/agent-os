# 🧠 Arquitectura de Enrutamiento y Selección de LLMs en Orquestaciones Multi-Agente

> **Documento de Arquitectura y Diseño de Sistemas**  
> **Área**: Orquestación Multi-Agente / Eficiencia de Tokens / Control Plane  
> **Fecha**: 2026-09-25  
> **Estado**: Vigente (Alineado con Orca ADE, Agent OS y $0 Inference Mandate)

---

## 1. El Principio Rector: Inferencia $0 y Reserva Quirúrgica de Antigravity

El sistema opera bajo un mandato estricto de eficiencia económica y técnica:
**CERO GASTO EN APIs EXTERNAS O MODELOS DE PAGO**.

```
                           ┌───────────────────────────────────────────┐
                           │          TAREA GLOBAL ENTRADA             │
                           └─────────────────────┬─────────────────────┘
                                                 │
                                                 ▼
                              ┌─────────────────────────────────────┐
                              │     COORDINADOR (Orca / agy)        │
                              │  Modelo: Sonnet/Opus o Gemini Pro   │
                              │  (Uso quirúrgico: solo trocear)     │
                              └──────────────────┬──────────────────┘
                                                 │
                    ┌────────────────────────────┴────────────────────────────┐
                    ▼                                                         ▼
       ¿Es diseño crítico / arquitectura?                        ¿Es código, tests o docs?
                    │                                                         │
                    ▼                                                         ▼
         CUOTA LIMITADA AGY                                        TIER $0 OBLIGATORIO
   ┌────────────────────────────────┐                        ┌─────────────────────────────────┐
   │ • agy (cuenta principal)       │                        │ • FreeLLMAPI (datamanager:3001) │
   │ • agy2 (cuenta secundaria)     │                        │ • OmniRoute (150+ free models)  │
   │   (Solo si no hay alternativa) │                        │ • Ollama local (offline)        │
   │   (Sonnet / Opus reservado)    │                        │ • OpenCode CLI ($0 tokens)      │
   └────────────────────────────────┘                        └─────────────────────────────────┘
```

### Reglas de Acceso a Modelos Comerciales:
1. **Antigravity CLI (`agy` y `agy2`)**:
   - Es el **único** entorno de la flota con acceso a modelos comerciales de alta fidelidad (Claude 3.5 Sonnet, Claude Opus, Gemini Pro).
   - Estos modelos cuentan con cuotas limitadas y límites de ratio por minuto (RPM).
   - Su uso queda **estrictamente restringido al Coordinador** para descomponer problemas, formular contratos de tareas y realizar la validación final del diff, o para modificaciones críticas de arquitectura donde un fallo comprometa la seguridad del sistema.
   - En caso de saturación o rate limit en la cuenta principal (`agy`), el enrutador conmuta a la cuenta secundaria (`agy2`), descubierta dinámicamente en T-046.
2. **Workers de Ejecución (Código, Tests, Diffs, Documentación, Mocks)**:
   - **Tienen prohibido consumir cuotas comerciales**.
   - Se ejecutan obligatoriamente sobre los concentradores de coste $0:
     - **FreeLLMAPI** en `datamanager:3001` ($0.00 / token vía Tailscale).
     - **OmniRoute** (pasarela candidata con 150+ proveedores gratuitos y compresión RTK).
     - **Ollama** en `datamanager:11434` (inferencia local 100% offline y privada).
     - **OpenCode CLI** operando como worker terminal autónomo.

---

## 2. ¿Quién Decide qué LLM se usa en cada Agente para cada Tarea?

La toma de decisiones de modelos se estructura en **tres capas desacopladas**:

```
[CAPA 1: POLÍTICA DECLARATIVA] ──▶ config/routing-policy.yaml (.agents/profiles/)
           │                     (Reglas estáticas de afinidad por tipo de tarea)
           ▼
[CAPA 2: DECISIÓN DEL COORDINADOR] ──▶ Al trocear la épica en subtareas (DAG)
           │                     (Evalúa complejidad semántica: TIER_PREMIUM vs TIER_FREE)
           ▼
[CAPA 3: ENRUTADOR DE PASARELA] ──▶ FreeLLMAPI / OmniRoute / RouteLLM
                                 (Balanceo dinámico, reintentos y failover ante error 429)
```

### Capa 1: Política Declarativa de Proyecto (`config/routing-policy.yaml`)
Define el mapeo base entre categorías funcionales y endpoints de computación:

- **`critical_tasks`**: Diseño nuclear, migraciones de datos, políticas de permisos.
  - *Tier*: `primary-reliable` (Antigravity commercial).
  - *Justificación*: El coste de una alucinación supera con creces el ahorro de tokens.
- **`code_implementation`**: Generación de código en ramas/worktrees aislados.
  - *Tier*: `primary-reliable` (si es arquitectura) → `freellmapi` / `omniroute` → `ollama-local` (`mistral-nemo:12b`).
- **`read_only_operations`**: Auditoría de logs, diffs de git, inspección de servidores.
  - *Tier*: `freellmapi` / `ollama-local` (`llama3.1:8b`). Coste $0 garantizado.
- **`marketing_and_seo`**: Copys, documentación técnica, resúmenes de release.
  - *Tier*: `freellmapi` / `qwen2.5:7b`.

### Capa 2: Decisión Semántica del Coordinador (Nivel de Tarea)
El agente Coordinador no delega "a ciegas". Al descomponer una épica en subtareas dentro de Orca ADE, evalúa tres variables:
1. **Volumen de Contexto**: Tareas que requieren leer cientos de líneas de logs o documentación se derivan a endpoints $0 con ventana amplia (o FreeLLMAPI).
2. **Impacto de la Mutación**: Tareas locales de refactorización de tests se asignan a OpenCode con FreeLLMAPI ($0).
3. **Nivel de Abstracción**: Solo el diseño inicial del contrato de interfaz o el esquema se procesa con el modelo del Coordinador (`agy`).

### Capa 3: Enrutador de Pasarela y Mitigación de Caídas (RouteLLM & OmniRoute)
De la prospección técnica (`scout.sh`), adoptamos dos principios de diseño:
1. **Principio RouteLLM (LMSYS)**: Los prompts sencillos o deterministas no deben enviarse a modelos pesados. Un clasificador heurístico local enruta solicitudes básicas a modelos locales o gratuitos sin degradación de calidad.
2. **Principio OmniRoute**: Si un proveedor gratuito sufre un error HTTP 429 o timeout, la pasarela conmuta transparentemente al siguiente proveedor disponible sin abortar la ejecución del agente worker.

---

## 3. Matriz de Asignación de Agentes y Modelos en Orca ADE

| Perfil Agent OS | Rol en la Orquestación | Runtime CLI en Orca | Tier de Modelo Predeterminado | Coste por Token |
| :--- | :--- | :--- | :--- | :---: |
| **`coordinator`** | Trocea tareas, asigna contratos, responde preguntas (`reply`) y aprueba merges. | `agy` (o `agy2`) | `primary-reliable` (Claude 3.5 / Gemini Pro) | Cuota controlada |
| **`developer`** | Implementa código y refactors en su worktree asignado. | `opencode` / `codex` | `freellmapi` (`qwen2.5-coder:32b` / `deepseek-r1`) | **$0.00** |
| **`reviewer`** | Audita diffs de git, busca vulnerabilidades y verifica tests. | `opencode` / `claude` | `freellmapi` / `mistral-nemo:12b` | **$0.00** |
| **`ops-auditor`** | Inspecciona contenedores, salud de bases de datos y relés en VPS. | `hermes` / `opencode` | `ollama-local` (`llama3.1:8b`) | **$0.00** |
| **`researcher`** | Prospección determinista, búsqueda de documentación y dependencias. | `scout.sh` / CLI | Determinista (0 tokens de inferencia) | **$0.00** |

---

## 4. Implementación del Despacho en Orca ADE

Al invocar trabajadores desde el Coordinador en Orca:

```bash
# 1. Crear el Run global de orquestación
orca orchestration run-create --objective "Implementar módulo de facturación" --json

# 2. Despachar Worker Developer sobre Worktree aislado con OpenCode ($0 inferencia)
orca worktree create --name feat-billing-core --no-parent --json
orca terminal create --worktree id:<repoId>::<path> --command "opencode" --json
orca orchestration worker-start --spec "Crear entidades y repositorio en src/billing/" --agent opencode --json

# 3. Despachar Worker Reviewer en paralelo para diseñar el arnés de pruebas ($0 inferencia)
orca worktree create --name test-billing-harness --no-parent --json
orca terminal create --worktree id:<repoId>::<path> --command "opencode" --json
orca orchestration worker-start --spec "Escribir tests unitarios mockeados en tests/billing/" --agent opencode --json

# 4. El Coordinador supervisa la finalización de ambos trabajadores concurrentes
orca orchestration check --wait --types "worker_done,escalation,question" --json
```

Esta arquitectura garantiza que la orquestación multi-agente sea fluida, simultánea, segura y con un coste económico de exactamente **$0.00** en todas las fases de ejecución masiva de código.
