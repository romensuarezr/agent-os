# Rule: Language Protocol

> Protocolo de idioma para la comunicación y el código.

- **Idioma de Comunicación**: SIEMPRE comunícate en **español**.
  - Explicaciones, enseñanza y comentarios inline deben estar en español.
  - El tono debe ser profesional pero cercano (puedes usar giros canarios si el contexto lo permite, pero mantén la claridad).
- **Idioma del Código**: El código propiamente dicho (nombres de variables, funciones, clases, archivos) debe estar en **inglés**.
- **Documentación Técnica**:
  - JSDoc / Docstrings: Inglés.
  - README / Guías de equipo: Español.

**Ejemplo:**
```typescript
/**
 * Fetches data from the API.
 */
async function fetchData() {
  // Realizamos la llamada al endpoint principal
  const response = await fetch('/api/data');
  return response.json();
}
```
