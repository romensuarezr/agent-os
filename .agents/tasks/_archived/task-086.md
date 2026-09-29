# Task-086: Detección defensiva de stack y runtimes en detect-stack.sh (resolución lockfile vs PATH)

## Objetivo
Blindar la detección de stack y gestores de paquetes en `scripts/agent/lib/detect-stack.sh` ante la presencia de lockfiles huérfanos o desincronizados en repositorios reales, verificando la disponibilidad real de los binarios en `PATH` (ej. `bun.lock` presente sin `bun` en el host) y aplicando fallback defensivo y trazable a ejecutables disponibles (`npm`, `pnpm`, `yarn`), preservando la clasificación declarativa del stack y la compatibilidad 100% con los consumidores del core.

## Contrato de Implementación y Reglas de Resolución

### 1. Variables exportadas por `detect_stack()`
- **`AGENT_OS_STACK`**: Conserva rígidamente la clasificación declarativa por marcadores (ej. `bun` aunque `bun` no esté instalado en el host). **NO se reclasifica**: el enum soportado (`bun`, `node-ts`, `node-js`, `python`, `rust`, `go`, `ruby`, `php`, `elixir`, `deno`, `generic`) y los digests/skills del core dependen de esta clasificación.
- **`AGENT_OS_DETECTED_LOCKFILE`**: Nombre del archivo de bloqueo que originó la clasificación declarativa (ej. `bun.lockb`, `bun.lock`, `pnpm-lock.yaml`, `yarn.lock`, `package-lock.json`, `poetry.lock`, `Pipfile.lock`, `Cargo.lock`, `go.sum`, etc.). Vacío si no aplica o no se detectó lockfile.
- **`AGENT_OS_PACKAGE_MANAGER`**: Gestor de paquetes verificado y disponible en `$PATH` (`bun|pnpm|yarn|npm|pip|poetry|cargo|go|...|`vacío si ninguno).

### 2. Regla de resolución del Gestor de Paquetes (`AGENT_OS_PACKAGE_MANAGER`)
1. **PM nativo**: Si el lockfile detectado tiene un gestor nativo asociado (`bun.lock` ➔ `bun`, `pnpm-lock.yaml` ➔ `pnpm`, etc.) y `command -v <pm>` lo encuentra en `$PATH`, se asigna directamente.
2. **Fallback ordenado (divergencia)**: Si el binario nativo NO está instalado en `$PATH`:
   - Para el ecosistema Node/JS/TS: primer gestor disponible en `$PATH` evaluado en orden de precedencia: `bun` → `pnpm` → `yarn` → `npm`.
   - Para Python: `poetry` → `pip` / `pip3` (o uv si existe).
3. **Sin gestores**: Si ningún gestor alternativo está disponible en `$PATH`, `AGENT_OS_PACKAGE_MANAGER=""`.
4. **Aviso de divergencia en `stderr`**: Toda divergencia lockfile-vs-PATH debe emitir obligatoriamente una advertencia a `stderr` con formato estándar:
   `⚠️  DIVERGENCE: <lockfile> detectado pero '<pm_nativo>' no está en PATH. Fallback a '<resolved_pm>'.`
   (O `⚠️  DIVERGENCE: <lockfile> detectado pero ningún gestor compatible está instalado en PATH.` si queda vacío).
   El `stdout` debe permanecer 100% limpio para no contaminar scripts consumidores que capturen la salida.

### 3. Preservación de Consumidores
- [`install.sh`](file:///home/romen/orca/workspaces/agent-os/Core-Hardening/scripts/agent/install.sh), [`inventory-check.sh`](file:///home/romen/orca/workspaces/agent-os/Core-Hardening/scripts/agent/inventory-check.sh), [`generate-digest.sh`](file:///home/romen/orca/workspaces/agent-os/Core-Hardening/scripts/agent/generate-digest.sh), [`audit-repo.sh`](file:///home/romen/orca/workspaces/agent-os/Core-Hardening/scripts/agent/audit-repo.sh):
  Mantienen intacto su consumo de `AGENT_OS_STACK`, `HAS_NEXTJS` y variables derivadas. La funcionalidad añadida es puramente aditiva y no rompe firmas.

### 4. Suite de pruebas (`tests/test-detect-stack.sh`)
- Nueva suite unitaria determinista que cubre:
  1. **Bucle nominal**: verificación de clasificación declarativa de los 11 stacks soportados con sus marcadores canónicos.
  2. **Escenario nominal con PATH**: lockfile y binario coincidentes (`bun.lock` + `bun` en PATH).
  3. **Escenario lockfile huérfano**: `bun.lock` presente en el proyecto pero sin binario `bun` en `$PATH` ➔ fallback limpio a `npm` con emisión de `⚠️  DIVERGENCE` a `stderr` y preservación de `AGENT_OS_STACK=bun`.
  4. **Escenario múltiples lockfiles**: presencia de `pnpm-lock.yaml` y `package-lock.json` con resolución priorizada según PATH.
  5. **Escenario sin lockfile**: proyecto con `package.json` estándar sin lockfiles, asignando el primer PM disponible en `$PATH`.

### 5. Suite de Control Plane (`tests/validate-control-plane.sh`)
- Se ejecuta exclusivamente como verificación de no-regresión (12/12 PASS), sin modificar sus pruebas de control plane core.

## Caja de archivos
Archivos autorizados para modificación / creación:
- `docs/sprints/sprint-13-core.md` (actualizar estado a `🟡 En curso`)
- `.agents/tasks/task-086.md`
- `scripts/agent/lib/detect-stack.sh`
- `tests/test-detect-stack.sh` (nueva suite unitaria de regresión)

## Criterios de done
- [x] `scripts/agent/lib/detect-stack.sh` exporta `AGENT_OS_PACKAGE_MANAGER`, `AGENT_OS_DETECTED_LOCKFILE` y preserva `AGENT_OS_STACK`.
- [x] Resolución en PATH verificada con `command -v` antes de asignar el gestor ejecutable.
- [x] Divergencia lockfile-vs-PATH emite aviso formal en `stderr` (`⚠️  DIVERGENCE:...`) con fallback ordenado a `npm` (u otro PM en PATH).
- [x] Salida estándar `stdout` permanece 100% limpia de mensajes de divergencia.
- [x] Bucle nominal de los 11 stacks soportados verificado en `tests/test-detect-stack.sh`.
- [x] 4 escenarios de prueba de divergencia / lockfiles huérfanos implementados y pasando en `tests/test-detect-stack.sh`.
- [x] Consumidores (`install.sh`, `inventory-check.sh`, `generate-digest.sh`, `audit-repo.sh`) verificados sin roturas de interfaz.
- [x] `tests/validate-control-plane.sh` pasa 12/12 sin regresiones en el core.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-29T23:47:19+01:00 (APROBADO CON CAMBIOS)
- [x] Rama creada: feat/T-086-defensive-stack-detection
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
