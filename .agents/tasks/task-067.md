# Task-067: fleet-doctor.sh — diagnóstico determinista de flota + Check 12 condicional

## Objetivo
Crear `scripts/agent/fleet-doctor.sh`: un script CLI determinista (0 tokens de inferencia) que audite el tooling local, la autenticación real y la conectividad viva de la flota, e integrarlo en `tests/validate-control-plane.sh` como Check 12 **condicional** (SKIP si no hay `fleet.yaml`, nunca FAIL).

## Contexto técnico
Batería de campo 2026-09-28: `gh` OK (romensuarezr, scopes repo/workflow); Infisical CLI v0.43.137 sin subcomando `status` y sin login profiles; FreeLLMAPI :3001 TCP OK pero 401 en `/v1/models` sin Bearer; Ollama :11434 caído en datamanager; OmniRoute :20128 OK; `validate-control-plane.sh` 11/11 pero solo valida sintaxis YAML, no realidad. `scout.sh "fleet doctor"` no encontró OSS que cubra la topología (Tailscale + perfiles declarativos): desarrollo a medida justificado, Bash + `nc`/`curl`/`python3`, 0 dependencias externas.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/fleet-doctor.sh` (nuevo)
- `tests/validate-control-plane.sh`
- `config/fleet.example.yaml`
- `docs/runbooks/fleet-doctor.md` (nuevo)

## Criterios de done
- [x] `fleet-doctor.sh --help` documenta uso y flags (`--json` para orquestadores).
- [x] Valida: CLIs presentes (git, gh, docker, infisical, tailscale), auth funcional (`gh auth status`, login profiles de infisical), conectividad TCP/HTTP con timeout estricto 2s por endpoint.
- [x] Lee endpoints de `config/fleet.yaml` si existe; si no, usa `config/fleet.example.yaml` en modo documentación (marca cada check como `SKIPPED-NO-FLEET`, no como fallo).
- [x] Check 12 en `validate-control-plane.sh`: pasa 12/12 con fleet.yaml, 11/12 + 1 SKIP sin él. Ningún secreto se imprime en el digest (tokens enmascarados).
- [x] `docs/runbooks/fleet-doctor.md` con ejemplos de salida y tabla de códigos de salida.
- [x] 0 rutas `/home/romen`, 0 IPs privadas commiteadas: lo personal solo en `fleet.yaml` (gitignored).

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-28T14:07:50+01:00 (APROBADO CON CAMBIOS)
- [x] Rama creada: feat/T-067-fleet-doctor
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
