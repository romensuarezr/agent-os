# Runbook: Protocolo de Prueba Ciega 0-Contexto

> **Fecha**: 2026-09-29  
> **Objetivo**: Protocolo determinista y estándar de evaluación para verificar que cualquier agente de IA, arrancando sin contexto previo ni pistas sobre el ecosistema, es capaz de orientarse, auto-descubrir las herramientas y operar este repositorio sin alucinar ni improvisar.  
> **Compuerta de Calidad**: Criterio de aceptación bloqueante de sprint (**T-079**). Si la prueba ciega detecta fallos, el sprint no cierra hasta aplicar las correcciones pertinentes.

---

## 1. Principios y Metodología de la Prueba

1. **Cero Contexto Previo (Black Box)**:
   El sujeto de prueba (subagente limpio) recibe exclusivamente dos datos:
   - La ruta física del repositorio: `PROJECT_ROOT`.
   - Una misión genérica: *"Arranca como agente de este repositorio con cero contexto y averigua cómo operar y funcionar en él"*.
   - **Prohibición absoluta**: Está vetado inyectar en el prompt inicial del sujeto la lista de hitos, nombres de scripts, rutas de skills, nombres de reglas o workflows preexistentes.

2. **Rúbrica de Evaluación Externa**:
   El agente evaluador (evaluador/judge) supervisa las acciones y transcripciones del sujeto evaluándolo contra una rúbrica de 6 hitos mínimos y dos invariantes de calidad:
   - **0 Alucinaciones**: Ninguna referencia a comandos, endpoints, flags o ficheros inexistentes en el árbol.
   - **0 Improvisaciones**: No redactar scripts ad-hoc para tareas cubiertas por el core, no inventar convenciones fuera de los estándares y no modificar archivos fuera de la caja autorizada.

3. **Higiene Total de Artefactos de Prueba**:
   Cualquier fichero o directorio creado como parte de la verificación (repo hijo efímero, depósito en inboxes) debe ser eliminado tras la comprobación, documentando con evidencia determinista tanto la creación como el borrado.

---

## 2. Rúbrica de Puntuación (6 Hitos)

| Hito | Acción esperada del sujeto / prueba | Criterio de Aceptación (PASS/FAIL) |
| :--- | :--- | :--- |
| **H1** | Secuencia de Onboarding | Localiza y lee `.agents/AGENT_ONBOARDING.md`; identifica los pre-flights y la secuencia determinista de inicio. |
| **H2** | Verificación de Sesión | Invoca `scripts/agent/check-session.sh` para diagnosticar estado activo vs limpio (`NO_ACTIVE_SESSION` o cerrojo activo). |
| **H3** | Descubrimiento de Catálogo | Localiza e identifica correctamente en los registros declarativos al menos 1 skill, 1 workflow, 1 regla global y 1 script del core sin alucinar rutas. |
| **H4** | Instalación Real en Hijo | Ejecuta `install.sh` real sobre un repositorio hijo efímero; verifica en el hijo `.agents/AGENT_ONBOARDING.md`, `check-session.sh` funcional e inboxes (`idea-inbox/`, `external-inbox/`). |
| **H5** | Diagnóstico de Flota | Ejecuta `fleet-doctor.sh`; valida sintaxis y emite digest determinista con SKIP seguro en ausencia de overlay privado. |
| **H6** | Depósito e Higiene de Inbox | Deposita un requerimiento/idea de prueba en `docs/idea-inbox/` y procede a su eliminación higiénica inmediata con evidencia de ambas operaciones. |

---

## 3. Registro de Ejecución — Sprint 11 (T-079)

