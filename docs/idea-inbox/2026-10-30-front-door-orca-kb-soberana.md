# Idea: Visión Front-Door + Orca ADE + Knowledge Base Soberana

- **Fecha:** 2026-10-30
- **Origen:** Conversación del usuario con un asistente externo (referencias no verificadas empíricamente, tratar estrictamente como pistas de prospección/scout, no como hechos probados).
- **Estado:** 💡 REGISTRADA, NO APROBADA (Idea capturada para auditoría y backlog futuro; no autorizada para implementación inmediata).
- **Tipo:** Arquitectura de Orquestación / Entrada Remota / Gestión de Conocimiento Soberano.

---

## 1. Visión Conceptual Destilada

Flujo end-to-end para interacción remota y ejecución desacoplada sobre infraestructura soberana:
```
[Mensaje móvil (front-door)]
            │
            ▼
    [Dispatcher central] ──(Sondeo de conectividad en malla privada)
            │
   ┌────────┴────────┐
   ▼                 ▼
[Host local ACTIVO] [Host local INACTIVO]
   │                 │
   │                 └──▶ [Encolar petición + Notificación de espera]
   ▼
[Despacho a workers Orca ADE en worktrees aislados]
   │
   ▼
[Ejecución autónoma + Verificación determinista por máquina (verify-goal / tests)]
   │
   ▼
[Revisión con compuertas humanas (Human Gates)]
   │
   ▼
[Consolidación de conocimiento en archivos propios versionados en Git (sin SaaS)]
```

1. **Front-door móvil**: Punto de contacto remoto simple para emitir directivas o requerimientos desde cualquier ubicación.
2. **Dispatcher consciente de la topología**: Comprueba si el entorno de cómputo local está accesible en la malla privada.
   - Si está en línea: aprovisiona worktrees y despacha tareas a workers supervisados en Orca ADE.
   - Si no está disponible: almacena en cola persistente y emite acuse de recibo notificando el estado diferido.
3. **Verificación y compuertas de calidad**: Validación de entregables combinando checks ejecutables por máquina (criterios deterministas, suites de test) y compuertas de autorización humana explícitas antes de cualquier integración.
4. **Base de conocimiento soberana**: Retención y memoria procedimental residente exclusivamente en el propio repositorio y sistema de archivos (Markdown, YAML, SQLite/JSONL locales), rechazando dependencias de plataformas SaaS propietarias.

---

## 2. Nota Crítica del Relay (Guardarraíles contra Sobre-Ingeniería)

> [!WARNING]
> **Principio de Máxima Parsimonia Tecnológica**: No incorporar sistemas nuevos (tales como demonios conversacionales pesados, interfaces dedicadas para bases de conocimiento o motores de búsqueda vectorial / RAG complejos) sin antes consolidar y validar las primitivas básicas de Agent OS.

Lo ya construido y operativo en el ecosistema de Agent OS cubre de forma determinista la mayor parte de los requerimientos identificados:
- **Deliberación autónoma**: `scripts/agent/deliberate-plan.sh` con jerarquía de arbitraje certificada (Orca -> Cascada HTTP -> `SIN_REVISOR`).
- **Trazabilidad y memoria de diseño**: `scripts/agent/design-digest.sh` y registros estructurados en `.agents/context/` y `docs/sprints/design-decisions/`.
- **Aislamiento y compuertas**: `scripts/agent/worktree-dispatch.sh`, `worktree-merge.sh` y el esquema estricto de compuertas humanas (Fase 3.5 / Definition of Done).
- **Memoria persistente**: Historial git, ADRs, contratos de tareas (`.agents/tasks/`) y reglas globales/locales (`.agents/rules/`).

### Prerrequisitos de maduración obligatorios:
1. **Deliberación en producción durante un ciclo completo**: Operación supervisada con el revisor vivo en host (Sprint 24 en curso).
2. **Paralelismo controlado y medido**: Despacho concurrente de workers y contención de recursos certificada (Sprint 25).
3. **Dispatcher fino y determinista**: Mecanismo de enrutamiento y encolado robusto sin procesos huérfanos.
4. **Nueva infraestructura de KB únicamente bajo demanda demostrada**: Explorar herramientas o bases de datos adicionales solo si el almacenamiento nativo en Git/Markdown exhibe limitaciones cuantitativas de escala no resolubles.

---

## 3. Secuencia Propuesta de Maduración

| Hito | Ámbito | Estado | Foco Principal |
| :---: | :--- | :---: | :--- |
| **Sprint 24** | Deliberación en producción | 🟡 En curso | Evaluar el revisor ejecutor vivo en tareas reales (T-137..T-140) y verificar bus de eventos Orca. |
| **Sprint 25** | Paralelo controlado | 📋 Planificado | Concurrencia de workers Orca, gestión de locks y contención de recursos en host. |
| **Sprint 26+** | Dispatcher fino & front-door | 💡 Backlog | Encolado asíncrono, detección de malla privada y despacho remoto hacia worktrees. |
| **Evaluación** | Base de conocimiento soberana | 🔬 Diferido | Auditar necesidades reales frente al modelo nativo de Markdown/Git antes de introducir dependencias. |

---

## 4. Solapamiento con Activos Existentes en Agent OS

| Componente de la Visión | Activo Existente en el Core | Grado de Cobertura Actual | Brecha Restante (Gap) |
| :--- | :--- | :---: | :--- |
| **Dispatcher / Enrutamiento** | `scripts/agent/worktree-dispatch.sh`, `scripts/agent/orca-orchestrate.sh`, `lib/orca-client.sh` | 70% | Falta conector de front-door remoto y cola diferida cuando el nodo está offline. |
| **Workers y Worktrees** | `scripts/agent/worktree-dispatch.sh`, `scripts/agent/worktree-merge.sh` | 85% | Despacho concurrente supervisado (alcance previsto de Sprint 25). |
| **Verificación por máquina** | `scripts/agent/verify-goal.sh`, `tests/validate-control-plane.sh` | 90% | Cableado directo como paso automático previo al human gate. |
| **Compuertas humanas** | Flujo canónico de Fase 3.5 en `AGENTS.md` y `close-task.sh` | 95% | Ya estandarizado y respetado operativamente. |
| **Memoria y Conocimiento** | `.agents/rules/`, `.agents/skills/`, `docs/adrs/`, `docs/architecture/` | 80% | Cobertura suficiente mediante Markdown soberano; RAG o bases vectoriales no justificadas hoy. |

---

## 5. Próximos Pasos (Solo Prospección y Scouting)
- [ ] No alterar el plan activo del Sprint 24 ni saltar fases.
- [ ] Usar `scripts/agent/scout.sh` en fases de research futuras para prospectar protocolos ligeros de mensajería asíncrona hacia colas locales (sin demonios pesados).
- [ ] Mantener esta captura como referencia de diseño estratégico para el planning del Sprint 26+.
