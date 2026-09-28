---
trigger: code-architecture
---

# Rule: DRY Architecture

> Estándar de separación de responsabilidades y modularidad: Don't Repeat Yourself.

## 1. Capas Universales y Responsabilidades

1. **Acceso a Datos / Infraestructura**: Clientes de base de datos, SDKs externos, llamadas HTTP/gRPC. Cero lógica de presentación.
2. **Lógica de Negocio / Dominio / Controladores**: Reglas de negocio, validaciones y orquestación de casos de uso. Aísla el dominio de los detalles de transporte o UI.
3. **Presentación / Interfaz / Vistas**: Routing, controladores de vista, endpoints REST/CLI o páginas UI. No deben invocar drivers de base de datos o almacenamiento directamente.
4. **Componentes / Primitivas Reutilizables**: Elementos puros o helpers modulares con responsabilidad única.

---

## 2. Ejemplos de Implementación por Stack (Etiquetados)

### Ejemplo A: Frontend (React / Next.js / Vue / Svelte)
- **Vistas/Pages**: Composición visual y rutas.
- **Hooks / Stores**: Estado y orquestación (ej: `useTasks` devolviendo `{ data, isLoading, error }`).
- **Servicios API**: Clientes HTTP puros (ej: `tasksApi.list()`).

### Ejemplo B: Backend / Servicios (Python / Go / Node / Rust)
- **Transporte / Handlers**: Enrutamiento HTTP, validación de schemas de entrada.
- **Servicio / Use Case**: Lógica de negocio (ej: `TaskService.create_task(...)`).
- **Repositorio / DAO**: Consultas SQL / ORM / driver persistente.

---

## 3. Mandatos Universales
- **Reutilización**: Si una lógica se duplica en dos sitios, extráela a un módulo, función o helper compartido antes del tercer uso.
- **Límites de Capa**: Ninguna capa superior debe saltarse la intermedia para acceder directamente al driver de datos.
- **Firma Consistente**: Respuestas y errores deben seguir patrones predecibles en cada capa (ej: tuplas `(data, error)`, estructuras `Result<T, E>` o envelopes `{ data, error }`).
- **Tech Scout**: Antes de implementar una utilidad compleja desde cero, prospecta si existe un estándar OSS probado.
