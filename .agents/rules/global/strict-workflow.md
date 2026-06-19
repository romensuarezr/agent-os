# Rule: Strict Workflow (Anti-Regression)

> Prioridad máxima: Control total del usuario y estabilidad de la rama principal.

## ⏸️ PAUSA OBLIGATORIA (Stop & Wait)

Solo en gates reales que requieren decisión del usuario:
- Fin de Fase 3.5 en `/session-start` (aprobación del plan)
- Detección de conflicto o riesgo no contemplado en el plan aprobado
- Cualquier acción fuera de la Caja de archivos autorizada

En estos casos:
1. Resume lo hecho en una línea.
2. Escribe: "**⏸️ ESPERANDO TU CONFIRMACIÓN**".
3. **Deténtate completamente**. No anticipes el siguiente paso.

*Única confirmación válida: Aprobación explícita ("sí", "adelante", "luz verde").*

> Fases de ejecución sin decisión pendiente no requieren pausa. Ver `silent-execution`.

## 🔄 Flujo de Git

1. **Investigación**: Evidencia basada en datos (logs, trazas), no suposiciones.
2. **Planificación (No-Code Plan)**: Crea un `implementation_plan.md` (o resumen) antes de tocar código.
3. **Feature Branches**: Nunca trabajes directamente en `main` o `staging`.
   - `git checkout -b feat/nombre-descriptivo`
4. **Verificación**: Cada cambio debe ser verificado (test/render) antes de dar por cerrada la tarea.

## 🚀 Aprobación de Núcleo (Core Changes)

Prohibido modificar archivos de **Diseño (UI)**, **Lógica de Negocio** o **Arquitectura** sin incluirlos explícitamente en el plan de Fase 3.5 y recibir APROBADO.
