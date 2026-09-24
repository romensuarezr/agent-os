# Sprint 06 — Core

**Período**: 2026-09-24 → 2026-09-30  
**Objetivo**: Fase 1B del Control Plane: Ejecutar la auditoría de infraestructura y seguridad en el VPS `oracle`, normalizar la autenticación de Git por SSH en servidores remotos y realizar el primer Run no destructivo supervisado de Orca validando los Decision Gates obligatorios.

---

## Estado
✅ Completado

---

## Tareas del Sprint (Fase 1B)

| ID | Descripción | Tamaño | Estado | Dependencias / Bloqueos | Task file |
| :--- | :--- | :---: | :---: | :--- | :---: |
| T-035 | Auditoría no destructiva de capacidad de disco y exposición de puertos en `oracle` | M | ✅ Completada | Solo lectura; informe generado en docs/runbooks/ | [.agents/tasks/task-035.md](file:///home/romen/Proyectos/agent-os/.agents/tasks/task-035.md) |
| T-036 | Diseño y normalización de autenticación GitHub SSH en `datamanager` y `oracle` | M | ✅ Completada | Solo lectura; runbook en docs/runbooks/ y check script en remote-admin | [.agents/tasks/task-036.md](file:///home/romen/Proyectos/agent-os/.agents/tasks/task-036.md) |
| T-038 | Prospección determinista pre-código: script `scout.sh` e integración con `tech-scout` y `tool-decision-flow` | S | ✅ Completada | Ninguna; script en scripts/agent/ y skill tech-scout | [.agents/tasks/task-038.md](file:///home/romen/Proyectos/agent-os/.agents/tasks/task-038.md) |
| T-037 | Primer Run Orca read-only y prueba de Decision Gates (L3) | M | ✅ Completada | Solo lectura; script audit-orca.sh y runbook actualizado | [.agents/tasks/task-037.md](file:///home/romen/Proyectos/agent-os/.agents/tasks/task-037.md) |

---

## Backlog Priorizado (Bloqueado — Fase 2)

> Tareas técnicas planificadas para el Sprint 07 (Fase 2: Conexión y Validación de Agentes).

### T-039: Validación local de OpenCode con FreeLLMAPI
- **Estado**: ⏸ Bloqueada en Backlog
- **Dependencias**: Cierre de Sprint 06.
- **Riesgos**: Consumo accidental de saldo si OpenCode se desvía a proveedores cloud de pago; fallos de streaming en tool calling.
- **Criterio de aceptación**: Configuración de `opencode` en local apuntando a `http://100.77.82.13:3001/v1`; generación exitosa de tests en un repositorio efímero de prueba con coste verificado $0.
- **Rollback**: `opencode providers logout` y eliminación de la configuración de test en `~/.config/opencode/`.
- **Gate humano requerido**: Aprobación del repositorio de prueba y del scope del prompt antes de ejecutar OpenCode.

### T-040: Integración Hermes -> cola de tareas Orca en estado pending_approval
- **Estado**: ⏸ Bloqueada en Backlog
- **Dependencias**: T-037, T-039.
- **Riesgos**: Apertura de superficie de ejecución desde WhatsApp; riesgo de saturación de la cola de Orca por mensajes externos.
- **Criterio de aceptación**: Handler o skill en Hermes que ante una instrucción validada en WhatsApp inserte una tarea en `orchestration.db` en estado `pending_approval`, requiriendo confirmación humana obligatoria en la consola antes de cualquier ejecución.
- **Rollback**: Deshabilitar el handler en Hermes y reiniciar `hermes-gateway.service` en `datamanager`.
- **Gate humano requerido**: Aprobación del diseño del canal de entrada y verificación estricta del allowlist de números de teléfono autorizados.

---

## Criterio de Éxito del Sprint 06

1. Diagnóstico completo y documentado del uso de disco en `/dev/sda1` en `oracle` (con recomendaciones de poda de imágenes y backups huérfanos sin tocar contenedores de producción).
2. Mapeo exhaustivo de la superficie de ataque de puertos en `oracle` frente a reglas de firewall o aislamiento Tailscale.
3. Propuesta aprobada y probada de claves SSH/Deploy Keys para eliminar el error `Host key verification failed` de GitHub en `datamanager` y `oracle`.
4. Ejecución exitosa del primer Run de auditoría supervisada mediante Orca con verificación del Decision Gate bloqueante ante acciones L3.
