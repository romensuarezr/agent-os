# Research Sprint 25 — Despacho Paralelo Controlado (Piloto Experimental y Gate de Validación)

> **Sprint**: Sprint 25 — Core de Agent OS  
> **Fecha**: 2026-10-30  
> **Ámbito**: Caracterización arquitectónica, prospección determinista OSS (Scout-First) y resolución de incógnitas empíricas para el piloto de despacho concurrente supervisado.  
> **Gate de Validación**: Compuerta cuantitativa de paralelismo definida en T-140 (`docs/sprints/sprint-24-observation-report.md`).  

---

## 1. Resolución de Incógnitas Abiertas del Sprint 24

Durante el Sprint 24 se operó el Revisor Ejecutor en modo secuencial estricto (1 worker a la vez), posponiendo cuatro incógnitas arquitectónicas críticas que debían resolverse con evidencia empírica antes de diseñar el piloto concurrente del Sprint 25:

### 1.1 Dueño del Worktree: Worktrees de Agent OS frente a Workspaces Nativos de Orca

- **Diagnóstico del problema**: Tanto Agent OS como Orca ADE disponen de primitivas de aislamiento de directorios de trabajo. Era necesario delimitar con exactitud quién posee la autoridad sobre el ciclo de vida del sistema de archivos.
- **Resolución arquitectónica**:
  - **Agent OS es el dueño exclusivo del ciclo de vida del árbol Git**: El aprovisionamiento de directorios efímeros aislados se realiza mediante `scripts/agent/worktree-dispatch.sh`, creando un árbol hermano al repo principal (`<padre>/<repo>-<task-id>/`, fuera del árbol según T-107 para evitar contaminación).
  - **Orca ADE es el runtime de cómputo subordinado**: Orca no crea ni gestiona el repositorio de trabajo; recibe el path aprovisionado como contexto de ejecución (`--target` o variable de entorno de trabajo) y ejecuta las herramientas sobre él. Las capacidades nativas de Orca (`folder-workspace`, `worktree.provisioned-root`) se utilizan exclusivamente como conectores de terminal/proceso, nunca como gestores de ramas ni de estado de Git.
  - **Invariante**: Ningún worker concurrente puede mutar o alterar el directorio raíz del repositorio coordinador; todo trabajo se confina estrictamente en el worktree asignado a su `task_id`.

### 1.2 Quién Borra y Quién Fusiona (Matriz de Responsabilidad)

- **Diagnóstico del problema**: En arquitecturas paralelas mal diseñadas, los workers concurrentes intentan fusionar sus propias ramas o desmantelar sus propios directorios, originando condiciones de carrera y corrupciones del ref log.
- **Resolución arquitectónica**:
  - **El Worker Concurrente es estrictamente un ejecutor acotado**: El worker solo tiene permisos para escribir en su propio worktree y emitir eventos de progreso o finalización (`worker_done`). Tiene terminantemente prohibido ejecutar `git checkout`, `git merge`, `git push` al branch principal o `git worktree remove`.
  - **El Coordinador (u Operador Humano) es el único que fusiona y borra**: La integración de resultados se realiza centralizadamente a través de `scripts/agent/worktree-merge.sh`. Este script evalúa las compuertas desacopladas (`verify-goal.sh`), rescata los artefactos de deliberación, ejecuta el merge controlado (`fast-forward` o `--no-ff` supervisado) y realiza el desmantelamiento atómico (`git worktree remove --force` + `git worktree prune`).
  - **Semántica de REJECT**: Si una compuerta falla o el trabajo es rechazado, `worktree-merge.sh` preserva el worktree intacto para inspección y depuración post-mortem, sin afectar a los demás workers activos.

### 1.3 Qué Pasa con un Worker Abandonado (Mecanismos de Reap y Limpieza)

