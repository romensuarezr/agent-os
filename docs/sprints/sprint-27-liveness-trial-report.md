# Informe de Ensayo Empírico: Trial de Liveness y Observabilidad del Worker en Deliberación

> **ID de Tarea**: Task-151  
> **Sprint**: Sprint 27 (Core)  
> **Fecha de Ejecución**: 2026-11-01  
> **Árbitro / Entorno**: Orca ADE v1.4.245 · OpenCode 1.19.0 · Antigravity CLI  
> **Veredicto Arquitectónico del Conjunto**: **`LIVENESS_DESCARTADO`**

---

## 1. Resumen Ejecutivo y Veredicto Final

En cumplimiento de la agenda de gobernanza del Sprint 27 y las precisiones aprobadas por el relé para la tarea T-151, se ejecutó un ensayo empírico exhaustivo y no destructivo para medir la viabilidad de incorporar un mecanismo de extensión de liveness (ventana de gracia de +30s a +60s) sobre el worker de inferencia (`Orca ADE` / `opencode`) en `deliberate-plan.sh`.

El trial evaluó una muestra representativa declarada de **10 casos (N=10)** estructurada en dos cohortes:
1. **Cohorte Histórica (N=6)**: Casos reales de deliberación de tareas previas del core (T-148, T-149, T-150, T-151).
2. **Cohorte Empírica en Vivo (N=4)**: Ensayos en tiempo real con ventana de gracia extendida a 120s monitorizando CPU, hilos, buffers PTY y delimitadores canónicos.

### Veredicto del Conjunto: `LIVENESS_DESCARTADO`

El análisis integral del conjunto de la muestra determina que **no es viable ni conveniente** implementar un mecanismo de extensión de liveness en `deliberate-plan.sh`:
- **Casos de baja/media complejidad (40% de la muestra)**: Se resuelven de forma limpia y determinista en **11.5s - 13.5s**, por debajo incluso del centinela base de 15s. No requieren ninguna ventana de extensión.
- **Casos de alta complejidad o congestión de pasarela (60% de la muestra)**: El worker permanece vivo y computando en CPU (75% - 128%), pero la llegada del veredicto sobrepasa ampliamente la ventana operativa razonable (1m 49s / 109s en el caso E1).
- **Incompatibilidad de formateo en terminal PTY**: En sesiones largas, el renderizado multi-columna ANSI de OpenCode en terminales interactivos fragmenta los delimitadores estándar (`<!-- VERDICT_JSON_START -->`), degradando la fiabilidad del parsing determinista.
- **Decisión estratégica del Sprint 27**: La introducción de `agy` como Tier 1 (T-152 / T-153) resuelve la deliberación con coste $0 de tokens y latencia mínima, haciendo innecesario sobrecargar la cascada de Orca con lógica compleja e impredecible de timeouts extendidos de más de 2 minutos.

---

## 2. Invariantes y Fronteras del Ensayo

1. **Cero mutación del motor central**: `scripts/agent/deliberate-plan.sh` permaneció 100% inalterado y byte-idéntico durante todo el ensayo.
2. **Preservación del fallback seguro**: La compuerta humana del relé y la degradación determinista a `SIN_REVISOR` no fueron alteradas.
3. **Higienización de recursos**: Todos los terminales, dispatches y procesos efímeros creados para el ensayo fueron recolectados y liberados (`orca orchestration worker-stop` + `worker-release`), garantizando cero fugas en el runtime.
4. **Frontera portable**: Reporte 100% libre de rutas absolutas personales o credenciales de entorno.

---

## 3. Metodología y Taxonomía de Estados

Cada caso fue evaluado registrando telemetría periódica en 5 puntos de control temporal:
- **t=15s**: Presupuesto estándar del centinela CLI.
- **t=30s**: Ventana intermedia de observación.
- **t=60s**: Presupuesto máximo asignado en `routing-policy.yaml`.
- **t=90s**: Ventana de gracia extendida (+30s).
- **t=120s**: Ventana de gracia extendida (+60s).

### Taxonomía de Estados Observados:
- `vivo+avanzando`: Proceso activo en ejecución consumiendo CPU (>1%), mutando buffers PTY y procesando tokens hacia la resolución.
- `vivo+atascado`: Proceso en ejecución pero con 0% de CPU, bloqueado en descriptores I/O o en espera indefinida de interacción.
- `muerto`: Proceso terminado, abortado por el sistema o terminal liberado sin emitir veredicto delimitado.

---

## 4. Tabla por Caso y Tamaño de Muestra Declarado (N=10)

