---
name: roadmap-a-tarea
description: Descompone un ítem del roadmap o una intención de producto en tareas atómicas implementables, con criterios de aceptación claros y respetando la arquitectura del proyecto. Úsala cuando el usuario diga 'quiero implementar X' o traiga algo del roadmap.
---

# Roadmap a Tarea (Planificación Atómica)

Esta habilidad permite transformar objetivos de alto nivel o ítems del roadmap en un plan de ejecución técnico y secuencial. Su propósito es asegurar que cada paso de la implementación sea claro, manejable y respete la arquitectura y principios del proyecto.

## Instrucciones

### 1. Análisis de Contexto
- **Roadmap**: Lee el archivo `roadmap.md` o la documentación de roadmap del proyecto para entender dónde encaja este ítem dentro del Sprint actual o el backlog.
- **Estado del Código**: Antes de descomponer, lee los archivos que podrían verse afectados para no subestimar la complejidad.

### 2. Definición de Alcance
Confirma con el usuario:
- ¿Vamos a implementar el ítem completo o solo un sub-módulo?
- ¿Existen dependencias externas (APIs, diseño previo) que debamos considerar?

### 3. Descomposición Atómica
Divide el trabajo en tareas (máximo 8). Para cada tarea, define:
- **Descripción**: Una línea clara de la acción.
- **Archivos Afectados**: Rutas exactas en `.agents/tasks/` o en el directorio de código.
- **Dependencia**: ¿Qué tarea debe terminarse antes de empezar esta?
- **Criterio de Aceptación**: ¿Cómo verificamos que esta tarea específica funciona? (Integra aquí pruebas manuales o automáticas necesarias).
- **Complejidad**: S (Simple <1h), M (Media 1-3h), L (Larga 3h+).

### 4. Secuenciación y Dependencias
- Ordena la lista de tareas de forma que la implementación sea fluida y sin bloqueos.
- Identifica si es necesario activar primero habilidades complementarias:
    - Diseño UX/UI / interfaz (si el flujo de pantallas no está claro).
    - `architecture-audit` (si el código base necesita limpieza previa).

### 5. Entrega
El resultado debe ser un artefacto con el plan de tareas detallado. Guardarlo en `.agents/tasks/task-XXX.md` usando la plantilla en `.agents/tasks/_template.md`.

## Restricciones
- **Límite de Tareas**: Máximo 8 tareas por desglose. Si salen más, propón dividir el ítem original en dos.
- **Pruebas Integradas**: No crees tareas separadas para "Testear" o "Documentar"; estas deben ser parte del criterio de aceptación de cada tarea técnica.
- **Realismo Técnico**: No asumas que una tarea es simple sin haber consultado primero el código existente en esa área.

---

## Modo Sprint (integración con /sprint-planning)

Cuando se activa desde el workflow `/sprint-planning` o el usuario dice "prepara el sprint", usar este modo:

### Selección de tareas para el sprint
1. Leer el sprint file activo en `docs/sprints/`.
2. Filtrar ítems del roadmap sin ✅ y sin `⏸ Pausada`.
3. Proponer 3-5 tareas siguiendo el equilibrio de tamaños:
   - No más de 1 tarea **L** por sprint.
   - Al menos 1 tarea **S** para garantizar momentum.
   - Completar con tareas **M**.
4. Para cada tarea propuesta, indicar: descripción, tamaño, dependencias y si ya tiene task file.

### Marcado de tareas completadas
Cuando el workflow `/session-close` cierra una tarea:
1. Localizar la tarea en `docs/sprints/sprint-XX.md`.
2. Actualizar estado a `✅ Hecho` con fecha.
3. Si la tarea tiene task file → confirmar que está archivado en `.agents/tasks/_archived/task-XXX.md`.
