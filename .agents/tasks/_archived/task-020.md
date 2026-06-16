# Task-020: Redactar ADRs de las decisiones clave de arquitectura tomadas

## Objetivo
Documentar formalmente las decisiones arquitectónicas fundamentales del core de Agent OS (auto-hospedaje, detección universal de stack y ciclo de vida de sesión) para asegurar la trazabilidad del diseño y guiar futuras contribuciones.

## Contexto técnico
Tras el lanzamiento de la v1.2.0, el core se ha vuelto multi-stack y auto-hospedado. No existe documentación que explique los trade-offs de mantenerlo libre de dependencias npm, usar scripts bash portables y estructurar la concurrencia a través de `.agent-session.lock`. Documentar esto en `docs/adrs/` es clave para la mantenibilidad del ecosistema.

## Caja de archivos
Archivos autorizados para modificación:
- `docs/adrs/README.md`
- `docs/adrs/adr-001-self-hosting.md`
- `docs/adrs/adr-002-stack-detection.md`
- `docs/adrs/adr-003-session-lifecycle.md`

## Criterios de done
- [x] Crear el directorio `docs/adrs/` y el índice `docs/adrs/README.md` con la lista de registros de decisión arquitectónica.
- [x] Redactar `docs/adrs/adr-001-self-hosting.md` detallando la decisión de auto-hospedaje, la ausencia de dependencias externas (npm/pip) y el mecanismo `--self`.
- [x] Redactar `docs/adrs/adr-002-stack-detection.md` explicando el diseño desacoplado de detección de stack (`lib/detect-stack.sh`) y la personalización manual (`stack.env`).
- [x] Redactar `docs/adrs/adr-003-session-lifecycle.md` especificando la política de sesión única, el uso del archivo lock y la transición de estados en tareas.

## Estado de aprobación
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-06-16T12:56:47+01:00
- [x] Rama creada: feat/T-020-redactar-adrs
- [x] Lock activo: .agent-session.lock creado
- [x] Sesión cerrada correctamente

