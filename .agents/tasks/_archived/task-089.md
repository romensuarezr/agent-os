# Task-089: Setup guiado y generación determinista de perfiles adaptados al stack

## Objetivo
Implementar una utilidad determinista (`scripts/agent/setup-profiles.sh`) que adapte y especialice los perfiles de agentes en `.agents/profiles/` (especialmente `developer.yaml`) y enriquezca la documentación de onboarding (`.agents/AGENT_ONBOARDING.md`) según el stack tecnológico y gestor de paquetes detectados por `detect-stack.sh`, incorporando herramientas permitidas, comandos de prueba/compilación y directrices técnicas específicas sin romper el esquema canónico validado por el control plane.

## Contexto técnico y Dependencias
- **Prerrequisitos**: `T-085` (namespacing `.agents/config/`), `T-086` (resolución defensiva de stack en `detect-stack.sh`), `T-088` (auditoría de salud en satélites) y `Fase 0` (fix de override de entorno en `detect-stack.sh`).
- **Política de Artefacto Regenerable**:
  - Los perfiles especializados por `setup-profiles.sh` son **REGENERABLES**, no personalizaciones humanas manuales.
  - Tras un `sync.sh` que actualice los perfiles base desde el core, se re-ejecuta `bash scripts/agent/setup-profiles.sh --apply`.
  - La especialización inyectada se delimita estrictamente entre marcadores canónicos:
    `# BEGIN AGENT-OS-GENERATED-STACK`
    `# END AGENT-OS-GENERATED-STACK`
    permitiendo a los operadores distinguir nítidamente lo generado por Agent OS de sus configuraciones propias.
  - Idempotencia: ejecuciones sucesivas con `--apply` reemplazan limpiamente el bloque existente entre dichos marcadores sin duplicar secciones.
- **Consumo de `detect-stack.sh` y Soporte de `--stack <override>`**:
  - `setup-profiles.sh` invoca `detect_stack()` para obtener `AGENT_OS_STACK`, `AGENT_OS_PACKAGE_MANAGER` y `AGENT_OS_DETECTED_LOCKFILE`.
  - Si se proporciona `--stack <override>`, se aprovecha el mecanismo de entorno reparado en Fase 0 (`AGENT_OS_STACK="$override" detect_stack "$TARGET_DIR"`).
- **Mapeo de Stacks Soportados (11 stacks)**:
  - TypeScript, JavaScript, Python, Go, Rust, Java, PHP, Ruby, Dotnet, Bun, Static.
  - Asocia herramientas de test, linter, typecheck y comandos de build específicos de cada ecosistema.
- **Modos de Operación**:
  - `--check` (dry-run): simula y muestra qué cambios se generarían sin escribir en disco.
  - `--apply`: escribe las adaptaciones respetando idempotencia de marcadores.
  - `--path <dir>`: permite ejecutar sobre cualquier directorio satélite o local.
  - `--stack <override>`: fuerza un stack explícito soportado.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `docs/sprints/sprint-13-core.md`
- `.agents/tasks/task-089.md`
- `scripts/agent/setup-profiles.sh`
- `scripts/agent/assets-manifest.txt`
- `tests/test-setup-profiles.sh`

## Criterios de done
- [x] `scripts/agent/setup-profiles.sh` implementado con soporte para `--check`, `--apply`, `--path <dir>` y `--stack <override>`.
- [x] Integración determinista con `detect-stack.sh` clasificando los 11 stacks soportados y su gestor verificado en `$PATH`.
- [x] Especialización de perfiles regenerable: delimitada por marcadores `# BEGIN AGENT-OS-GENERATED-STACK` y `# END AGENT-OS-GENERATED-STACK`, idempotente sin duplicación ante re-ejecución con `--apply`.
- [x] Enriquecimiento determinista de `AGENT_ONBOARDING.md` con los comandos frecuentes del stack si existe en destino.
- [x] Preservación estricta del esquema canónico YAML/MD validado por `tests/validate-control-plane.sh` (Checks 1 y 2).
- [x] `scripts/agent/setup-profiles.sh` registrado en `scripts/agent/assets-manifest.txt` bajo `[active]`.
- [x] Suite de pruebas dedicada `tests/test-setup-profiles.sh` cubriendo matriz TypeScript/Python/Rust/Go, idempotencia de marcadores y caso `--stack <override>`.
- [x] `tests/validate-control-plane.sh` permanece en 12/12 PASS sin regresiones.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-30T09:21:54+01:00
- [x] Rama creada: feat/T-089-setup-profiles-stack
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
