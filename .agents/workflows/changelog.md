---
description: Generar el registro de cambios (changelog) de un sprint utilizando los scripts del repositorio en {{PROJECT_NAME}}.
---

# changelog

Workflow para la actualización automatizada del historial de cambios del proyecto y la propuesta del bump de versión semver al finalizar un sprint.

## Objetivo

- Extraer y clasificar los commits de un sprint basándose en la especificación de *Conventional Commits*.
- Actualizar el archivo `CHANGELOG.md` con los cambios del sprint de forma estructurada.
- Sugerir y validar el bump de versión semver adecuado para el release.

## Archivos y rutas a revisar

- `CHANGELOG.md`
- `scripts/agent/update-changelog.sh`
- `scripts/agent/close-sprint.sh`

## Protocolo

### 1. Identificar el Sprint
- Determina el identificador del sprint activo que se va a cerrar (por ejemplo, `sprint-15`).

### 2. Generar el Changelog localmente
- Ejecuta el script de generación del changelog pasando el nombre del sprint como argumento. Esto modificará `CHANGELOG.md` pero no realizará ningún commit:

```bash
bash scripts/agent/update-changelog.sh [sprint-id]
```

### 3. Revisar cambios y versión propuesta
- Abre `CHANGELOG.md` y verifica la nueva sección insertada en la parte superior.
- Revisa la versión sugerida por el script (bump de tipo Major si hay *breaking changes*, Minor para *features*, o Patch para *fixes*).
- Si necesitas ajustar o corregir la descripción de algún commit para que sea más amigable en el changelog final, edítala manualmente en `CHANGELOG.md` en este momento.

### 4. Archivar el Sprint
- Una vez validado el changelog, procede a archivar el sprint para persistir los cambios del changelog en el repositorio:

```bash
bash scripts/agent/close-sprint.sh [sprint-id]
```
- Este script validará que todas las tareas estén completadas en el sprint file, moverá el sprint file a `docs/sprints/_archived/`, agregará los cambios de `CHANGELOG.md` al stage de Git y creará el commit atómico de cierre de sprint.

## Reglas

- **Orden estricto**: Siempre ejecuta `update-changelog.sh` antes de `close-sprint.sh` para garantizar que los cambios en el changelog entren en el commit de archivado.
- **Sin commits manuales**: No ejecutes `git commit` ni `git add` sobre `CHANGELOG.md` de forma manual. Deja que `close-sprint.sh` gestione el commit atómico de archivado.
- **Validación de tareas**: No intentes cerrar el sprint si existen tareas con estado `⬜ Pendiente` o `🟡 En curso`. Todo debe estar resuelto o resuelto mediante *spillover*.