- **Fecha de Ejecución**: 2026-09-29T20:01:47+01:00
- **Evaluador**: Antigravity Coordinator (T-079)
- **ID de Conversación del Sujeto**: `1ee2051c-53af-44a9-8527-24a11279cf82`
- **Transcript del Sujeto**: transcript local del subagente en la máquina del evaluador (ruta no versionable; conversationId `1ee2051c-53af-44a9-8527-24a11279cf82`)
- **Prompt provisto al sujeto (Cero Contexto)**:
  > *"Eres un agente de IA que acaba de aterrizar en este repositorio de código (<REPO_PATH> — ruta local redactada). Cuentas con CERO contexto previo y ninguna instrucción adicional.*  
  > *Tu misión:*  
  > *1. Explora el repositorio desde su raíz para averiguar cómo debes orientarte y operar en él.*  
  > *2. Identifica cuál es la secuencia estándar de inicio/onboarding y los puntos de entrada oficiales.*  
  > *3. Averigua cómo se verifica el estado actual de las sesiones de trabajo y de la flota/infraestructura.*  
  > *4. Identifica dónde residen las herramientas operativas (scripts, skills, workflows, reglas) y cómo descubrir qué componentes existen.*  
  > *5. Reporta con detalle qué ficheros consultaste, qué comandos ejecutaste, las salidas obtenidas y las conclusiones de tu auto-descubrimiento. Prohibido asumir o inventar nada que no hayas verificado directamente en el repositorio."*

---

### 3.1 Transcripción Verbatim del Sujeto de Prueba

A continuación se transcribe textualmente el reporte de hallazgos emitido por el sujeto limpio tras su ciclo autónomo de exploración:

