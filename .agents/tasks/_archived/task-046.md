# Task-046: Script CLI determinista discover-fleet.sh para auto-descubrimiento y generación de fleet.yaml

## Objetivo
Desarrollar el script CLI determinista `scripts/agent/discover-fleet.sh` que audite y auto-descubra el entorno local (sistema operativo, gestores de paquetes, clientes CLI de IA, Docker, Tailscale, utilidades de terminal) y genere o enriquezca `config/fleet.yaml` a coste 0 de tokens de inferencia. El script debe operar en modo no destructivo por defecto (mostrando digest estructurado), requerir `--apply` para persistir cambios sin sobreescribir configuraciones manuales previas, y permitir la generación opcional de documentación humana en `docs/architecture/tools/local-environment.local.md`.

## Contexto técnico
En T-044 se desacopló la flota hacia `config/fleet.yaml` (ignorado en git) y `config/fleet.example.yaml`. En T-045 se formalizó el mandato de eficiencia ("Scripts locales primero para acciones deterministas").
Actualmente, si un usuario nuevo instala Agent OS o un desarrollador abre el entorno en un equipo diferente, debe rellenar manualmente `config/fleet.yaml`.
`discover-fleet.sh` resuelve esto inspeccionando deterministamente la máquina local (`PATH`, `~/.local/bin`, `which`, versiones) e integrando de manera modular los datos en `config/fleet.yaml` respetando cualquier clave previa de nodos remotos (`nodes`) o servidores MCP (`mcpServers`).

## Caja de archivos
Archivos autorizados para modificación:
- `docs/sprints/sprint-07-core.md`
- `.agents/tasks/task-046.md`
- `scripts/agent/discover-fleet.sh`
- `config/known-web-tools.yaml`
- `.agents/skills/tool-inventory/SKILL.md`
- `tests/validate-control-plane.sh`
- `config/fleet.yaml`
- `docs/architecture/tools/local-environment.local.md`
- `docs/architecture/tools/candidate-gateways.md`

## Criterios de done
- [x] Script ejecutable `scripts/agent/discover-fleet.sh` creado con permisos de ejecución (`chmod +x`).
- [x] Catálogo declarativo `config/known-web-tools.yaml` creado con firmas de herramientas web populares y gateways/routers (omniroute, omnirouter, portkey, litellm).
- [x] Descubrimiento dinámico de perfiles y cuentas de Antigravity: escaneo sin cablear de ejecutables `agy*` (`agy`, `agy2`, etc.) y detección de sus variables HOME/perfil.
- [x] Detección exhaustiva determinista: SO, gestores de paquetes (`apt`, `brew`, `npm`, `pip`, `cargo`), CLIs y escaneo seguro de marcadores de navegador (Chrome, Brave, Firefox con lista blanca + heurística de carpetas IA).
- [x] Modo no destructivo por defecto: si se ejecuta sin flags, emite un digest YAML compacto a stdout sin alterar archivos en disco.
- [x] Flag `--apply`: crea o actualiza `config/fleet.yaml`, registrando `antigravity_accounts` y preservando intactos los nodos remotos (`nodes`), servidores MCP (`mcpServers`) y configuraciones manuales existentes.
- [x] Flag `--docs`: genera informe legible por humanos en `docs/architecture/tools/local-environment.local.md` con visión unificada (CLIs locales, cuentas Antigravity, pasarelas de inferencia remotas como `freellmapi` y políticas activas de enrutamiento).
- [x] Prospección determinista pre-código de pasarelas y routers candidatos (OmniRoute, Portkey, LiteLLM) documentada en `docs/architecture/tools/candidate-gateways.md`.
- [x] Integración en `tests/validate-control-plane.sh` para verificar el correcto funcionamiento del auto-descubrimiento (6/6 tests pasando).
- [x] Referencia y ejemplos documentados en `.agents/skills/tool-inventory/SKILL.md`.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-25T11:24:00+01:00
- [x] Rama creada: feat/T-046-discover-fleet-cli
- [x] Lock activo: .agent-session.lock
- [ ] Sesión cerrada correctamente
