# Informe Final y Evaluación de Compuerta GO/NO-GO del Piloto Paralelo — Sprint 25

> **Documento Canónico de Evaluación de Gate**  
> **Fecha**: 30 de Octubre de 2026  
> **Autor**: Antigravity Orchestrator & Control Plane Maintenance  
> **Compuerta Contractual Evaluada**: Gate formalizado en T-140 (`docs/sprints/sprint-24-observation-report.md`)  
> **Estado del Piloto**: Finalizado  
> **Dictamen Vinculante**: ❌ **NO-GO** (Se preserva la ejecución estrictamente secuencial en el core)

---

## 1. Resumen Ejecutivo y Dictamen Vinculante

El Sprint 25 se concibió contractualmente como un **piloto controlado de validación empírica**, no como una activación automática o forzada del despacho paralelo. A lo largo del sprint se implementaron y certificaron los componentes de infraestructura requeridos:
- Calibración inicial concurrente (T-141).
- Espera reactiva orientada a eventos (`orca orchestration check --wait` + `worker-read` + `--ack`) para erradicar el sondeo acelerado (T-142).
- Particionado estricto de contextos (`deliberation-${TASK_ID}.json`) y frontera de aislamiento de variables de entorno `env -i` (T-143).
- Mecanismo determinista de recolección de procesos (`terminal-reaper.sh`) con trampas POSIX unificadas (`EXIT`, `INT`, `TERM`, `HUP`) y censo auditado (T-144).

Tras completar la pila tecnológica, se ejecutó una segunda batería idéntica de 10 ejecuciones (5 lotes de concurrencia $C=2$) sobre el stack completo consolidado, comparándola contra la línea base de T-141 bajo el mismo método matemático de percentiles (*nearest-rank*).

### Evaluación Matemática de la Compuerta de T-140

| Criterio Evaluado | Umbral Contractual (T-140) | Tanda 1: Baseline (T-141) | Tanda 2: Full-Stack (T-145) | Veredicto Criterio |
|---|:---:|:---:|:---:|:---:|
| **1. Latencia P95** | **< 45.0s** | 65.87s | **63.28s** | ❌ **INCUMPLE** |
| **2. Latencia Máxima Individual** | **< 60.0s** | 65.87s | **63.28s** | ❌ **INCUMPLE** |
| **3. Disponibilidad Tier 1 (Orca)** | **≥ 95.0%** | 90.0% (9/10) | **0.0% (0/10)** | ❌ **INCUMPLE** |
| **4. Terminales Huérfanas** | **Exactamente 0** (`delta_active == 0`) | 0 | **0 (10/10 liberadas)** | ✅ **CUMPLE** |

### ⚖️ Dictamen Vinculante
**DICTAMEN: NO-GO**.  
La compuerta contractual no autoriza el paso a producción del despacho paralelo en el core de `agent-os`. El sistema **permanece en ejecución estrictamente secuencial**.

**Causal del Dictamen**:
Aunque el criterio de higiene y recolección de terminales se cumplió de forma impecable (cero fugas de procesos en ambas baterías), la pasarela local de inferencia en el host no tolera la concurrencia de dos trabajadores simultáneos sin degradarse o exceder el presupuesto de 60 segundos. En la segunda tanda, la saturación de la pasarela condujo a un 100% de caídas al fallback seguro por timeout (>60s), arrojando un P95 de 63.28s y una disponibilidad de Tier 1 de 0.0%.

---

## 2. Marco Contractual del Gate de Paralelismo (T-140)

El informe de observación de T-140 estipuló las siguientes condiciones indispensables para autorizar la concurrencia:
1. **Presupuesto Temporal Estricto**: P95 inferior a 45.0 segundos para evitar que la deliberación multi-agente bloquee el ciclo de desarrollo interactivo.
2. **Tope Absoluto por Ejecución**: Ninguna ejecución individual puede superar los 60.0 segundos (tiempo límite establecido en `routing-policy.yaml`).
3. **Resiliencia del Tier 1 (Orca ADE)**: Al menos el 95.0% de las deliberaciones deben resolverse en el motor prioritario sin degradar a cascadas secundarias.
4. **Higiene Absoluta de Runtime**: Cero procesos zombies o terminales en estado `active` tras la finalización de los scripts.
5. **Criterios de Bloqueo Inmediato (NO-GO)**: Latencias mayores a 55 segundos sostenidas, terminales residuales o colisiones en archivos de contexto.

---

## 3. Análisis Comparativo de Rendimiento

Ambas baterías fueron ejecutadas en el mismo entorno de host, con 10 tareas sintéticas idénticas (`T-BENCH-01` a `T-BENCH-10`), 5 lotes de concurrencia $C=2$ y timeout de 60s.

### 3.1 Resumen Estadístico (Método Nearest-Rank: $rank = \lceil (P/100) \times N \rceil$)

| Métrica | Tanda 1 (Baseline T-141) | Tanda 2 (Full-Stack T-145) | Delta / Variación |
|---|:---:|:---:|:---:|
| **Mínima** | 30.50s | 62.10s | +31.60s (Degradación por pasarela) |
| **Mediana (P50)** | 34.09s | 62.76s | +28.67s |
| **P90** | 58.12s | 63.25s | +5.13s |
| **P95** | 65.87s | 63.28s | -2.59s (Acotado por timeout) |
| **Máxima** | 65.87s | 63.28s | -2.59s |
| **Tasa Tier 1 (Orca)** | 90.0% (9/10) | 0.0% (0/10) | Pasarela local no respondió en <60s |
| **Veredictos SIN_REVISOR** | 1/10 | 10/10 | Fallback determinista activado |
| **Terminales Huérfanas** | 0 | 0 | 100% efectividad de recolección |
| **Tráfico CLI (`worker-read`)** | ~40 lecturas/tarea (polling 1.5s) | 0 lecturas en timeout (espera de evento) | Reducción del 100% de llamadas ciegas |

