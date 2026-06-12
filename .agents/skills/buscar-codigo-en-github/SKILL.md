---
name: buscar-codigo-en-github
description: Encuentra implementaciones reales, patrones de arquitectura y ejemplos de código en GitHub antes de programar una feature. Úsala cuando el usuario diga 'busca cómo lo hacen en GitHub', 'encuéntrame ejemplos reales' o quiera contrastar varias formas de resolver algo.
---

# Buscar Código en GitHub (Patrones Reales)

Esta habilidad permite investigar cómo otros desarrolladores han resuelto problemas similares en repositorios reales de GitHub. Su objetivo es identificar patrones de arquitectura, estructuras de carpetas y lógicas de implementación que encajen con el stack del proyecto.

## Scope Exclusivo
- **SÍ**: Patrones de diseño, implementaciones de lógica compleja, estructuras de componentes, integración de servicios.
- **NO**: Búsqueda de librerías para instalar (usar `tech-scout` para eso).

## Instrucciones

### 1. Análisis del Contexto Local
Antes de buscar, identifica las restricciones del stack actual leyendo el `.agents/AGENT_ONBOARDING.md` del proyecto destino:
- **Tecnologías**: Lenguaje, frameworks, bases de datos.
- **Arquitectura**: Patrones de capas establecidos (ej. DRY, Clean Architecture, etc.).
- **Objetivo**: Qué funcionalidad específica se busca implementar.

### 2. Ejecución de Búsqueda
Usa `search_repositories` y `search_web` para encontrar entre **3 y 5 referencias** relevantes.
- Filtra por lenguaje (ej: `language:TypeScript` o `language:Python`).
- Prioriza repositorios con actividad reciente y buena reputación (estrellas).
- Evita resultados que usen frameworks incompatibles a menos que el patrón sea agnóstico.

### 3. Análisis de Referencias
Para cada repositorio seleccionado, extrae:
- **Repo y Ruta**: Enlace al repositorio y archivo(s) clave.
- **Patrón Extraíble**: Descripción técnica del enfoque (ej: "Factory Pattern para proveedores de auth").
- **Trade-offs**: Ventajas y desventajas de esa implementación específica.
- **Fit con el Proyecto**: ¿Cumple con nuestras reglas y arquitectura? ¿Es fácil de adaptar?

### 4. Output de la Skill
El reporte final debe estar estructurado en estos tres bloques:

#### 📂 Hallazgos
(Tabla comparativa de las 3-5 referencias analizadas).

#### 💡 Recomendación para el Proyecto
Cuál de los patrones encontrados es el más adecuado y por qué (basado en arquitectura y MVP).

#### 🚀 Próximo Paso Implementable
Acción concreta para empezar la implementación (ej: "Crear el service `X` siguiendo el patrón `Y`").

## Restricciones y Ética
- **No copiar bloques largos**: Entiende la lógica y replícala adaptada a nuestro estilo. No hagas copy-paste masivo.
- **Licencias**: Advierte explícitamente si encuentras una solución brillante en un repo con licencia restrictiva (GPL, etc.).
- **Comparar antes de actuar**: No empieces a escribir código hasta haber presentado y comparado las opciones.
