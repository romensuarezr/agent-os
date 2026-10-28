# Task-119: Motor determinista de arbitraje Coder-Reviewer (`deliberate-plan.sh`)

## Objetivo
Implementar `scripts/agent/deliberate-plan.sh` como motor autónomo de arbitraje para la deliberación cruzada de planes de sesión en `agent-os`. Automatiza la revisión de inventario contra git y detecta supuestos falsos o dependencias fantasma antes de la ejecución, con límite estricto de 1 ronda de corrección automática, timeout de 5s, fallback seguro a `SIN_REVISOR` y coste $0 de tokens.

## Contexto técnico
Hoy la Fase 3.5 de `session-start.md` genera un bloque de plan crudo y detiene al operador en seco. El operador copia el plan a un revisor externo (Muse/Perplexity) para comprobar inventario real antes de aprobarlo. Este cuello de botella de "humano-middleware" se automatiza mediante `deliberate-plan.sh`, que:
1. Extrae un inventario determinista y acotado (<4KB): allowlist de la tarea, rutas declaradas en skills del task file, y estructura del árbol (`git ls-files` filtrado a configs, scripts, templates y perfiles). Si se trunca, se declara explícitamente en el payload.
2. Despacha la consulta al Revisor usando el endpoint OpenAI-compatible configurado en `.agents/config/fleet.yaml` o entorno (`INFERENCE_BASE_URL`), sin literales de infraestructura ni IPs fijas (cumple Check 22). No existe webhook/pasarela accesible por script para Muse en la flota; el Revisor es exclusivamente el modelo $0 de la pasarela.
3. Timeout estricto de 5 segundos. Si falla o no responde, degrada de inmediato al estado `SIN_REVISOR` con aviso en stderr y genera el fallback al plan crudo clásico sin bloquear la sesión. Los mocks son exclusivos para pruebas automatizadas y nunca emiten `CONSENSO` en ejecución real.
4. Límite de 1 ronda de corrección automática (tope absoluto 2 rondas). Si tras 1 ronda persisten las discrepancias, devuelve `ESCALADO_A_HUMANO` contrastando ambas posturas.
5. Emite uno de los 4 estados canónicos: `CONSENSO`, `REVISADO_CON_CAMBIOS`, `ESCALADO_A_HUMANO` o `SIN_REVISOR`.
6. Aplica la cláusula de skills: comprueba que las skills declaradas en el task file estén justificadas con su regla aplicada en el plan, o emite la objeción `skill declarada no aplicada`.

## Skills relevantes
- `goal-evaluation`: patrón Ralph Loop, compuertas desacopladas y circuit breakers (máx 2 rondas, fallback fail-safe).
- `agent-os-scripts`: estándares CLI universales, lib/cli-help.sh, opciones `--help`, códigos de salida POSIX.
- `doc-maintainer`: preservación de trazabilidad y actualización de referencias cruzadas.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/deliberate-plan.sh` (nuevo)
- `.agents/config/routing-policy.yaml` (declaración del rol 'reviewer' en Capa 2/4)
- `.agents/tasks/task-119.md`

## Criterios de done
- [ ] `scripts/agent/deliberate-plan.sh` ejecutable con `--help`, control de dependencias (`curl`, `python3`, `git`, `sed`), y soporte `--plan <path>`, `--task-id <id>`, `--output <path>`, `--json`.
- [ ] Límite estricto de rondas implementado: máx 1 ronda de ajuste automático (tope 2); si no hay acuerdo emite `ESCALADO_A_HUMANO`.
- [ ] Timeout de 5s configurado en la llamada HTTP; ante fallo o timeout emite `SIN_REVISOR` y replica el plan crudo sin romper la sesión.
- [ ] Empaquetado de inventario acotado estrictamente a <4KB con indicador de truncado si excede.
- [ ] Cero literales de infraestructura: resuelve endpoint vía `fleet.yaml` o `INFERENCE_BASE_URL` (Check 22 compliant).
- [ ] Cláusula de skills validada: objeta si una skill declarada no justifica su regla en el plan.
- [ ] Pruebas unitarias/funcionales manuales ejecutadas verificando los 4 estados: `CONSENSO`, `REVISADO_CON_CAMBIOS`, `ESCALADO_A_HUMANO` y `SIN_REVISOR`.
