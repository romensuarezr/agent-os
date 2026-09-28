# Task-079: Prueba ciega 0-contexto — criterio de aceptación del sprint

## Objetivo
Demostrar con un test ciego que un agente arrancando con 0 contexto opera este repo sin alucinar ni reinventar. **Si la prueba ciega falla, el sprint no cierra**: cada fallo genera su fix antes del cierre.

## Contexto técnico
Tesis del sprint: los dos fallos estructurales de gobernanza (alucinación en Homepage, bootstrapping improvisado) nacen de la misma raíz — el agente no encontró determinísticamente lo que ya existía. Las T-067 a T-078 construyen la cura; esta tarea la verifica de forma ciega y la deja protocolizada para futuros sprints.

## Caja de archivos
Archivos autorizados para modificación:
- `docs/runbooks/prueba-ciega.md` (nuevo — el protocolo, reutilizable cada sprint)
- Fixes puntuales donde el test encuentre fallos (caja abierta; cada fix justificado en el PR)

## Protocolo mínimo (criterios de done)
- [ ] El sujeto recibe **únicamente** la ruta/URL del repo. Cero contexto previo, cero pistas.
- [ ] Debe completar sin ayuda: 1) leer `.agents/AGENT_ONBOARDING.md` y ejecutar la secuencia de boot; 2) `check-session.sh`; 3) localizar por nombre 1 skill, 1 workflow, 1 regla global y 1 script; 4) `install.sh --check` en un repo vacío; 5) `fleet-doctor.sh`; 6) depositar una idea en el inbox canónico.
- [ ] **0 alucinaciones**: ninguna referencia en su transcript a archivos, skills, comandos o endpoints inexistentes (verificación por `grep` del transcript contra el árbol real).
- [ ] **0 improvisaciones**: no crea scripts ad-hoc, no inventa widgets, no escribe fuera de la caja autorizada.
- [ ] Cada fallo detectado se corrige en el repo y el test se repite hasta pasar limpio.
- [ ] Resultado registrado en `docs/runbooks/prueba-ciega.md`: fecha, pasos ejecutados, evidencias y veredicto.

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
