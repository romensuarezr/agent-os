# Task-123: Hardening del subsistema de deliberación y digests

## Objetivo
Consolidar la robustez operativa de las herramientas introducidas en Sprint 20: implementar derivación real de fuentes de claves en `design-digest.sh` (evitando passthrough silencioso en ausencia de catálogo ambiental), actualizar la documentación de arquitectura en `AGENTS.md`, incorporar una sonda config-driven (warn-only) en `fleet-doctor.sh` para el endpoint del revisor, blindar el contexto efímero en `.gitignore` con soporte opcional de histórico crudo redactado por tarea, y añadir un test de regresión en el Check 34 que verifique la redacción derivada sin depender de catálogos ambientales ni fixtures.

## Contexto técnico y alcance
Tras la implementación de T-119 a T-122, se han identificado las siguientes necesidades de endurecimiento y completitud operativa:

1. **Fuente de claves real en `scripts/agent/design-digest.sh`**:
   - Derivar NOMBRES de claves (nunca valores) desde:
     - Variables declaradas en la tarea activa.
     - Nombres en archivos `.env` o `.env.*` si existen en el repo.
     - Parámetros explícitos o autodescubiertos.
   - Pasar estas claves a `lib/redact.sh` para que la redacción obligatoria funcione de forma determinista aun en un clon limpio sin catálogo ambiental `.agents/config/secrets-catalog.yaml`.
   - **Regla estricta de seguridad**: PROHIBIDO terminantemente el uso de `source` o `eval` sobre `.env`. El parseo de nombres debe realizarse exclusivamente con herramientas seguras (`grep`/`sed`/`awk`).

2. **Higiene arquitectónica en `AGENTS.md`**:
   - Registrar `deliberate-plan.sh` y `design-digest.sh` en el árbol de estructura de directorios de `scripts/agent/`.
   - Registrar e indexar ambos scripts en la sección de herramientas CLI operativas del core (creando o completando la tabla canónica si falta).

3. **Sonda config-driven (warn-only) en `scripts/agent/fleet-doctor.sh`**:
   - Diagnosticar el endpoint configurado para el revisor de inferencia (`INFERENCE_BASE_URL` o configuración en `routing-policy.yaml` / `fleet.yaml`).
   - Emitir estado `OK` si responde o `WARN: Revisor offline o no configurado (fallback SIN_REVISOR disponible)`.
   - **Comportamiento warn-only**: nunca provocar error de salida (exit > 0) en diagnósticos regulares de `fleet-doctor.sh` cuando el revisor no esté disponible, respetando la resiliencia del core.

4. **Higiene en `.gitignore` e histórico crudo**:
   - Añadir a `.gitignore` las rutas efímeras de contexto de trabajo:
     - `.agents/context/plan-draft.md`
     - `.agents/context/plan-deliberation.json`
   - Implementar el archivado del JSON crudo redactado de la deliberación junto con el digest en `docs/sprints/design-decisions/${TASK_ID}-raw.json`, implementado íntegramente dentro de `design-digest.sh` (sin mutar `close-task.sh`).

5. **Test de regresión en `tests/validate-control-plane.sh`**:
   - Extender el Check 34 para verificar que `design-digest.sh` redacta secretos derivados del contenido SIN catálogo ambiental y SIN necesidad de inyectar variables de fixture como `AGENT_OS_SECRETS_CATALOG`.

## Skills relevantes
- `agent-os-scripts`: Robustez en bash, observancia de estándares POSIX, parsers seguros sin eval/source y diagnósticos en `fleet-doctor.sh`.
- `infisical-secrets`: Manejo seguro de nombres de secretos, prevención de fugas y redacción obligatoria vía `lib/redact.sh`.
- `doc-maintainer`: Mantenimiento y consistencia de la documentación técnica en `AGENTS.md`.

## Caja de archivos
Archivos autorizados para modificación:
- `scripts/agent/design-digest.sh`
- `AGENTS.md`
- `scripts/agent/fleet-doctor.sh`
- `.gitignore`
- `.agents/tasks/task-123.md`
- `tests/validate-control-plane.sh`

> [!CAUTION]
> **Fuera de caja**: `close-task.sh` y cualquier otro archivo no listado arriba. Cualquier defecto detectado fuera de esta caja debe ser registrado y reportado como tarea nueva en el backlog.

## Criterios de done
- [ ] `design-digest.sh` extrae nombres de claves de forma determinista (parseo seguro sin `eval`/`source`) y redacta con éxito sin catálogo ambiental.
- [ ] `AGENTS.md` incluye `deliberate-plan.sh` y `design-digest.sh` en la estructura de archivos y en las tablas/descripciones de scripts del core.
- [ ] `fleet-doctor.sh` incluye sonda config-driven para el revisor de inferencia en modo warn-only (nunca rompe exit code).
- [ ] `.gitignore` excluye `.agents/context/plan-draft.md` y `.agents/context/plan-deliberation.json`.
- [ ] `design-digest.sh` archiva opcionalmente el JSON crudo redactado si existe deliberación activa.
- [ ] Check 34 ampliado verifica la redacción autocontenida derivada de contenido sin catálogo ambiental ni fixtures forzados.
- [ ] Suite completa `tests/validate-control-plane.sh` pasando 34/34 checks exitosamente sin regresiones.
