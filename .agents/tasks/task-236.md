# T-236 — Optimización Reactiva de Coordinación en orca-reactive-wait.sh (Despertar Nativo sin Polling)
Sprint: Sprint 44 | Estado: ⬜ Pendiente | Tamaño: S | Rama propuesta: feat/T-236-orca-reactive-wait-optimization | Merge destino: multi-agent

## Diseño macro aprobado en planning
- **Sprint / Fecha**: Sprint 44 — 2026-11-23
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Capitalizar la mejora nativa de Orca v1.4.268 ("A worker's final report wakes the agent that started it").
  - Revisar y optimizar `scripts/agent/lib/orca-reactive-wait.sh` para reducir tiempos de respuesta ante eventos `worker_done`, eliminando backoffs pasivos innecesarios cuando el daemon de Orca esté activo.
  - Asegurar la degradación transparente y segura (fail-safe) en entornos donde Orca no esté presente o corra en modo CLI aislado.
- **Veredicto de diseño macro**: [APROBADO_EN_PLANNING]

---

## 1. Objetivo
Acelerar la comunicación y finalización de tareas multi-agente en `deliberate-plan.sh` y orquestación por worktrees aprovechando la señalización de eventos nativa de Orca 1.4.268 a $0 tokens.

## 2. Contexto técnico
- Biblioteca de espera reactiva: `scripts/agent/lib/orca-reactive-wait.sh`.
- Cliente CLI: `scripts/agent/lib/orca-client.sh`.
- Motor de deliberación: `scripts/agent/deliberate-plan.sh`.

## 3. Caja de archivos
- `scripts/agent/lib/orca-reactive-wait.sh`
- `tests/` (pruebas de reactividad o mocks de control plane)
- `.agents/tasks/task-236.md`
- `docs/sprints/sprint-44.md`

## 4. Plan de implementación
1. Auditar `orca-reactive-wait.sh` para verificar el manejo de `orca orchestration check --types worker_done --wait`.
2. Adaptar la captura del evento inmediato emitido por Orca al reportar el worker.
3. Verificar que la degradación sin Orca sigue funcionando limpiamente.
4. Ejecutar pruebas unitarias locales.

## 5. Criterios de aceptación
- `orca-reactive-wait.sh` responde de forma inmediata al evento nativo sin sleeps superfluos.
- No hay regresiones en la suite de validación de control plane.
