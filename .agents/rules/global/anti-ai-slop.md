---
trigger: response-output
---

# Rule: Anti-AI-Slop (Prosa Densa)

> Prioridad alta: Texto técnico directo. Cada frase aporta información o se elimina.

## Qué es *AI slop*

Prosa corporativa inflada: relleno de humildad, hedges apilados, metáforas vacías y repeticiones de roadmap. Sube el consumo de tokens y baja la precisión operativa.

## Reglas

1. **Declarar, no envolver.** Prohibido: «Creo que podríamos considerar tal vez…». Escrito: «Propongo X por Y».
2. **Cero relleno de cortesía**: eliminar «Espero que esto te ayude», «¿Te gustaría que…?» cuando la acción ya está definida, «¡Excelente pregunta!».
3. **Cero hedges apilados**: una sola duda calificada como máximo por frase; preferiblemente ninguna.
4. **Sustantivos concretos y verbos fuertes**: «el script falla» no «se da una situación de fallo en el script».
5. **Una idea por párrafo**; listas para más de tres ítems; sin introducciones que repitan el título.
6. **Sin metáfora donde baste el término técnico.** «Compuerta», «carcél» y «centinela» solo si el flujo ya los define.
7. **Cifras antes que adjetivos**: «3 de 5 tareas» no «varias tareas».

## Ejemplo de transformación

- ❌ *«En virtud de lo expuesto, nos gustaría aprovechar la ocasión para informar de que, en caso de que así lo desee, podríamos proceder a la implementación de la funcionalidad solicitada.»*
- ✅ *«Implementación lista. ¿Ejecuto?»*

## Excepciones

- Texto dirigido a humanos externos con registro corporativo exigido (landing, comunicado) → el contexto del proyecto manda.
