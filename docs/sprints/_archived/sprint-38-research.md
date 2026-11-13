# Sprint 38 Research — Descubrimiento Dinámico de Capacidades, Priorización Proactiva por ROI Económico y Sincronización a Satélites

## 1. Estado y Metodología de la Investigación
- **Fecha**: 2026-11-13
- **Fuentes consultadas**:
  - Prospección OSS y herramientas: `scout.sh`, `@oh-my-pi/pi-catalog`, `@agentclientprotocol/claude-agent-acp`.
  - Investigaciones de la industria sobre ROI en agentes: Samuel J. Woods (*Profit Infrastructure vs Demo Trap*), Mastra AI (*Bounded Blast Radius Workflows*), Enterprise AI Agent ROI benchmarks (Automation Anywhere, Elastic, Snowflake).
  - Patrones de priorización en ingeniería de producto: RICE (Reach, Impact, Confidence, Effort), WSJF (Weighted Shortest Job First / Cost of Delay) y Value-Driven Development.
  - Entorno de ejecución en vivo: Inspección de capacidades activas de Antigravity (`swarm action: models`) y satélites reales de la flota (`annascheer-web`).

---

## 2. Hallazgos Clave de la Comunidad e Industria

### A. El Problema del "Automation Theater" y el Sesgo Anti-Actividad (*Anti-Activity Bias*)
- **El Síntoma**: Los agentes de IA tienden a ejecutar miles de acciones de bajo impacto que consumen tokens y tiempo (ajustar paddings mínimos, reescribir documentación interna, refactors cosméticos de código que ya funciona) sin mover métricas de negocio.
- **La Causa**: Por defecto, los modelos son evaluados por "completar la instrucción dada" o "seguir el orden numérico secuencial" (T-001, luego T-002, luego T-003), sin tener un modelo mental del impacto económico de lo que están programando.
- **La Solución en la Industria**: Incorporar en las directivas del agente coordinador un **sesgo anti-actividad** (*Anti-Activity Bias*). Todo esfuerzo técnico debe justificar su línea de visión hacia un resultado de negocio tangible (ingresos, conversión, captación de leads, retención o reducción de costes reales).

### B. Matriz de Priorización "Value-First" (BV/E: Business Value vs Effort)
La comunidad de agentes autónomos clasifica los backlogs de producto en tres niveles de retorno:

| Nivel de Valor | Tipo de Tarea | Ejemplos en Satélites Web/App | Impacto en Negocio | Prioridad de Ejecución |
|---|---|---|---|:---:|
| **Tier 1: Direct Revenue & Conversion** | Embudos de venta, captación y monetización directa | Pasarela de pago (Stripe/PayPal), formulario de contacto/leads con notificación activa, reservas/calendario, tabla de precios, CTA principal del Hero. | Directo e inmediato sobre el P&L y facturación. | 🔴 **Máxima (Hacer primero)** |
| **Tier 2: Operational Leverage & Trust** | Infraestructura de confianza, descubrimiento y retención | SEO técnico e indexación, Core Web Vitals (velocidad de carga), analítica de eventos, testimonios y prueba social, cumplimiento legal/GDPR. | Multiplica la efectividad del Tier 1 y evita penalizaciones. | 🟡 **Media (Hacer segundo)** |
| **Tier 3: Supporting & Internal** | Contenido estático auxiliar y mantenimiento interno | Páginas institucionales secundarias (Sobre nosotros, historia), refactors no bloqueantes, documentación de arquitectura interna. | Indirecto o cosmético; propenso a convertirse en "shelfware" si se prioriza antes de validar tracción. | ⚪ **Baja (Hacer al final)** |

### C. Fórmulas de Decisión para el Coordinador
En lugar de una selección arbitraria, el Coordinador calcula mentalmente el **Índice de Retorno (ROI Index)**:
$$\text{ROI Index} = \frac{\text{Impacto en Conversión/Ingresos (1 a 10)} \times \text{Confianza (0.1 a 1.0)}}{\text{Esfuerzo Estimado (Talla XS=1, S=2, M=3, L=5, XL=8)}}$$

