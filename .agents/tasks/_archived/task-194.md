# Task-194: Estandarización de Changelog, GitHub Releases y archivo VERSION universal para satélites

## Objetivo
Estandarizar el ciclo de release y publicación conforme al estándar de la industria (Keep a Changelog + GitHub Releases API), automatizando la creación de releases oficiales en GitHub con notas y enlaces comparativos, e incorporando en todos los proyectos satélite el patrón de archivo plano universal `VERSION` en la raíz para consumo desacoplado en aplicaciones sin hardcodear (Next.js, Node, Python, Docker).

## Contexto técnico
- Actualmente `promote-to-main.sh` genera el tag `vX.Y.Z` pero no crea el objeto Release en GitHub (`gh release create`), por lo que no existe una URL pública navegable con las notas de cada versión.
- En `update-changelog.sh` no se agregan enlaces Markdown al pie para comparar diffs entre versiones (`[1.29.0]: https://github.com/.../compare/v1.28.0...v1.29.0`).
- En proyectos satélite, las aplicaciones suelen hardcodear la versión en el código fuente. Se debe estandarizar el patrón de archivo `VERSION` plano y proveer utilidades/plantillas de inyección en variables de entorno públicas (`NEXT_PUBLIC_APP_VERSION`, `APP_VERSION`).

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 35 / 2026-11-11
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - `update-changelog.sh`: Genera enlaces de comparación al pie del archivo siguiendo el estándar Keep a Changelog.
  - `promote-to-main.sh`: Soporte para crear la Release oficial en GitHub mediante CLI `gh release create` si `gh` está autenticado, con degradación limpia si no está disponible.
  - `install.sh` y satélites: Inicialización obligatoria del archivo `VERSION` en la raíz de satélites y sincronización en `close-sprint.sh`.
  - Documentación de patrones de consumo de `VERSION` en plantillas para Next.js, FastAPI y Dockerfiles.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/update-changelog.sh`
- `scripts/agent/promote-to-main.sh`
- `scripts/agent/install.sh`
- `scripts/agent/lib/sync-version.sh`
- `templates/root/`
- `docs/sprints/sprint-35.md`

## Criterios de done
- [x] `update-changelog.sh` inserta enlaces de diff comparativo SemVer al final de `changelog.md`.
- [x] `promote-to-main.sh` incluye subcomando o flag determinista para publicar Release en GitHub con notas extraídas del changelog.
- [x] `install.sh` provisiona el archivo `VERSION` en la raíz de los nuevos proyectos satélite.
- [x] Plantillas documentan la lectura desacoplada de `VERSION` para entornos web/backend.
- [x] Suite `tests/validate-control-plane.sh` pasa 38/38 checks verdes.

## Estado de aprobación y deliberación
- [x] Deliberación técnica completada (`deliberate-plan.sh`)
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido en planning
- [x] Rama de trabajo activa
- [x] Lock activo: —
- [x] Tarea cerrada y verificada
