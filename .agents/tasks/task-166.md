# Task-166: Plantilla de despliegue soberano de Nango en VPS y runbook de integración

## Objetivo
Diseñar, formalizar y verificar la plantilla declarativa Docker Compose de Nango (`templates/nango/docker-compose.yml` y `templates/nango/.env.example`) bajo estricta frontera portable para el servidor de orquestación (<nodo-orquestacion>), declarar el servicio en `.agents/config/fleet.example.yaml`, elaborar el runbook de administración y autenticación unificada `docs/runbooks/nango-oauth-service.md`, y añadir las validaciones sintácticas en `tests/validate-control-plane.sh`.

## Contexto técnico
Nango es la plataforma open-source de referencia (13.1k⭐) para la integración y gestión unificada de autenticación OAuth hacia cientos de APIs externas. Actualmente, la flota de Agent OS no cuenta con una pasarela centralizada de autenticación OAuth para herramientas y agentes.
Esta tarea formaliza la arquitectura declarativa de Nango en el repositorio del core y sienta las bases operativas para su despliegue soberano en <nodo-orquestacion>, operando bajo el régimen estándar de **Opción D**.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 30 / 2026-11-03
- **Diseño y arquitectura aprobados por**: Humano / Relé (Sprint Planning Sprint 30)
- **Decisiones e interfaces selladas**:
  - Crear `templates/nango/docker-compose.yml` con el servicio `nango-server` (`nangohq/nango-server:latest`) y una base de datos PostgreSQL (`postgres:15-alpine`), con variables parametrizadas, volúmenes persistentes y límites de recursos estándar.
  - Crear `templates/nango/.env.example` con variables saneadas y documentación de configuración (`NANGO_SERVER_PORT: 4004`, `NANGO_DB_USER`, `NANGO_DB_PASSWORD`, `NANGO_ENCRYPTION_KEY`).
  - Registrar el esquema del servicio Nango en `.agents/config/fleet.example.yaml` bajo el nodo de orquestación.
  - Redactar el runbook operativo `docs/runbooks/nango-oauth-service.md` detallando despliegue en Coolify / Docker Compose, aprovisionamiento de secretos vía Infisical, rotación de claves de cifrado y consumo por agentes.
  - Incorporar validaciones en `tests/validate-control-plane.sh` que verifiquen la existencia y validez sintáctica de la plantilla Compose y esquema de flota de Nango.
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
- [ ] `templates/nango/docker-compose.yml` creado con arquitectura server + postgres y límites de recursos.
- [ ] `templates/nango/.env.example` creado con variables saneadas y explicadas.
- [ ] Servicio Nango declarado en `.agents/config/fleet.example.yaml`.
- [ ] Runbook `docs/runbooks/nango-oauth-service.md` redactado con procedimientos claros de despliegue y uso.
- [ ] Comprobaciones de control plane añadidas en `tests/validate-control-plane.sh`.
- [ ] Suite de validación de control plane pasando limpia (0 errores).
- [ ] Cero literales privados o rutas de host en los archivos nuevos.
- [ ] Ejecutada y registrada bajo las reglas de Opción D.