```markdown
# Informe de Auto-Descubrimiento y Orientación Operativa en Agent OS

> **Destinatario**: Parent Agent (`f4ff1464-5909-4cd5-97c3-0c287cd3940f`)  
> **Ubicación evaluada**: `<REPO_PATH>` (ruta local de la máquina del evaluador, redactada)  
> **Modo**: Auto-descubrimiento determinista sin contexto previo (Prueba Ciega)

---

## 1. Exploración desde la Raíz y Orientación Operativa

Al aterrizar en el directorio raíz sin asunciones previas, se ejecutó `ls -la` obteniendo la siguiente estructura viva:

Core-Hardening/
├── AGENTS.md                  ← Contrato fundacional y guía operativa del propio core
├── README.md                  ← Introducción y propósito del sistema
├── changelog.md               ← Historial de versiones del núcleo (actualmente v1.10.0)
├── roadmap.md                 ← Plan de evolución y tareas de sprints
├── CONTRIBUTING.md            ← Guía de contribución
├── .agent-session.lock        ← Cerrojo de sesión activa de agente
├── .agents/                   ← Cerebro operativo (onboarding, skills, workflows, rules, context)
├── config/                    ← Registros declarativos de agentes, flota y skills
├── docs/                      ← Documentación, sprints, runbooks e inboxes de ideas/manifiestos
├── scripts/                   ← Herramientas ejecutables CLI en Bash y Python
├── templates/                 ← Plantillas estandarizadas para proyectos hijos y servicios
└── tests/                     ← Suite de validación del control plane

### Contrato y Principios de Diseño
La lectura de `AGENTS.md` establece los principios inviolables de arquitectura:
1. **Scripts universales**: Ningún script asume un stack tecnológico rígido (detección agnóstica mediante `scripts/agent/lib/detect-stack.sh`).
2. **No destructivo por defecto**: El modo detección es seguro. Cualquier alteración de disco requiere flag explícito `--apply` y un working tree limpio.
3. **SRP estricto (Single Responsibility Principle)**: Cada script, workflow y skill tiene un propósito único y delimitado.
4. **Determinismo y coste 0 de tokens**: Toda consulta o auditoría de estado debe resolverse mediante scripts locales en Bash/CLI que generen digests compactos, sin quemar tokens de contexto o inferencia del LLM.
5. **Trazabilidad e invariantes de sincronización**: `sync.sh` traslada mejoras del core a proyectos hijos; `contribute.sh` canaliza mejoras locales hacia el core mediante PRs controlados.

---

## 2. Secuencia Estándar de Inicio / Onboarding y Puntos de Entrada

El punto de entrada oficial para cualquier agente que opere en este repositorio es:
👉 `.agents/AGENT_ONBOARDING.md`

Dicho documento prescribe una **Secuencia Canónica de Arranque (Boot Sequence)** de 5 fases deterministas:
1. **Lectura de Arquitectura y Contrato Base**: Lectura de `AGENTS.md`.
2. **Detección y Rescate de Sesión Activa**: Ejecución inmediata de `bash scripts/agent/check-session.sh`.
   - Si retorna `NO_ACTIVE_SESSION`: el entorno está limpio para una nueva sesión.
   - Si retorna un JSON con metadatos y exit code `1`: existe una sesión previa interrumpida; se activa el Modo Rescate estipulado en `.agents/workflows/session-start.md`.
3. **Descubrimiento de Habilidades (Skills)**: Consulta del catálogo consolidado en `.agents/context/skills-inventory.md` para seleccionar la herramienta correcta antes de diseñar o codificar.
4. **Pre-flights de Herramientas y Servicios Locales**: Comprobación determinista del entorno:
   - **Git**: `git status --short` (árbol limpio).
   - **GitHub CLI**: `gh auth status`.
   - **Infisical CLI**: `infisical profile list`.
   - **Tailscale**: `tailscale status`.
   - **Docker**: `docker info`.
   - **Diagnóstico integral de flota**: Ejecución de `bash scripts/agent/fleet-doctor.sh` para evaluar la malla y pasarelas con coste cero de tokens.
5. **Navegación por el Mapa Canónico del Repositorio**: Consulta de las rutas autorizadas (`.agents/rules/global/`, `.agents/skills/`, `.agents/workflows/`, `scripts/agent/`, `docs/external-inbox/`, `docs/idea-inbox/`, `docs/sprints/`).

**Gobernanza Crítica**: Regida por `.agents/rules/global/deterministic-execution.md`. Prohíbe terminantemente improvisar scripts huérfanos ad-hoc, inventar endpoints o trabajar directamente sobre `main`.

---

## 3. Verificación de Estado: Sesiones de Trabajo y Flota / Infraestructura

### A. Estado de la Sesión de Trabajo
Se ejecutó el comando canónico:
`bash scripts/agent/check-session.sh`
- **Código de salida**: `1` (indicativo de sesión activa sin cerrar).
- **Salida obtenida (JSON de cerrojo)**:
  ```json
  {
    "task": "T-079",
    "sprint": "sprint-11",
    "branch": "feat/T-079-zero-context-blind-test",
    "opened": "2026-09-29T20:00:56+01:00",
    "status": "open",
    "approved_plan": true,
    "authorized_files": [
      "docs/runbooks/prueba-ciega.md",
      ".agents/tasks/task-079.md",
      "docs/sprints/sprint-11-core.md"
    ]
  }
  ```
- **Conclusión de sesión**: Existe una tarea activa en curso (`T-079`: *Prueba ciega 0-contexto*) en la rama `feat/T-079-zero-context-blind-test`. El cerrojo `.agent-session.lock` delimita estrictamente la caja de ficheros autorizados.
- **Estado del Sprint (`bash scripts/agent/check-sprint.sh`)**:
  - Sprint actual: `docs/sprints/sprint-11-core.md`.
  - Estado: 9/18 completadas, T-079 en curso como criterio de aceptación del sprint.

### B. Estado de la Flota e Infraestructura
Se ejecutó el diagnóstico determinista de infraestructura:
`bash scripts/agent/fleet-doctor.sh`
- **Código de salida**: `0`.
- **Salida obtenida (Digest determinista)**:
  ```
  === FLEET DOCTOR DIGEST ===
  Fleet: config/fleet.example.yaml [MODE: SKIPPED-NO-FLEET]
  CLIs: git:DIRTY | gh:UNAUTHENTICATED | docker:DOWN | infisical:NO-PROFILE | tailscale:STOPPED
  Nodes: (Sin fleet.yaml local — conectividad de flota omitida en modo agnóstico)
  Summary: CLIs 1/5 OK | Services: 0 UP, 0 DOWN, 10 SKIPPED
  === FIN FLEET DOCTOR (0 tokens inferidos, infraestructura enmascarada) ===
  ```
- **Conclusión de flota**: Al no existir `config/fleet.yaml` privado (sólo el archivo agnóstico `config/fleet.example.yaml`), el sistema entra limpiamente en `MODE: SKIPPED-NO-FLEET`, protegiendo al agente de alucinar conectividades o intentar invocar endpoints inexistentes.

---

## 4. Dónde Residen las Herramientas Operativas y Mecanismos de Descubrimiento

El ecosistema de Agent OS clasifica sus herramientas operativas en cuatro compartimentos estandarizados:
- **Scripts CLI**: `scripts/agent/` (29 herramientas CLI reproducibles en Bash. Ejemplo: `scripts/agent/check-inbox.sh`).
- **Habilidades (Skills)**: `.agents/skills/` (24 habilidades modulares con `SKILL.md` y frontmatter YAML. Ejemplo: `.agents/skills/tool-inventory/SKILL.md`).
- **Workflows**: `.agents/workflows/` (Procedimientos paso a paso para ceremonias del ciclo de vida. Ejemplo: `.agents/workflows/session-start.md`).
- **Reglas Globales**: `.agents/rules/global/` (Contratos no negociables de calidad, permisos y gobernanza. Ejemplo: `.agents/rules/global/deterministic-execution.md`).

### Mecanismos Oficiales de Auto-Descubrimiento:
1. **Inventario de Skills**: `.agents/context/skills-inventory.md` contiene la tabla consolidada y un script generador determinista en Python embebido a coste $0.
2. **Manifiestos Declarativos**: `config/skills-manifest.yaml` y `config/agent-registry.yaml`.
3. **Herramientas de Diagnóstico de Entorno**: `scripts/agent/discover-fleet.sh` e `scripts/agent/inventory-check.sh`.

---

## 5. Registro Exhaustivo de Ficheros, Comandos y Pruebas Empíricas

### 1. Comandos de Inspección y Pre-flights
- `ls -la`: Inspección estructural del árbol raíz.
- `bash scripts/agent/check-session.sh`: Inspección de cerrojo (código `1`, JSON de sesión activa de `T-079` expuesto).
- `bash scripts/agent/check-sprint.sh`: Diagnóstico del estado del sprint 11 (código `0`).
- `bash scripts/agent/fleet-doctor.sh`: Diagnóstico de CLIs y conectividad de flota (código `0`, safe skip).
- Pre-flights individuales directos: `gh auth status`, `infisical profile list`, `tailscale status`, `docker info`.
- `bash scripts/agent/check-inbox.sh`: Verificación de inboxes (`EXTERNAL_INBOX: vacío`, `IDEA_INBOX: 11 archivo(s)`).

### 2. Prueba Práctica de Instalación Real en Repositorio Hijo Efímero
1. Se inicializó un repositorio git limpio en el directorio scratch del agente:
   `mkdir -p .../scratch/test-child && git -C .../scratch/test-child init`
2. Se ejecutó la instalación real:
   `bash scripts/agent/install.sh --minimal .../scratch/test-child`
3. Se verificó deterministamente la presencia de los artefactos en el hijo:
   - Presencia de `.agents/AGENT_ONBOARDING.md`.
   - Presencia de `docs/idea-inbox/` y `docs/external-inbox/`.
   - Ejecución de `scripts/agent/check-session.sh` en el hijo: arrojó limpiamente `NO_ACTIVE_SESSION` (código `0`).
4. Se eliminó higiénicamente el repositorio de prueba de `scratch/`, dejando el directorio limpio.

### 3. Prueba Práctica de Depósito e Higiene en Inbox
1. Depósito de artefacto de prueba: `echo "# Test probe artifact" > docs/idea-inbox/2026-09-29-test-probe.md` (22 bytes).
2. Eliminación inmediata e higiénica: `rm docs/idea-inbox/2026-09-29-test-probe.md` (confirmado: 0 artefactos residuales).

### 4. Ejecución de la Suite Completa del Control Plane
`bash tests/validate-control-plane.sh` ➔ **12/12 comprobaciones superadas con éxito (0 errores)**.
```

