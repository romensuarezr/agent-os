# Research y Prospección Tecnológica — Sprint 24

> **Documento de Respaldo Scout (Fase 2d / 2e del Sprint Planning)**  
> **Tema**: Deliberación en producción durante un ciclo completo con el revisor vivo.  
> **Herramienta determinista de prospección**: `scripts/agent/scout.sh` (coste $0 de inferencia).  
> **Fecha de ejecución**: 2026-10-30

---

## Metodología y Ejecución de Búsquedas Scout

Se ejecutaron consultas deterministas sobre el ecosistema open source (GitHub, NPM Registry y Hacker News) mediante `scripts/agent/scout.sh`:
1. `cli parameter header documentation timeout consistency` (T-137)
2. `agent lifecycle state machine worker release` (T-138)
3. `event stream wake condition wait queue timeout` (T-139)
4. `multi-agent parallel execution observation criteria metrics` (T-140)

---

## Descubrimientos Scout (por tarea)

### T-137: Deuda Cosmética de T-135 (`deliberate-plan.sh`)

- **Alternativas detectadas**:
  - `@rushstack/ts-command-line` (v5.3.17, NPM): Parser de línea de comandos tipado para TypeScript con generación de ayuda automática.
  - `cli-table3` (v0.6.5, NPM): Generador de tablas Unicode para salidas CLI.
- **Recomendación del agente**: Modificar in-place. La deuda técnica es estrictamente cosmética en el script Bash nativo `scripts/agent/deliberate-plan.sh`. No procede incorporar dependencias externas ni transpiladores. Se deben actualizar los comentarios de cabecera (líneas 10 y 19) y el texto del bloque de ayuda `show_help` para alinear el presupuesto documentado a 60s y la latencia en el peor caso a ~66s (<1s sonda + 60s Orca + 5s HTTP), explicando la precedencia `CLI > routing-policy.yaml > default (15s)`.
- **Decisión vigente**: Modificación interna en `scripts/agent/deliberate-plan.sh` sin alterar la lógica de ejecución ya certificada por el Check 37.
- **Notas de integración**: El revisor vivo en host deliberará el borrador del plan de T-137 para verificar que no se introduzcan regresiones sintácticas ni roturas en los tests de control plane existentes.

---

### T-138: Corregir y Archivar el Scout de Ciclo de Vida Orca

- **Alternativas detectadas**:
  - `@ricsam/r5d-worker` (NPM): Ejecutor host duradero y gestor de adaptadores supervisados independientes.
  - `@deepseek-ai/dsh-tool-ralph` (v0.0.1-rc.1, NPM): Bucle Ralph Loop agéntico sobre interfaces de workflow y costuras de subagentes.
  - *Show HN: Pizza Bot – An inbox for AI agents that work in the background* (Hacker News #49713894): Patrón de buzón asíncrono para agentes en background.
- **Recomendación del agente**: Construir y rectificar documentación. En sprints anteriores se redactaron guías iniciales (`docs/runbooks/orca-multiagent-orchestration.md` y `docs/architecture/tools/llm-routing-selection.md`) con asunciones previas a la verificación empírica en host (comandos inventados como `orca worktree create --prompt`, omisión del requisito de `worker-stop` antes de `worker-release` bajo estado activo, o ausencia de la whitelist `env -i`). Corregir estas referencias con los comandos canónicos certificados en host (`orca orchestration worker-start --spec`, `worker-stop`, `worker-release`).
- **Decisión vigente**: Saneado y actualización documental de runbooks y guías de arquitectura, archivando el registro histórico con evidencia contrastada en host.
- **Notas de integración**: Asegurar que ningún runbook ni guía promueva comandos obsoletos que provoquen errores `dispatch_inactive` o fugas de credenciales.

---

### T-139: Verificar el Recolector de Eventos Orca en Host (`check --wait` vs `--types`, payload `worker_done`)

- **Alternativas detectadas**:
  - `p-wait-for` (v7.0.0, NPM): Utilidad de espera activa condicional para JavaScript/Node.js.
  - `@workflow/world` (v5.0.5, NPM): Interfaz para orquestación de workflows asíncronos y eventos reactivos.
  - `duplexify` (v4.1.3, NPM): Adaptador de streams asíncronos para pipelines.
- **Recomendación del agente**: Exploración empírica en host ($0). Orca ADE cuenta con el subcomando `orca orchestration check` que admite `--run <id>`, `--wait`, `--types <tipo,...>` y `--timeout-ms <ms>`. Según las notas oficiales de Orca CLI:
  - `--types` actúa como condición de despertar para `--wait`, pero la entrega retornada (`Delivery`) siempre contiene el lote FIFO completo (nunca se filtra por tipo en el consumo, solo en `--peek` y `--all`).
  - Emite keepalives cada 15s a stderr (`_keepalive: true`) durante la espera.
  - Es mandatorio verificar en host si el evento `worker_done` llega con el veredicto en su payload o si solo señala la conclusión del turno requiriendo un `worker-read` subsiguiente.
- **Decisión vigente**: Diseñar un test/diagnóstico no destructivo en host sobre un Run real con OpenCode para caracterizar el comportamiento exacto de `check --wait` y documentar el contrato de eventos.
- **Notas de integración**: El resultado servirá como base técnica para decidir en el futuro si `deliberate-plan.sh` debe migrar de polling de terminal (`worker-read`) a escucha reactiva (`check --wait`).

---

### T-140: Informe de Observación del Ciclo con Criterio de Paso al Paralelo

- **Alternativas detectadas**:
  - `agent-trajectories` (v0.7.0, NPM): Módulo para capturar trazas y trenes de pensamiento de agentes como artefactos de primer nivel.
  - `@newrelic/native-metrics` (v13.1.0, NPM): Extracción de métricas nativas de ejecución de procesos.
  - `deepthink-js` (v2.1.0, NPM): Módulo de procesos agénticos con métricas locales y cloud.
- **Recomendación del agente**: Compilar informe analítico en Markdown. La transición del bucle secuencial supervisado hacia el paralelismo multi-worker exige evidencia empírica acumulada a lo largo del Sprint 24: latencia media observada, tiempo de resolución de veredictos, tasa de degradación a cascada HTTP y contención de procesos terminales en el host.
- **Decisión vigente**: Generar `docs/sprints/sprint-24-observation-report.md` con las métricas observadas durante los cierres de T-137, T-138 y T-139, estipulando los criterios cuantitativos necesarios para autorizar el despacho concurrente de workers en sprints futuros.
- **Notas de integración**: Cierre del sprint que servirá de insumo para la toma de decisiones en el planning de Sprint 25.
