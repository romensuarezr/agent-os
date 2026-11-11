# Task-195: Desbloqueo y rotación de credenciales (Cloudflare API Token / Infisical)

## Objetivo
Resolver el bloqueo prioritario registrado en el `roadmap.md`, acordando y delimitando el alcance de `CLOUDFLARE_API_TOKEN` (alcance transversal para la cuenta vs. tokens acotados por zona DNS) y ejecutando el saneamiento y rotación de las 15 credenciales revocadas detectadas en la bóveda de Infisical, actualizando el catálogo declarativo y validando con las herramientas de inspección determinista de secretos a $0 tokens.

## Contexto técnico
- En `roadmap.md` figura como bloqueo de alta prioridad: "Rotar las 15 credenciales revocadas detectadas en la bóveda; requiere decidir si CLOUDFLARE_API_TOKEN es transversal o un token por zona. ⛔ BLOQUEADO hasta el veredicto del usuario".
- Se requiere acotar el alcance técnico de la credencial de Cloudflare, actualizar las referencias en `.agents/config/secrets-catalog.yaml` y verificar la salud de la bóveda mediante `scripts/agent/secrets.sh` y `scripts/agent/secret-locate.sh` sin filtrar ningún valor en logs ni en git.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 35 / 2026-11-11
- **Diseño y arquitectura aprobados por**: Humano (Operador soberano)
- **Decisiones e interfaces selladas**:
  - Delimitación del token de Cloudflare acordada: soporte para token transversal con permisos mínimos estrictos (Zone.DNS Edit / Read) o tokens específicos por zona declarados en `.agents/config/secrets-catalog.yaml`.
  - Rotación en Infisical inyectando valores exclusivamente por stdin mediante `scripts/agent/secrets.sh set` (prohibido pasar valores como argumentos CLI o en variables de entorno expuestas).
  - Actualización del catálogo `.agents/config/secrets-catalog.yaml` y validación con `scripts/agent/secret-locate.sh --search` y `verify-secrets.py`.
- **Veredicto de diseño macro**: APROBADO_EN_PLANNING

## Caja de archivos
Archivos autorizados para modificación:
- `.agents/config/secrets-catalog.yaml`
- `scripts/agent/secrets.sh`
- `scripts/agent/secret-locate.sh`
- `roadmap.md`
- `docs/sprints/sprint-35.md`

## Criterios de done
- [ ] Alcance de `CLOUDFLARE_API_TOKEN` delimitado formalmente en el catálogo y documentación.
- [ ] Catálogo `.agents/config/secrets-catalog.yaml` actualizado reflejando el estado de rotación de credenciales.
- [ ] Verificación determinista de secretos (`secret-locate.sh --search` y `verify-secrets.py`) ejecutada sin fugas de valores en salida ni git.
- [ ] Ítem del roadmap desbloqueado y marcado en progreso o resuelto.
- [ ] Suite `tests/validate-control-plane.sh` pasa 38/38 checks verdes.

## Estado de aprobación y deliberación
- [ ] Deliberación técnica completada (`deliberate-plan.sh`)
- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido en planning
- [ ] Rama de trabajo activa
- [ ] Lock activo: —
- [ ] Tarea cerrada y verificada
