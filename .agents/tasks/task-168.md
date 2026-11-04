# Task-168: Arreglo en vivo de Homepage, ping granular y descubrimiento portable multi-repo

## Estado
⬜ Pendiente

## Objetivo
Reparar de forma definitiva y en vivo el dashboard de Homepage en el VPS de orquestación (<nodo-orquestacion>), desacoplando el descubrimiento residual de Docker (`docker.yaml`), dotando al generador de soporte para pings de salud configurables o con fallback a `/` (para servicios como OmniRoute que carecen de `/health`), integrando Glances del VPS de inferencia si responde vivo con su widget, triando las tarjetas faltantes mediante endpoints reales verificados en el overlay privado, realizando un backup previo fechado con timestamp (`.bak`) antes de sobrescribir el volumen persistente en vivo, y condicionando el cierre de la tarea al **pase visual del usuario en navegador**.

## Contexto técnico
El diagnóstico de campo post T-167 evidenció que:
1. `docker.yaml` intenta consultar `tcp://docker-socket-proxy:2375/services` (búsqueda de Swarm services), pero `tecnativa/docker-socket-proxy` tiene configurado `SERVICES: '0'`, lo que provoca respuestas `403 Forbidden` y errores recurrentes `AggregateError: ECONNREFUSED` en `homepage.log`. Al eliminar `docker.yaml`, Homepage deja de intentar descubrir servicios Docker inexistentes y basa el 100% de su visualización en los servicios generados deterministamente desde el overlay privado (`fleet.yaml`).
2. Esto consolida el patrón de **descubrimiento portable multi-repo**: el mismo generador determinista (`generate-homepage-config.sh`) y las mismas plantillas (`templates/homepage/`) operan en cualquier repositorio hijo; cada repo mantiene su overlay privado (`fleet.yaml`), sin persistir ningún dato sensible en git.
3. OmniRoute responde HTTP 200 en su raíz `/`, pero HTTP 404 en `/health`, marcando erróneamente la tarjeta en rojo. El generador debe soportar rutas de ping personalizadas o utilizar `/` por defecto cuando `/health` no esté disponible.
4. Glances en el VPS de inferencia: debe verificarse si el daemon responde activamente en su puerto (61208). Si responde, se habilita su widget en `widgets.yaml` / `services.yaml`; si no responde o está inactivo, se mantiene documentado su estado sin degradar el dashboard.
5. Triage de tarjetas faltantes: Open-WebUI y Hermes deben quedar documentados según su arquitectura real; Ollama debe validarse en su host real (<nodo-inferencia>).
6. Toda actualización en vivo debe realizarse previa copia de seguridad fechada con timestamp del volumen activo de Coolify.
7. Esta tarea se ejecuta bajo el régimen estándar de **Opción D**.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 30 / 2026-11-04 (Enmienda T-168 a T-170)
- **Diseño y arquitectura aprobados por**: Relé (Decisión Macro de Enmienda Sprint 30)
- **Decisiones e interfaces selladas**:
  - **Ping granular por servicio**: Soportar `ping_path` explícito o fallback determinista a `/` para servicios como OmniRoute que devuelven 404 en `/health`.
  - **Eliminación de integración Docker (`docker.yaml`)**: Quitar la integración de sockets Docker de Homepage para erradicar los errores `ECONNREFUSED` / `403 Forbidden` hacia el proxy. El descubrimiento de la flota es puramente declarativo y portable a través de `fleet.yaml`.
  - **Descubrimiento portable multi-repo**: Las plantillas y el generador permanecen universales y aplicables a cualquier repositorio hijo satélite; la información privada de IPs/puertos reside estrictamente en el `fleet.yaml` local no trackeado.
  - **Triage de tarjetas**:
    - Restaurar únicamente tarjetas que cuenten con endpoints reales alcanzables en el overlay privado.
    - Explicar y documentar la situación operativa de Open-WebUI y Hermes.
    - Verificar el estado real del servicio Ollama en su host correspondiente.
  - **Glances**: Comprobar conectividad en el nodo secundario; si está activo, incorporar su widget de métricas en Homepage.
  - **Backup obligatorio antes de sobrescribir**: Generar un respaldo fechado con timestamp del directorio de configuración vivo (`..._homepage-config/_data.bak.<timestamp>`) en el VPS antes de aplicar la nueva configuración.
  - **Compuerta de cierre**: El cierre de la tarea requiere **estrictamente el pase visual del usuario en navegador**, no dándose por cerrada únicamente con respuestas HTTP automáticas del agente.
  - **Denominador de suite**: Inmutable en **38/38** (0 errores).

## Skills relevantes
- `coolify-admin`: Gestión del contenedor y volúmenes de Homepage en Coolify.
- `remote-admin`: Verificación de puertos y servicios en nodos remotos vía SSH determinista.
- `agent-os-scripts`: Generación determinista y validación de plantillas.

## Caja de archivos
- `scripts/agent/generate-homepage-config.sh`
- `templates/homepage/config/services.yaml`
- `templates/homepage/config/widgets.yaml`
- `templates/homepage/config/docker.yaml`
- `docs/runbooks/coolify-homepage-deployment.md`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-168.md`

## Criterios de done
- [ ] `generate-homepage-config.sh` soporta rutas de ping específicas por servicio (resuelve ping 200 en OmniRoute).
- [ ] Integración Docker Swarm (`docker.yaml`) removida del despliegue en vivo y plantillas, eliminando `ECONNREFUSED` en `homepage.log`.
- [ ] Principio de descubrimiento portable multi-repo preservado (plantillas agnósticas, 0 datos privados en git).
- [ ] Estado de Glances verificado en nodo secundario; widget integrado si responde o documentado si está inactivo.
- [ ] Triage completado para Ollama, Open-WebUI y Hermes con evidencia en el reporte.
- [ ] Backup fechado con timestamp creado en el VPS previo a la sobrescritura del volumen en vivo.
- [ ] Configuración regenerada y redesplegada en vivo en el VPS de orquestación.
- [ ] HTTP status 200 verificado para todos los pings de servicios activos.
- [ ] Pase visual del usuario en navegador otorgado y acreditado.
- [ ] Suite de validación de control plane inmutable en 38/38 pasando limpia (0 errores).
- [ ] Ejecutada y registrada bajo las reglas de Opción D.
