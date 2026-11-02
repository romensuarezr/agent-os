# Task-162: Cierre de Bane (límites de recursos en docker-compose.yml + templates/bane/.env.example)

## Objetivo
Incorporar directivas declarativas de límites de recursos (`deploy.resources.limits` y `deploy.resources.reservations`) en la plantilla Compose de Bane (`templates/bane/docker-compose.yml`), crear la plantilla de configuración `templates/bane/.env.example` con fallbacks estándar y documentar las variables en el runbook operativo, preservando la frontera portable del core sin literales privados.

## Contexto técnico
En el Sprint 28 se integró el motor de búsqueda y razonamiento soberano Bane mediante los hitos T-158 a T-161. Para dar por cerrado formalmente el soporte de Bane en la infraestructura del core:
1. `templates/bane/docker-compose.yml` debe contener límites de CPU y memoria acordes a la especificación estándar de Docker Compose v2, parametrizados por variables de entorno (`BANE_CPU_LIMIT`, `BANE_MEMORY_LIMIT`, etc.) con valores por defecto seguros.
2. `templates/bane/.env.example` debe proveer una guía reproducible y sin secretos para el aprovisionamiento de variables (`HOST_BIND_IP`, `BANE_PORT`, `BANE_INFERENCE_URL`, `BANE_API_KEY`, `BANE_SEARCH_URL`, y variables de recursos).
3. `docs/runbooks/bane-deep-research-service.md` debe documentar los límites de recursos recomendados y el uso de `.env.example`.

Esta tarea se ejecuta bajo el régimen estándar de **Opción D**.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 29 / 2026-11-02
- **Diseño y arquitectura aprobados por**: Humano / Relé (Sprint Planning Sprint 29)
- **Decisiones e interfaces selladas**:
  - En `templates/bane/docker-compose.yml`:
    - Bloque `deploy.resources.limits`: `cpus: "${BANE_CPU_LIMIT:-2.0}"`, `memory: "${BANE_MEMORY_LIMIT:-2G}"`.
    - Bloque `deploy.resources.reservations`: `cpus: "${BANE_CPU_RESERVATION:-0.5}"`, `memory: "${BANE_MEMORY_RESERVATION:-512M}"`.
  - Crear `templates/bane/.env.example` análogo a `templates/freellmapi/.env.example`.
  - Actualizar `docs/runbooks/bane-deep-research-service.md`.
  - Cero literales de IPs, dominios privados, hostnames personales o credenciales (Check 22 limpio).
  - Denominador de la suite de control plane se mantiene en **38/38** (0 errores).
  - Régimen Opción D: avance desatendido en camino limpio ante veredicto `CONSENSO`.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `agent-os-scripts`: Mantenimiento y estándares de plantillas del core.
- `tool-inventory`: Consistencia con la configuración declarativa de la flota.

## Caja de archivos
- `templates/bane/docker-compose.yml`
- `templates/bane/.env.example`
- `docs/runbooks/bane-deep-research-service.md`
- `.agents/tasks/task-162.md`

## Criterios de done
- [ ] Directivas `deploy.resources.limits` y `reservations` incorporadas en `templates/bane/docker-compose.yml` con sintaxis Compose v2 válida.
- [ ] `templates/bane/.env.example` creado con todas las variables requeridas y placeholders agnósticos.
- [ ] `docs/runbooks/bane-deep-research-service.md` actualizado con instrucciones de límites de recursos y variables.
- [ ] Check 22 de higiene de frontera portable pasando sin hallazgos.
- [ ] Suite de control plane 38/38 pasando limpia (0 errores).
- [ ] Ejecutada y registrada bajo las reglas de Opción D.
