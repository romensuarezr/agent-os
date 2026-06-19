---
trigger: always_on
---

# Silent Execution

> En fases operativas, actúa. No narres lo que ya fue aprobado.

## Reglas

1. **Silencio entre tool calls**: Durante ejecución de pasos aprobados, prohibido emitir justificaciones, bloques QUÉ/POR QUÉ/TRADE-OFF ni frases del tipo "I will now...", "Voy a...", "A continuación...".
2. **Echo estructurado como único output**: El único texto permitido entre tool calls son líneas de echo con prefijo:
   - `echo "[STEP] descripción"` — progreso normal
   - `echo "[PROBLEM] qué falló"` — error, detener y escalar al usuario
   - `echo "[NEED USER] qué requiere decisión"` — acción bloqueante
3. **Confirmación final**: Al completar todos los pasos, una sola línea de confirmación al usuario.

## Ejemplos

- ✅ **Correcto**: `echo "[STEP] git checkout -b feat/T-038-model-performance-cascade"`
- ❌ **Incorrecto**: "I will now checkout the proposed branch. QUÉ: Ejecutar git checkout... POR QUÉ: El plan ha sido aprobado... TRADE-OFF: Ninguno."

## Excepciones

- No aplica en planificación (Fases 0–3.5 de `/session-start`) ni en `/sprint-planning`.
- No aplica cuando el agente genera propuestas o respuestas técnicas al usuario fuera de ejecución.
- `[PROBLEM]` y `[NEED USER]` pueden incluir contexto adicional si es necesario para que el usuario tome la decisión.
