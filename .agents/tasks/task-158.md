# Task-158: Plantillas Docker Compose y configuración de flota de Bane con frontera portable

## Objetivo
Incorporar la plantilla de despliegue Docker Compose (`templates/bane/docker-compose.yml`) y la especificación declarativa en `.agents/config/fleet.example.yaml` para el servicio de deep research Bane (motor open-source de razonamiento profundo y clon de Perplexity Pro), preservando escrupulosamente la frontera portable del core mediante placeholders genéricos y variables de entorno estándar sin ningún literal de infraestructura personal.

## Contexto técnico
Bane es un motor de búsqueda y razonamiento profundo open-source que permite ejecutar búsquedas técnicas complejas conectándose a pasarelas OpenAI-compatibles gratuitas (como FreeLLMAPI) y motores de búsqueda (SearXNG).
Para que cualquier satélite o nodo de la flota pueda aprovisionar y consumir Bane de forma soberana:
1. Se provee una plantilla de orquestación en `templates/bane/docker-compose.yml` parametrizada con variables estándar (`BANE_PORT`, `BANE_INFERENCE_URL`, `BANE_API_KEY`).
2. Se declara el servicio en `.agents/config/fleet.example.yaml` bajo `services.bane` con endpoint de referencia mediante placeholders genéricos (`http://<nodo-inferencia>:3000` o `${BANE_API_URL}`).
3. La frontera portable (validada por Check 22 de `tests/validate-control-plane.sh`) prohíbe terminantemente incluir IPs privadas, URLs personales o credenciales en estos archivos del core.

Esta tarea se ejecuta bajo el régimen autónomo del **Piloto Opción D**.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 28 / 2026-11-02
- **Diseño y arquitectura aprobados por**: Humano / Relé (Sprint Planning Sprint 28 - Enmienda Bane)
- **Decisiones e interfaces selladas**:
  - Crear `templates/bane/docker-compose.yml` siguiendo la estructura estándar de `templates/freellmapi/` y `templates/homepage/`.
  - Añadir en `.agents/config/fleet.example.yaml` la sección `services.bane` con `url: "http://<nodo-inferencia>:3000"` y descripción estándar.
  - Cero literales de IPs, dominios privados, hostnames personales o credenciales en el repositorio.
  - Ejecución bajo el régimen de autonomía Opción D: si el revisor emite `CONSENSO`, la suite pasa en verde y no hay desviaciones, el agente completa el ciclo sin esperar señales interactivas de chat.
  - Denominador de la suite de control plane se mantiene en **37/37** (0 errores).
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `agent-os-scripts`: Mantenimiento de plantillas y configuración de flota del core.
- `tool-inventory`: Registro declarativo de herramientas de la flota en fleet configs.

## Caja de archivos
- `templates/bane/docker-compose.yml`
- `.agents/config/fleet.example.yaml`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-158.md`

## Criterios de done
- [ ] Plantilla `templates/bane/docker-compose.yml` creada y sintácticamente válida.
- [ ] Especificación de `services.bane` añadida en `.agents/config/fleet.example.yaml` con placeholders genéricos.
- [ ] Higiene de frontera portable certificada por Check 22 (`locator-hygiene.sh` pasando limpio).
- [ ] Suite de control plane pasando limpia (37/37) con 0 errores.
- [ ] Ejecutada y registrada bajo las reglas del piloto Opción D.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido
- [ ] Rama creada
- [ ] Cierre y merge autorizado por el relé
