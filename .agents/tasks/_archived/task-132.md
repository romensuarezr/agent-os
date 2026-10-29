# Task-132: Resolución Histórica de Research Archivado en Design Digest

## Objetivo
Extender la resolución de documentos de prospección tecnológica en `scripts/agent/design-digest.sh` para inspeccionar tanto la carpeta activa `docs/sprints/` como el histórico archivado `docs/sprints/_archived/`, garantizando que la compuerta `--check-scout` y la extracción de contexto scout en digests históricos sigan siendo funcionales y deterministas tras el cierre y archivado formal de los sprints.

## Contexto técnico
En la tarea T-129 se institucionalizó la compuerta de prospección scout determinista a $0 tokens, integrando en `scripts/agent/design-digest.sh` la validación `--check-scout` y la extracción del veredicto scout en el Executive Design Digest.

Sin embargo, la implementación original de `design-digest.sh` asumía una ruta canónica fija en `$ROOT_DIR/docs/sprints/sprint-${SPRINT_NUM}-research.md`. Cuando un sprint concluye y se ejecuta el ritual de cierre (`close-sprint.sh`), los artefactos de sprint y research son trasladados al directorio `docs/sprints/_archived/`. Esto ocasiona una regresión en frío:
1. Las verificaciones posteriores (como la prueba de seguridad `--check-scout --task-id 22` contenida en el Check 36 de `validate-control-plane.sh`) fallan con error al no encontrar el fichero en la raíz de `docs/sprints/`.
2. Los digests históricos de tareas pasadas degradan el estado scout a `OMITIDO (sin research registrado / tarea heredada)` al no encontrar el archivo de research en su ubicación activa.

Para subsanar esta limitación sin romper el aislamiento ni requerir dependencias externas, se debe implementar una resolución en cascada (primero `docs/sprints/`, luego `docs/sprints/_archived/`) tanto en el manipulador bash de `--check-scout` como en el bucle extractor en Python de la metadata scout.

## Skills relevantes
- `agent-os-scripts`: Regla aplicada: diseño de scripts deterministas a $0 tokens, robustez en manejo de rutas POSIX y consistencia de códigos de salida CLI.
- `workflow-designer`: Regla aplicada: preservación de invariantes del ciclo de vida de tareas y coherencia entre las fases activas y archivadas del sprint.

## Caja de archivos
- `scripts/agent/design-digest.sh`
- `.agents/tasks/task-132.md`
- `docs/sprints/sprint-22-core.md`

## Criterios de done
- [ ] `design-digest.sh` resuelve `RESEARCH_FILE` en `--check-scout` comprobando primero `docs/sprints/sprint-${SPRINT_NUM}-research.md` y luego `docs/sprints/_archived/sprint-${SPRINT_NUM}-research.md`.
- [ ] El extractor Python de `design-digest.sh` busca patrones de tareas en ficheros de research tanto en `docs/sprints/` como en `docs/sprints/_archived/`.
- [ ] Comprobación observable de funcionamiento: `--check-scout --task-id 22` devuelve exit 0 tanto si el research reside en `docs/sprints/` como en `docs/sprints/_archived/`.
- [ ] Suite `tests/validate-control-plane.sh` pasando íntegramente los 36 checks (36/36) con 0 errores.
