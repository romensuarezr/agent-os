# Task-024: Detección automática de actualizaciones del core en check-session.sh

## Objetivo
Implementar un mecanismo de detección de actualizaciones de Agent OS remoto al inicio del script `check-session.sh` de los proyectos hijos, ofreciendo sincronización automática interactiva y previniendo bloqueos por falta de conexión.

## Contexto técnico
- Los proyectos hijos consumen reglas, skills y workflows del core a través de `sync.sh`.
- Se requiere consultar `git ls-remote` (con timeout de 3s) del core remoto y compararlo con el commit actual registrado localmente en `.agents/context/agent-os-changelog.md` o revisar si han pasado más de 7 días desde la fecha en `.agents/context/last-sync.md`.
- Si se detecta que se está ejecutando dentro del propio repositorio core de `agent-os`, la comprobación debe omitirse automáticamente.
- El comportamiento estándar posterior de `check-session.sh` no debe verse alterado.
- 📚 Research integrado (ver docs/sprints/sprint-03-core-research.md): Usar Opción A (timeout + subshell de 3s para consulta de red) combinada con comprobación local de caché en `.agents/context/last-sync.md` (evitando consultar más de una vez por hora o si no es necesario).

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/check-session.sh`

## Criterios de done
- [x] Omitir la comprobación automáticamente si se detecta que el script se está ejecutando en el propio repositorio core.
- [x] Implementar la lectura de `.agents/context/last-sync.md` y `.agents/context/agent-os-changelog.md`.
- [x] Consultar el último commit del core remoto con `git ls-remote` aplicando un timeout estricto de 3 segundos y manejando fallos silenciosamente.
- [x] Si hay diferencias de commits o la fecha en `last-sync.md` supera los 7 días de antigüedad:
  - Mostrar resumen de cambios si está disponible.
  - Ofrecer al operador actualizar de forma interactiva (sync / skip).
  - Ejecutar `sync.sh` si se selecciona "sync".
  - Registrar "skipped: FECHA" en `last-sync.md` si se selecciona "skip".
- [x] Validar que con la red desconectada el script continúe su flujo normal en menos de 4 segundos sin generar errores fatales.
- [x] Compilación/Verificación sin errores.

## Estado de aprobación
- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-06-17T14:19:46+01:00
- [x] Rama creada: feat/T-024-check-session-core-updates-detection
- [x] Lock activo: .agent-session.lock
- [x] Sesión cerrada correctamente
