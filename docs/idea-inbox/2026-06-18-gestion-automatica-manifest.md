# Idea: Gestión automática de agent-os-assets-manifest.txt
**Fecha**: 2026-06-18

## Contexto
`sync.sh` necesita un manifest del core para saber qué archivos gestiona y cuáles han sido deprecados. Actualmente `assets-manifest.txt` (creado en T-025) es un archivo estático que nadie regenera automáticamente cuando cambia el core.

## Decisiones de diseño acordadas

### 1. Nomenclatura y diferenciación
*   `agent-os-assets-manifest.txt`: Manifiesto del core, generado y mantenido de forma automatizada en `agent-os`. Viaja a los proyectos hijos a través de `sync.sh`, y se deposita en `.agents/context/` del hijo.
*   `assets-manifest.txt`: Manifiesto local del proyecto hijo, generado por su respectivo `close-sprint.sh`, el cual nunca es tocado ni sobrescrito por `sync.sh`.

### 2. Estructura de `agent-os-assets-manifest.txt`
*   La lista de assets activos se generará dinámicamente mediante comandos `find` sobre las carpetas gestionadas por el core (reglas, workflows, scripts, etc.), evitando la edición manual y desactualizada.
*   La sección `[deprecated]` seguirá manteniéndose de forma manual y commiteada bajo el formato: `fecha | archivo | motivo`.

### 3. Automatización al cerrar el sprint
*   `close-sprint.sh` (del core) regenerará automáticamente `agent-os-assets-manifest.txt` antes de realizar el commit atómico de cierre de sprint. Así, cada release del core contará con su manifiesto fiel actualizado de forma nativa.

### 4. Comportamiento del Sync
*   `sync.sh` comparará el `agent-os-assets-manifest.txt` entrante con el previamente guardado en `.agents/context/agent-os-assets-manifest.txt` del proyecto hijo.
*   Procesará la sección `[deprecated]` para avisar de los archivos a limpiar (sólo eliminará si se provee explícitamente el flag `--cleanup`).
*   Al finalizar con éxito, copiará el manifiesto entrante a `.agents/context/agent-os-assets-manifest.txt` del hijo.

### 5. Universalidad de `close-sprint.sh`
*   Esta lógica es universal y portable. Al cerrar el sprint de cualquier proyecto hijo, el script local generará su propio `assets-manifest.txt` local. No hay conflicto de sobrescritura ya que `sync.sh` sólo busca y actualiza el archivo con prefijo `agent-os-`.

---

## Archivos afectados
*   `scripts/agent/close-sprint.sh` → Agregar paso de regeneración automática de manifiesto antes de commitear.
*   `scripts/agent/sync.sh` → Modificar lógica de sincronización para renombrar las referencias al manifiesto.
*   `scripts/agent/assets-manifest.txt` → Renombrar a `scripts/agent/agent-os-assets-manifest.txt`.
