# Sprint 05 — Core

**Período**: 2026-09-24 → 2026-09-30  
**Objetivo**: Fase 1A del Control Plane de Agentes: implementar la base declarativa, revisable y no destructiva en `agent-os` (perfiles de agentes, registro central, políticas de enrutamiento y permisos, topología de red, ADR fundacional, runbook de auditoría Orca y suite de validación) sin alterar los runtimes en ejecución.

---

## Estado
✅ Completado

---

## Tareas del Sprint (Fase 1A)

| ID | Descripción | Tamaño | Estado | Dependencias / Bloqueos |
| :--- | :--- | :---: | :---: | :--- |
| T-030 | Arquitectura y ADR de control plane (`docs/adrs/adr-004-agent-control-plane-architecture.md`) | M | ✅ Completada | Aprobada por el usuario |
| T-031 | Perfiles declarativos, agent registry y routing policy (`.agents/profiles/`, `config/agent-registry.yaml`, `config/routing-policy.yaml`) | M | ✅ Completada | Aprobada por el usuario |
| T-032 | Políticas, runbooks y topología (`.agents/rules/global/agent-permissions.md`, `docs/architecture/control-plane-topology.md`, `docs/runbooks/`) | M | ✅ Completada | Aprobada por el usuario |
| T-033 | Validación automatizada y compatibilidad con skills/symlinks de Hermes (`tests/validate-control-plane.sh`, `.gitignore`) | S | ✅ Completada | Aprobada por el usuario |
| T-034 | Revisión de diff, validación final y preparación de commit atómico de Fase 1A | S | ✅ Completada | Aprobada por el usuario; merge realizado |

---

## Backlog Priorizado (Bloqueado — Fuera del alcance del commit actual)

> Tareas técnicas y de integración operativa planificadas para fases posteriores. Ninguna de estas tareas debe implementarse en la rama actual antes del cierre y commit atómico de la Fase 1A.

### T-035: Auditoría de capacidad de disco y exposición de puertos en oracle (Solo lectura)
- **Estado**: ⏸ Bloqueada en Backlog
- **Dependencias**: Cierre y merge de T-034.
- **Riesgos**: Posible confusión con listeners dinámicos de Coolify; riesgo nulo en el servidor al ser solo lectura.
- **Criterio de aceptación**: Informe detallado con desglose de uso de disco en `/dev/sda1` (por volúmenes Docker, bases de datos y backups huérfanos) y mapeo exhaustivo de puertos abiertos a `0.0.0.0` frente a reglas de firewall.
- **Rollback**: N/A (operación no invasiva de lectura).
- **Gate humano requerido**: Aprobación previa de la lista de comandos de diagnóstico antes de invocar SSH sobre `oracle`.

### T-036: Diseño y normalización de autenticación GitHub SSH en datamanager y oracle
- **Estado**: ⏸ Bloqueada en Backlog
- **Dependencias**: T-035.
- **Riesgos**: Corrupción accidental de `~/.ssh/known_hosts` o inyección indebida de credenciales privadas con alcance excesivo.
- **Criterio de aceptación**: Propuesta documentada (ADR/runbook) y resolución de `Host key verification failed` usando Deploy Keys de solo lectura por repositorio o normalización de `known_hosts` sin secretos interactivos.
- **Rollback**: Restaurar copias de seguridad de `~/.ssh/known_hosts` y `~/.ssh/config`.
- **Gate humano requerido**: Autorización explícita para la generación, registro en GitHub y prueba de llaves SSH en cada host.

### T-037: Primer Run Orca read-only y prueba de decision gates
- **Estado**: ⏸ Bloqueada en Backlog
- **Dependencias**: T-034, T-035.
- **Riesgos**: Ejecución accidental de comandos mutacionales en servidores remotos si falla la configuración del gate.
- **Criterio de aceptación**: Despacho exitoso de un Run supervisado no destructivo desde Orca Desktop hacia los relés de `datamanager` y `oracle`; verificación en `orchestration.db` de que un comando de prueba L3 activa el estado `pending_approval` y detiene la ejecución.
- **Rollback**: Cancelación manual del Run en Orca Desktop y purga del dispatch context.
- **Gate humano requerido**: Autorización interactiva explícita en la UI de Orca Desktop antes de autorizar el dispatch del worker.

### T-038: Validación local de OpenCode con FreeLLMAPI
- **Estado**: ⏸ Bloqueada en Backlog
- **Dependencias**: T-034.
- **Riesgos**: Consumo accidental de saldo si OpenCode se desvía a proveedores cloud de pago; fallos de streaming en tool calling.
- **Criterio de aceptación**: Configuración de `opencode` en local apuntando a `http://100.77.82.13:3001/v1` mediante variable de entorno o provider config; generación exitosa de tests en un repositorio de pruebas efímero con coste verificado $0.
- **Rollback**: `opencode providers logout` y eliminación de la configuración de test en `~/.config/opencode/`.
- **Gate humano requerido**: Aprobación del repositorio de prueba y del scope del prompt antes de ejecutar OpenCode.

### T-039: Integración Hermes -> cola de tareas Orca en estado pending_approval
- **Estado**: ⏸ Bloqueada en Backlog
- **Dependencias**: T-037.
- **Riesgos**: Apertura de superficie de ejecución desde WhatsApp; riesgo de saturación de la cola de Orca por mensajes externos.
- **Criterio de aceptación**: Skill o handler en Hermes que ante una instrucción validada en WhatsApp inserte una tarea en `orchestration.db` en estado `pending_approval`, requiriendo confirmación humana obligatoria en la consola antes de cualquier ejecución.
- **Rollback**: Deshabilitar el handler en Hermes y reiniciar `hermes-gateway.service` en `datamanager`.
- **Gate humano requerido**: Aprobación del diseño del canal de entrada y verificación estricta del allowlist de números de teléfono autorizados.

---

## Criterio de Éxito del Sprint 05 (Fase 1A)

1. El repositorio `agent-os` cuenta con perfiles formales para `coordinator`, `ops-auditor`, `developer`, `reviewer`, `marketing`, `seo` y `researcher` debidamente registrados en `config/agent-registry.yaml`.
2. Las políticas de enrutamiento y permisos quedan tipificadas de forma abstracta y sin secretos en `config/routing-policy.yaml` y `.agents/rules/global/agent-permissions.md`.
3. El ADR 004 y la topología técnica documentan formalmente la separación de roles entre `agent-os` (core), `hermes-vps-config` (infra VPS), Hermes (front door 24/7), Orca (supervisión y execution plane) y FreeLLMAPI (routing/fallback).
4. El `.gitignore` raíz previene activamente la fuga de credenciales, logs, estados runtime o worktrees efímeros.
5. Los runbooks existentes (`freellmapi-vps-runbook.md` y `hermes-vps-runbook.md`) quedan organizados en `docs/runbooks/` junto al nuevo runbook de auditoría de Orca.
6. El validador `tests/validate-control-plane.sh` ejecuta y aprueba con código de salida 0.
7. T-034 completa la revisión técnica del diff sin introducir deuda técnica ni secretos antes del commit aprobado por el usuario.
