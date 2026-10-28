# Task-120: Modificación del workflow `session-start.md` (Integración de Deliberación)

## Objetivo
Actualizar el workflow canónico `.agents/workflows/session-start.md` para integrar la deliberación determinista de `deliberate-plan.sh` en Fase 3.5, sustituyendo el bloque crudo de 100 líneas por el **Executive Design Digest** sin alterar la semántica de seguridad: la única autorización de ejecución sigue siendo el `APROBADO` (o `Y`) del operador humano.

## Contexto técnico
Actualmente la Fase 3.5 detiene al agente obligándolo a emitir un bloque exhaustivo de plan que el operador copia a un revisor externo (Muse). Con T-119 completado (`deliberate-plan.sh`), el agente:
1. Redacta el borrador en `.agents/context/plan-draft.md`.
2. Invoca automáticamente `deliberate-plan.sh --plan .agents/context/plan-draft.md --task-id T-XXX`.
3. Si el estado es `CONSENSO`, `REVISADO_CON_CAMBIOS` o `ESCALADO_A_HUMANO`, presenta el **Executive Design Digest** con campos obligatorios:
   - Objetivo estratégico
   - Correcciones acordadas entre Coder y Revisor
   - Ficheros a tocar
   - Acciones irreversibles
   - Skills aplicadas (con su regla justificada)
   - Referencia a artefactos completos (`plan-draft.md` + `plan-deliberation.json`)
   - Estado del veredicto
   - Token bloqueante: `⏳ ESPERANDO: responde APROBADO (o Y), APROBADO CON CAMBIOS: [...] o CANCELAR`
4. Si el estado es `SIN_REVISOR`, emite un aviso visible (`⚠️ REVISOR OFFLINE`) y ejecuta el fallback al formato de plan crudo clásico de Fase 3.5 para aprobación manual directa sin bloquear la sesión.

## Skills relevantes
- `workflow-designer`: Estándar oficial de diseño y refactorización de workflows de agent-os.
- `goal-evaluation`: Compuertas de decisión desacopladas y circuit breaker humano.
- `doc-maintainer`: Preservación de formato semántico, enlaces y no rotura de referencias.

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/workflows/session-start.md`
- `.agents/tasks/task-120.md`

## Criterios de done
- [ ] `.agents/workflows/session-start.md` documenta la invocación de `deliberate-plan.sh` tras Fase 3.
- [ ] Fase 3.5 especifica el bloque **Executive Design Digest** con los 8 campos obligatorios (objetivo, correcciones, ficheros, acciones irreversibles, skills aplicadas, referencias completas, estado, token bloqueante).
- [ ] La semántica de autorización se mantiene 100% inalterada: la única autorización para abrir `.agent-session.lock` y crear ramas es la respuesta explícita `APROBADO` / `Y` del operador.
- [ ] Se documenta el comportamiento de fallback `SIN_REVISOR` hacia el plan crudo clásico sin romper la sesión.
- [ ] Cláusula de skills integrada en el contrato: las skills declaradas deben citar su regla aplicada en el plan borrador.
- [ ] Suite de validación `validate-control-plane.sh` ejecutada pasando 33/33 checks sin regresiones.
