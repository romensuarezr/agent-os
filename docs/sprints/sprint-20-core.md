# Sprint 20 — Deliberación Cruzada Autónoma y Executive Design Digest

## Estado
⚪ Planificado (PRÓXIMO — no activo hasta cierre formal de versión de sprint 19)

## Tareas
| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :--- | :--: | :--- | :--- |
| T-119 | `deliberate-plan.sh`: motor determinista de arbitraje Coder-Reviewer con timeout 5s, máx 1 ronda de auto-corrección, fallback a `SIN_REVISOR`, inventario acotado <4KB y 4 estados | Nueva herramienta | M | ✅ Completada | — | [.agents/tasks/task-119.md](.agents/tasks/_archived/task-119.md) |
| T-120 | Modificación del workflow `session-start.md`: sustitución del bloqueo crudo de Fase 3.5 por el Executive Design Digest sin tocar la semántica del APROBADO (Y) ni la cláusula de skills | Workflow | S | ✅ Completada | T-119 | [.agents/tasks/task-120.md](.agents/tasks/_archived/task-120.md) |
| T-121 | `design-digest.sh`: generador de registro histórico de diseño integrado en `close-task.sh`, salida canalizada por `lib/redact.sh` hacia `docs/sprints/design-decisions/` | Nueva herramienta | S | ⬜ Pendiente | T-119, T-120 | [.agents/tasks/task-121.md](.agents/tasks/task-121.md) |
| T-122 | Extensión de la suite de validación: check 34 (denominador 33→34) para mock/offline, cero secretos en artefactos y frontera portable (check 22) | DX / Tests | S | ⬜ Pendiente | T-119, T-120, T-121 | [.agents/tasks/task-122.md](.agents/tasks/task-122.md) |

## Notas de planning

- **Origen**: Solicitud de plataforma del operador para resolver el "cuello de botella del humano-middleware" (copiar/pegar entre agente local y revisor externo).
- **Modo Piloto Supervisado**: Durante el Sprint 20, el relay externo (Muse) continúa auditando como control; el bucle autónomo no sustituye la revisión humana/externa hasta que los datos de un sprint completo demuestren paridad de detección. Retirar el relay es una decisión aparte.
- **Auditoría de Muse**: No existe pasarela API ni webhook accesible por script para Muse en la flota/entorno. El Revisor autónomo es **únicamente el modelo $0** accesible vía pasarela OpenAI-compatible (`FreeLLMAPI` / `OmniRoute` configurado en `fleet.yaml` o variables de entorno estándar).
- **Guardarraíles Obligatorios**:
  1. Máximo 1 ronda de corrección automática (tope absoluto 2 rondas). Sin consenso → `ESCALADO_A_HUMANO`. Nunca bucle infinito.
  2. Timeout 5s a la inferencia. Si falla o no responde → `SIN_REVISOR` con fallback directo al plan clásico de Fase 3.5. Cero bloqueos de sesión. Los mocks son exclusivos de tests unitarios y nunca emiten `CONSENSO` en ejecución real.
  3. Inventario acotado (<4KB): allowlist primero, archivos de skills declaradas después, estructura de árbol filtrada. Si se trunca, se declara en el payload.
  4. Endpoint configurable (frontera portable, check 22): sin IPs ni rutas fijas en el código del core.
  5. Cláusula Skills: cada task file declara skills por nombre; `plan-draft.md` justifica su aplicación o "no aplica"; el Revisor audita la aplicación de skills como clase de objeción; el digest final lista las skills aplicadas.
  6. Redacción de seguridad: todos los artefactos de diseño pasan por `lib/redact.sh` antes de persistir en disco.
