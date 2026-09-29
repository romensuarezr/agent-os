# Task-087: Distribución universal del Core — One-Liner reejecutable e instalación idempotente pineada a release tag

## Objetivo
Crear y formalizar el mecanismo de distribución universal del core de Agent OS mediante un instalador ejecutable vía comando único (`one-liner`), reejecutable e idempotente, pineado estrictamente a tags de release canónicos (`https://raw.githubusercontent.com/romensuarezr/agent-os/<tag>/scripts/agent/install.sh`, nunca a `main`), garantizando la preservación completa del diferencial de Agent OS (flota, gobernanza, perfiles, reglas y workflows, no sólo skills) y sin sobreescribir personalizaciones en proyectos hijos.

## Contexto técnico y Dependencias
- **Prerrequisito obligatorio**: `T-085` completado (namespacing runtime a `.agents/config/` operativo).
- **Ejecución remota vía pipe (`curl | bash`)**: Cuando `install.sh` se ejecuta canalizado por `curl -fsSL https://raw.githubusercontent.com/romensuarezr/agent-os/<tag>/scripts/agent/install.sh | bash -s -- [destino]` o como script individual sin un clon local del core, `$BASH_SOURCE[0]` carece de directorio padre con los assets. `install.sh` debe detectar automáticamente la ausencia del árbol local de `AGENT_OS_PATH` y descargar/clonar de forma efímera y determinista el release tarball o repositorio en el tag especificado.
- **Pinchado estricto a tag de release y Fuente de Verdad (`VERSION`)**: Se crea el archivo `VERSION` en la raíz del core (una línea, ej. `1.11.0`) como fuente de verdad canónica. Cuando `install.sh` se ejecuta desde un clon local del core, lee `VERSION` para el valor por defecto de `--tag` / `AGENT_OS_TAG`; en ejecución remota pura el one-liner del README pinea el tag explícitamente en la URL y en `--tag` (nunca `main`, nunca `latest`).
- **ADR-006 (Distribución Universal y no reducible a skills sueltas)**: Formaliza la decisión arquitectónica de por qué Agent OS se distribuye como un sistema operativo de agentes integral (gobernanza, workflows, rules, perfiles, scripts, `audit-child`) y no como un catálogo fragmentado tipo `npx skills add`.

## Proceso de Release e Invariantes de Versión
1. **Fuente de verdad**: `VERSION` es la única fuente de verdad canónica del core.
2. **Bump atómico**: Al cerrar un sprint (`close-sprint.sh` / release workflow), se bumpéa atómicamente `VERSION` y se sincroniza con `changelog.md`.
3. **Creación y push de Tag Git**: Cada cierre de sprint crea y pushea a `origin` el tag git anotado correspondiente a `VERSION` (ej: `git tag vX.Y.Z <commit> -m "release vX.Y.Z — sprint-XX-core" && git push origin vX.Y.Z`), garantizando que la URL del one-liner y las instalaciones desatendidas resuelvan inmediatamente con HTTP 200 en GitHub.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `docs/sprints/sprint-13-core.md`
- `.agents/tasks/task-087.md`
- `scripts/agent/install.sh`
- `README.md`
- `VERSION`
- `docs/adrs/adr-006-universal-distribution.md`
- `docs/adrs/README.md`
- `tests/test-install-oneliner.sh`

## Criterios de done
- [x] ADR `docs/adrs/adr-006-universal-distribution.md` creado y registrado en `docs/adrs/README.md` justificando la distribución integral frente a catalogos tipo `npx skills add`.
- [x] Archivo `VERSION` creado en la raíz del core como fuente canónica de verdad (leído por `install.sh`).
- [x] `scripts/agent/install.sh` detecta si se ejecuta sin clon local de Agent OS y aprovisiona efímeramente los assets del core pineados al tag de release.
- [x] El one-liner está pineado a tag de release explícito (`https://raw.githubusercontent.com/romensuarezr/agent-os/<tag>/scripts/agent/install.sh`), nunca a `main`.
- [x] Reejecución idempotente: ejecutar `install.sh` múltiples veces en el mismo repositorio no rompe ni sobreescribe personalizaciones locales ni duplica entradas en `.gitignore`.
- [x] Instalación completa del diferencial de Agent OS: perfiles, reglas, workflows, skills, configs y scripts operativos instalados y funcionales.
- [x] Documentación pública en `README.md` actualizada con el comando canónico del one-liner pineado a tag de release.
- [x] Nueva suite `tests/test-install-oneliner.sh` valida la instalación en repo efímero limpio y la re-ejecución idempotente.
- [x] `tests/validate-control-plane.sh` pasa 12/12 sin regresiones en el core.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-30T00:10:43+01:00 (APROBADO CON CAMBIOS)
- [x] Rama creada: feat/T-087-universal-core-distribution
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
