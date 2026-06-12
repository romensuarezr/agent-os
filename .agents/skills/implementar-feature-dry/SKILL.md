---
name: implementar-feature-dry
description: Protocolo de implementación DRY para features de cualquier proyecto. Activa siempre que vayas a escribir código. Verifica que no duplicas lógica antes de crear nada nuevo.
---

# Implementar Feature — DRY First

## Antes de escribir una sola línea

Responde estas preguntas en orden. Si alguna es SÍ, adapta en lugar de crear:

### 1. Controladores y Lógica de Negocio
- ¿Ya existe un hook, controlador o clase de acciones `use[Entidad]Actions` o `[Entidad]Controller` para esta entidad?
  *(Ejemplos: `useUserActions`, `ProjectController`, etc.)*
- ¿O una función helper/utilidad genérica que cubra el caso?

### 2. Componentes de UI / Vistas
- ¿Existe ya un componente que haga lo mismo o algo similar en el proyecto?
- Si es similar en un 80% o más, **extiende el componente existente** usando parámetros/props en lugar de crear uno nuevo.

### 3. Modelo de Datos y Base de Datos
- ¿Los campos propuestos siguen las convenciones de naming del proyecto (ej: `.agents/rules/naming-convention.md`)?
- ¿El modelo de datos propuesto encaja con las entidades o tablas existentes sin añadir redundancia o duplicación?

### 4. Servicios y Capa de API / DB
- ¿La llamada a la base de datos, SDK o servicio de API externa ya existe en algún archivo de servicios (ej: `services/`)?

### 5. Acciones y Mutaciones
- ¿La acción (crear, editar, borrar) ya está contemplada en la capa de servicios o acciones para la entidad afectada? Si no existe, créala primero en su ubicación centralizada.

## Modularidad
- Si la feature afecta a **6 o más archivos** (nuevos o modificados), usa la skill `roadmap-a-tarea` para dividirla en tareas más pequeñas antes de empezar.

## Durante la implementación
1. Un archivo a la vez.
2. Tras cada archivo: compilación mental (o pruebas unitarias rápidas) — ¿sigue funcionando el conjunto?
3. Si surge un desvío o idea paralela: la skill de captura de ideas la anota en el inbox correspondiente, tú sigues con el objetivo de la tarea actual.

## Al terminar
- Revisa que no queden `TODO`, logs de debug o archivos huérfanos.
- Actualiza el archivo de la tarea (task file) con el estado `DONE`.
- Activa la revisión de accesibilidad o UX si la feature tiene interfaz de usuario y el proyecto dispone de dicha skill.
