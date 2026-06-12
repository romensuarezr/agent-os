---
name: architecture-audit
description: Realiza auditorías técnicas del código del proyecto para detectar violaciones de arquitectura, dependencias incorrectas, duplicidades y componentes fuera de su capa. Actívala antes de un refactor o cuando un archivo supere las 300 líneas.
---

# Skill: Architecture Audit (Experto en Limpieza)

Realiza auditorías técnicas profundas para asegurar que el código sigue los estándares de arquitectura del proyecto.

## Cuándo usar
- Antes de empezar un refactor.
- Cuando una página o archivo de lógica crece demasiado (> 300 líneas).
- Para verificar el cumplimiento de las reglas DRY y de capas del proyecto.

## Proceso de Auditoría
1. **Identificar la Arquitectura del Proyecto**: Lee el archivo `.agents/AGENT_ONBOARDING.md` o las directivas de arquitectura del proyecto para comprender el stack, la división de capas y el diseño de software.
2. **Mapeo de Dependencias**: Analizar los imports y llamadas de función para identificar violaciones de límites de capas (ej: llamadas directas a base de datos/servicios en la capa de presentación de la UI).
3. **Análisis de Lógica y Estado**: Buscar lógicas de negocio pesadas o de estado acopladas en archivos de la vista que deberían delegarse a controladores, hooks o servicios de negocio.
4. **Detección de Duplicidad**: Encontrar patrones de código repetitivos (ej: try/catch duplicados, queries repetidas, etc.) que infrinjan el principio DRY.
5. **Validación de Componentes y Diseño**: Verificar que se utilicen los componentes de UI compartidos y los design tokens globales del proyecto en lugar de crear estilos o elementos ad-hoc.

## Output del Skill
El resultado debe ser un reporte detallado que incluya:
- Tabla de violaciones por archivo.
- Gravedad del incumplimiento.
- Plan de acción sugerido con pasos atómicos y priorizados.

## Comando de Activación
- `/audit` o "Haz una auditoría de arquitectura de [componente/directorio]".
