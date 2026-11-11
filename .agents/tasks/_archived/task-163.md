# Task-163: Higiene de cierre completa (blindaje de rutas personales fuera de repo y re-chequeo post-cierre)

## Objetivo
Generalizar el filtro de saneamiento de rutas personales en `scripts/agent/design-digest.sh` para abarcar rutas absolutas de host fuera de `${ROOT_DIR}` e incorporar un re-chequeo determinista de higiene en los scripts de cierre (`close-task.sh` y `close-sprint.sh`), blindando el flujo de cierre contra violaciones de frontera portable.

## Contexto técnico
En el Sprint 28, durante el cierre de T-159/T-160, el revisor generó rutas absolutas con esquema `file:///home/usuario/...` que provocaron el disparo preventivo de Check 22 (`locator-hygiene.sh`). Se implementó un blindaje puntual en `design-digest.sh` para eliminar `${ROOT_DIR}/`. Sin embargo:
1. Si un LLM o herramienta produce rutas que caen fuera de `${ROOT_DIR}` (ej. `/home/usuario/...` o `/Users/usuario/...` sin coincidencia exacta con `${ROOT_DIR}`), el filtro actual no las atrapa.
2. `close-task.sh` realiza commits atómicos del task file y el digest sin ejecutar una verificación de higiene sobre el staging o post-cierre, lo que permitía que un digest defectuoso se commiteara y solo fuera detectado después por la suite general.
3. Se requiere generalizar la sustitución de rutas personales en `design-digest.sh` y añadir re-chequeo determinista de higiene en `close-task.sh` y `close-sprint.sh`.

Esta tarea se ejecuta bajo el régimen estándar de **Opción D**.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 29 / 2026-11-02
- **Diseño y arquitectura aprobados por**: Humano / Relé (Sprint Planning Sprint 29)
- **Decisiones e interfaces selladas**:
  - En `scripts/agent/design-digest.sh`:
    - Extender el pipeline de sanitización previo a `lib/redact.sh` para sustituir de forma universal patrones `/(home|Users)/[a-zA-Z0-9_-]+/` y esquemas `file:///...`, normalizando rutas internas a relativas (`.agents/tasks/...`, `src/...`) y enmascarando rutas externas como `<home>/...` o relativas al workspace.
  - En `scripts/agent/close-task.sh`:
    - Incorporar validación determinista de higiene con `locator-hygiene.sh` en el staging previo al commit de cierre para fail-closed si se detecta alguna fuga.
  - En `scripts/agent/close-sprint.sh`:
    - Incorporar validación de higiene determinista en el staging del sprint.
  - En `tests/validate-control-plane.sh`:
    - Adecuar Check 18, Check 19 y Check 34 para verificar el blindaje generalizado y la validación en scripts de cierre sin regresiones.
  - Denominador de la suite de control plane se mantiene en **38/38** (0 errores).
  - Régimen Opción D: avance desatendido en camino limpio ante veredicto `CONSENSO`.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `agent-os-scripts`: Mantenimiento y robustez de los scripts de cierre del core.
- `structure-guardian`: Aseguramiento de convenciones de rutas relativas y portables.

## Caja de archivos
- `scripts/agent/design-digest.sh`
- `scripts/agent/close-task.sh`
- `scripts/agent/close-sprint.sh`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-163.md`

## Criterios de done
- [x] Pipeline de sanitización en `scripts/agent/design-digest.sh` generalizado para cualquier ruta personal de host Unix/macOS.
- [x] Verificación de higiene determinista (`locator-hygiene.sh`) integrada en `scripts/agent/close-task.sh`.
- [x] Verificación de higiene determinista integrada en `scripts/agent/close-sprint.sh`.
- [x] Suite de control plane 38/38 pasando limpia (0 errores).
- [x] Tests de Check 18, Check 19 y Check 34 cubren los nuevos re-chequeos.
- [x] Ejecutada y registrada bajo las reglas de Opción D.