- **Diagnóstico del problema**: En ejecuciones concurrentes, la interrupción prematura de un script (ej: `SIGINT`, timeout de socket, caída del proceso padre) puede dejar workers y terminales zombi consumiendo recursos en el host.
- **Resolución arquitectónica**:
  - **Traps de Señales Vinculantes en Shell**: Todo despachador de workers debe declarar traps obligatorios para señales estándar (`trap 'cleanup_parallel_workers' EXIT INT TERM HUP`), invocando `orca orchestration worker-stop` seguido de `orca orchestration worker-release` para cada `dispatch_id` activo.
  - **Censo Preventivo (`worker-list`)**: Antes de iniciar cualquier lote y al finalizarlo, el coordinador invoca deterministamente `orca orchestration worker-list --json` para verificar que el conteo de terminales activas sea exactamente `0`.
  - **Política de Rescate / Stale Reclaim**: Orca ADE dispone de `orcad.stale-lock-reclaim.v1`. Si un terminal queda colgado, el orquestador aplica una fase de limpieza explícita (`worker-stop --force` + `worker-release --archive`), garantizando que ningún proceso residual persista entre iteraciones.

### 1.4 Presupuesto de Memoria RAM por Worker Concurrente

- **Medición empírica en host (Sprint 24)**:
  - Consumo en reposo por terminal Orca: **~95–115 MB**.
  - Consumo en pico de inferencia y streaming de buffer: **~380–430 MB**.
- **Evaluación de viabilidad en host de 16 GB**:
  - Para el piloto concurrente acotado a **2 workers simultáneos**:
    $$\text{RAM Consumida} = 2 \times [100\text{ MB} - 430\text{ MB}] = 200\text{ MB} - 860\text{ MB}$$
  - En el peor escenario de pico simultáneo, 2 workers consumen **< 860 MB** (< 5.5% de los 16 GB totales de memoria del host).
  - Esto deja un margen superior a **15 GB libres** para el sistema operativo, servicios de orquestación y modelos locales de inferencia, confirmando la total viabilidad operativa del límite de 2 workers sin riesgo de OOM (Out Of Memory).

---

## 2. Compuerta de Salida (Gate de T-140) — Marco Cuantitativo Vinculante

El piloto del Sprint 25 se somete literalmente al contrato formalizado en la sección 6 de `docs/sprints/sprint-24-observation-report.md`:

| Métrica / Dimensión | Umbral Obligatorio (Criterio GO) | Condición de Bloqueo Inmediato (NO-GO) |
|---|---|---|
| **Latencia Concurrente (P95)** | **P95 < 45.0 segundos** con hasta 2 workers | Latencia sostenida > 55.0s o P95 ≥ 45.0s |
| **Tiempo Máximo Individual** | **< 60.0 segundos** (timeout default `routing-policy.yaml`) | Cualquier worker individual que supere los 60.0s |
| **Disponibilidad Tier 1** | **≥ 95.0%** resuelto en Orca nativo en batería de 10 ejecuciones | Degradación recurrente a HTTP o `SIN_REVISOR` (< 95%) |
| **Estabilidad de Terminales** | **0 terminales huérfanas** tras `worker-release` | Detección de ≥ 1 terminal residual en `worker-list` |
| **Gestión de Buzón FIFO** | **100% de entregas acusadas con `--ack`** | Mensajes acumulados o re-emisión por omisión de `--ack` |
| **Aislamiento Concurrente** | **0 colisiones de lock** en `.agents/context/` y `env -i` estricto | Contaminación de variables o sobrescritura de archivos |

> [!CAUTION]
> **Principio de No Forzar el Paralelo**:  
> Si las pruebas de estrés o el análisis final no satisfacen los umbrales de la compuerta, **el Sprint 25 cerrará con veredicto NO-GO**. En ese escenario, Agent OS permanecerá en su modo secuencial certificado (1 worker) y no se habilitará el paralelismo en el core.

---

## 3. Descubrimientos Scout (por tarea)

