# Task-068: Saneamiento definitivo de Homepage en producción

## Objetivo
Eliminar las tarjetas DOWN ficticias y los 401 de la Homepage en producción: quitar/condicionar dominios placeholder `*.example.com`, pingear FreeLLMAPI en `/health` (o con Bearer), y parametrizar el estado de Ollama según respuesta real.

## Contexto técnico
Fallo estructural #1 (sesiones recientes): la Homepage mostraba widgets inexistentes, 401 en inferencia y tarjetas DOWN por dominios ficticios (`infisical.example.com`, `bytebox.example.com`, `coolify.example.com` en `services.yaml`), lo que provocó bucles de ensayo-error en los agentes. Diagnóstico de campo: FreeLLMAPI :3001 responde HTTP 200 en `/` y `/health` pero 401 en `/v1/models` sin `Authorization: Bearer`; Ollama :11434 está caído en datamanager (el widget miente en verde o en rojo según el ping). Trade-off aceptado: ping a `/health` no muestra nº de modelos pero da un estado verídico sin credenciales en el ping simple.

## Caja de archivos
Archivos autorizados para modificación:
- `templates/homepage/`
- `scripts/agent/generate-homepage-config.sh`
- `docs/runbooks/coolify-homepage.md` (si existe; si no, crear)

## Criterios de done
- [ ] Ningún dominio `*.example.com` aparece como tarjeta DOWN en producción: placeholders eliminados o condicionados (solo visibles si están configurados).
- [ ] Widget FreeLLMAPI en verde verídico: ping a `/health`, o `Authorization: Bearer {{HOMEPAGE_VAR_FREELLMAPI_KEY}}` si se consulta `/v1/models`.
- [ ] Widget Ollama refleja estado real: parametrizado/condicional si :11434 no responde (no inventa estado).
- [ ] Verificado con `fleet-doctor.sh` (T-067): el digest confirma cada endpoint antes y después del cambio.
- [ ] `generate-homepage-config.sh` sigue sin IPs hardcodeadas (parsea `fleet.yaml`/`fleet.example.yaml`).

## Estado de aprobación
> Este bloque lo rellena el agente durante /session-start.
> No modificar manualmente.

- [ ] Plan presentado al usuario (Fase 3.5)
- [ ] APROBADO recibido — fecha/hora: ___
- [ ] Rama creada: ___
- [ ] Lock activo: ___
- [ ] Sesión cerrada correctamente
