# Idea: Portabilidad de copias no destructivas (`cp -n` vs `--update=none`) — 2026-09-30

**Prioridad:** Baja / Calidad (Candidata Sprint 14 / Universalización)

**Problema:**
En sistemas Linux con versiones recientes de GNU coreutils (v9.3+), la opción `-n` emite warnings en stderr:
`cp: warning: behavior of -n is non-portable and may change in future; use --update=none instead`
Sin embargo, en macOS (BSD cp), `--update=none` no existe y `-n` es la sintaxis nativa soportada.

**Propuesta:**
1. Crear una función helper portable en `scripts/agent/lib/portable-fs.sh`:
   `portable_cp_no_clobber src dest`
   que evalúe si `cp --help` soporta `--update=none` y utilice la opción óptima para el runtime detectado sin contaminar stderr con advertencias.

**Origen:**
Hallazgo empírico durante la prueba ciega de T-090 con sujeto real en `/tmp/agent-os-blind-subject`.
