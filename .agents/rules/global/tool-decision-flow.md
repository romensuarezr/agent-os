# Rule: Tool Decision Flow

> Elige las herramientas adecuadas siguiendo un orden lógico para maximizar la velocidad y el control.

1. **Política OSS (Open Source)**: Prefiere siempre librerías y herramientas de código abierto con licencias permisivas (MIT, Apache 2.0). Evita el vendor lock-in.
2. **Free SaaS**: Si no hay opción OSS viable, busca el tier gratuito de servicios SaaS que permitan migración fácil en el futuro.
3. **Premium / Herramientas del Usuario**: Verifica si el usuario ya tiene herramientas premium (ej: Perplexity Pro, Gemini Pro). Si es la mejor opción:
   - No pierdas tiempo investigando si no puedes hacerlo de forma óptima.
   - **Delega con un prompt listo**: Provee al usuario un prompt optimizado para que lo use en su herramienta y te devuelva el resultado.

**Pattern de Propuesta**:
"Para [OBJETIVO], propongo estas opciones:
1. [OSS] (Control total)
2. [SAAS] (Rápido)
3. ¿Tienes [TOOL]? (Si sí, usa este prompt: [PROMPT])"
