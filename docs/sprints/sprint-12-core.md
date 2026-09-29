# Sprint 12 — Core Hardening, Gobernanza & Pilotaje Portable

**Período**: 2026-09-30 → 2026-10-10  
**Objetivo**: Culminar la purga residual de infraestructura personal en workflows, skills y templates (T-080), blindar la portabilidad de shell y el contrato de sync (T-081), resolver inconsistencias de gobernanza y precedencia de perfiles (T-082), estandarizar la interfaz CLI `--help` y normalizar skills (T-083), y ejecutar el pilotaje real de validación en un repositorio satélite externo `romensuarez-web` (T-084).

---

## Estado
🟡 En curso

---

## Tareas del Sprint

| ID | Descripción | Categoría | Tamaño | Estado | Dependencias | Task file |
| :--- | :--- | :---: | :---: | :---: | :--- | :--- |
| T-080 | Purga extendida de infraestructura personal en Workflows, Skills, Scripts y Templates | Universalización / Core | M | 🟢 Done | — | `.agents/tasks/task-080.md` |
| T-081 | Portabilidad Shell, Robustez CLI y Validación de Sincronización en `sync.sh` | Bug del sistema / DX | S | 🟢 Done | — | `.agents/tasks/task-081.md` |
| T-082 | Coherencia de Gobernanza, Resolución de Contradicciones y Precedencia de Perfiles | Gobernanza / Core Standard | M | ⬜ Pendiente | — | `.agents/tasks/task-082.md` |
| T-083 | Estandarización de Interfaz CLI (`--help` en 15 scripts) y Normalización de Skills | DX / Universalización | M | ⬜ Pendiente | — | `.agents/tasks/task-083.md` |
| T-084 | Pilotaje del core portable en repo real (`romensuarez-web`) | Validación Externa / DX | S | ⬜ Pendiente | T-080, T-081 | `.agents/tasks/task-084.md` |

---

## Requisitos de Implementación y Restricciones Arquitectónicas

1. **Cero referencias personales en el Core**: Ni rutas locales (`/home/romen`, `/Users`), hostnames privados (`oracle`, `datamanager`, `inteligencia-colectiva`) ni endpoints de producción en ficheros versionados del core.
2. **Decisiones de Arquitectura Confirmadas**:
   - `config/agent-registry.yaml` pasa a ser plantilla agnóstica con placeholders.
   - `discover-fleet.sh` mantiene peers Tailscale como paso manual documentado.
   - `ops-auditor.yaml` declara scope explícito ("Linux/Docker").
   - `AGENT_ONBOARDING.md` integra mapa de fases para las 4 reglas de auditoría.
   - `.env` mantiene fricción explícita en onboarding (delegando en Infisical).
   - `.agents/workflows/changelog.md` se renombra a `changelog-workflow.md` para evitar colisión case-insensitive.
   - `install.sh`/`sync.sh` mantienen aborto ruidoso con `set -euo pipefail` sin `nullglob`.
3. **Validación Continua**: Cada tarea debe superar `tests/validate-control-plane.sh` (12/12) y mantener working trees limpios.
4. **Pilotaje Externo (T-084)**: El subagente limpio debe operar de forma autónoma sobre `romensuarez-web` sin alucinaciones ni improvisaciones.

---

## Criterios de cierre del sprint

- [ ] Las 5 tareas completadas con sus criterios verificados.
- [ ] `tests/validate-control-plane.sh` 12/12 sin regresiones.
- [ ] `grep -rn "/home/romen" .agents/ templates/ scripts/` → 0 ocurrencias.
- [ ] T-084 en verde: pilotaje en repositorio real completado con éxito.
- [ ] `docs/external-inbox/triaje-post-sprint-11.md` archivado al cierre del sprint.
- [ ] `changelog.md` y `roadmap.md` actualizados atómicamente.
