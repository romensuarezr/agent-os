# Task-022: Validar la compatibilidad del script sync.sh tras el bootstrap self-hosted

## Objetivo
Asegurar la compatibilidad de `sync.sh` tras un bootstrap self-hosted añadiendo una validación estricta de igualdad de rutas al inicio del script, evitando la auto-sincronización destructiva del core sobre sí mismo y mostrando un mensaje de error claro en color ANSI rojo con guías de resolución inline.

## Contexto técnico
- `sync.sh` sincroniza el core global de `agent-os` hacia proyectos hijos.
- Si se ejecuta en el propio core (self-hosted) apuntando al directorio raíz del core, la copia recursiva puede alterar los archivos origen.
- Se debe resolver la ruta absoluta real (usando `realpath`) de `AGENT_OS_PATH` y `TARGET_PROJECT`, compararlas y abortar con un error explícito si coinciden.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/sync.sh`

## Criterios de done
- [x] Implementar la validación de igualdad de rutas físicas usando `realpath` al inicio de `scripts/agent/sync.sh`.
- [x] Abortar la ejecución y mostrar un error en color ANSI rojo con las guías específicas si las rutas coinciden.
- [x] Validar localmente ejecutando el script contra sí mismo para comprobar el comportamiento.
- [x] Compilación/Verificación sin errores.

## Estado de aprobación
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-06-16T13:36:05+01:00
- [x] Rama creada: feat/T-022-validate-sync-compatibility
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
