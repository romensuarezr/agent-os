# Idea: Paquete de Gobernanza de Contexto, Sandboxing, Inferencia Asesora y Estándares Web

- **Fecha:** 2026-11-11
- **Origen:** Propuesta externa depurada y adaptada a la arquitectura real de Agent OS core.
- **Estado:** 💡 REGISTRADA, NO APROBADA
- **Tipo:** Gobernanza de Contexto, Seguridad Defensiva, Inferencia y Estándares de Producto.

---

## 1. Motivación y Diagnóstico (POR QUÉ)

A medida que el ecosistema de Agent OS escala con múltiples agentes, satélites y digests automáticos, surgen 6 vectores de fricción que no están cubiertos por las herramientas actuales:

1. **Confusión entre axiomas del usuario y resúmenes sintéticos**: Los agentes consumen digests de diseño generados por IA (`docs/sprints/design-decisions/`) y los asumen como restricciones humanas inmutables, derivando en sesgo acumulativo. Además, la prosa corporativa inflada (*AI slop*) incrementa el consumo de tokens y reduce la precisión operativa.
2. **Ceguera de tokenomics en skills en memoria**: Todas las skills de `.agents/skills/` se ofrecen o cargan sin métricas estáticas de peso en tokens o líneas, ni detección determinista de skills huérfanas (no vinculadas a perfiles ni workflows).
3. **Sobrecoste en inferencia de código**: La matriz actual en `routing-policy.yaml` asigna modelos comerciales premium para generación mecánica de código, cuando el patrón eficiente consiste en workers económicos/rápidos para codificación y modelos de razonamiento superior como *Asesores* (`advisor`) en deliberación y arquitectura. Las plantillas de FreeLLMAPI carecen de conectores para DeepSeek MoE y Nvidia NIM.
4. **Falta de guardas no-root y auditoría de seguridad defensiva en satélites**: Aunque `agent-permissions.md` establece niveles L1/L2/L3, no existe una regla que verifique que daemons y agentes corran sin privilegios de `root`. Asimismo, se carece de una skill especializada para escanear endpoints, validación de firma en JWT e IDOR en aplicaciones satélite.
5. **Sesgo de complacencia en prospección de ideas (*Sycophancy*)**: Cuando se propone una idea de producto, el LLM tiende a validarla positivamente sin contrastar demanda real, alternativas OSS ni competidores existentes.
6. **Desperdicio en renders multimedia y omisión de datos estructurados para IA**: En satélites web y multimedia se lanzan compilaciones de vídeo/motion sin aprobación de guión previo, y las landings públicas omiten marcado semántico estructurado (Schema.org / JSON-LD) optimizado para motores de IA generativa (GEO).

---

## 2. Alineación con la Arquitectura Real de Agent OS

Para adherirse estrictamente a los principios de Agent OS ($0 tokens, determinismo POSIX y soberanía de datos), la propuesta se ajusta a la realidad técnica del repositorio:

- **Soberanía de Búsqueda**: La prospección objetiva de ideas **NO usa motores de terceros ni dependencias obsoletas** (Bane fue purgado en Sprint 31/32). Debe apoyarse de forma determinista en nuestro nodo soberano **SearXNG** (`scripts/agent/searxng-search.py`) y `scripts/agent/scout.sh`.
- **Modularidad en Auditoría**: La medición del impacto de memoria en skills se integra como flag determinista (`inspect-skills.sh --context` o utility específica) sin sobrecargar `fleet-doctor.sh` (que mantiene el SRP de conectividad viva de red).
- **Higiene de Secretos**: Cero claves en git; cualquier salida pasa por `scripts/agent/lib/redact.sh`.

---

## 3. Propuesta de Tareas Candidatas para Sprint Planning

El siguiente conjunto de 6 componentes atómicos queda registrado para ser evaluado y seleccionado durante el ritual de `sprint-planning.md`:

### Bloque A: Gobernanza de Contexto y Jerarquía de Conocimiento
- **T-A: Jerarquía de Conocimiento y Comunicación Natural**:
  - Creación de `.agents/rules/global/knowledge-hierarchy.md`: separación canónica estricta entre directrices/restricciones inmutables del operador humano y salidas sintéticas/digests de máquina para evitar sesgos derivados.
  - Creación o extensión de regla contra prosa inflada (*AI slop*), imponiendo lenguaje denso, conciso y técnico.
- **T-B: Auditoría Determinista de Tokenomics en Skills (`inspect-skills.sh --context`)**:
  - Analizador determinista en Bash/Python que mida líneas e impacto estimado de tokens de cada `SKILL.md` en `.agents/skills/`.
  - Detección de skills huérfanas (nunca referenciadas en workflows ni perfiles declarativos) con recomendaciones de desactivación.

### Bloque B: Inferencia Asesora y Sandboxing
- **T-C: Política de Enrutamiento (/advisor) y Catálogo FreeLLMAPI**:
  - Formalización del rol y patrón de modelo Asesor (`advisor`) en `.agents/config/routing-policy.yaml`: workers rápidos para codificación intensiva y delegación al modelo top para diseño y arbitraje.
  - Declaración de proveedores DeepSeek MoE y Nvidia NIM en la plantilla `templates/freellmapi/config/freellmapi.config.json`.
- **T-D: Sandboxing No-Root y Auditoría Defensiva de Aplicaciones**:
  - Creación de `.agents/rules/global/agent-sandbox.md`: verificación de que daemons, agentes y contenedores operen con usuarios no privilegiados (no-root).
  - Creación de la skill `.agents/skills/security-audit/SKILL.md`: escáner estático determinista para satélites (autorización de rutas, firma obligatoria en tokens JWT y comprobación de permisos).

### Bloque C: Validación Objetiva y Estándares Web
- **T-E: Skill de Validación de Viabilidad Objetiva (`idea-validator`)**:
  - Creación de `.agents/skills/idea-validator/SKILL.md`: filtro de viabilidad previo para ideas en `docs/idea-inbox/`.
  - Consulta determinista de competidores, demanda y alternativas usando SearXNG (`scripts/agent/searxng-search.py`) y `scout.sh`, emitiendo un veredicto numérico (1–10) para neutralizar el sesgo de complacencia antes de abrir un sprint.
- **T-F: Compuerta Storyboard Decision Gate y Marcado Estructurado GEO (JSON-LD)**:
  - Creación de plantilla de compuerta `templates/workflows/media-storyboard-gate.md`: guión estático previo de 5-6 fotogramas obligatorio antes de autorizar renders pesados de vídeo.
  - Creación de regla `.agents/rules/global/web-structured-data.md`: marcado semántico obligatorio `Schema.org` / `JSON-LD` y estructura de conversión para proyectos satélite web.

---

## 4. Criterios de Aceptación Preliminares

- [ ] Las propuestas no introducen servicios comerciales ni dependencias de pago ($0 tokens de suscripción).
- [ ] Todo script CLI nuevo o modificado incluye `--help`, códigos de salida POSIX estándar y soporte `--json`.
- [ ] La suite `tests/validate-control-plane.sh` permanece en 38/38 checks verdes (o amplía el denominador limpiamente si se agregan scripts a los checks).
- [ ] Ninguna regla o skill asume un stack tecnológico único, respetando la portabilidad agnóstica de Agent OS.
