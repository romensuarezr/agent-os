# Task-075: Barrido de portabilidad shell (Linux + macOS)

## Objetivo
Todos los scripts de `scripts/` funcionan en Linux y macOS; cada script declara y comprueba sus dependencias al inicio con mensajes accionables.

## Contexto técnico
Auditoría 2026-09-28 (A6–A10, M1–M4): flags GNU que rompen en macOS — `grep -oP` (`close-task.sh:15`), `sed -i` con sintaxis GNU (`audit-repo.sh:224`), `date -d` (`audit-repo.sh:476`, `check-session.sh:45`), `date -Iseconds` (`discover-fleet.sh:331`); `discover-fleet.sh` escanea solo `/home/...` (en macOS los homes están en `/Users`); shebangs inconsistentes (16× `#!/bin/bash`, 10× `#!/usr/bin/env bash`); `import-secrets.sh` y `coolify.sh` usan `jq`/`curl` sin comprobar disponibilidad; `validate-control-plane.sh` asume PyYAML. Patrón a replicar: el chequeo de dependencias de `scout.sh`.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/*.sh`
- `scripts/agent/lib/*`
- `scripts/ops/*.sh`
- `tests/validate-control-plane.sh`

## Criterios de done
- [x] 0 usos de `grep -P`, `sed -i` sin sufijo portable, `date -d` / `date -I` sin rama por OS (verificado con `grep`; donde no haya alternativa POSIX, rama `uname` explícita).
- [x] `discover-fleet.sh` cubre `/home` y `/Users` (y respeta `$HOME` cuando aplique).
- [x] Shebang único `#!/usr/bin/env bash` en todos los scripts.
- [x] Cada script comprueba sus dependencias externas al inicio (`command -v jq || { mensaje con Guía: accionable; exit 1; }`), siguiendo el patrón de `scout.sh`.
- [x] `validate-control-plane.sh` comprueba PyYAML (o usa `python3 -c` con `json` como fallback) antes de asumirlo.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-28T15:32:13+01:00 (APROBADO CON CAMBIOS)
- [x] Rama creada: feat/T-075-shell-portability
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
