# Task-110: Wrapper portable de copias no destructivas

## Objetivo
Crear `lib/portable-fs.sh` con `agent_cp_n` (usa `--update=none` si el `cp` lo soporta, cae a `-n`
en macOS/BSD) y aplicarlo en los 8 usos de `cp -n` de `install.sh`. Elimina los warnings de
GNU coreutils ≥9.3 sin romper macOS.

## Contexto técnico
Precedente exacto a replicar: `lib/portable-timeout.sh`. `install.sh` es el único script del core
con `cp -n` (8 ocurrencias, verificado). Detección en runtime, sin dependencias nuevas, portable
Linux/macOS como todo el core.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/lib/portable-fs.sh` (nuevo)
- `scripts/agent/install.sh` (solo las 8 líneas de `cp -n`)

## Criterios de done
- [ ] `agent_cp_n` detecta soporte `--update=none` y cae a `-n` si no existe
- [ ] Los 8 `cp -n` de `install.sh` migran al wrapper; 0 `cp -n` directos restantes
- [ ] Suite en verde; sin warnings en GNU coreutils; comportamiento idéntico en macOS
      (por diseño + inspección, el core no tiene CI en macOS)

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
