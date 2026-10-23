# Task-110: Wrapper portable de copias no destructivas

## Objetivo
Crear `lib/portable-fs.sh` con `agent_cp_n` (usa `--update=none` si el `cp` lo soporta, cae a `-n`
en macOS/BSD) y aplicarlo en las **11** copias no destructivas de `install.sh` (8 `cp -n` + 3 `cp -rn`).
Elimina los warnings de GNU coreutils ≥9.3 sin romper macOS. Ampliación aprobada: los `-rn` también
avisan en 9.4 y son el camino más usado (skills y `lib/`); un único wrapper con flags reenviados.

## Contexto técnico
Precedente exacto a replicar: `lib/portable-timeout.sh`. `install.sh` es el único script del core
con copias no destructivas: 8 `cp -n` (559/569/623/636/647/666/683/712) y 3 `cp -rn`
(619/633/651). Detección por sonda sin escrituras (`cp --update=none --version`), sin dependencias
nuevas, portable Linux/macOS como todo el core.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/lib/portable-fs.sh` (nuevo)
- `scripts/agent/install.sh` (11 líneas: 8 `cp -n` + 3 `cp -rn` → `-r`, y el `source` de la lib)
- `tests/validate-control-plane.sh` (check 28 + renumeración `/27` → `/28`)

## Criterios de done
- [ ] `agent_cp_n` detecta soporte `--update=none` y cae a `-n` si no existe
- [x] Las 11 copias de `install.sh` migran al wrapper; 0 `cp -n`/`cp -rn` directos
- [x] Suite **28/28** con check 28; instalación de prueba en `mktemp` con stderr capturado = 0 warnings
- [x] Comportamiento idéntico en macOS (por diseño: sonda falla → rama `-n` nativa)

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO — 2026-10-23 (A: incluir 3 `-rn`; B: `agent_cp_n` con flags reenviados; C: check 28 + smoke install)
- [x] Rama creada: `feat/T-110-portable-cp-n` (desde `multi-agent` @ e3b7bea)
- [x] Lock activo: `.agent-session.lock`
- [ ] Sesión cerrada correctamente
