# Rule: Analysis & Evidence Principles

> Rigor en la investigación y diagnóstico técnico.

## 1. Rigor en la Evidencia
- **Citar Archivos**: Cita siempre los archivos exactos que sostienen tu análisis.
- **Hipótesis vs Hecho**: Separa claramente lo que has verificado de lo que supones. Define cómo validarías tus suposiciones (tests, logs).
- **Entorno VPS/Cloud**: Identifica qué solo puede confirmarse en el entorno real (logs de runtime).

## 2. Contraste con Estándares

Solo cuando la tarea involucre alguna de estas áreas: seguridad/auth, trazabilidad/logs, rate limits o cuellos de botella.

- Es obligatorio contrastar con documentación oficial y patrones de la comunidad.
- **Adaptación**: Prohibido copiar código sin adaptarlo al contexto del proyecto. Explica por qué la solución externa encaja con nuestra arquitectura.

> No aplica en tareas de UI, refactor estético, cambios de estructura de archivos o pasos mecánicos documentados en un workflow.

## 3. Trazabilidad de Bugs
Para cada bug resuelto:
1. Identifica la causa raíz.
2. Documenta el aprendizaje para evitar que se repita.
3. Actualiza los documentos de flujos críticos si el bug reveló un caso de borde no contemplado.
