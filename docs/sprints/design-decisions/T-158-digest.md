# Executive Design Digest — T-158

## 🎯 Objetivo
Incorporar la plantilla de despliegue Docker Compose (`templates/bane/docker-compose.yml`) y la especificación declarativa en `.agents/config/fleet.example.yaml` para el servicio de deep research Bane (motor open-source de razonamiento profundo y clon de Perplexity Pro), preservando escrupulosamente la frontera portable del core mediante placeholders genéricos y variables de entorno estándar sin ningún literal de infraestructura personal.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico para T-158 cumple de forma rigurosa con el diseño macro sellado en planning y las restricciones arquitectónicas de Agent OS. Garantiza la frontera portable mediante el uso exclusivo de variables de entorno estándar con fallbacks agnósticos y placeholders genéricos en templates/bane/docker-compose.yml y fleet.example.yaml, evitando cualquier referencia a infraestructura personal o credenciales.

La delimitación de la caja de archivos es estricta (4 archivos autorizados), las mitigaciones contemplan la preservación del denominador de control plane en 37/37 (Check 34) y la validación previa de higiene con locator-hygiene.sh. Los pasos de ejecución se ajustan al ciclo desatendido del Piloto Autónomo Opción D con publicación previa en origin y merge controlado.
- **Prospección Scout**: `CONFORME (sprint-28-research.md)`
  - Alternativa detectada:** `docker-compose` (v1.5.0, NPM), `@powersync/cli-plugin-docker` (v0.10.3, NPM).
  - Recomendación del agente:** Desarrollo a medida justificado (plantilla compose agnóstica en `templates/bane/`).
  - Decisión del usuario:** Desarrollo a medida justificado — incorporar las plantillas y esquemas de configuración para el despliegue soberano de Bane (motor open-source de deep research y clon de Perplexity Pro) en la flota de Agent OS:
  - Plantilla*: `templates/bane/docker-compose.yml` parametrizada con variables de entorno estándar (`BANE_PORT`, `BANE_INFERENCE_URL`, `BANE_API_KEY`).
- **Mensaje de Cierre**: `Merge branch 'feat/T-158-bane-compose-and-fleet' into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/config/fleet.example.yaml`
- `.agents/tasks/_archived/task-158.md`
- `docs/sprints/sprint-28-core.md`
- `templates/bane/docker-compose.yml`
- `tests/validate-control-plane.sh`

## 🧠 Skills Declaradas y Aplicadas
- `agent-os-scripts`
- `tool-inventory`