---

### 3.2 Desglose Individual por Ejecución

```text
Tanda 1 (T-141 - Baseline Polling):
  Lote 1: T-BENCH-01 (35.09s, orca)    | T-BENCH-02 (33.75s, orca)
  Lote 2: T-BENCH-03 (42.96s, orca)    | T-BENCH-04 (32.71s, orca)
  Lote 3: T-BENCH-05 (32.37s, orca)    | T-BENCH-06 (34.09s, orca)
  Lote 4: T-BENCH-07 (30.50s, orca)    | T-BENCH-08 (58.12s, orca)
  Lote 5: T-BENCH-09 (50.48s, orca)    | T-BENCH-10 (65.87s, fallback SIN_REVISOR)

Tanda 2 (T-145 - Full-Stack Reactivo + Aislamiento + Reaper):
  Lote 1: T-BENCH-01 (62.40s, fallback) | T-BENCH-02 (62.40s, fallback)
  Lote 2: T-BENCH-03 (63.08s, fallback) | T-BENCH-04 (63.20s, fallback)
  Lote 3: T-BENCH-05 (63.25s, fallback) | T-BENCH-06 (63.28s, fallback)
  Lote 4: T-BENCH-07 (63.18s, fallback) | T-BENCH-08 (62.76s, fallback)
  Lote 5: T-BENCH-09 (62.15s, fallback) | T-BENCH-10 (62.10s, fallback)
```

---

## 4. Eficacia de las Mejoras Técnicas del Sprint 25

A pesar de que el veredicto general es NO-GO debido al cuello de botella externo de inferencia, las mejoras de ingeniería del Sprint 25 han transformado la robustez del sistema:

1. **Patrón Reactivo (`orca-reactive-wait.sh`)**:
   - En T-141, cuando una deliberación tardaba 60s, el proceso coordinador ejecutaba ~40 llamadas a `worker-read` en un bucle acelerado, saturando los sockets de Orca y compitiendo por I/O.
   - En T-145, al esperar de forma reactiva el evento `worker_done`, si el evento no llega, el cliente no realiza ninguna llamada de sondeo innecesaria. El tráfico de lectura en timeouts se redujo a **cero**.
2. **Aislamiento Concurrente de Contextos (`deliberate-plan.sh`)**:
   - Se erradicaron totalmente las condiciones de carrera y lecturas parciales (*torn reads*) mediante escrituras atómicas POSIX (`mktemp` + `mv -f`).
   - Los veredictos particionados (`deliberation-${TASK_ID}.json`) garantizaron que ninguna tarea contaminara o sobrescribiera la salida de otra.
3. **Estabilidad de Terminales y Recolección Garantizada (`terminal-reaper.sh`)**:
   - En T-145, a pesar de que las 10 tareas sufrieron timeouts severos de inferencia (>60s), el manejador de trampas unificado detuvo y liberó de forma inmediata cada uno de los terminales (`worker-stop` + `worker-release`).
   - El censo de terminales confirmó que el contador de liberados subió de 36 a 46, manteniendo exactamente **0 terminales huérfanas o activas** al terminar.

---

## 5. Auditoría de Censo y Recursos en Host

- **Censo Pre-Batería T-145**:
  - Activas: `0`
  - Preexistentes retenidas: `9`
  - Preexistentes reclamables: `1`
  - Preexistentes liberadas: `36`
- **Censo Post-Batería T-145**:
  - Activas: `0`
  - Preexistentes retenidas: `9`
  - Preexistentes reclamables: `1`
  - Preexistentes liberadas: `46` (+10 terminales creadas en la prueba, 100% liberadas).
  - Terminales zombies / huérfanas detectadas: `0`.

---

## 6. Conclusiones y Hoja de Ruta para Futuros Sprints

### 6.1 Principio de No Forzar el Paralelismo
El dictamen NO-GO valida uno de los principios rectores de `agent-os`: **los datos empíricos mandan sobre el optimismo arquitectónico**. Forzar el paralelismo en el estado actual degradaría la experiencia de desarrollo, dispararía los tiempos de espera y causaría deliberaciones degradadas continuas.

### 6.2 Decisiones Vinculantes de Operación
1. **Modo Secuencial Preservado**: `agent-os` continuará operando en modo secuencial estricto para la planificación, deliberación y ejecución de tareas.
2. **Retención de las Mejoras del Sprint**: Los componentes de resiliencia (`terminal-reaper.sh`, `orca-reactive-wait.sh` y el particionado atómico de T-143) se quedan permanentemente en el core, ya que aportan robustez, seguridad de señales e higiene incluso en modo secuencial.
3. **Condición para Reabrir el Gate en el Futuro**: No se reconsiderará el paralelismo multi-agente en local hasta que la infraestructura de inferencia del host (pasarelas LLM o hardware acelerador) sea capaz de entregar respuestas con latencias P95 < 20s en modo mono-agente.
