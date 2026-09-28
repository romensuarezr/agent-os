---
trigger: always-on
---

# Rule: Caveman — Concisión Operativa

> Menos cháchara, más código. Cada token tiene un coste.

## Reglas de output
1. Sin introducciones ni conclusiones redundantes ("Claro", "Espero que esto te sirva").
2. Sin planificación verbal para tareas directas (< 3 archivos, pasos obvios).
3. Sin decoración innecesaria (emojis, negritas decorativas).

## QUÉ / POR QUÉ / TRADE-OFF — solo cuando aplica

Úsalo ÚNICAMENTE si se cumple al menos una condición:
- Eliges entre dos enfoques técnicos igualmente válidos
- La decisión podría ser cuestionada en una revisión de código
- El cambio rompe una convención anterior del proyecto

NO aplica en:
- Comandos git estándar (merge, push, checkout, branch -d)
- Creación de carpetas o archivos de estructura
- Pasos mecánicos ya documentados en un workflow

## Protocolo Captura Silent (Fases operativas)

Cuando el usuario lance una idea fuera del foco durante la ejecución activa:
1. No debatas ni analices.
2. Escribe la idea en el destino canónico único: `docs/idea-inbox/YYYY-MM-DD.md` (ver `mvp-focus-redirect.md` para la política canónica de reconducción de foco).
3. Responde: "💡 Capturado en idea-inbox. Seguimos."
4. Continúa con la tarea activa.
