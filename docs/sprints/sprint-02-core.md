# Sprint 02 — Core

**Período**: 2026-06-16 → 2026-06-30  
**Objetivo**: Consolidar la universalidad del core mediante soporte multi-stack y documentación de arquitectura (ADRs), mejorando la experiencia del agente (DX).

---

## Tareas

- [x] CORE-18: Universalizaciones pendientes (eliminar hardcodes de paths en scripts) — Universalización
- [ ] CORE-19: Soporte multi-stack documentado en `lib/detect-stack.sh` — Universalización
- [ ] CORE-20: Redactar ADRs de las decisiones clave de arquitectura tomadas — Documentación
- [ ] CORE-21: Mejoras de DX del agente (mensajes de error claros y guías inline) — DX del agente
- [ ] CORE-22: Validar la compatibilidad del script `sync.sh` tras el bootstrap self-hosted — Universalización

## Criterio de éxito

El core es agnóstico del stack y se comporta de manera consistente en proyectos híbridos, documentando sus principales decisiones arquitectónicas en ADRs y ofreciendo mejor soporte para el desarrollo iterativo por agentes.

## Notas

- Este sprint inicia formalmente el proceso de universalización robusta tras el bootstrap del core.
- Las tareas del backlog se basan directamente en las necesidades detectadas durante los despliegues de Kanarii y Polymarket.