Si una tarea de captación de clientes (T-010 Contacto) tiene Impacto 9 y Esfuerzo M (3), su ratio es $3.0$; si una página institucional secundaria (T-006) tiene Impacto 2 y Esfuerzo M (3), su ratio es $0.66$. El Coordinador proactivamente recomendará adelantar la tarea de mayor tracción.

### D. Descubrimiento Dinámico de Modelos y Cuotas (Tokens $0)
- En lugar de nombres comerciales fijos (`flash_lite` o listas estáticas), los agentes modernos descubren en tiempo de ejecución los modelos disponibles y su nivel de esfuerzo (`low`, `medium`, `high`, `thinking`), reservando las cuotas más caras y lentas para diseño arquitectónico y seguridad.

---

## 3. Descubrimientos Scout y Veredicto de Solución Existente vs Desarrollo a Medida

| Tarea | Búsqueda Scout / Referencias | Solución Existente | Veredicto en Agent OS |
|---|---|---|---|
| **T-205** (Modelos dinámicos & cuotas) | `@oh-my-pi/pi-catalog`, `@agentclientprotocol/claude-agent-acp`, Antigravity swarm | Los arneses exponen APIs dinámicas, pero no matrices de gobernanza contextual. | **Desarrollo a medida integrado** en perfiles nativos (`coordinator.md`, `coordinator-boot.md`, `orchestrator`). |
| **T-206** (Telemetría de modelos en CLI) | `orchestration-report.sh`, scripts de telemetría deterministas | No existe herramienta CLI externa estándar para telemetría a $0 tokens acoplada a Agent OS. | **Desarrollo a medida integrado** extendiendo `orchestration-report.sh`. |
| **T-207** (Priorización Proactiva por ROI Económico) | Frameworks Value-First, RICE/WSJF, Anti-Activity Prompts | Existen prompts teóricos aislados, pero ninguna regla de gobernanza integrada en frameworks multi-agente open-source. | **Desarrollo a medida integrado**: Regla global `.agents/rules/global/roi-first-prioritization.md` e integración en el boot del Coordinador (`coordinator-boot.md`). |
| **T-208** (Promoción a main y sincronización a satélites) | `promote-to-main.sh`, `sync.sh --force --cleanup --commit`, `audit-satellites.sh` | El core de Agent OS ya cuenta con herramientas deterministas de release y sincronización. | **Aprovechar utilidades existentes**: Ejecución formal del Decision Gate `/promote`, corte de tag `v1.34.0`, propagación universal a satélites y auditoría de integridad. |

---

## 4. Diseño de la Regla de Priorización ROI-First (T-207)
1. **Regla de Gobernanza**: Crear `.agents/rules/global/roi-first-prioritization.md` instruyendo:
   - Análisis de valor de negocio previo a cualquier sugerencia o planificación.
   - Clasificación explícita de tareas en los 3 Tiers (Tier 1: Revenue/Conversion, Tier 2: Distribution/Trust, Tier 3: Supporting).
   - Inyección en el saludo del Coordinador (`coordinator-boot.md`): presentar la "💡 Sugerencia Proactiva de Retorno de Negocio", argumentando el motivo económico si una tarea de alto impacto comercial está pendiente.
2. **Impacto en Satélites Reales**: En proyectos como `annascheer-web`, ante tareas pendientes como *T-007 Blog*, *T-008 Servicios/Reservas*, *T-009 Blog Detalle* y *T-010 Contacto*, el Coordinador identificará que *T-010 Contacto* y *T-008 Servicios* son Tier 1 (captación directa de clientes y reservas), sugiriendo priorizarlas o paralelizar hacia ellas para habilitar facturación cuanto antes.
