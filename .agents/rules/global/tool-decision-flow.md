# Rule: Tool Decision Flow & Pre-Code Scouting Governance

> Elige las herramientas adecuadas siguiendo un orden lógico para maximizar la velocidad, el control y la reutilización sin reinventar la rueda.

---

## 🧭 Jerarquía de Decisión de Herramientas

1. **Reutilización de la Flota Activa (`tool-inventory`)**:
   - Consulta primero `config/fleet.yaml` (o la skill `tool-inventory`). Si la capacidad ya está desplegada (ej. modelos locales $0 en FreeLLMAPI, n8n Native MCP, bases de datos en Unified-DB, MinIO S3), reutilízala directamente sin instalar ni programar nada nuevo.

2. **Política OSS-First con Scouting Determinista Obligatorio (`scout.sh`)**:
   - Si la capacidad no existe en la flota, antes de diseñar, planificar o implementar código para cualquier nuevo módulo o herramienta, **valida obligatoriamente el ecosistema abierto**:
     ```bash
     bash scripts/agent/scout.sh "<palabras clave>"
     ```
   - **Criterio de adopción**: Si el digest detecta soluciones consolidadas (≥500⭐, licencias permisivas MIT/Apache), la prioridad número 1 es adoptar o integrar la solución OSS en lugar de programar desde cero.
   - **Coste de tokens**: **0 tokens de inferencia** en la prospección (el agente únicamente lee el digest plano de 10-15 líneas producido por el script CLI).

3. **Free SaaS**:
   - Si no existe opción OSS viable, busca el tier gratuito de servicios SaaS que permitan migración fácil en el futuro sin vendor lock-in.

4. **Herramientas Premium del Usuario (Delegación Asistida)**:
   - Verifica si el usuario dispone de herramientas premium (ej: Perplexity Pro, Google AI Studio 2M context). Si es la opción óptima:
     - No pierdas tiempo investigando si una herramienta externa lo resuelve mejor.
     - **Delega con prompt estructurado**: Provee al usuario el prompt exacto para copiar y pegar en su herramienta.

---

## ⚡ Mandato de Eficiencia: Scripts Locales para Acciones Deterministas

**Regla de Oro**: Siempre que una acción, consulta, búsqueda, auditoría o extracción de datos sea determinista (ej. parsear JSON/YAML, listar contenedores, auditar puertos, consultar APIs estandarizadas, comprobar git o verificar dependencias):
- **Prohibido quemar tokens de LLM**: El agente no debe volcar archivos masivos en el contexto ni realizar bucles probabilísticos de lectura de código fuente si la tarea puede resolverse mediante código determinista.
- **Pensar en scripts primero**: La solución por defecto debe ser invocar o crear un script local ligero (Bash, Python CLI, jq, sed, awk, curl) que procese el estado del sistema a coste **$0** y devuelva al agente únicamente un **digest estructurado y conciso (10–20 líneas)**.
- **División de responsabilidades**: La inteligencia del LLM se reserva para el razonamiento de alto nivel, la toma de decisiones y la síntesis; la recolección determinista de datos se delega a herramientas de terminal y scripts.

---

## 🔒 Gating Check Obligatorio en Sprint Planning y Task Files

1. **En `sprint-planning.md` (Paso 2d)**:
   - Ninguna tarea técnica entra al sprint sin haber ejecutado `scout.sh` y presentado su tabla comparativa en el informe para decisión del usuario.
2. **En Task Files (`.agents/tasks/task-XXX.md`)**:
   - Si la tarea implica crear o evaluar una herramienta/librería, la sección `## Contexto técnico` debe registrar el resultado del scouting determinista (`scout.sh: detectado [repo] / justificado desarrollo a medida`).

---

## 📋 Pattern de Propuesta

```text
Para [OBJETIVO], propongo estas opciones evaluadas:
1. [Flota/OSS detectado por scout] (Control total / coste $0)
2. [SaaS / Alternativa de mercado] (Rápido sin mantenimiento)
3. ¿Tienes [TOOL]? (Si sí, usa este prompt: [PROMPT])
```
