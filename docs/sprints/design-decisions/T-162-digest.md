# Executive Design Digest — T-162

## 🎯 Objetivo
Incorporar directivas declarativas de límites de recursos (`deploy.resources.limits` y `deploy.resources.reservations`) en la plantilla Compose de Bane (`templates/bane/docker-compose.yml`), crear la plantilla de configuración `templates/bane/.env.example` con fallbacks estándar y documentar las variables en el runbook operativo, preservando la frontera portable del core sin literales privados.

## 🏛️ Decisiones de Arquitectura y Buenas Prácticas
- **Veredicto de Deliberación**: `CONSENSO` (Rondas: 1)
- **Síntesis de Diseño**: El plan técnico satisface con rigor milimétrico el diseño macro aprobado en planning para T-162 y las directivas vinculantes del relé. La parametrización declarativa de recursos en `templates/bane/docker-compose.yml` (`BANE_MEMORY_LIMIT:-250M`, `BANE_CPU_LIMIT:-1.0`) respeta el límite estricto de memoria (<250MB) y asegura portabilidad mediante fallbacks deterministas.

La creación de `templates/bane/.env.example` y la actualización del runbook se encuadran dentro de la caja de archivos autorizada, empleando placeholders agnósticos que preservan la higiene del Check 22 y la invariante de 38/38 en la suite de control plane. Se autoriza el avance autónomo desatendido bajo régimen de Opción D.
- **Prospección Scout**: `CONFORME (sprint-29-research.md)`
  - Alternativa detectada:** Específicación oficial Docker Compose v2 (`deploy.resources.limits` y `reservations`), paquete `docker-compose` en npm (v1.5.0) y librería `dockerode` (v5.0.1).
  - Recomendación del agente:** Desarrollo a medida justificado (especificación declarativa Compose estándar).
  - Decisión del usuario:** Desarrollo a medida justificado — se parametriza la plantilla YAML del core sin añadir dependencias runtime externas.
  - Notas de integración:** Añadir en `templates/bane/docker-compose.yml` las claves estándar `deploy.resources.limits.cpus`, `deploy.resources.limits.memory`, `deploy.resources.reservations.cpus` y `deploy.resources.reservations.memory` con fallbacks deterministas dentro del spec original (<250MB) al no disponer de medición empírica bajo carga (`${BANE_CPU_LIMIT:-1.0}`, `${BANE_MEMORY_LIMIT:-250M}`, `${BANE_CPU_RESERVATION:-0.1}`, `${BANE_MEMORY_RESERVATION:-64M}`). Crear `templates/bane/.env.example` análogo a `templates/freellmapi/.env.example`.
- **Mensaje de Cierre**: `Merge branch 'feat/T-162-bane-resources-and-env-example' into multi-agent`

## 🛠️ Ajustes y Arbitraje de Deliberación
- Consenso inicial sin objeciones o cerrado en modo directo.

## 📁 Ficheros Modificados y Criterio de Alcance
- `.agents/tasks/_archived/task-162.md`
- `docs/runbooks/bane-deep-research-service.md`
- `docs/sprints/sprint-29-core.md`
- `templates/bane/.env.example`
- `templates/bane/docker-compose.yml`

## 🧠 Skills Declaradas y Aplicadas
- `agent-os-scripts`
- `tool-inventory`