En cumplimiento estricto del protocolo Scout-First (T-129), se ha ejecutado prospección tecnológica determinista ($0 inferencia) para cada una de las tareas del sprint:

### T-141 — Pre-flight del gate y batería de calibración concurrente (10 ejecuciones)
- **Alternativas detectadas**:
  - `fastparallel` (v2.4.1, NPM): Módulo de paralelismo asíncrono zero-overhead.
  - `run-parallel` (v1.2.0, NPM): Ejecutor paralelo de funciones sin dependencias pesadas.
  - `oscardlfr/kmp-test-runner` (1★, MIT, GitHub): Runner paralelo de tests para Kotlin/Android.
- **Recomendación del agente**: **Desarrollo a medida justificado**.
- **Decisión del usuario**: **Desarrollo a medida justificado**.  
  *Motivo*: La calibración del gate requiere lanzar ejecuciones reales contra el runtime de Orca ADE local (`deliberate-plan.sh`) midiendo percentiles P95 y consumo con herramientas nativas de Linux (`date +%s%N`, `awk`, `python3`). No procede introducir dependencias de Node.js ni transpiladores en el arnés de benchmarking del core.
- **Notas de integración**: Script en `scripts/agent/lib/bench-concurrency.sh` o arnés temporal en `tests/` que lance baterías parametrizables (ej: N=10, concurrencia C=2) emitiendo telemetría tabular y JSON con métricas de percentiles.
- **Alternativas rechazadas y motivos**:
  - `fastparallel` / `run-parallel`: Requieren entorno Node.js y no tienen visibilidad nativa sobre procesos desacoplados Bash de Orca.
  - `kmp-test-runner`: Específico para el ecosistema Kotlin/Gradle; incompatible con scripts Bash universales.

### T-142 — Despacho paralelo supervisado con patrón reactivo Orca (`check --wait` + `worker-read` + `--ack`)
- **Alternativas detectadas**:
  - `piscina` (v5.3.2, NPM): Pool de workers multihilo con colas de tareas.
  - `fastq` (v1.20.3, NPM): Cola de trabajo en memoria de alta velocidad.
  - `@workflow/world` (v5.0.5, NPM): Orquestación asíncrona de eventos evaluada en Sprint 24.
- **Recomendación del agente**: **Desarrollo a medida justificado**.
- **Decisión del usuario**: **Desarrollo a medida justificado**.  
  *Motivo*: Orca ADE ya dispone de su propio bus de eventos reactivos IPC (`orca orchestration check --wait`). La tarea consiste en implementar el conector nativo de bajo nivel en shell que escuche el despertar de `worker_done`, lea el terminal con `worker-read` y confirme la entrega con `--ack`, sustituyendo el polling de 1.5s por eventos reactivos.
- **Notas de integración**: Implementar helper en `scripts/agent/lib/orca-reactive-wait.sh` asegurando el filtrado de keepalives en stderr (`jq "select(._keepalive|not)"`) certificado en el runbook de T-139.
- **Alternativas rechazadas y motivos**:
  - `piscina` / `fastq`: Gestionan hilos de Node.js en memoria propia; no interactúan con procesos externos ni sockets UNIX de Orca ADE.
  - `@workflow/world`: Sobredimensionado para un script CLI determinista en Bash.

### T-143 — Aislamiento concurrente de variables y archivos de contexto
- **Alternativas detectadas**:
  - `proper-lockfile` (v4.1.2, NPM): Utilidad inter-proceso para bloqueo de archivos e idempotencia.
  - `async-lock` (v1.4.1, NPM): Mutex asíncrono para JavaScript.
  - `throat` (v6.0.2, NPM): Control de concurrencia y estrangulamiento de paralelismo.
