# Sprint 30 — Validación de Ejecución Autónoma sobre Trabajo Real: Nango OAuth, Remediación Homepage y Motor de Búsqueda Soberano

> **Período**: 2026-11-03 → 2026-11-19  
> **Enfoque**: Validación empírica de la autonomía desatendida sobre casos de uso reales de infraestructura de la flota antes de la promoción a `main`: plantilla Compose soberana y despliegue en vivo de Nango OAuth en VPS (T-166), remediación de compatibilidad en `generate-homepage-config.sh` (T-167), arreglo en vivo de Homepage con ping granular y descubrimiento portable multi-repo (T-168), validación e integración del motor de búsqueda profunda soberano (T-169), primera integración funcional de Nango en flujos operativos (T-170) y re-ensayo de Vane con investigación real (T-171).

---

## Estado
🟡 En curso

---

## Tareas

| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :---: | :--: | :--- | :--- |
| T-166 | Plantilla de despliegue soberano de Nango en VPS, despliegue en vivo y runbook | Core / Infraestructura & Auth | M | ✅ Completada | — | [.agents/tasks/_archived/task-166.md](.agents/tasks/_archived/task-166.md) |
| T-167 | Remediación determinista de compatibilidad en `generate-homepage-config.sh` y Homepage Dashboard | Core / Tooling & Observabilidad | M | ✅ Completada | T-166 | [.agents/tasks/_archived/task-167.md](.agents/tasks/_archived/task-167.md) |
| T-168 | Arreglo en vivo de Homepage, ping granular y descubrimiento portable multi-repo | Core / Observabilidad & DX | S | ✅ Completada | T-167 | [.agents/tasks/_archived/task-168.md](.agents/tasks/_archived/task-168.md) |
| T-169 | Validación de motor de búsqueda profunda (ensayo Vane en vivo, reactivación de SearXNG e integración de backend) | Core / Motores & Búsqueda | M | ✅ Completada | T-168 | [.agents/tasks/_archived/task-169.md](.agents/tasks/_archived/task-169.md) |
| T-170 | Primera integración real de Nango en flujo operativo de agente | Core / Auth & Integraciones | M | ✅ Completada | T-169 | [.agents/tasks/_archived/task-170.md](.agents/tasks/_archived/task-170.md) |
| T-171 | Re-ensayo de Vane (`itzcrazykns1337/vane:latest`), investigación real y posible integración soberana | Core / Motores & Búsqueda | M | ⏳ Pendiente | T-170 | [.agents/tasks/task-171.md](.agents/tasks/task-171.md) |
| T-165 | Despliegue en vivo y validación operativa de Bane en la flota | Core / Infraestructura & Ops | M | ⏸ Pausada | — | [.agents/tasks/task-165.md](.agents/tasks/task-165.md) |

---

## Disposición Explícita de Candidatas de Planning

### Candidatas Fuera de Alcance en Sprint 30 (con Motivo)
1. **Promoción a `main` de v1.15 a v1.25 y tags de release**:
   - **Motivo**: Excluido explícitamente. Se realiza tras validar empíricamente la ejecución autónoma desatendida en este sprint de trabajo real.
2. **Rotación de las 15 credenciales revocadas en bóveda**:
   - **Motivo**: Bloqueado hasta decisión del usuario sobre alcance por zona de `CLOUDFLARE_API_TOKEN`.
3. **ByteBox CLI Curator**:
   - **Motivo**: Backlog técnico posterior; no entra a sprint sin consolidar la infraestructura de auth (Nango) y observabilidad (Homepage).
4. **Sincronización masiva de satélites (`sync.sh`)**:
   - **Motivo**: Pospuesto a la siguiente ventana de releases tras la promoción a `main`.

---

## Notas de planning

### 1. Régimen Operativo Estándar: Opción D (Autonomía Acotada)
Aprobado por el usuario y formalizado en los workflows canónicos (`session-start.md`, `sprint-planning.md`, `AGENTS.md`) en T-164:
- **Nivel Macro**: Esta sección, complementada por la enmienda vinculante aprobada por el Relé, constituye la **única autorización habilitante** para la autonomía desatendida en cada tarea.
- **Nivel Micro (Camino Limpio)**: Si `deliberate-plan.sh` emite veredicto estrictamente `CONSENSO`, la suite de control plane se mantiene en verde, los cambios están dentro de la caja autorizada, no hay desvíos frente al macro y los centinelas están intactos, el agente avanza de forma 100% desatendida hasta el merge y cierre inclusive.
- **Compuertas de Aborto Fail-Closed**: Ante cualquier veredicto != `CONSENSO`, fallo en suite, archivo fuera de caja o mutación centinela, el agente detiene de inmediato el avance y escala al operador en el chat presentando el Executive Design Digest.
- **Protocolo Pre-Merge Refinado**: Publicación previa en `origin` de la rama de feat y el informe/notas acreditando el recibo de deliberación, captura atómica del digest y raw json en el commit de cierre con `close-task.sh`.

