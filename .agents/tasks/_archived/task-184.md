# Task-184: Auditoría determinista de integridad y salud de scripts en satélites (audit-satellites.sh)

## Objetivo
Crear la herramienta determinista `scripts/agent/audit-satellites.sh` para auditar la integridad, permisos y desvíos de los scripts del core en repositorios satélite registrados en `.agents/config/satellites.yaml` (o pasados por argumento), operando en modo solo lectura a coste cero de tokens.

## Contexto técnico
Actualmente `fleet-version.sh` solo compara la versión semver registrada en el ledger `.agents/context/last-sync.md`. No existe un mecanismo determinista para verificar si los scripts instalados en `scripts/agent/` del satélite sufrieron drift, borrados accidentales o pérdida de permisos ejecutables (`+x`). Se requiere una herramienta ligera que compare sumas sha256 contra el core y reporte el diagnóstico.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 33 / 2026-11-10
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Script determinista `scripts/agent/audit-satellites.sh` con flags `--satellites <yaml>`, `--check`, `--json`, `-h/--help`.
  - Operación segura por defecto: solo lectura, sin modificar ficheros ni hacer peticiones de red.
  - Comprobación: existencia de scripts estándar, permisos de ejecución y sumas de verificación vs scripts del core.
  - Integrar en `tests/validate-control-plane.sh` (añadir aserción determinista en Check 9 o check específico sin elevar el denominador 38/38).
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/audit-satellites.sh`
- `tests/validate-control-plane.sh`
- `AGENTS.md`
- `.agents/tasks/task-184.md`

## Criterios de done
- [x] Script `scripts/agent/audit-satellites.sh` ejecutable (0755) con ayuda `cli-help.sh`.
- [x] Soporte para auditar satélites desde `.agents/config/satellites.yaml` o ruta directa.
- [x] Reporte de integridad: OK, DRIFT, MISSING, NO-EXEC.
- [x] Modo `--check` con exit code determinista (0 si limpio, 1 si hay desvíos).
- [x] Suite de validación `tests/validate-control-plane.sh` 38/38 verde.
- [x] `locator-hygiene.sh` 100% limpio.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `CONSENSO`
  - **Rol del revisor**: Compuerta técnica determinista (qa-judge).
- [x] Plan presentado al usuario (Fase 3.5 — Opción D sellada en planning)
- [x] APROBADO recibido — fecha/hora: 2026-11-10 21:19 UTC (camino limpio Opción D)
- [x] Rama creada: feat/T-184-audit-satellites-script
- [x] Lock activo: .agent-session.lock
- [ ] Sesión cerrada correctamente