- **Recomendación del agente**: **Desarrollo a medida justificado**.
- **Decisión del usuario**: **Desarrollo a medida justificado**.  
  *Motivo*: El aislamiento de variables se resuelve nativamente mediante `env -i` y la whitelist certificada de 10 variables (`PATH`, `HOME`, `USER`, etc.). La partición de archivos de contexto se resuelve asignando nombres únicos con prefijo de tarea (`.agents/context/plan-deliberation-${TASK_ID}.json`) y mecanismos de lock basados en primitivas POSIX atómicas (`mkdir` o `flock`), sin librerías externas.
- **Notas de integración**: Extender la validación de `scripts/agent/deliberate-plan.sh` para soportar `--output` segregado por tarea y asegurar que ninguna variable de entorno compartida contamine a workers paralelos.
- **Alternativas rechazadas y motivos**:
  - `proper-lockfile`: Incompatible con el principio de scripts universales sin dependencias de Node.js en el core.
  - `async-lock`: Solo opera dentro de un único runtime de NodeJS en memoria.

### T-144 — Estabilidad de terminales, censo `worker-list` y recolección de basura
- **Alternativas detectadas**:
  - `node-cleanup` (v2.1.2, NPM): Instalador de handlers de limpieza en salida.
  - `focus-trap` (v8.2.4, NPM): Enfoque de UI (no aplicable a backend/CLI).
- **Recomendación del agente**: **Desarrollo a medida justificado**.
- **Decisión del usuario**: **Desarrollo a medida justificado**.  
  *Motivo*: La recolección de procesos huérfanos en Bash debe basarse en el comando nativo `trap` del sistema operativo (`trap '...' EXIT INT TERM`) invocando `orca orchestration worker-stop` y `worker-release` con censo verificador mediante `orca orchestration worker-list`.
- **Notas de integración**: Integrar función centinela de recolección en `scripts/agent/lib/terminal-reaper.sh` que audite y purgue terminales inactivas antes y después de cada despacho.
- **Alternativas rechazadas y motivos**:
  - `node-cleanup`: Dependencia npm innecesaria para un flujo nativo en shell.
  - `focus-trap`: Librería DOM no relacionada.

### T-145 — Informe final y evaluación de compuerta GO/NO-GO del piloto paralelo
- **Alternativas detectadas**:
  - `alien-signals` (v3.2.1, NPM): Biblioteca reactiva de señales.
  - `agent-runner` (Hacker News #46047637): Harness open-source para benchmarking de agentes de código.
- **Recomendación del agente**: **Desarrollo a medida justificado**.
- **Decisión del usuario**: **Desarrollo a medida justificado**.  
  *Motivo*: Se trata de la redacción del reporte formal de gobernanza `docs/sprints/sprint-25-parallel-pilot-report.md`, que recopilará los datos empíricos de las 10 ejecuciones de estrés y emitirá el veredicto definitivo respecto a los umbrales de T-140.
- **Notas de integración**: Estructura de reporte con tablas telemétricas, percentiles P50/P90/P95, histograma de estabilidad de terminales y recomendación vinculante.
- **Alternativas rechazadas y motivos**:
  - `alien-signals`: Librería reactiva de estado en frontend.
  - `agent-runner`: Harness orientado a SWE-Bench, no aplicable al arnés interno de Orca ADE.

---

## 4. Síntesis y Recomendación para el Planning

1. **Topología de Tareas**: 5 tareas balanceadas (2 M, 3 S), cubriendo el ciclo completo del piloto (calibración, eventos reactivos, aislamiento, recolección y veredicto del gate).
2. **Sin Falsas Dependencias**: Todas las implementaciones se sustentan sobre el motor nativo existente (`deliberate-plan.sh`, `orca orchestration`, scripts en `lib/`), sin añadir paquetes externos que degraden la portabilidad.
3. **Fail-Safe Garantizado**: El diseño impone que el cierre del sprint concluya en NO-GO si cualquiera de los criterios cuantitativos no se alcanza al 100%, preservando intacta la estabilidad del core de Agent OS.