### 2. Cumplimiento de Compuerta Scout-First (T-129)
Las 3 tareas cuentan con su respectiva prospección determinista registrada en [docs/sprints/sprint-30-research.md](sprint-30-research.md), garantizando 0 dependencias runtime ajenas, coste $0 en prospección y justificación técnica para cada decisión de adopción vs. desarrollo a medida.

### 3. Enmienda de Planning Vinculante (Aprobada por el Relé — 2026-11-03)
1. **T-166 Despliegue vivo obligatorio**:
   - Se incorpora como criterio de done el despliegue en vivo de su propia plantilla en el VPS y la comprobación de que el health check real responde, con evidencia en el reporte y sin secretos en el repo.
   - Si el despliegue vivo resulta inviable, el sistema aborta de inmediato a humano (fail-closed); queda prohibido cerrar con solo la plantilla.
   - La composición Compose se valida contra la especificación oficial de Nango self-hosted antes de sellarla (no se asume ciegamente que server + postgres basten, y el puerto no queda rígidamente fijado en 4004 si el spec oficial define otro; la versión del CLI npm no determina la imagen Docker).
2. **T-167 Remediación viva obligatoria y dependencias**:
   - Dependencia estricta de T-166: la tarjeta de Nango en Homepage utiliza el puerto y esquema efectivamente verificados en T-166.
   - Se incorpora como criterio de done: regenerar la configuración mediante el generador ya tolerante y redesplegar en la instancia viva de Coolify, verificando tarjeta por tarjeta desde el contenedor y con pase visual final.
   - Corrección estrictamente por generador y redespliegue, nunca editando a mano el volumen Docker.
   - Proxy de Docker y Glances se resuelven según la realidad viva (Glances solo se reactiva si responde; si no, queda documentado).
   - Tolerancia a esquema abreviado como fallback transparente (el estándar es el preferido); fixtures de tests deben cubrir casos estándar, abreviado y mixto.
   - Plantilla saneada: cero URLs inventadas, placeholders reconocibles por el filtro de omisión, Orca configurable u omitida (no localhost rígido), y Ollama reflejando la realidad viva verificada.
3. **T-165 Precisiones operativas y pausa**:
   - El endpoint vivo se registra exclusivamente en el overlay privado (`fleet.yaml`), nunca en `fleet.example.yaml` commiteado (este solo admite placeholders o esquema).
   - Aborto fail-closed registrado por inexistencia de la imagen declarada `ghcr.io/pythops/bane:latest`. Estado: `⏸ Pausada` pendiente de redefinición humana.
4. **Denominador de Suite Inmutable**:
   - Las validaciones añadidas para T-166 y T-167 se integran como subchecks dentro de Checks existentes (Check 11 para Homepage, Check 38 o Check 1 para Nango), manteniendo el denominador de la suite rígidamente en **38/38** (0 errores).
5. **Honestidad de Actas**:
   - Las actas reflejan que las propuestas del scout son recomendaciones técnicas del agente ratificadas por el Relé en esta enmienda de planning.

### 4. Enmienda de Reordenación de Secuencia (Decisión Macro Humana — 2026-11-03)
- **Nuevo Orden**: `T-166 → T-167 → T-165` (sustituye formalmente la secuencia previa `T-165 → T-166 → T-167`).
- **T-166**: Arranca como primera tarea del sprint bajo Opción D, sin dependencia de T-165 (`Dependencias: —`).
- **T-167**: Mantiene su dependencia estricta de T-166 (la tarjeta de Nango en Homepage requiere el puerto y esquema efectivamente verificados en vivo en T-166).
- **T-165**: Queda en estado `⏸ Pausada` (causa: imagen Docker `ghcr.io/pythops/bane:latest` inexistente en registro, aborto fail-closed). Queda **FUERA del encadenado desatendido**: su arranque futuro exige una nueva decisión humana sobre el motor de búsqueda y no arrancará automáticamente tras T-167.
- **Contexto registrado**: Activación de SearXNG aprobada por el humano como backend del motor a redefinir; no constituye compuerta para T-166/T-167 ni trabajo suelto de esta enmienda.
- **Resto del Macro**: Denominador inmutable en **38/38**, despliegue vivo en T-166, remediación viva en T-167, sin tocar `main`, sin tags de release.

