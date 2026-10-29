# Task-127: Extensión de la Suite de Validación con Check 35 (34→35)

## Objetivo
Extender la suite canónica de validación `tests/validate-control-plane.sh` implementando el **Check 35**, actualizando el denominador de la suite de `[X/34]` a `[X/35]` (34 ocurrencias actualizadas + el nuevo Check 35), y validando de forma determinista y sin red las garantías del flujo multi-agente: persistencia de deliberación multi-sesión, contratos de perfiles de handover y compatibilidad de despacho en worktrees.

## Contexto técnico
Sprint 21 consolida la arquitectura multi-agente de Agent OS. El Check 35 debe verificar deterministamente:
1. **Persistencia de deliberación**:
   - `deliberate-plan.sh --task-id <ID>` genera `.agents/context/deliberation-${TASK_ID}.json`.
   - `design-digest.sh` lee preferentemente el archivo nombrado y conserva veredicto/objeciones reales en el digest.
2. **Contratos de perfiles multi-agente**:
   - Perfiles declarativos contienen las secciones de Protocolo de Handover sin romper esquemas YAML/Markdown.
3. **Flujo de despacho y worktrees**:
   - `worktree-dispatch.sh` preserva el aislamiento y la estructura requerida para la deliberación.
4. **Denominador**:
   - Actualización consistente de `[X/34]` a `[X/35]` en todo el script.

## Skills relevantes
- `testing-flows`: Arquitectura de pruebas deterministas no destructivas en el control plane.
- `agent-os-scripts`: Convenciones CLI y estándares de pruebas en bash.
- `orchestrator`: Validación de contratos de roles y perfiles multi-agente.

## Caja de archivos
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-127.md`

## Criterios de done
- [x] Ocurrencias del denominador actualizadas de `[X/34]` a `[X/35]` (34 ocurrencias existentes).
- [x] Check 35 implementado verificando persistencia de deliberación, perfiles de handover y aislamiento de worktrees.
- [x] Suite completa `tests/validate-control-plane.sh` pasando 35/35 checks exitosamente (0 errores).
- [x] Frontera portable (Check 22) y cero regresiones certificadas.
