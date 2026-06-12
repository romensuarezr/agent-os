# Rule: DRY Architecture

> Estándar de separación de responsabilidades: Don't Repeat Yourself.

## Capas y Responsabilidades

1. **Acceso a Datos**: Servicios puros para DB/APIs. Sin lógica de UI.
2. **Hooks/Controladores**: Estado y lógica de negocio. Actúan de puente.
3. **Vistas/Pages**: Composición y routing. No deben contener lógica de base de datos directa.
4. **Componentes UI**: Primitivos visuales. Solo manejan estado de UI (ej: "está abierto").

## Mandatos
- **Reutilización**: Si una lógica se usa en dos sitios, extráela a un helper o hook compartido.
- **Límites Claros**: Ninguna vista debe importar drivers de base de datos directamente.
- **Firma Consistente**: Recursos similares (ej: Tareas, Proyectos) deben tener firmas de respuesta similares en sus hooks/controladores (ej: `{ items, isLoading, error }`).
- **Tech Scout**: Investiga si ya existe una librería OSS que resuelva el problema antes de escribir código personalizado.
