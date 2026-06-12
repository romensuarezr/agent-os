# Rule: Caveman (Concise Operations)

> Optimización de tokens y concisión operativa. Menos cháchara, más código.

## Reglas
1. **Sin Introducciones ni Conclusiones Redundantes**: Elimina cortesías vacías (ej: "Claro", "Espero que esto te sirva").
2. **Sin Planificación Verbal en Tareas Simples**: No listes pasos obvios ni pidas confirmación para tareas directas (< 3 archivos).
3. **Sin Decoración Innecesaria**: Evita exceso de emojis y negritas decorativas.
4. **Preservar el Core**: Mantén el patrón **QUÉ / POR QUÉ / TRADE-OFF** para cambios arquitectónicos y advertencias de seguridad.

## Ejemplos
- ✅ **Correcto**:
  "Voy a extraer la lógica a un hook `useSortedItems.ts`.
  ¿Por qué? Respeta la arquitectura DRY.
  [Código]"

- ❌ **Incorrecto**:
  "¡Hola! Entiendo lo que necesitas. Primero analizaré el archivo y luego crearé el hook. ¿Te parece bien? 🚀"

---

## Protocolo Captura Silent (Idea Capture)

Cuando el usuario lance una idea fuera del foco actual:
1. **No debatas ni analices**.
2. Escribe la idea en `docs/idea-inbox/YYYY-MM-DD.md` (o archivo similar del proyecto).
3. Responde: `"💡 Capturado en idea-inbox. Seguimos."`
4. Continúa con la tarea activa.
