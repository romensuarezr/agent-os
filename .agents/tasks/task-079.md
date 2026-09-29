# Task-079: Prueba ciega 0-contexto — criterio de aceptación del sprint

## Objetivo
Demostrar con un test ciego que un agente arrancando con 0 contexto opera este repo sin alucinar ni reinventar. **Si la prueba ciega falla, el sprint no cierra**: cada fallo genera su fix antes del cierre.

## Contexto técnico
Tesis del sprint: los dos fallos estructurales de gobernanza (alucinación en Homepage, bootstrapping improvisado) nacen de la misma raíz — el agente no encontró determinísticamente lo que ya existía. Las T-067 a T-078 construyen la cura; esta tarea la verifica de forma ciega y la deja protocolizada para futuros sprints.

## Caja de archivos
Archivos autorizados para modificación:
- `docs/runbooks/prueba-ciega.md` (nuevo — el protocolo, reutilizable cada sprint)
- `.agents/tasks/task-079.md`
- `docs/sprints/sprint-11-core.md`
- Fixes puntuales donde el test encuentre fallos (caja abierta con justificación y evidencia)

## Protocolo mínimo (criterios de done)
- [x] El sujeto (subagente limpio) recibe **únicamente** la ruta del repo y la misión genérica ("arranca como agente de este repo con cero contexto y averigua cómo funcionar"). Cero pistas de hitos o nombres preexistentes.
- [x] Rúbrica de evaluación sobre las acciones y salidas del subagente limpio:
  1) Lectura de `.agents/AGENT_ONBOARDING.md` y ejecución de pre-flights deterministas.
  2) `check-session.sh` ejecutado sin error.
  3) Localización por catálogo de 1 skill, 1 workflow, 1 regla global y 1 script sin alucinar.
  4) Instalación REAL con `install.sh` sobre repo hijo efímero (verificando en el hijo: `AGENT_ONBOARDING.md`, `check-session.sh` funcional e inboxes canónicos `idea-inbox/` y `external-inbox/`).
  5) `fleet-doctor.sh` ejecutado determinísticamente con SKIP seguro.
  6) Depósito de artefacto de prueba en `docs/idea-inbox/` y posterior eliminación inmediata con evidencia higiénica de ambas operaciones.
- [x] **0 alucinaciones**: ninguna referencia en su transcript a archivos, skills, comandos o endpoints inexistentes.
- [x] **0 improvisaciones**: no crea scripts ad-hoc, no inventa widgets, no escribe fuera de la caja autorizada.
- [x] Cada fallo detectado se corrige en el repo y el test se repite hasta pasar limpio (0 fallos detectados en ejecución).
- [x] Resultado registrado en `docs/runbooks/prueba-ciega.md`: fecha, pasos ejecutados, transcripción verbatim de evidencias y veredicto PASS/FAIL.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [x] Plan presentado al usuario (Fase 3.5)
- [x] APROBADO recibido — fecha/hora: 2026-09-29T20:00:56+01:00 (APROBADO CON CAMBIOS)
- [x] Rama creada: feat/T-079-zero-context-blind-test
- [x] Lock activo: .agent-session.lock
- [ ] Sesión cerrada correctamente
