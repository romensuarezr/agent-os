# Task-173: Sonda determinista de actualización de herramientas (check-tooling-updates.sh)

## Objetivo
Implementar una utilidad CLI determinista en `scripts/agent/check-tooling-updates.sh` con coste $0 de tokens para inspeccionar versiones disponibles de las herramientas y CLIs de la flota a través de registros oficiales (npm, GitHub releases, PyPI), con normalización semver, mapeo de fuente verídica por herramienta y soporte de ejecución resiliente ante cuotas y desconexión.

## Contexto técnico
El inventario de herramientas de la flota requiere seguimiento periódico de versiones para prevenir obsolescencia y detectar mejoras de seguridad o nuevas capacidades. Sin embargo, no todas las herramientas publican sus versiones en el mismo canal (por ejemplo, `@opencode/cli` publica la línea 2.x en npm mientras que GitHub releases mantiene la 1.x). Además, consultar la API de GitHub sin token impone un límite estricto de 60 peticiones/hora.
La sonda debe operar de forma ligera, determinista y fail-soft, mapeando la fuente primaria adecuada para cada componente.
Esta tarea se ejecuta bajo el régimen estándar de **Opción D** y depende de **T-172**.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 31 / 2026-11-08
- **Diseño y arquitectura aprobados por**: Humano / Relé (Decisión Macro en Planning)
- **Decisiones e interfaces selladas**:
  - **Ubicación y firma CLI**: `scripts/agent/check-tooling-updates.sh [--tool <nombre>] [--check] [--json] [--help]`.
  - **Mapeo de fuentes verídicas**:
    - OpenCode: registro npm (`@opencode/cli`).
    - Hermes Agent: GitHub API (`NousResearch/hermes-agent`).
    - Orca IDE: GitHub API (`stablyai/orca`).
    - Herramientas Python: PyPI JSON API.
  - **Normalización semver**: Manejo uniforme de prefijos (ej. eliminación de prefijo `v` para comparaciones matemáticas).
  - **Resiliencia de rate-limiting y offline**: Timeout por petición breve (≤5s); salida fail-soft (código 0 informativo o 2 ante fallo de conectividad/429, nunca crash).
  - **Salida dual**: Salida humana tabular/resumen por defecto y estructurada con `--json`.
  - **Denominador de suite**: Inmutable en **38/38** (0 errores).
- **Veredicto de diseño macro**: `APROBADO_EN_PLANNING`

## Skills relevantes
- `agent-os-scripts`: Integración con utilidades y convenciones del core.
- `tool-inventory`: Conexión con el catálogo de herramientas de la flota.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/check-tooling-updates.sh`
- `tests/validate-control-plane.sh` (subcheck de validación dentro de checks existentes)
- `.agents/tasks/task-173.md`

## Criterios de done
- [ ] Script ejecutable y determinista `scripts/agent/check-tooling-updates.sh` implementado con soporte de `--help`, `--check` y `--json`.
- [ ] Mapeo de fuente verídica implementado correctamente (npm para `@opencode/cli`, GitHub para repositorios y PyPI para paquetes python).
- [ ] Normalización semver funcional que compare versiones sin fallos por prefijos `v`.
- [ ] Tolerancia a fallos ante desconexión o rate limiting HTTP 429 con degradación limpia.
- [ ] Validación integrada en la suite de control plane preservando denominador inmutable en **38/38** (0 errores).
- [ ] Ejecutada y registrada bajo las reglas de Opción D.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `[CONSENSO | REVISADO_CON_CAMBIOS | ESCALADO_A_HUMANO | SIN_REVISOR]`
  - **Rol del revisor**: Compuerta técnica determinista (caja de archivos, tests, realidad repo, fidelidad a diseño macro).
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
