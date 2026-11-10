---
description: Protocolo determinista de investigación técnica profunda (Deep Research). Utiliza el motor soberano de búsqueda de la flota (SearXNG) de forma autónoma si está activo en la flota, o genera el prompt guiado para Perplexity Pro en modo manual.
---

# deep-research

> Protocolo unificado de investigación técnica profunda para tareas complejas o rituales de sprint planning en {{PROJECT_NAME}}.

## Objetivo

- Automatizar la recolección, síntesis y contraste de documentación técnica y arquitectónica antes de abordar implementaciones complejas.
- Despachar consultas al motor de búsqueda profunda soberano (SearXNG) cuando esté disponible en la flota.
- Degradar limpiamente al modo manual asistido (Perplexity Pro) si el servicio no está configurado o no responde en tiempo.

## Archivos y rutas involucradas

- `scripts/agent/lib/searxng-client.sh`
- `.agents/config/fleet.yaml` (o `fleet.example.yaml`)
- `docs/sprints/sprint-{{SPRINT_ACTIVE}}-research.md` (o archivo de destino especificado)

---

## Protocolo de Ejecución

### FASE 1 — Comprobación Determinista de Disponibilidad

Antes de intentar cualquier llamada remota o pedir acciones al usuario, el agente evalúa la disponibilidad del servicio de búsqueda soberana con un timeout estricto de 3 segundos (usando `searxng-client.sh --check`):

```bash
bash scripts/agent/lib/searxng-client.sh --check --json
```

- **Código de salida 0 (`status: active`)** → El servicio está configurado y alcanzable. Proceder inmediatamente a la **FASE 2A (Ruta Autónoma SearXNG)**.
- **Código de salida 2 (`status: inactive`)** → El servicio no está configurado o no responde. Proceder inmediatamente a la **FASE 2B (Ruta Manual Perplexity)** sin emitir bloqueos ni errores fatales.

---

### FASE 2A — Ruta Autónoma (SearXNG Activo)

1. **Construcción de la Consulta**:
   El agente formula la consulta técnica profunda estructurada con contexto del proyecto, stack y alternativas analizadas.

2. **Despacho desatendido vía CLI**:
   ```bash
   bash scripts/agent/lib/searxng-client.sh --query "<CONSULTA_ESTRUCTURADA>" --timeout 30
   ```

3. **Integración Directa en Research**:
   El resultado Markdown devuelto por stdout se vuelca directamente en `docs/sprints/sprint-{{SPRINT_ACTIVE}}-research.md` respetando las secciones canónicas:
   ```markdown
   ## Hallazgos clave
   [Síntesis estructurada obtenida desatendidamente de SearXNG]

   ## Decisiones tomadas
   [Conclusiones técnicas directas para la tarea o sprint]

   ## Descartado
   [Alternativas o enfoques invalidados por la investigación]
   ```

4. **Transición Continua**:
   El agente informa brevemente: `"✅ Investigación técnica completada autónomamente mediante SearXNG."` y continúa el flujo de trabajo sin pausas humanas.

---

### FASE 2B — Ruta Manual (Fallback Perplexity Pro)

Si el motor soberano está inactivo, ausente o experimenta una caída transitoria de red:

1. **Generación del Prompt Estructurado**:
   El agente emite por el chat el bloque de prompt listo para copiar:

   ```text
   CONTEXTO: Estoy desarrollando [descripción de {{PROJECT_NAME}}].
   STACK: [Describe el stack tecnológico principal].
   SITUACIÓN ACTUAL: [helpers existentes, patrones en uso, deuda técnica conocida].
   TAREA O TEMA A INVESTIGAR: [pregunta específica y exhaustiva]
   FORMATO ESPERADO: Comparativa técnica, ejemplos de código y decisiones de arquitectura.
   ```

2. **Pausa y Espera de Respuesta**:
   El agente detiene la ejecución, solicita al usuario que pegue los resultados de Perplexity y espera la entrada interactiva para incorporarla en el research file.
