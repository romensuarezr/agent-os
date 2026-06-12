---
name: doc-maintainer
description: Supervisa la edición de documentación, imponiendo análisis de ubicación previa y actualización obligatoria de fecha.
---

# Smart Doc Maintainer

Esta habilidad actúa como el "bibliotecario" del proyecto, asegurando que la documentación se mantenga ordenada, ubicada lógicamente y siempre actualizada.

## Cuándo Activar
- **Siempre** que vayas a editar o crear archivos en `.agents/context/`, `docs/` o `README.md`.

## Flujo de Trabajo

### 1. FASE DE ANÁLISIS (Ubicación)
Antes de escribir o crear un archivo:
1.  **Pregunta**: "¿Es este el mejor lugar para esta información?".
2.  **Investiga**: Ejecuta `ls` en el directorio destino y lee los títulos de archivos vecinos para entender la estructura.
3.  **Decide**:
    - Si existe un archivo específico (ej: `user_premium_tools.md`), úsalo en lugar de uno genérico (`services.md`).
    - Si el tema es nuevo y denso, crea un archivo nuevo.
    - Evita el "dumping" de información en archivos raíz como `README.md`.

### 2. FASE DE EDICIÓN (Contenido)
1.  **Respeta el Estilo**: Mantén el formato de headers, tablas y emojis del archivo original.
2.  **Edita**: Realiza los cambios necesarios.

### 3. FASE DE CIERRE (Timestamp - OBLIGATORIO)
1.  **Buscar Footer**: Mira al final del archivo. Busca patrones como `*Última actualización: ...*` o `Last updated: ...`.
2.  **Actualizar**:
    - **Si existe**: Cambia la fecha a la fecha actual real (Formato: `DD MMM YYYY`, ej: `29 Ene 2026`).
    - **Si no existe**: Añade al final del archivo:
      ```markdown

      ---

      *Última actualización: [FECHA_ACTUAL]*
      ```

## Verificación
- ¿La información está en el archivo más específico posible?
- ¿El archivo tiene la fecha de hoy al final?
