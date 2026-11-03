# Task-165: Despliegue en vivo y validación operativa de Bane en la flota

## Objetivo
Poner en funcionamiento real el motor Bane en el servidor de inferencia (<nodo-inferencia>) desplegando la plantilla declarativa validada en T-162 (`templates/bane/docker-compose.yml`), aprovisionando sus variables de entorno en el host, actualizando el overlay de flota con el endpoint accesible y validando la disponibilidad con `bane-client.sh --check` (`exit 0`) y una búsqueda profunda real autónoma mediante el workflow `deep-research`.

## Contexto técnico
El core de Agent OS cuenta con las plantillas Compose (`templates/bane/docker-compose.yml`, `templates/bane/.env.example`), el cliente CLI determinista (`scripts/agent/lib/bane-client.sh`) y el workflow canónico (`.agents/workflows/deep-research.md`). Sin embargo, hasta la fecha Bane nunca ha sido desplegado en vivo en la flota ni se ha ejecutado una consulta real a través de este canal.
Esta tarea valida la puesta en producción viva de Bane como motor de investigación profunda y clon soberano de Perplexity Pro, operando bajo el régimen estándar de **Opción D**.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 30 / 2026-11-03
- **Diseño y arquitectura aprobados por**: Humano / Relé (Sprint Planning Sprint 30)
- **Decisiones e interfaces selladas**:
  - Desplegar el stack Compose de Bane en el servidor de inferencia (<nodo-inferencia>) respetando los límites de recursos configurados (`BANE_CPU_LIMIT`, `BANE_MEMORY_LIMIT: 250M`).
  - Configurar las variables de entorno en el host VPS según `templates/bane/.env.example` enlazando con el endpoint de inferencia ($0) y embeddings locales.
  - Registrar el endpoint vivo en el overlay de flota (`fleet.yaml`) bajo el nodo correspondiente.
  - Ejecutar verificación determinista de salud con `bash scripts/agent/lib/bane-client.sh --check`, certificando transición de estado inactivo (`exit 2`) a activo (`exit 0`).
  - Ejecutar una consulta de prueba real con `bash scripts/agent/lib/bane-client.sh --query "[consulta]" --output [archivo]` verificando generación de respuesta Markdown estructurada.
  - Actualizar `docs/runbooks/bane-deep-research-service.md` con los hallazgos operativos y notas de despliegue real.
  - Mantener la suite de control plane `tests/validate-control-plane.sh` en verde (**38/38**, 0 errores).
  - Régimen Opción D: avance desatendido en camino limpio ante veredicto `CONSENSO`.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `remote-admin`: Ejecución remota de comandos y gestión de contenedores Docker vía SSH seguro.
- `coolify-admin`: Gestión y despliegue de servicios en infraestructura Coolify / Docker Compose.
- `agent-os-scripts`: Verificación determinista de salud y control de la flota.

## Caja de archivos
- `.agents/config/fleet.example.yaml`
- `docs/runbooks/bane-deep-research-service.md`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-165.md`

## Criterios de done
- [ ] Servicio Bane desplegado y en ejecución en el servidor de inferencia.
- [ ] Variables de entorno configuradas en el host VPS sin fuga de credenciales en el repositorio.
- [ ] Endpoint de Bane declarado en el overlay de flota (`fleet.yaml`).
- [ ] `bash scripts/agent/lib/bane-client.sh --check` retorna código 0 y JSON con estado `"active"`.
- [ ] Consulta real de investigación ejecutada con éxito mediante `bane-client.sh`.
- [ ] `docs/runbooks/bane-deep-research-service.md` actualizado con instrucciones verificadas en producción.
- [ ] Suite de validación de control plane pasando limpia (0 errores).
- [ ] Ejecutada y registrada bajo las reglas de Opción D.