### 5. Enmienda de Alcance y Nuevas Tareas T-168 a T-170 (Decisión Macro Humana — 2026-11-04)
- **Nuevo Orden y Encadenado**: `T-168 → T-169 → T-170` bajo régimen estándar de Opción D. Cada tarea es estrictamente dependiente de la anterior para la continuidad de la cadena autónoma.
- **T-165**: Permanece en estado `⏸ Pausada` fuera del encadenado desatendido, no se reabre directamente. Su propósito de proveer un motor de búsqueda profunda soberano se retoma formalmente en T-169 con un nuevo identificador (sucesor, no renombre).
- **Ampliación de Período**: Período del sprint extendido hasta el **2026-11-12**.
- **Denominador de Suite**: Rígidamente inmutable en **38/38** (0 errores). Las validaciones nuevas se incorporan como subchecks dentro de checks preexistentes.
- **Compuertas y Límites**: Cero interacción con `main`, cero creación de git tags.
- **T-168 (Tamaño S)**: Arreglo vivo de Homepage y descubrimiento portable multi-repo. Soporte de ping granular por servicio (permitiendo `/` para OmniRoute sin ruta de `/health`). Eliminación definitiva de la integración Docker (`docker.yaml`) erradicando los errores 403 Forbidden y `ECONNREFUSED` hacia el socket proxy (`SERVICES: '0'`). El descubrimiento se consolida a través del overlay privado (`fleet.yaml`), permitiendo usar el mismo generador y plantillas en repositorios satélite sin persistir datos privados en git. Triage de tarjetas faltantes (restaurar solo endpoints reales alcanzables; documentar Open-WebUI y Hermes; verificar estado real de Ollama en su nodo). Glances en el VPS secundario integrado si responde o documentado si no. Backup fechado (`.bak.<timestamp>`) obligatorio previo a sobrescribir volumen en vivo. **Compuerta de cierre estricta: pase visual del usuario en navegador**.
- **T-169 (Tamaño M)**: Motor de búsqueda soberano, sucesor de T-165. Ensayo previo de Vane en vivo con verificación obligatoria de pull de imagen pública; si la imagen no existe o el ensayo no genera un informe útil, aborto inmediato fail-closed a humano (prohibido cerrar con plantilla). Reactivación e integración de la instancia preexistente de SearXNG en la flota, validando consulta real y conectándola como backend de búsqueda profunda sin duplicar instancias. Sustitución de artefactos fantasma de Bane (cliente CLI, workflow deep-research, checks y runbook). Cierre condicionado a búsqueda real ejecutada por la ruta autónoma.
- **T-170 (Tamaño M)**: Primera integración real de Nango en flujo operativo. Apertura obligatoria con propuesta técnica formal al operador (analizando Cloudflare, Infisical u otros, flujo desbloqueado y credenciales/OAuth afectados). **Compuerta fail-closed: sin aprobación humana expresa de la propuesta en el chat, queda terminantemente prohibido conectar nada**. Tras aprobación, conexión en Nango vivo y adaptación/construcción de flujo de agente operativo con evidencia verificable.

### 6. Enmienda de Planificación: Re-ensayo de Vane en vivo (T-171) (Decisión Macro Humana — 2026-11-07)
- **Tarea NUEVA**: T-171 arranca encadenada tras T-170 bajo Opción D. No reabre T-169 ni reescribe T-165.
- **T-165**: Permanece en estado `⏸ Pausada`; su cierre como descartada queda formalmente para cuando el motor de búsqueda profunda quede definitivamente decidido en la flota, no ahora.
- **Imagen Exacta**: `itzcrazykns1337/vane:latest` antes de sondear nada; queda terminantemente prohibido utilizar `pythops/vane` o la variante `slim`.
- **Gate 0 Determinista**: `docker pull itzcrazykns1337/vane:latest` debe ejecutarse y terminar exitosamente antes de desplegar nada; si falla, aborto inmediato a humano (fail-closed), sin cierre de plantilla.
- **Ensayo en Vivo**: Desplegar la imagen y ejecutar una investigación profunda real a través de la ruta autónoma.
- **Compuerta de Cierre / Informe Útil**: El cierre exige estrictamente un informe útil y estructurado, no una mera respuesta sintética con citas; si no se obtiene un informe útil, aborto inmediato a humano (fail-closed), sin forzar la integración.
- **Integración Condicionada de SearXNG**: Solo si el ensayo lo justifica de forma explícita, integrar la instancia de SearXNG preexistente sin usar; prohibido desplegar un segundo SearXNG.
- **Ampliación de Período**: Período del Sprint 30 extendido hasta el **2026-11-19**.
- **Denominador de Suite Inmutable**: Denominador de la suite de control plane rígidamente inmutable en **38/38** (0 errores) salvo Check nuevo formalmente declarado.
- **Compuertas Globales**: Sin interacción con `main`, sin creación de tags de git.
