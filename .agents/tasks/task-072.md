# Task-072: Purga de infraestructura personal en scripts y config

## Objetivo
Cero rutas personales y cero IPs/hostnames privados commiteados en `scripts/` y `config/`. La flota del autor vive únicamente en `config/fleet.yaml` (gitignored, overlay local); el core solo lleva `config/fleet.example.yaml` limpio y documentado.

## Contexto técnico
Auditoría 2026-09-28 (hallazgos A1–A4): 18 ocurrencias de `/home/romen/...` en `scripts/` — `contribute.sh:10` (sin override posible), `check-session.sh` (7 refs), `scripts/ops/coolify.sh:28`, `audit-orca.sh:13,104`, `orca-orchestrate.sh:35-36`. `config/routing-policy.yaml` y `config/agent-registry.yaml` commitean `100.77.82.13` (datamanager) sin variante `.example`. `config/fleet.example.yaml` contiene datos personales filtrados y no documenta la convención de hosts que el sistema espera. T-069 ya cubre `install.sh`/`sync.sh`; esta tarea cubre el resto.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/contribute.sh`
- `scripts/agent/check-session.sh`
- `scripts/ops/coolify.sh`
- `scripts/agent/audit-orca.sh`
- `scripts/agent/orca-orchestrate.sh`
- `scripts/agent/discover-fleet.sh`
- `config/routing-policy.yaml`
- `config/agent-registry.yaml`
- `config/fleet.example.yaml`
- `.gitignore`

## Criterios de done
- [x] `grep -rn "/home/romen" scripts/` devuelve 0 resultados. Donde una ruta por defecto sea necesaria, se resuelve dinámicamente o vía variable de entorno documentada (nunca default personal).
- [x] `grep -rEn "100\.[0-9]+\.[0-9]+\.[0-9]+" config/` devuelve 0 resultados, y el barrido extendido sobre `scripts/` y `.agents/` también devuelve 0 (salvo notas históricas de contexto). `fleet.example.yaml` usa rangos RFC 5737 (`192.0.2.x`) y documenta la convención de hosts (datamanager, oracle, local).
- [x] `config/fleet.yaml` añadido a `.gitignore`; `routing-policy.yaml` referencia endpoints vía variables de entorno con fallback local y documenta el mecanismo de resolución.
- [x] `tests/validate-control-plane.sh` en verde tras los cambios (12/12 OK).

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-28T17:07:40+01:00 (APROBADO CON CAMBIOS)
- [x] Rama creada: feat/T-072-purge-personal-infra
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
