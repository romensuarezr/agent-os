# T-099: Sincronización remota desde GitHub (--remote) en sync.sh y paridad en check-session.sh

**Estado:** ✅ Completada  
**Fecha:** 2026-10-12  
**Sprint:** Sprint 14 — Core  
**Asignado:** developer / coordinator  

---

## 🎯 Objetivo

Dotar a `scripts/agent/sync.sh` de capacidad para sincronizar proyectos satélites directamente desde el repositorio canónico en GitHub mediante el flag `--remote` (y fallback automático cuando no exista un clon local del core), resolviendo el fallo asimétrico en `scripts/agent/check-session.sh` (que avisa de actualizaciones remotas pero no podía ejecutarlas sin el core clonado en disco), y documentando la capacidad en la skill `agent-os-scripts`.

---

## 📋 Contexto Técnico

1. **Limitación actual de `sync.sh`**:
   `sync.sh` resuelve `AGENT_OS_PATH` hacia un directorio físico local. Si se ejecuta dentro de un satélite (`bash scripts/agent/sync.sh .`), `AGENT_OS_PATH` se resuelve al propio satélite, abortando con `ERROR: AGENT_OS_PATH y TARGET_PROJECT apuntan al mismo directorio`.
2. **Asimetría en `check-session.sh`**:
   `check-session.sh` consulta `git ls-remote https://github.com/romensuarezr/agent-os.git HEAD`. Cuando detecta novedades, ofrece al agente `¿Actualizar agent-os ahora? (sync / skip)`. Al responder `sync`, ejecuta `bash scripts/agent/sync.sh .`, que fallaba en cualquier entorno sin el core local clonado.
3. **Mecanismo de solución**:
   Inspirado en el aprovisionamiento efímero de `install.sh` (ADR 006):
   - Con `--remote`, `sync.sh` crea un directorio temporal aislado (`mktemp -d`), descarga efímeramente el tarball de GitHub (o clona con `--depth 1`), ejecuta la sincronización contra ese directorio y limpia deterministamente sus recursos mediante `trap EXIT`.
   - `check-session.sh` pasa `--remote` cuando invoca `sync.sh`.
   - Se actualiza la skill `agent-os-scripts` (`.agents/skills/agent-os-scripts/SKILL.md`) para que los agentes conozcan formalmente la capacidad de sincronización remota.

---

## 📦 Caja de Archivos

- `scripts/agent/sync.sh`
- `scripts/agent/check-session.sh`
- `.agents/skills/agent-os-scripts/SKILL.md`
- `docs/sprints/sprint-14-core.md`
- `changelog.md`

---

## 🧪 Criterios de Aceptación (DoD)

- [x] `sync.sh` soporta `--remote` (y `--tag=<tag>` / `--branch=<branch>` opcional) descargando efímeramente el core desde GitHub.
- [x] `sync.sh --remote --dry-run` permite simular sincronización remota sin escrituras permanentes fuera del directorio temporal.
- [x] Si `sync.sh` se ejecuta en un satélite sin `AGENT_OS_PATH` configurado y sin el core clonado, sugiere o activa el modo `--remote` con un mensaje claro.
- [x] `check-session.sh` invoca `sync.sh --remote .` en satélites de forma compatible.
- [x] `.agents/skills/agent-os-scripts/SKILL.md` documenta la opción `--remote` y el ciclo de vida de actualización remota.
- [x] Limpieza estricta de temporales mediante `trap` (cero fugas de carpetas en `/tmp`).
- [x] `tests/validate-control-plane.sh` pasa al 100% (13/13).
- [x] `changelog.md` actualizado con la nueva funcionalidad.
