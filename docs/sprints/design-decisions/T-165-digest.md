# Executive Design Digest — T-165

## 🎯 Objetivo
Poner en funcionamiento real el motor Bane en el servidor de inferencia (<nodo-inferencia>) desplegando la plantilla declarativa validada en T-162 (`templates/bane/docker-compose.yml`), aprovisionando sus variables de entorno en el host, actualizando el overlay de flota con el endpoint accesible y validando la disponibilidad con `bane-client.sh --check` (`exit 0`) y una búsqueda profunda real autónoma mediante el workflow `deep-research`.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico para T-165 satisface rigurosamente los estándares de aislamiento, higiene y control de regresión de Agent OS. La segregación del endpoint vivo en el overlay privado ignorado por git (`.agents/config/fleet.yaml`), preservando `fleet.example.yaml` con placeholders seguros, neutraliza el riesgo de fuga de credenciales o URLs de infraestructura privada.

Asimismo, el flujo secuencial desacopla adecuadamente la comprobación determinista de salud (`bane-client.sh --check`) de la prueba funcional E2E en la rama autónoma de `deep-research.md`, garantizando la invariancia del denominador del control plane en 38/38 sin inducir acoplamientos ni mutaciones de código en `src/`.
- **Prospección Scout**: `CONFORME (sprint-30-research.md)`
  - Alternativa detectada:** Imagen oficial `ghcr.io/pythops/bane` (1060⭐), SearXNG (`searxng/searxng`), cliente `bane-client.sh` nativo del core.
  - Recomendación del agente:** Adopción de la imagen oficial Docker existente en el core (`templates/bane/docker-compose.yml`), operando en producción viva sobre el VPS de inferencia.
  - Dictamen del Relé (Enmienda vinculante):** Recomendación ratificada. Precisiones operativas: el endpoint vivo se registra exclusivamente en el overlay privado (`fleet.yaml`), nunca en `fleet.example.yaml` commiteado (que solo contiene placeholders o esquema). El criterio de done exige una búsqueda real ejecutada a través de la rama autónoma del workflow `deep-research` con Bane activo, no solo un `--query` aislado del cliente CLI.
  - Notas de integración:**
- **Mensaje de Cierre**: `feat(T-171): cierre de tarea T-171`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-165.md`
- `.agents/tasks/_archived/task-171.md`
- `docs/sprints/design-decisions/T-171-digest.md`
- `docs/sprints/design-decisions/T-171-raw.json`
- `docs/sprints/sprint-30-core.md`

## 🧠 Skills Declaradas y Aplicadas
- `remote-admin`
- `coolify-admin`
- `agent-os-scripts`
