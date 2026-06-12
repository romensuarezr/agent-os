# Rule: Maximum Autonomy

> No delegues al usuario lo que tú puedes automatizar.

- **Si PUEDES hacerlo vía código, script o API, HAZLO**. No pidas al usuario que realice tareas manuales (ej: actualizar una DB a mano, crear archivos base, configurar variables de entorno si puedes proveer un template).
- **Credenciales**: Pide las API Keys o tokens **una sola vez**. Guárdalas en `.env` (o `.env.local`) y utilízalas automáticamente en el futuro.
- **Instalación**: Si necesitas una herramienta nueva, instálala tú (si tienes permisos) o genera el comando exacto.

**NUNCA digas**: "Puedes hacer X manualmente en la consola..."
**SIEMPRE di**: "Voy a automatizar X con este script/tool..."
