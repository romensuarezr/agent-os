# Task-166: Plantilla de despliegue soberano de Nango en VPS, despliegue en vivo y runbook de integración

## Objetivo
Diseñar, formalizar y verificar la plantilla declarativa Docker Compose de Nango (`templates/nango/docker-compose.yml` y `templates/nango/.env.example`) validada contra el spec oficial self-hosted de Nango, desplegar en vivo el stack en el servidor de orquestación (<nodo-orquestacion>) verificando respuesta del health check real sin filtrar secretos, declarar el esquema en `.agents/config/fleet.example.yaml`, elaborar el runbook de administración `docs/runbooks/nango-oauth-service.md`, y añadir las validaciones como subchecks en `tests/validate-control-plane.sh` manteniendo el denominador inmutable en 38/38.

## Contexto técnico
Nango es la plataforma open-source de referencia (13.1k⭐) para la integración y gestión unificada de autenticación OAuth hacia APIs externas. Actualmente, la flota de Agent OS no cuenta con una pasarela centralizada de autenticación OAuth para herramientas y agentes.
Por mandato vinculante del Relé, esta tarea no se limita a crear plantillas y documentación, sino que exige el **despliegue en vivo obligatorio** en el VPS con verificación de endpoint de salud. Si el despliegue vivo resulta inviable, el sistema aborta de inmediato a humano (fail-closed); queda prohibido cerrar con solo la plantilla.
Esta tarea se ejecuta bajo el régimen estándar de **Opción D**.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 30 / 2026-11-03
- **Diseño y arquitectura aprobados por**: Relé (Veredicto APROBADO CON CAMBIOS con enmienda vinculante y reordenación macro en Sprint Planning Sprint 30)
- **Decisiones e interfaces selladas**:
  - **Secuencia y dependencias**: Pasa a ser la primera tarea ejecutada del Sprint 30, sin dependencia de T-165 (`Dependencias: —`).
  - Validar la composición contra la especificación oficial de Nango self-hosted antes de sellarla (no asumir ciegamente que server + postgres basten; verificar si requiere redis/workers, puertos oficiales y variables obligatorias; la versión del CLI npm no determina la imagen del servidor).
  - Crear `templates/nango/docker-compose.yml` conteniendo los servicios requeridos por el spec oficial con variables parametrizadas, volúmenes persistentes y límites de recursos estándar.
  - Crear `templates/nango/.env.example` con variables saneadas y documentación de configuración.
  - Registrar el esquema del servicio Nango en `.agents/config/fleet.example.yaml` bajo el nodo de orquestación usando únicamente placeholders.
  - Desplegar en vivo en el VPS de orquestación (<nodo-orquestacion>) y verificar que el health check real responde con éxito, registrando evidencia en el reporte sin exponer valores ni credenciales.
  - **Inviolabilidad de despliegue**: si el despliegue en vivo resulta inviable, se aborta inmediatamente a humano; no se permite cerrar la tarea con solo la plantilla.
  - Redactar el runbook operativo `docs/runbooks/nango-oauth-service.md` detallando despliegue en Coolify / Docker Compose, aprovisionamiento de secretos vía Infisical, rotación de claves de cifrado y consumo por agentes.
  - Incorporar validaciones como subchecks dentro de checks existentes en `tests/validate-control-plane.sh`, manteniendo el denominador rígidamente inmutable en **38/38** (0 errores).
  - Cero literales personales, IPs privadas o secretos trackeados en git (estricta frontera portable).
  - Régimen Opción D: avance desatendido en camino limpio ante veredicto `CONSENSO`.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `coolify-admin`: Gestión y despliegue de stacks Docker Compose y variables de entorno.
- `remote-admin`: Verificación y diagnóstico de contenedores remotos.
- `infisical-secrets`: Gestión segura e inyección de secretos (`NANGO_ENCRYPTION_KEY`, contraseñas de BD).

## Caja de archivos
- `templates/nango/docker-compose.yml`
- `templates/nango/.env.example`
- `docs/runbooks/nango-oauth-service.md`
- `.agents/config/fleet.example.yaml`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-166.md`

## Criterios de done
- [x] Composición Compose validada contra la especificación oficial de Nango self-hosted (servicios requeridos, imagen y puerto canónicos).
- [x] `templates/nango/docker-compose.yml` y `templates/nango/.env.example` creados bajo estricta frontera portable y límites de recursos.
- [x] Servicio Nango declarado en `.agents/config/fleet.example.yaml` (solo placeholders).
- [x] Despliegue en vivo ejecutado en el VPS de orquestación (<nodo-orquestacion>) usando la propia plantilla.
- [x] Health check real responde exitosamente en vivo (evidencia acreditada en el reporte de cierre, sin credenciales en repo).
- [x] Runbook `docs/runbooks/nango-oauth-service.md` redactado con procedimientos verificados en producción.
- [x] Subchecks de validación integrados en checks existentes de `tests/validate-control-plane.sh` manteniendo denominador inmutable en 38/38 (0 errores).
- [x] Cero literales privados o rutas de host en los archivos nuevos.
- [x] Ejecutada y registrada bajo las reglas de Opción D.

## Evidencia acreditada de deliberación y verificación en vivo
- **Deliberación de plan técnico**: Recibo `.agents/context/deliberation-T-166.json` emitido por Revisor Ejecutor Tier 1 (`qa-judge`) con veredicto `CONSENSO`.
- **Despliegue en vivo**: Stack desplegado en nodo de orquestación (`~/services/nango`) con Docker Compose v2.
- **Health check real verificado**:
  - `GET http://localhost:3003/health` -> HTTP 200 OK `{"result":"ok"}`
  - `HEAD http://localhost:3009` -> HTTP 200 OK (Connect UI)
  - Contenedores activos: `nango-server` (712MB), `nango-db` (85MB), `nango-redis` (3.4MB)
- **Suite de control plane**: 38/38 checks en verde (0 errores).
- **Higiene de localizadores**: 0 hallazgos en `locator-hygiene.sh`.
