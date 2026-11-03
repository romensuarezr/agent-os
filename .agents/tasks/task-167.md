# Task-167: Remediación determinista de compatibilidad en generate-homepage-config.sh y puesta a punto de Homepage Dashboard

## Objetivo
Robustecer el generador determinista `scripts/agent/generate-homepage-config.sh` para tolerar tanto el esquema canónico (`fleet.example.yaml`) como esquemas simplificados de overlays privados (`fleet.yaml`), eliminando el error `AttributeError: 'int' object has no attribute 'get'`. Sanear `templates/homepage/config/services.yaml` eliminando URLs ficticias (`example.com`) y referencias erróneas (`localhost:8000`), y actualizar el runbook de despliegue en Coolify / VPS.

## Contexto técnico
El diagnóstico de campo de la flota (2026-11-03) evidenció que el contenedor Homepage en <nodo-orquestacion> presenta fallos de resolución DNS (`ENOTFOUND`) y de proxy (`ECONNREFUSED` hacia `localhost:8000`), debido a una configuración desfasada que contiene dominios de ejemplo.
Asimismo, `generate-homepage-config.sh --check` falla al ejecutarse contra overlays privados donde los servicios están definidos con puertos enteros numéricos o donde los nodos usan el campo `ip` en lugar de `host`.
Esta tarea soluciona de raíz la compatibilidad en el generador y sanea las plantillas del dashboard, operando bajo el régimen estándar de **Opción D**.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 30 / 2026-11-03
- **Diseño y arquitectura aprobados por**: Humano / Relé (Sprint Planning Sprint 30)
- **Decisiones e interfaces selladas**:
  - En `scripts/agent/generate-homepage-config.sh`:
    - Normalizar el acceso a servicios: si el valor de un servicio en `fleet.yaml` es un entero o string (puerto directo, ej. `freellmapi: 3001`), tratarlo como activo y construir el diccionario estándar con puerto por defecto, evitando llamadas directas `.get()` sobre tipos no-dict.
    - Soportar el campo `ip` como fallback transparente cuando `host` no esté definido en el nodo.
    - Añadir soporte para el servicio Nango (puerto 4004) en el grupo de PaaS / Control Plane de Homepage.
  - En `templates/homepage/config/services.yaml`:
    - Reemplazar dominios ficticios `example.com` por URLs configurables o marcadores válidos.
    - Corregir el endpoint de Orca Desktop Engine para que no apunte rígidamente a `localhost:8000`.
    - Ajustar la tarjeta de Ollama para apuntar al puerto nativo o proxy directo en lugar del agregador.
  - En `docs/runbooks/coolify-homepage-deployment.md`:
    - Documentar la resolución de excepciones del socket proxy de Docker (`SERVICES: '1'` si se requiere descubrimiento interno) y las variables `HOMEPAGE_VAR_*` para widgets autenticados.
  - En `tests/validate-control-plane.sh`:
    - Actualizar Check 11 para probar `generate-homepage-config.sh --check` tanto con esquema estándar (diccionarios) como con esquema abreviado (enteros / `ip`).
  - Régimen Opción D: avance desatendido en camino limpio ante veredicto `CONSENSO`.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `coolify-admin`: Diagnóstico y configuración del stack Homepage en Coolify.
- `remote-admin`: Verificación y diagnóstico de contenedores remotos.
- `agent-os-scripts`: Herramientas deterministas del core y generadores.

## Caja de archivos
- `scripts/agent/generate-homepage-config.sh`
- `templates/homepage/config/services.yaml`
- `docs/runbooks/coolify-homepage-deployment.md`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-167.md`

## Criterios de done
- [ ] `generate-homepage-config.sh` procesa sin errores overlays con servicios definidos como enteros numéricos y nodos con campo `ip`.
- [ ] `generate-homepage-config.sh --check` pasa limpiamente contra `fleet.example.yaml` y contra fixtures de esquema abreviado.
- [ ] `templates/homepage/config/services.yaml` saneado de dominios `example.com` y URLs locales no enrutables.
- [ ] `docs/runbooks/coolify-homepage-deployment.md` actualizado con notas de proxy Docker y variables de widgets.
- [ ] Check 11 de `tests/validate-control-plane.sh` actualizado y validado.
- [ ] Suite de validación de control plane pasando limpia (0 errores).
- [ ] Cero literales privados o rutas absolutas en los cambios.
- [ ] Ejecutada y registrada bajo las reglas de Opción D.
