# Task-160: Workflow deep-research con bifurcación autónomo (Bane activo) / manual (Perplexity)

## Objetivo
Crear el workflow especializado `.agents/workflows/deep-research.md` e integrarlo en el flujo de `sprint-planning.md` implementando una bifurcación determinista: si Bane está configurado y alcanzable ("activo"), despacha la consulta automáticamente y deposita la investigación estructurada sin intervención humana; si Bane está inactivo, ausente o no responde, preserva íntegramente el flujo manual actual emitiendo el bloque de prompt listo para copiar en Perplexity Pro sin provocar bloqueos ni roturas.

## Contexto técnico
El ritual de sprint planning contiene actualmente un paso manual donde se genera un bloque de texto formateado para que el usuario lo copie, abra Perplexity Pro en el navegador, ejecute la búsqueda y vuelva a pegar los resultados (`.agents/workflows/sprint-planning.md` Paso 5).
Para dar el salto a la investigación técnica autónoma sin degradar la experiencia en entornos donde no se disponga del servicio:
1. **Bifurcación Determinista**:
   - El workflow consulta `bane-client.sh --check`.
   - **Rama Autónoma (Bane Activo)**: Despacha la consulta generada mediante `bane-client.sh --query ...`, recibe el markdown estructurado por stdout y lo vuelca directamente en `docs/sprints/sprint-XX-research.md` rellenando las secciones `## Hallazgos clave`, `## Decisiones tomadas` y `## Descartado`. No se requiere ninguna acción manual del usuario.
   - **Rama Manual (Bane Inactivo / Fallback)**: Si la comprobación de Bane falla o no está configurado, el workflow cae de forma fluida y determinista en el comportamiento clásico: muestra el prompt formateado para Perplexity, pausa el workflow y espera el pegado humano habitual.
2. **Invariante de No Regresión**: Los desarrolladores y satélites sin contenedor Docker de Bane continúan operando exactamente como hasta ahora, sin errores ni dependencias rotas.

Esta tarea se ejecuta bajo el régimen autónomo del **Piloto Opción D**.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 28 / 2026-11-02
- **Diseño y arquitectura aprobados por**: Humano / Relé (Sprint Planning Sprint 28 - Enmienda Bane)
- **Decisiones e interfaces selladas**:
  - Crear `.agents/workflows/deep-research.md` definiendo el protocolo estándar de investigación profunda.
  - Actualizar `.agents/workflows/sprint-planning.md` en Paso 5 incorporando la bifurcación condicional sobre `bane-client.sh --check`.
  - Garantizar que si Bane no responde dentro de la ventana de timeout, la transición al modo manual sea instantánea (<3s) y sin trazas de error invasivas.
  - El formato de las secciones de research generadas desatendidamente debe coincidir exactamente con el estándar canónico de Agent OS.
  - Denominador de la suite de control plane se mantiene en **37/37** (0 errores).
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `agent-os-scripts`: Integración de utilidades CLI en workflows.
- `workflow-designer`: Diseño y refactorización de especificaciones de workflows Markdown.

## Caja de archivos
- `.agents/workflows/deep-research.md`
- `.agents/workflows/sprint-planning.md`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-160.md`

## Criterios de done
- [x] Workflow `.agents/workflows/deep-research.md` creado según el estándar oficial.
- [x] Integración de bifurcación completada en `.agents/workflows/sprint-planning.md`.
- [x] Comprobación de que ante Bane inactivo, el flujo manual de Perplexity se mantiene 100% idéntico y funcional.
- [x] Comprobación de que ante Bane activo, la investigación se vuelca de forma autónoma en el research file.
- [x] Suite pasando limpia en 37/37 (0 errores).

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
- [x] Plan presentado al usuario (Fase 3.5 / Régimen Opción D)
- [x] APROBADO recibido (Régimen Opción D)
- [x] Rama creada
- [x] Cierre y merge autorizado por el relé (Régimen Opción D camino limpio)
