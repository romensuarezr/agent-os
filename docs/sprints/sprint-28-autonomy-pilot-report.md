# Informe del Piloto de Autonomía Acotada (Opción D) — Sprint 28

> Documento canónico de arquitectura operativa, arnés de compuertas deterministas y registro de telemetría del piloto de autonomía acotada del Sprint 28.

---

## 1. Resumen Ejecutivo y Marco de Gobernanza

Durante la enmienda de planning del Sprint 28, el relé humano autorizó la adopción formal del **Modelo Opción D** para evaluar la autonomía desatendida del agente en tareas del core, utilizando el mini-sprint de Bane (T-158 a T-161) como banco de pruebas testigo real.

El modelo Opción D establece un avance continuo y desatendido a través de las compuertas internas de ciclo de vida de tarea exclusivamente cuando se cumplen simultáneamente todas las condiciones de un **Camino Limpio**, preservando la trazabilidad completa mediante publicación previa en `origin` para auditoría asíncrona *a posteriori*, y aplicando un principio estricto de **Fail-Closed** ante cualquier anomalía o degradación.

---

## 2. Reglas Vinculantes del Piloto (Contrato Operativo)

Conforme a las directrices de gobernanza selladas por el relé en la aprobación de T-157:

1. **Veredicto Estricto de Camino Limpio**:
   - El camino limpio exige un veredicto **exactamente igual a `CONSENSO`**.
   - Veredictos como `REVISADO_CON_CAMBIOS`, `ESCALADO_A_HUMANO`, `SIN_REVISOR` o `RECHAZADO` **abortan inmediatamente a humano**.
   - Queda estrictamente prohibido auto-aplicar modificaciones del revisor o re-etiquetar veredictos para simular consenso en modo desatendido.
2. **Condición Pre-Merge Inviolable**:
   - Antes de ejecutar cualquier merge a la rama base (`multi-agent`), el agente debe haber completado y publicado en `origin` los siguientes artefactos:
     1. La rama de feature (`feat/T-XXX-...`) con los commits de implementación.
     2. El recibo estructurado de deliberación (`.agents/context/deliberation-T-XXX.json`).
     3. El reporte de implementación en el chat o digest correspondiente.
   - Ningún merge a `multi-agent` puede ocurrir sin que el estado previo esté 100% respaldado en el repositorio remoto para auditoría *a posteriori*.
3. **Estructura y Evaluación del Informe**:
   - En T-157 se establece la arquitectura formal, las reglas de compuerta y el arnés de métricas con el log auditable tarea por tarea.
   - El dictamen de evaluación final sobre la viabilidad de la Opción D queda formalmente **pendiente hasta el cierre de T-161**.
4. **Fase de Transición de Puertas**:
   - La tarea **T-157** misma se ejecuta y cierra bajo el **régimen de puertas interactivas clásicas** (Paso 6 con visto bueno del relé).
   - El régimen de autonomía desatendida rige de forma efectiva a partir de **T-158 hasta T-161** tras el merge de T-157.

---

## 3. Especificación del Camino Limpio (5 Condiciones Concurrentes)

Para que el agente avance de manera autónoma y desatendida, deben satisfacerse de forma concurrente y verificada las 5 condiciones siguientes:

| Condición | Criterio de Aceptación | Método de Verificación |
|---|---|---|
| **1. Veredicto del Revisor** | Exactamente `CONSENSO` (Tier 1 `agy` o Tier 2 `Orca ADE`) | `.agents/context/deliberation-T-XXX.json` (`verdict == "CONSENSO"`) |
| **2. Suite de Control Plane** | 100% de tests en verde (0 errores) | `bash tests/validate-control-plane.sh` (código de salida 0) |
| **3. Confinamiento de Caja** | Cero modificaciones fuera de la lista autorizada en el task file | `git diff --name-only` contrastado contra `caja` de sesión |
| **4. Integridad del Macro** | Cero desviaciones del `## Diseño macro aprobado en planning` | Verificación de interfaces, dependencias y alcance sellado |
| **5. Centinelas de Seguridad** | Cero mutaciones en archivos protegidos o repositorios externos | Centinelas PRE y POST de `deliberate-plan.sh` limpios |

**Acción Autorizada en Camino Limpio**:
Si las 5 condiciones son verdaderas, el agente:
1. Realiza el commit atómico de implementación en su rama `feat/T-XXX-...`.
2. Publica la rama de feature en `origin` (`git push -u origin feat/...`).
3. Ejecuta el merge `--no-ff` hacia `multi-agent`.
4. Publica `multi-agent` en `origin` (`git push origin multi-agent`).
5. Elimina la rama de feature en local y en `origin`.
6. Actualiza el sprint file a `✅ Completada` y ejecuta `scripts/agent/close-task.sh T-XXX`.
7. Publica el commit de cierre en `origin`.
8. Procede al `/session-start` de la siguiente tarea sin requerir intervención humana intermedia.