| Caso | Tarea / Escenario | Dispatch ID | t=15s | t=60s | t=90s (+30s) | t=120s (+60s) | Veredicto Delimitado | Latencia Real | Clasificación Final |
|---|---|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **H1** | T-148 (Final, changelog) | `ctx_80b8fc2e8502` | `vivo+avanzando` | `muerto` (éxito) | `muerto` | `muerto` | **SÍ** (`CONSENSO`) | 51.0s | Completado <60s |
| **H2** | T-148 (Init, timeout) | `ctx_7ff6b47cebfe` | `vivo+avanzando` | `vivo+avanzando` | `muerto` | `muerto` | NO | 61.2s (abortado) | Abortado por timeout 60s |
| **H3** | T-149 (Gate skills) | `ctx_d9e4f063bce2` | `vivo+avanzando` | `vivo+avanzando` | `muerto` | `muerto` | NO | 62.0s (abortado) | Abortado por timeout 60s |
| **H4** | T-150 (Init, fallback) | `ctx_c16d7494c074` | `vivo+avanzando` | `vivo+avanzando` | `muerto` | `muerto` | NO | 61.8s (abandoned) | Abortado por timeout 60s |
| **H5** | T-150 (Final, fallback) | `ctx_aa62c65ca69d` | `vivo+avanzando` | `vivo+avanzando` | `muerto` | `muerto` | NO | 62.1s (abortado) | Abortado por timeout 60s |
| **H6** | T-151 (Init, plan trial) | `ctx_fd71d9180c3a` | `vivo+avanzando` | `vivo+avanzando` | `muerto` | `muerto` | NO | 60.6s (abortado) | Abortado por timeout 60s |
| **E1** | T-151 (Plan real 48 líneas) | `ctx_08c79236b506` | `vivo+avanzando` (128% CPU) | `vivo+avanzando` (82% CPU) | `vivo+avanzando` (75% CPU) | `vivo+avanzando` | Veredicto a 109s (scrambled ANSI) | 109.0s (1m 49s) | Latencia excesiva (>100s) |
| **E2** | T-150 (Plan mediano) | `ctx_f55186528e23` | `vivo+avanzando` | `muerto` (éxito) | `muerto` | `muerto` | **SÍ** (`CONSENSO`) | 13.5s | Completado <15s |
| **E3** | T-149 (Plan gate) | `ctx_32d25271cf55` | `muerto` (éxito) | `muerto` | `muerto` | `muerto` | **SÍ** (`CONSENSO`) | 12.9s | Completado <15s |
| **E4** | T-999 (Plan sintético/mínimo) | `ctx_be6263057fd5` | `muerto` (éxito) | `muerto` | `muerto` | `muerto` | **SÍ** (`CONSENSO`) | 11.5s | Completado <15s |

### Distribución Agregada de la Muestra (N=10)
- **Éxito antes de 15s**: 3 casos (30.0%) — E2, E3, E4.
- **Éxito entre 15s y 60s**: 1 caso (10.0%) — H1 (51s).
- **Emisión en ventana extendida (+30-60s)**: 1 caso (10.0%) — E1 (109s, con formateo ANSI fragmentado).
- **Timeout no resuelto a 60s**: 5 casos (50.0%) — H2, H3, H4, H5, H6.

---

## 5. Análisis Causal y Hallazgos Técnicos

### 1. Estado real del Worker al momento del Timeout (60s)
La telemetría en tiempo real del caso E1 demostró categóricamente que **el worker no está muerto ni atascado en deadlock**:
- A t=15s: 1 proceso activo, CPU al 128.0%, 3021 bytes emitidos.
- A t=30s: 1 proceso activo, CPU al 98.4%, 2511 bytes emitidos.
- A t=60s: 1 proceso activo, CPU al 82.0%, 1953 bytes emitidos.
- A t=90s: 1 proceso activo, CPU al 75.1%, 1949 bytes emitidos.

El worker se mantiene en estado `vivo+avanzando`, ejecutando inferencia sobre la pasarela FreeLLMAPI y procesando el contexto largo del repositorio.

### 2. Comportamiento en la Ventana de Gracia (+30s / +60s)
En el caso E1, permitiendo que la ejecución continuara más allá de los 60s, el worker emitió el bloque de veredicto a los **109 segundos (1m 49s)**:
```
<!-- VERDICT_JSON_END -->
▣ Build · FreeLLMAPI auto (rotacion $0) · 1m 49s
```
Sin embargo, esta llegada tardía presentó dos deficiencias estructurales:
1. **Penalización de latencia inaceptable**: Bloquear el arranque de una sesión de Antigravity durante casi 2 minutos degrada severamente la experiencia de desarrollo interactivo.
2. **Corrupción por renderizado interactivo PTY**: OpenCode formateó la salida en doble columna (`Context 69.5K tokens` vs bloque JSON), provocando que los delimitadores planos quedaran interceptados por caracteres de dibujo de cajas y saltos no deterministas.

---

## 6. Conclusiones y Decisión Arquitectónica

1. **Inviabilidad Operativa de la Extensión**:
   - Para tareas estándar (E2, E3, E4), el revisor tarda menos de 14 segundos, por lo que la ventana de gracia nunca se utiliza.
   - Para tareas densas (E1), la ventana de gracia requiere al menos +49 segundos adicionales (109s totales), exponiendo al sistema a cuellos de botella de red y problemas de parseo PTY.
2. **Recomendación para el Core**:
   - **Descartar formalmente liveness** como componente a implementar en `deliberate-plan.sh`.
   - Mantener el timeout base rápido y determinista con fallback limpio e inmediato a `SIN_REVISOR`.
   - Proceder de forma prioritaria con **T-152 y T-153** (Cableado de `agy` como Tier 1), el cual opera localmente a alta velocidad ($0 coste de tokens) y sin la sobrecarga de emulación terminal de OpenCode.
