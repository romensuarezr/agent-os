---
name: tech-scout
description: Busca, evalúa y compara librerías, paquetes npm y SDKs antes de añadir dependencias al proyecto. Úsala cuando el usuario pregunte qué librería usar, quiera comparar opciones o necesite validar una dependencia nueva.
---

# Tech Scout (Explorador de Dependencias)

Esta habilidad es tu departamento de I+D personal. Su misión es evitar reinventar la rueda buscando bibliotecas, herramientas o SDKs dentro del ecosistema de dependencias que ya resuelvan el problema planteado, asegurando compatibilidad con el stack del proyecto.

## Prerrequisitos
- Acceso a herramientas de búsqueda (`perplexity`, `search_web`).

## Instrucciones

### 1. Análisis de Requerimientos
Antes de buscar, define los criterios técnicos del stack leyendo el archivo `.agents/AGENT_ONBOARDING.md` o el archivo de dependencias correspondiente (ej: `package.json`, `pyproject.toml`):
- **Lenguaje**: (ej: TypeScript, Python, etc.)
- **Framework / Runtime**: (ej: React, Next.js, FastAPI, Node.js)
- **Ecosistema y Base de datos**: (ej: Firebase, PostgreSQL, etc.)
- **Funcionalidad Clave**: ¿Qué debe hacer exactamente la dependencia?

### 2. Ejecución de Búsqueda
Usa las herramientas disponibles en este orden de preferencia:

1.  **Perplexity**:
    - Prompt: "Find best packages/libraries for [task] in a [stack] environment. Prioritize active maintenance and TypeScript/language support. Compare top 3 options."
2.  **Web Search (Reddit & StackOverflow)**:
    - Query: "best [language] library for [task] reddit"
    - Query: "[library-A] vs [library-B] [framework] 2025/2026"
3.  **Búsqueda Técnica (NPM Trends / Bundlephobia / PyPI Stats)**:
    - Investiga el volumen de descargas, vulnerabilidades de seguridad y el peso del bundle si la información no es clara.

### 3. Evaluación (Matriz de Calidad)
Para cada candidato, evalúa los siguientes puntos:

| Criterio | Requerimiento MVP |
| :--- | :--- |
| **Compatibilidad** | Soporte para el stack del proyecto (ej: React, Vite, ESM). |
| **Tipado / Soporte** | Tipado nativo (TS) o soporte nativo para el lenguaje. |
| **Peso / Overhead** | Tamaño ligero y bajo impacto de rendimiento. |
| **Actividad** | Commits frecuentes y buena resolución de issues en GitHub. |
| **Licencia** | Permisiva (MIT, Apache 2.0). |
| **Riesgo Lock-in** | Nivel de dependencia de servicios externos propietarios. |

### 4. Validación Social
Busca opiniones reales para detectar "banderas rojas":
- Hilos de Reddit sobre problemas de performance o bugs conocidos.
- Dificultades de integración reportadas en StackOverflow.
- Facilidad de uso y calidad de la documentación.

### 5. Reporte de Resultados
Presenta al usuario una tabla comparativa clara:

| Librería | Licencia | Peso/Overhead | Compatibilidad | Pros | Contras | Recomendación |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `lib-A` | MIT | 5kb / bajo | Alta | Nativa TS, Ligera | Pocos temas | ✅ Opción #1 |
| `lib-B` | Apache | 45kb / medio | Media | Muy potente | Pesada | ⚠️ Solo si necesitas X |

### 6. Acción Post-Scout
- Si hay un ganador claro: **Proponer usar la herramienta de instalación adecuada (ej: `npm install [package]`, `poetry add [package]`, `pip install [package]`)**.
- Si no hay opciones viables: **Proceder a construir una solución personalizada (Custom)**.