---

## 4. Compuertas de Aborto Inmediato (Fail-Closed)

Si en cualquier punto del flujo se manifiesta alguna de las siguientes condiciones de anomalía, la ejecución desatendida se suspende de inmediato:

1. **Veredicto Distinto de CONSENSO**:
   - `SIN_REVISOR`: pasarela de inferencia no disponible o timeout agotado.
   - `REVISADO_CON_CAMBIOS`: objeciones técnicas del revisor pendientes.
   - `ESCALADO_A_HUMANO` o `RECHAZADO`: violación de contratos o límites de diseño.
2. **Violación de Caja de Archivos**:
   - Intento o necesidad de modificar cualquier archivo no listado en `## Caja de archivos`.
3. **Desviación del Macro Planning**:
   - Nuevas dependencias, cambio de interfaces de scripts o alteración de especificaciones selladas en planning.
4. **Fallo en Suite o Higiene**:
   - Error en cualquier check de `tests/validate-control-plane.sh` o detección de secretos/locators por `locator-hygiene.sh`.
5. **Disparo de Centinelas**:
   - Detección de modificaciones no autorizadas durante la fase de deliberación técnica.

**Protocolo de Aborto**:
- El agente **detiene toda ejecución autónoma**.
- Queda terminantemente prohibido ejecutar el merge a `multi-agent` o cerrar la tarea.
- El agente presenta el estado detallado en el chat interactivo y transfiere el control al operador humano (Relé).

---

## 5. Puertas Humanas Inmutables

Las siguientes fronteras operativas son exclusivas del operador humano y no forman parte del perímetro de autonomía:

1. **Macro Planning**: Sellado inicial del alcance, dependencias y contratos en sprint planning.
2. **Gestión de Anomalías**: Resolución de abortos, desempate ante objeciones y re-planificación.
3. **Política de SIN_REVISOR**: Las degradaciones a `SIN_REVISOR` jamás se auto-aprueban; requieren siempre autorización humana en el chat.
4. **Promoción a Producción (`main`)**: La integración a `main` y creación de tags semver de release es manual y externa a los sprints.

---

## 6. Arnés de Métricas e Instrumentación

### Métrica Primaria: Tasa de Intervenciones Humanas
- **Línea Base Histórica**: **~3 intervenciones por tarea**:
  1. Aprobación del digest de deliberación (Fase 3.5).
  2. Revisión del reporte de implementación previo al merge (Paso 6).
  3. Autorización y confirmación del cierre de tarea (`close-task.sh`).
- **Objetivo Opción D**: **0 intervenciones por tarea** en camino limpio.

### Métricas de Fiabilidad y Seguridad
- **Falsos Consensos**: Meta 0 (0.0%).
- **Degradaciones Silenciosas Coladas**: Meta 0 (0.0%).
- **Desviaciones del Diseño Macro**: Meta 0 (0.0%).
- **Integridad de la Suite**: 100% verde (37/37 en T-157..T-160; 38/38 tras T-161).

---

## 7. Registro de Telemetría por Tarea Testigo (Batería Bane T-158..T-161)

| Tarea | Veredicto Revisor | Suite Control Plane | Diff en Caja | Publicado Origin Pre-Merge | Intervenciones Humanas | Estado y Trazabilidad |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **T-157** | `CONSENSO` (agy) | 37/37 (0 errores) | Conforme | Conforme | 1 (Puerta clásica de transición) | Marco formalizado |
| **T-158** | `CONSENSO` (agy) | 37/37 (0 errores) | Conforme | Conforme | 0 (Avance autónomo) | Testigo 1 cerrado desatendido |
| **T-159** | *Pendiente* | *Pendiente* | *Pendiente* | *Pendiente* | *Pendiente* | Testigo 2 (Cliente CLI Bane) |
| **T-160** | *Pendiente* | *Pendiente* | *Pendiente* | *Pendiente* | *Pendiente* | Testigo 3 (Workflow Deep Research) |
| **T-161** | *Pendiente* | *Pendiente* | *Pendiente* | *Pendiente* | *Pendiente* | Testigo 4 (Doctor, Gate & Suite 38/38) |

---

## 8. Evaluación y Dictamen Final del Piloto

> ⏳ **ESTADO**: **PENDIENTE DE EVALUACIÓN**  
> El dictamen final de viabilidad, cálculo de reducción efectiva de fricción operativa y recomendación de adopción definitiva para futuros sprints se computará tras el cierre de la tarea testigo **T-161**.
