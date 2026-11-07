# Task-171: Re-ensayo de Vane (`itzcrazykns1337/vane:latest`), investigación real y posible integración soberana

## Estado
⏳ Pendiente

## Objetivo
Ejecutar un re-ensayo técnico riguroso de Vane partiendo de la imagen exacta `itzcrazykns1337/vane:latest` antes de sondear cualquier otra variante, descartando terminantemente `pythops/vane` y variantes `slim`.
La tarea cuenta con una compuerta estricta inicial (**Gate 0**): `docker pull itzcrazykns1337/vane:latest` debe funcionar de forma verificada antes de desplegar nada en la infraestructura; si el pull falla, la tarea aborta inmediatamente a humano (fail-closed), quedando prohibido cerrar con meras plantillas.
Superado el Gate 0, el ensayo consiste en desplegar el contenedor y ejecutar una investigación profunda real a través de la ruta autónoma.
La compuerta de cierre exige la obtención de un **informe útil** y estructurado (no únicamente una respuesta corta con citas); en caso de no generar dicho informe útil, abortar inmediatamente a humano sin forzar la integración.
Solo si el ensayo lo justifica de forma concluyente, se integrará la instancia preexistente de SearXNG (sin uso actual) como backend del motor de búsqueda profunda, sin desplegar en ningún caso un segundo SearXNG.
La tarea se ejecuta bajo el régimen estándar de **Opción D**, sin tocar `main`, sin tags y con denominador de suite inmutable en **38/38**.

## Contexto técnico
En T-169 se intentó ensayar Vane sondeando `pythops/vane`, imagen que no existía en los registros públicos, lo que provocó la activación del rescate hacia SearXNG.
Se ha identificado que la imagen real de Vane se encuentra publicada bajo el namespace de su autor/mantenedor como `itzcrazykns1337/vane:latest`.
Esta tarea T-171 constituye un encadenamiento formal tras T-170 para re-evaluar Vane bajo condiciones empíricas estrictas, preservando T-165 en pausa y manteniendo T-169 archivada como evidencia histórica.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 30 / 2026-11-07 (Enmienda T-171)
- **Diseño y arquitectura aprobados por**: Humano / Relé (Decisión Macro de Enmienda Sprint 30)
- **Decisiones e interfaces selladas**:
  - **Identidad de T-171**: Tarea NUEVA, encadenada tras T-170. No reabre T-169 ni reescribe T-165.
  - **Estado de T-165**: Mantiene estado `⏸ Pausada`. Su cierre definitivo como descartada se pospone a cuando el motor quede decidido en la flota.
  - **Imagen exacta**: `itzcrazykns1337/vane:latest` antes de sondear nada; nunca `pythops/vane` ni la variante `slim`.
  - **Gate 0 Determinista**: `docker pull itzcrazykns1337/vane:latest` debe operar con éxito antes de desplegar nada; si falla, aborto inmediato a humano (fail-closed), prohibido cerrar con meras plantillas.
  - **Ensayo en Vivo**: Desplegar la imagen y ejecutar una investigación profunda real por la ruta autónoma.
  - **Compuerta de Cierre / Informe Útil**: Exige informe estructurado y útil; no basta una respuesta con citas. Si no produce informe útil, aborto a humano, no forzar integración.
  - **Integración condicionada de SearXNG**: Solo si el ensayo lo justifica, integrar el SearXNG existente sin usar; no desplegar un segundo SearXNG.
  - **Denominador de Suite**: Inmutable en **38/38** (0 errores) salvo Check nuevo declarado.
  - **Compuertas Globales**: Sin interacción con `main`, sin creación de tags de git.

## Skills relevantes
- `remote-admin`: Verificación y ejecución de contenedores Docker en VPS vía SSH seguro.
- `tech-scout`: Análisis técnico de imágenes de contenedores e interfaces OpenAPI/REST.
- `agent-os-scripts`: Diagnósticos de flota, suite de validación y control de calidad.
- `coolify-admin`: Gestión de servicios y contenedores si procede.

## Caja de archivos
- `.agents/tasks/task-171.md`
- `docs/sprints/sprint-30-core.md`
- `docs/sprints/sprint-30-research.md`
- `roadmap.md`
- `tests/validate-control-plane.sh`
- `templates/` (plantilla compose de Vane si el ensayo procede)
- `scripts/agent/lib/` (cliente o integración si el ensayo procede)
- `docs/runbooks/` (runbook operativo si el ensayo procede)

## Criterios de done
- [ ] Gate 0 superado: `docker pull itzcrazykns1337/vane:latest` ejecutado exitosamente en nodo de flota (o aborto fail-closed documentado).
- [ ] Contenedor Vane desplegado y en ejecución en la infraestructura de la flota para el ensayo.
- [ ] Búsqueda/investigación real ejecutada por la ruta autónoma produciendo un informe útil (o aborto fail-closed documentado).
- [ ] Decisión técnica fundamentada sobre la integración del SearXNG preexistente (sin duplicar instancias).
- [ ] Suite de validación de control plane inmutable en 38/38 pasando limpia (0 errores).
- [ ] Sin interacción con `main` y sin tags de git.
- [ ] Ejecutada y registrada bajo las reglas de Opción D.