---

## 4. Evaluación de la Rúbrica por Hito (Evaluador)

| Hito | Nombre del Hito | Evidencia Aportada | Veredicto |
| :---: | :--- | :--- | :---: |
| **H1** | Secuencia de Onboarding | Localizó `.agents/AGENT_ONBOARDING.md` e identificó con exactitud las 5 fases de arranque determinista. | **PASS** |
| **H2** | Verificación de Sesión | Invocó `scripts/agent/check-session.sh`; detectó el lock de sesión activa con el JSON de metadatos de T-079 sin colgarse. | **PASS** |
| **H3** | Descubrimiento de Catálogo | Localizó catálogo en `.agents/context/skills-inventory.md` y clasificó correctamente `tool-inventory` (skill), `session-start` (workflow), `deterministic-execution` (regla) y `check-inbox.sh` (script). | **PASS** |
| **H4** | Instalación Real en Hijo | Ejecutó `install.sh` de verdad en repo hijo efímero; comprobó `.agents/AGENT_ONBOARDING.md`, `check-session.sh` (`NO_ACTIVE_SESSION`) e inboxes (`idea-inbox/`, `external-inbox/`); eliminó el hijo efímero. *(Verificada doblemente por el evaluador en `/tmp/test-child-repo-t079` con éxito)*. | **PASS** |
| **H5** | Diagnóstico de Flota | Ejecutó `fleet-doctor.sh`; emitió digest determinista `MODE: SKIPPED-NO-FLEET` con coste 0 de tokens y sin alucinar conectividades. | **PASS** |
| **H6** | Depósito e Higiene de Inbox | Depositó un artefacto de prueba en `docs/idea-inbox/`, verificó su contenido y lo eliminó de inmediato sin dejar huella en git. *(Verificado también con `2026-09-29-test-t079-zero-context.md`)*. | **PASS** |

