# Rule: Strict Workflow (Anti-Regression)

> Prioridad máxima: Control total del usuario y estabilidad de la rama principal.

## ⏸️ PAUSA OBLIGATORIA (Stop & Wait)

Cada vez que completes una fase o tarea:
1. Resume lo hecho.
2. Escribe: "**⏸️ ESPERANDO TU CONFIRMACIÓN**".
3. **Detente completamente**. No anticipes el siguiente paso.

*Única confirmación válida: Aprobación explícita ("sí", "adelante", "luz verde").*

## 🔄 Flujo de Git

1. **Investigación**: Evidencia basada en datos (logs, trazas), no suposiciones.
2. **Planificación (No-Code Plan)**: Crea un `implementation_plan.md` (o resumen) antes de tocar código.
3. **Feature Branches**: Nunca trabajes directamente en `main` o `staging`.
   - `git checkout -b feat/nombre-descriptivo`
4. **Verificación**: Cada cambio debe ser verificado (test/render) antes de dar por cerrada la tarea.

## 🚀 Aprobación de Núcleo (Core Changes)

Prohibido modificar archivos de **Diseño (UI)**, **Lógica de Negocio** o **Arquitectura** sin explicar detalladamente el **QUÉ** y el **POR QUÉ**.
