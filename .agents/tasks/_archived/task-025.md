# Task-025: assets-manifest.txt — gestión de eliminaciones en sync.sh

## Objetivo
Implementar una gestión de eliminaciones en `sync.sh` mediante un archivo manifiesto de recursos para eliminar assets deprecados en proyectos hijos, y alertar de la presencia de archivos deprecados conocidos en `check-session.sh`.

## Contexto técnico
- `sync.sh` propaga assets globales del core a proyectos hijos, pero nunca los elimina cuando son deprecados en el core (ej. `IMPLEMENTED.md`).
- Se necesita una lista canónica en `scripts/agent/assets-manifest.txt` para mapear los recursos gestionados.
- `sync.sh` debe leer este manifiesto y limpiar con `git rm` (o `rm -f`) los archivos presentes en el proyecto hijo que ya no estén listados en el manifiesto actual.
- `check-session.sh` debe incorporar una alerta rápida si detecta archivos deprecados históricos en el hijo, indicando que debe ejecutarse `sync.sh`.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/assets-manifest.txt`
- `scripts/agent/sync.sh`
- `scripts/agent/check-session.sh`

## Criterios de done
- [x] Crear `scripts/agent/assets-manifest.txt` con la lista canónica de recursos activos y la sección `[deprecated]` con fecha, ruta y motivo.
- [x] Modificar `sync.sh` para que por defecto solo detecte y avise de la presencia de archivos deprecados sin borrarlos, instruyendo sobre el uso del flag `--cleanup`.
- [x] Modificar `sync.sh` para que con `--cleanup` elimine interactivamente (confirmando con `s/N` tras mostrar las primeras 5 líneas de cada archivo) usando `git rm -f` o `rm -f`.
- [x] Implementar validación en `sync.sh` para que si se ejecuta `--cleanup` de forma no interactiva (sin TTY), requiera el flag `--force` para proceder (de lo contrario, abortar con error).
- [x] Validar que `sync.sh` nunca afecte a archivos propios locales del hijo.
- [x] Modificar `check-session.sh` para detectar los deprecados conocidos y emitir alerta en proyectos hijos.
- [x] Compilación/Verificación sin errores.

## Estado de aprobación
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-06-17T14:28:13+01:00
- [x] Rama creada: feat/T-025-sync-assets-manifest-cleanup
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
