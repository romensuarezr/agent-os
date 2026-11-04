# Task-169: Validación de motor de búsqueda profunda (ensayo Vane en vivo, reactivación de SearXNG e integración de backend)

## Estado
⬜ Pendiente
> **Sucesor formal de T-165**: Retoma el objetivo de proveer un motor de búsqueda profunda soberano y funcional para Agent OS, abordando la imposibilidad técnica de desplegar Bane por inexistencia de su imagen pública.

## Objetivo
Evaluar y poner en producción viva una solución soberana de búsqueda profunda para la flota de Agent OS. En primera instancia, realizar un ensayo en vivo de Vane comprobando de forma determinista la disponibilidad de una imagen pública descargable (`docker pull`) y la generación de un informe útil; en caso de que la imagen no exista o el ensayo no resulte satisfactorio, abortar inmediatamente a humano (fail-closed, quedando prohibido cerrar con meras plantillas). Tras el ensayo o como solución soberana prioritaria, reactivar la instancia preexistente de SearXNG en la flota sin uso actual, validando una consulta real y cableándola como backend del motor de búsqueda sin duplicar contenedores. Finalmente, sustituir los artefactos fantasma de Bane (cliente CLI, workflow de deep-research, checks de la suite y runbook) por componentes adaptados al motor validado, cerrando la tarea con una investigación real ejecutada por la ruta autónoma del workflow.

## Contexto técnico
La tarea T-165 fue pausada al detectarse que la imagen declarada `ghcr.io/pythops/bane:latest` no se encuentra publicada ni descargable en ningún registro de contenedores público.
Vane se postula como una posible evolución o alternativa viable. Para evitar repetir un bloqueo similar, la tarea impone la verificación previa de la imagen pública como condición sine qua non.
Por otra parte, la infraestructura de la flota ya dispone de una instancia de SearXNG desplegada en el pasado que actualmente se encuentra inactiva o sin uso. La directriz macro establece reactivar y aprovechar dicho SearXNG existente antes de considerar cualquier despliegue duplicado.
Esta tarea se ejecuta bajo el régimen estándar de **Opción D**.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 30 / 2026-11-04 (Enmienda T-168 a T-170)
- **Diseño y arquitectura aprobados por**: Relé (Decisión Macro de Enmienda Sprint 30)
- **Decisiones e interfaces selladas**:
  - **Ensayo previo de Vane en vivo**: Verificar mediante sondeo y pull si existe una imagen Docker pública y ejecutable de Vane. Si la imagen no está disponible o el ensayo no produce un informe útil, abortar a humano de inmediato (fail-closed). Queda explícitamente prohibido cerrar la tarea con una plantilla no verificada.
  - **Integración de SearXNG existente**:
    - Localizar y reactivar la instancia de SearXNG ya presente en los nodos de la flota.
    - Ejecutar una consulta real directa contra SearXNG y verificar respuesta válida con resultados parseables.
    - Cablear SearXNG como backend de búsqueda profunda de Agent OS.
    - No desplegar un segundo SearXNG sin una justificación técnica formal aprobada frente a la instancia existente.
  - **Sustitución de artefactos fantasma de Bane**:
    - Adaptar o reemplazar `scripts/agent/lib/bane-client.sh` por un cliente CLI determinista alineado con el motor real.
    - Actualizar `.agents/workflows/deep-research.md` (Fase 2A) para consumir el nuevo endpoint de búsqueda.
    - Actualizar `tests/validate-control-plane.sh` (Check 38) asegurando que valide la integración real del motor activo y mantenga el denominador inmutable en **38/38**.
    - Actualizar o sustituir `docs/runbooks/bane-deep-research-service.md`.
  - **Compuerta de cierre**: El criterio de done exige una investigación profunda real ejecutada exitosamente a través de la ruta autónoma del workflow `deep-research.md`.
  - **Denominador de suite**: Inmutable en **38/38** (0 errores).

## Skills relevantes
- `remote-admin`: Inspección y gestión de contenedores Docker en VPS vía SSH seguro.
- `tech-scout`: Análisis y prospección de imágenes y motores OSS.
- `coolify-admin`: Operación sobre servicios en Coolify si aplica.
- `agent-os-scripts`: Verificación y validación de herramientas CLI deterministas.

## Caja de archivos
- `scripts/agent/lib/` (cliente de búsqueda adaptado)
- `.agents/workflows/deep-research.md`
- `templates/` (plantilla compose de búsqueda adaptada)
- `docs/runbooks/` (runbook del servicio de búsqueda)
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-169.md`

## Criterios de done
- [ ] Ensayo en vivo de Vane ejecutado (pull verificado y reporte útil, o aborto documentado a humano si la imagen no existe).
- [ ] Instancia preexistente de SearXNG reactivada y verificada en vivo con consulta real satisfactoria.
- [ ] SearXNG cableado como backend operativo de búsqueda profunda de la flota.
- [ ] Artefactos fantasma de Bane (cliente CLI, compose, checks, runbook) saneados y adaptados al motor validado.
- [ ] Consulta de investigación real ejecutada con éxito a través de la ruta autónoma del workflow `deep-research.md`.
- [ ] Suite de validación de control plane inmutable en 38/38 pasando limpia (0 errores).
- [ ] Ejecutada y registrada bajo las reglas de Opción D.
