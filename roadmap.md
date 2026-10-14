# Roadmap — agent-os

## En curso
- (Sin sprint activo. Ejecuta /sprint-planning para abrir el siguiente.)

## Completado recientemente
- **Sprint 14**: Automejora y Confianza (T-091 a T-098)
  - [T-091] Regla de destilación y automejora procedimental (Self-Improvement Distillation) (M).
  - [T-092] Fix consistencia de secciones en `roadmap.md` y `audit-repo.sh` (HIGH) (S).
  - [T-093] Port de patrones estáticos de SkillSpector adaptado a `.agents/skills/` (M).
  - [T-094] Unificación de firma CLI con soporte `--path` en `audit-repo.sh` (S).
  - [T-095] Ciclo de vida de secretos: localizador, auditoría de bóveda, taxonomía, catálogo y materialización (L).
  - [T-096] Guidance operativo del working tree post-instalación en `install.sh` (S).
  - [T-097] Remediación inmediata y desbloqueo de Hermes en <nodo-inferencia> y <nodo-orquestacion> (M).
  - [T-098] Pre-flight de pasarelas de inferencia y formalización de la remediación (S).
- Sprint 13: Escalado, Distribución Universal del Core & Ciclo de Vida de Satélites (T-085 a T-090).
- Sprint 12: Core Hardening, Gobernanza & Pilotaje Portable (T-080 a T-084).
- Sprint 11: Core Hardening, Fleet Doctor & Descubrimiento 0-contexto (T-067 a T-079).
- Sprint 10: Homepage Fleet Observability, Perimetral Security & AI Telemetry (T-060 a T-065).
- Sprint 09: Multi-Agent Parallel Orchestration & Deterministic Goals Engine (T-054 a T-059).

## Próximo
- Automatizar la publicación de ramas de tarea (extender `promote-to-main.sh` con `--push-source`, `--merge-commit` y `--pr`); NO crear un script nuevo: ya cubre el 80% (idea de 2026-10-12).
- Mapa global de flujos de Agent OS con niveles de zoom C4, generado y versionado, para lectura humana y de agentes (idea de 2026-10-12).
- Rotar las 15 credenciales revocadas detectadas en la bóveda; requiere decidir si `CLOUDFLARE_API_TOKEN` es transversal o un token por zona.
- **FIXES de `close-*.sh`** — comparten patrón: el script afirma haber hecho algo que no hizo del todo y el flujo sigue como si nada.
  - `close-task.sh` archiva el task file pero **no actualiza el enlace de su fila** en el sprint file: roto en T-094, T-095, T-096 y T-098, parcheado a mano cuatro veces.
  - `close-sprint.sh` **commitea solo el rename**: `git mv` mueve la versión del índice, no la del working tree, así que las modificaciones sin stagear se quedan fuera del commit. Ocurrió en el cierre de sprint-14: el commit salió `0 insertions / 0 deletions` y las ediciones quedaron colgando. No debe abortar en silencio: o incluye los cambios, o falla diciendo por qué.
- Wrapper portable de copias no destructivas (`cp -n` vs `--update=none`) en `lib/portable-fs.sh` (S).
- Estandarización de variables de entorno y endpoints en `coolify-admin` / MCPs (S).
- Impeccable critique: protocolo de auditoría y revisión de interfaces UI para satélites (M).
- [T-043] Prospección periódica automatizada de herramientas Freemium / OSS para `tool-inventory` (S).
- Auditorías automáticas del estado de salud de los scripts en proyectos hijos.
- Refinamiento de workflows globales y estandarización de logs de ejecución.

## Descartado
- (Sin líneas descartadas por el momento)

## Deuda observada

- **`docs/architecture/control-plane-topology.md` incumple la política de
  `docs/critical-flows.md`.** El primero abre con un `[!IMPORTANT]` que prohíbe literales de
  infraestructura; el segundo está versionado en git desde `8b335c1` y contiene cuatro hostnames
  reales (`<host-local>`, `<nodo-inferencia>`, `<nodo-web>`, `<nodo-datos>`). Verificado en
  `HEAD`, `origin/main`, `origin/multi-agent` y `feat/sprint-11-core-planning`.
  **Detectado en T-102** (2026-10-13) al modelar el mapa de flujos. No se arregla aquí: el
  mapa se genera desde `critical-flows.md` y deliberadamente **no lee** ese fichero, así que no
  propaga los literales. Sanear el documento existente es trabajo aparte.