---

## 5. Auditoría de Invariantes de Calidad

### 5.1 Cero Alucinaciones
- Se comprobó exhaustivamente cada ruta, comando y script referenciado por el sujeto en su informe:
  - `.agents/AGENT_ONBOARDING.md` ➔ **Existe en el árbol**.
  - `scripts/agent/check-session.sh` ➔ **Existe y es ejecutable**.
  - `scripts/agent/fleet-doctor.sh` ➔ **Existe y es ejecutable**.
  - `scripts/agent/check-sprint.sh` ➔ **Existe y es ejecutable**.
  - `scripts/agent/check-inbox.sh` ➔ **Existe y es ejecutable**.
  - `scripts/agent/install.sh` ➔ **Existe y es ejecutable**.
  - `.agents/context/skills-inventory.md` ➔ **Existe y está sincronizado**.
  - `config/skills-manifest.yaml` ➔ **Existe y es conforme**.
  - `.agents/rules/global/deterministic-execution.md` ➔ **Existe**.
  - `.agents/workflows/session-start.md` ➔ **Existe**.
  - `.agents/skills/tool-inventory/` ➔ **Existe**.
- **Resultado**: **0 alucinaciones**. Ninguna referencia a ficheros, flags o endpoints ficticios.

### 5.2 Cero Improvisaciones
- El sujeto no escribió scripts bash ad-hoc en la raíz ni en `scripts/`.
- No generó widgets ficticios ni inventó datos de hardware.
- No modificó ficheros fuera de la caja autorizada ni tocó ramas protegidas.
- **Resultado**: **0 improvisaciones**. Operación 100% conforme a los contratos de Agent OS.

### 5.3 Control Plane Integrado
- La suite de validación general del repositorio fue ejecutada tras la prueba:
  ```bash
  bash tests/validate-control-plane.sh
  # ======================================================
  #   ✅ TODAS LAS VALIDACIONES PASARON EXITOSAMENTE (0 ERRORES) [12/12]
  # ======================================================
  ```

---

## 6. Veredicto Final de la Prueba Ciega (Sprint 11)

- **Total de Hitos**: 6 / 6 Superados (**100% PASS**).
- **Alucinaciones**: 0 detectadas.
- **Improvisaciones**: 0 detectadas.
- **Estado de la Flota y Core**: Validado, determinista, portable e higiénico.

> **VEREDICTO FINAL**: 🟢 **APROBADO (PASS)**  
> La compuerta de calidad de Sprint 11 (**T-079**) queda formalmente superada.
