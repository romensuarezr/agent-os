# Task-069: Blindaje de install.sh — ruta dinámica, pre-flights, --check y onboarding

## Objetivo
Que `install.sh` sea imposible de improvisar o de romper en otra máquina: ruta del core resuelta dinámicamente, pre-flights de autenticación, modo `--check` (dry-run), `set -euo pipefail`, e instalación de `.agents/AGENT_ONBOARDING.md` en el proyecto destino.

## Contexto técnico
Fallo estructural #2 (sesiones recientes): agentes creando satélites a mano (carpetas + commits) sin ejecutar `install.sh`, produciendo repos huérfanos sin reglas ni workflows; además fallos de auth con `gh`/Infisical descubiertos tarde. Auditoría 2026-09-28: `AGENT_OS_PATH="${AGENT_OS_PATH:-/home/romen/Proyectos/agent-os}"` (`install.sh:33`, también en `sync.sh:43`); sin `set -euo pipefail` una instalación parcial reporta "✅ completada"; 4 skills exigen `.agents/AGENT_ONBOARDING.md` pero ningún script lo instala. Depende de T-070 (la regla de gobernanza lo hace obligatorio) y T-071 (el contenido del onboarding).

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/install.sh`
- `scripts/agent/sync.sh` (solo: coherencia de no-destructividad — añadir `--dry-run` y aviso antes de sobrescribir personalizaciones locales)
- `README.md` (documentar `--check` y pre-flights)

## Criterios de done
- [x] 0 ocurrencias de `/home/romen` en `scripts/` (grep de verificación). Ruta resuelta desde `BASH_SOURCE[0]`; funciona en cualquier workspace/clone.
- [x] Pre-flights obligatorios: `git` presente (bloqueante), `gh auth status` antes de operaciones remotas (bloqueante si se va a crear repo), login de Infisical (advertencia, no bloqueante).
- [x] `--check`: describe exactamente qué se instalaría sin tocar el árbol de trabajo (exit 0 si todo OK).
- [x] `set -euo pipefail` en `install.sh` y `sync.sh`; un fallo a mitad deja error visible, nunca "✅ completada" parcial.
- [x] `install.sh` copia `.agents/AGENT_ONBOARDING.md` (plantilla de proyecto de T-071) al proyecto destino.
- [x] `sync.sh --dry-run` existe y `sync.sh` sin flags no sobrescribe personalizaciones locales sin aviso (coherencia con el `cp -n` de `install.sh` y el principio "no destructivo por defecto").
- [x] `sync.sh` propaga `templates/docs` y `templates/root` a proyectos hijos existentes (hoy solo llegan en instalaciones nuevas).

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-28T16:43:42+01:00 (APROBADO CON CAMBIOS)
- [x] Rama creada: feat/T-069-install-sync-hardening
- [x] Lock activo: .agent-session.lock
- [ ] Sesión cerrada correctamente
