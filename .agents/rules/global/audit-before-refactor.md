# Rule: Audit Before Refactor

> Evita construir sobre cimientos inestables o duplicar lógica existente.

## Protocolo Obligatorio (4 Pasos)

### 1. Inventario Previo
Antes de modificar o crear archivos, haz un `grep` o `ls` para listar TODOS los archivos del mismo dominio funcional.
*Ej: Si vas a crear `OrderService.ts`, busca `*Order*` en todo el proyecto.*

### 2. Clasificación Técnica
Evalúa los archivos encontrados:
- **Patrón**: ¿Sigue la arquitectura del proyecto?
- **Consistencia**: ¿Los nombres de campos y tipos coinciden con lo existente?
- **Uso**: ¿Es código activo o huérfano?

### 3. Reporte de Auditoría
Muestra el inventario y señala inconsistencias (ej: campos duplicados, lógica dispersa).
> [!IMPORTANT]
> Si detectas violaciones graves de la arquitectura en código existente, propone su corrección antes de proceder.

### 4. Prevención de Duplicidad
Extender es preferible a crear. Solo crea archivos nuevos si la responsabilidad es claramente distinta.
