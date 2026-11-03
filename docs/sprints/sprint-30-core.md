# Sprint 30 — Validación de Ejecución Autónoma sobre Trabajo Real: Bane en Vivo, Nango OAuth y Remediación Homepage

> **Período**: 2026-11-03 → 2026-11-07  
> **Enfoque**: Validación empírica de la autonomía desatendida sobre casos de uso reales de infraestructura de la flota antes de la promoción a `main`: puesta en producción viva de Bane en el nodo de inferencia (T-165), plantilla Compose soberana y runbook de integración de Nango OAuth en VPS (T-166), y remediación determinista de compatibilidad en `generate-homepage-config.sh` junto con saneamiento de plantillas de Homepage Dashboard (T-167).

---

## Estado
🟡 En curso

---

## Tareas

| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :--- | :---: | :--: | :--- | :--- |
| T-166 | Plantilla de despliegue soberano de Nango en VPS, despliegue en vivo y runbook | Core / Infraestructura & Auth | M | ✅ Completada | — | [.agents/tasks/task-166.md](.agents/tasks/_archived/task-166.md) |
| T-167 | Remediación determinista de compatibilidad en `generate-homepage-config.sh` y Homepage Dashboard | Core / Tooling & Observabilidad | M | ✅ Completada | T-166 | [.agents/tasks/task-167.md](.agents/tasks/_archived/task-167.md) |
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
