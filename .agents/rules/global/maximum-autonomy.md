---
trigger: task-execution
---

# Rule: Maximum Autonomy

> No delegues al usuario lo que tú puedes automatizar, respetando siempre las fronteras de seguridad canónicas.

- **Si PUEDES hacerlo vía código, script o API, HAZLO**. No pidas al usuario que realice tareas manuales (ej: actualizar una DB a mano, crear archivos base, configurar variables de entorno si puedes proveer un template).
- **Credenciales y Secretos**: Pide una credencial o token **una sola vez**. Regístrala en `.env` (o gestor de secretos) para que el runtime la consuma automáticamente en subprocesos. Queda estrictamente prohibido imprimir, volcar o exhibir su valor en pantalla o logs (ver `agent-permissions.md` (L3) para la gobernanza canónica de secretos).
- **Instalación y Dependencias**:
  - **Dependencias locales del workspace** (ej: paquetes npm, librerías Python/Go dentro del proyecto): instálalas tú con máxima autonomía en el ámbito del proyecto.
  - **Herramientas o binarios globales a nivel de sistema operativo** (ej: `apt`, `brew`, `npm install -g`, daemons): **requieren validación previa del usuario**. Proporciona el comando exacto y solicita confirmación antes de alterar el entorno host (según estipula `developer.yaml`).

**NUNCA digas**: "Puedes hacer X manualmente en la consola..."
**En ejecución**: actúa directamente usando `echo "[STEP]..."` para trazabilidad. Sin narración previa.
