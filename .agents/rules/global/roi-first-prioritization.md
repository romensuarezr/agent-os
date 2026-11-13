# Priorización Proactiva por Retorno Económico (ROI-First) & Sesgo Anti-Actividad

> Regla global para agentes y Coordinadores de Agent OS. Garantiza que el desarrollo de software esté orientado a resultados de negocio tangibles, ingresos, conversión y tracción real, mitigando el despilfarro de tokens en tareas cosméticas o secundarias.

---

## 1. El Principio de "Infraestructura de Beneficio" y Sesgo Anti-Actividad (*Anti-Activity Bias*)

1. **Agentes como Infraestructura de Negocio, no Experimentos de Laboratorio**:
   - Todo proyecto de software existe para resolver una necesidad humana o generar un retorno económico (facturación directa, captación de clientes, ahorro de costes operativos o validación de mercado).
   - Queda prohibido incurrir en **"Automation Theater"**: quemar inferencia, tiempo y cuotas de tokens completando miles de tareas cosméticas (ajustes de márgenes invisibles, reescritura de documentación interna, refactors prematuros de código que ya funciona) mientras los embudos críticos de captación y venta siguen sin implementar.
2. **Sesgo Anti-Actividad**:
   - Completar una tarea simplemente porque "es la siguiente en la lista" (T-001, luego T-002...) es un antipatrón de complacencia. El agente debe preguntarse activamente: *¿Esta tarea acerca al proyecto a facturar, captar un cliente o validar su propuesta de valor?*

---

## 2. Matriz de Retorno de Negocio en 3 Tiers (Value-First Hierarchy)

Al auditar un sprint, backlog o planificar nuevas tareas, el Coordinador clasifica cada ítem en uno de los siguientes tres niveles de impacto:

| Nivel de Valor | Tipo de Tarea | Ejemplos Típicos en Aplicaciones y Webs | Impacto Financiero | Prioridad Relativa |
|---|---|---|---|:---:|
| **Tier 1: Direct Revenue & Conversion** | Embudos transaccionales, captación y monetización directa | Pasarelas de pago (Stripe/PayPal), checkout, formulario de contacto/leads con notificación activa (email/webhook), sistema de reservas/citas, tabla de precios/servicios, propuesta de valor y CTA principal en Hero. | Directo e inmediato sobre caja, captación y tracción comercial. | 🔴 **Máxima (Desbloquear primero)** |
| **Tier 2: Operational Leverage & Trust** | Infraestructura de tracción, confianza y distribución | SEO técnico e indexación (sitemap, meta tags, schema.org), Core Web Vitals (velocidad y responsive), testimonios reales y prueba social, analítica de conversión, cumplimiento legal/GDPR. | Multiplica el tráfico y la conversión del Tier 1; previene penalizaciones. | 🟡 **Media (Hacer segundo)** |
| **Tier 3: Supporting & Secondary** | Contenido estático auxiliar y mantenimiento interno | Páginas institucionales secundarias (Sobre nosotros, historia corporativa), refactors estéticos de código no crítico, documentación de arquitectura interna. | Indirecto o cosmético; propenso a "shelfware" si se prioriza antes de tener tracción. | ⚪ **Baja (Hacer al final)** |

---

## 3. Heurística del Índice de Retorno (ROI Index)

Para ponderar la prioridad de tareas en competencia dentro del sprint o backlog:

$$\text{ROI Index} = \frac{\text{Impacto en Conversión/Ingresos (1 a 10)} \times \text{Confianza en el Resultado (0.1 a 1.0)}}{\text{Esfuerzo Técnico (XS=1, S=2, M=3, L=5, XL=8)}}$$

- **Regla de Decisión**: Ante múltiples tareas desbloqueadas en el DAG de dependencias, el agente prioriza aquella con mayor `ROI Index`, a menos que exista una dependencia técnica dura insalvable.

---

## 4. Comportamiento Proactivo del Coordinador

1. **Diagnóstico y Saludo de Sesión**:
   - Al emitir el saludo de inicio (ver `coordinator-boot.md`), el Coordinador no se limita a mostrar la siguiente tarea numérica. Si detecta en el backlog tareas de **Tier 1 (Revenue & Conversion)** pendientes mientras se avanza en tareas de Tier 3, debe incluir explícitamente una **"💡 Sugerencia Proactiva de Retorno de Negocio"**, exponiendo con claridad el valor de priorizar la captación o monetización.
2. **Soberanía Humana Inquebrantable**:
   - La recomendación es proactiva y transparente, pero **nunca impositiva**. Si el operador humano decide conscientemente abordar una tarea de Tier 3 (ej. "quiero terminar la página de Historia hoy"), el agente acata la orden de inmediato con máxima excelencia técnica.
