# Task-179: Soporte declarativo de servidores MCP remotos HTTP/SSE en Fleet

## Objetivo
Ampliar el esquema declarativo de la flota en `.agents/config/fleet.example.yaml` y `.agents/config/fleet.yaml` para permitir la especificación y diagnóstico de servidores Model Context Protocol (MCP) remotos con transporte HTTP streamable o SSE (`url`, `headers`, `transport`), adaptando la sonda determinista `scripts/agent/fleet-doctor.sh` para verificar su disponibilidad sin fugar credenciales.

## Contexto técnico
El estándar de flota de Agent OS soportaba únicamente servidores MCP locales basados en entrada/salida estándar (`stdio`), definidos por `command`, `args` y `env`. Los nuevos estándares de MCP y herramientas externas (como DeepWiki o pasarelas agénticas) operan como servicios HTTP remotos sin necesidad de instalar o empaquetar binarios pesados en local.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 32 / 2026-11-10
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Ampliar la sección `mcpServers` en `.agents/config/fleet.example.yaml` para documentar la estructura de servidores remotos: campo `url` (obligatorio para remotos), `transport` (`http` por defecto, o `sse`), y mapa opcional `headers` con soporte de inyección referencial de secretos.
  - Adaptar `scripts/agent/fleet-doctor.sh` para sondear la conectividad básica de servidores MCP remotos vía `curl` determinista (con timeout corto de máx 3s), clasificándolos como disponibles o degradados sin exponer claves o headers confidenciales.
  - Asegurar retrocompatibilidad 100% con los servidores `stdio` existentes.
  - Verificar que Check 1 y Check 12 de `tests/validate-control-plane.sh` validen el nuevo esquema sin regresiones.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/config/fleet.example.yaml`
- `scripts/agent/fleet-doctor.sh`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-179.md`

## Criterios de done
- [x] Esquema de `.agents/config/fleet.example.yaml` ampliado y documentado con soporte de servidores MCP remotos HTTP/SSE (`url`, `transport`, `headers`).
- [x] `scripts/agent/fleet-doctor.sh` incluye sonda determinista para verificar conectividad de servidores MCP remotos con fail-soft y sin fugar credenciales.
- [x] Servidores MCP `stdio` preexistentes continúan funcionando sin ninguna alteración.
- [x] Suite de pruebas `tests/validate-control-plane.sh` 38/38 en verde.
- [x] `locator-hygiene.sh` 100% limpio.

## Estado de aprobación y deliberación
> Este bloque lo rellena el agente durante /session-start y cierre de tarea.
> No modificar manualmente.

- [x] Deliberación técnica completada (`deliberate-plan.sh`)
  - **Veredicto del revisor**: `CONSENSO`
  - **Rol del revisor**: Compuerta técnica determinista (caja de archivos, tests, realidad repo, fidelidad a diseño macro).
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-11-10T19:04:15Z (Opción D - Desatendida, Aprobado en Planning Sprint 32)
- [x] Rama creada: feat/T-179-soporte-declarativo-mcp-remotos-fleet
- [x] Lock activo: .agent-session.lock
- [ ] Sesión cerrada correctamente
