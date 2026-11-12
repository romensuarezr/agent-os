# Task-204: Ensayo y validación E2E en satélite real (annascheer-web)

## Objetivo
Ejecutar la validación práctica de extremo a extremo de las innovaciones del Sprint 37 sincronizándolas al satélite real `<satelites>/annascheer-web`, verificando deterministamente la presencia de `AGENTS.md`, la activación de la regla de boot del Coordinador y la selección de playbooks, y dejando una guía operativa paso a paso para que el operador humano realice la prueba manual directa en una terminal de Antigravity sobre la web de Anna.

## Contexto técnico
- El usuario solicitó explícitamente validar la implementación en un satélite real antes de dar por cerrado el sprint: *"incluye la prueba real como tarea del sprint, para testear que está bien implementado. y luego lo hago yo manualmente en un proyecto que me digas, como la web de anna"*.
- `annascheer-web` es el satélite ideal: tiene el Sprint 02 activo con T-006 y T-007 hechas, y 3 tareas pendientes listas (T-008, T-009, T-010).
- Permite verificar el ciclo completo: distribución de `AGENTS.md`, reconocimiento del rol de Coordinador, diagnóstico del sprint a coste $0 y selección del playbook adecuado (`parallel-worktrees` o `plan-big-execute-small`).

### Research integrado (`docs/sprints/sprint-37-research.md` → `### T-204`)
- **Scout OSS**: Validación empírica directa en proyecto real sin intermediarios sintéticos.
- **Veredicto**: `Desarrollo a medida justificado`.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 37 / 2026-11-12
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - Sincronizar todos los activos nuevos de T-201, T-202 y T-203 a `<satelites>/annascheer-web` usando `bash scripts/agent/sync.sh --force --cleanup --commit <satelites>/annascheer-web`.
  - Verificar deterministamente en el satélite:
    1. Existencia y contenido de `AGENTS.md` en la raíz de `annascheer-web`.
    2. Existencia de `.agents/rules/global/coordinator-boot.md` y `.agents/config/orchestration-playbooks.yaml`.
    3. Ejecución de `check-sprint.sh` y `orchestration-report.sh` devolviendo códigos de salida limpios (exit 0).
  - Documentar en el task file y en el informe de cierre la **Guía de Verificación Manual para el Operador**:
    - Comando para abrir la terminal en `annascheer-web`.
    - Qué debe responder el nuevo agente de Antigravity al abrir la sesión (saludo como Coordinador, estado del Sprint 02 y menú interactivo de opciones).
    - Cómo verificar que el agente propone el playbook correcto para las tareas pendientes.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `docs/sprints/sprint-37.md`
- `.agents/tasks/task-204.md`
- Referencia externa: `<satelites>/annascheer-web` (solo vía `sync.sh`)

## Criterios de done
- [x] `sync.sh --force --cleanup --commit` ejecutado satisfactoriamente sobre `<satelites>/annascheer-web`.
- [x] Verificado que `annascheer-web/AGENTS.md` existe y está en paridad con la plantilla canónica.
- [x] Verificado que `audit-satellites.sh` reporta `annascheer-web` como LIMPIO (61/61 scripts OK).
- [x] Guía paso a paso documentada para la prueba manual del operador humano en `annascheer-web`.
- [x] Suite `tests/validate-control-plane.sh` pasando limpia sin regresiones (38/38 checks verdes).

## Guía de Verificación Manual para el Operador (annascheer-web)

Para verificar en vivo que las innovaciones de Agent OS funcionan correctamente sobre el satélite real:

### Paso 1: Abrir terminal interactiva en el satélite
Abre una terminal o inicia una sesión de Antigravity en la carpeta del satélite:
```bash
cd ~/Proyectos/annascheer-web
# o inicia la sesión de Antigravity / Cursor en dicho directorio
```

### Paso 2: Saludo inicial y boot proactivo
Escribe un simple saludo:
> `"hola"` o `"buenas"`

**Respuesta esperada del agente**:
- El agente lee proactivamente `AGENTS.md` y la regla `coordinator-boot.md`.
- Ejecuta internamente en silencio `bash scripts/agent/check-session.sh` y `bash scripts/agent/check-sprint.sh` ($0 tokens).
- Se presenta explícitamente como el **Coordinador** de Agent OS.
- Reporta el estado real del **Sprint 02** (2/5 completadas, tareas pendientes: `T-008`, `T-009`, `T-010`).
- Muestra el menú de opciones interactivas para continuar con el sprint (`/session-start`), planificar o consultar telemetría.

### Paso 3: Verificación de telemetría determinista a $0 tokens
Ejecuta directamente el nuevo script de telemetría de orquestación:
```bash
bash scripts/agent/orchestration-report.sh
```
**Resultado esperado**:
- Reporte formateado en terminal mostrando el progreso de Sprint 02 (40.0%), los playbooks (`plan-big-execute-small` para T-008, T-009 y T-010 debido a sus cajas >3 archivos) y métricas de eficiencia.

### Paso 4: Comprobar la regla de umbral de orquestación
Si ejecutas una tarea pequeña (<= 3 archivos en su caja autorizada), el Coordinador utilizará el modo `direct` en la sesión local sin crear ramas ni worktrees efímeros redundantes. Si ejecutas una tarea extensa (como T-008 o T-009 con 9–10 archivos), el agente propondrá aislarla en worktree para evitar el context rot.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
- [x] Plan presentado al usuario (Fase 3.5)
- [x] Rama de trabajo creada
- [x] Verificación con verify-goal.sh
- [x] Cierre y merge formalizado
