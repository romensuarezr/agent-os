# ADR 003: Ciclo de vida de sesión y concurrencia por locks

**Estado:** Accepted  
**Fecha:** 2026-06-16  
**Contexto:** Sprint 02 — Core  

## Contexto
El desarrollo autónomo por parte de agentes de IA introduce riesgos de integridad en el código si no existe un control estricto de concurrencia y límites operativos. Sin restricciones, un agente podría realizar modificaciones sin aprobación previa, trabajar en múltiples tareas en paralelo mezclando contextos, o modificar archivos críticos fuera de su asignación. Necesitábamos un mecanismo rígido y determinista para forzar al agente a seguir un ciclo de vida lineal y seguro para cada tarea.

## Decisión
1. Implementar un semáforo de sesión basado en un archivo físico `.agent-session.lock`. La existencia de este archivo con estado activo bloquea al agente para que solo pueda operar en la tarea especificada.
2. Definir una estructura de ciclo de vida de sesión obligatoria estructurada en fases:
   * **Fase 0/1 (Detección y Contexto)**: Comprobación de locks activos mediante `check-session.sh` y lectura del sprint file.
   * **Fase 2 (Task File)**: Creación del archivo de tarea `.agents/tasks/task-XXX.md` que actúa como contrato de done y define la "Caja de archivos" autorizados.
   * **Fase 3.5 (Aprobación del Plan - Bloqueante)**: Presentación obligatoria del plan de acción al usuario en el chat. No se permite realizar ningún cambio en el disco ni crear ramas git antes de recibir el `APROBADO` explícito.
   * **Fase 4 (Apertura del Lock)**: Creación de la rama `feat/T-XXX-...` e inyección de metadatos en `.agent-session.lock`.
   * **Fase 5 (Ejecución)**: Modificaciones limitadas estrictamente a los archivos de la Caja.
   * **Fase 6 (Cierre)**: Validación de cambios (`git diff`), actualización del sprint file, commit atómico de cierre mediante `close-task.sh`, traslado del task file a `_archived/` y eliminación del lock.

### Componentes Clave
1. `.agent-session.lock`: Fichero JSON que almacena el estado de la sesión, la rama activa y los archivos autorizados.
2. `scripts/agent/check-session.sh`: Validador de estado que detecta bloqueos huérfanos o cambios en `src/` sin aprobación.
3. `scripts/agent/close-task.sh`: Script automatizado para empaquetar, commitear, archivar la tarea y destruir el lock de forma atómica.

## Consecuencias

### Positivas (Pros)
* **Seguridad e integridad**: Se evita que el agente modifique partes sensibles del sistema de forma descontrolada.
* **Trazabilidad**: Todo commit en el repositorio está directamente asociado a una tarea aprobada y documentada con sus criterios de aceptación.
* **Foco en tarea única**: Evita la dispersión del agente, obligándole a cerrar una tarea antes de iniciar la siguiente.

### Negativas (Cons)
* **Fricción operativa**: Iniciar y cerrar sesiones requiere múltiples pasos y llamadas a scripts, ralentizando correcciones extremadamente pequeñas.
* **Resiliencia ante caídas**: Si el proceso del agente se interrumpe abruptamente durante la fase de ejecución, el lock puede quedar en un estado inconsistente y requerir intervención manual o "Modo Rescate".

### Riesgos y Mitigaciones
* **Ignorar el lock por edición directa**: *Probabilidad: Media* -> *Mitigación*: El script `check-session.sh` realiza un análisis del `git diff` en directorios de código fuente cuando no hay lock activo, lanzando alertas críticas si detecta cambios huérfanos sin aprobación.

## Referencias
* [Workflows: session-start](file:///home/romen/Proyectos/agent-os/.agents/workflows/session-start.md)
* [Workflows: session-close](file:///home/romen/Proyectos/agent-os/.agents/workflows/session-close.md)
* [scripts/agent/close-task.sh](file:///home/romen/Proyectos/agent-os/scripts/agent/close-task.sh)
