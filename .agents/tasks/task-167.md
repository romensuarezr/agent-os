# Task-167: Remediación determinista de compatibilidad en generate-homepage-config.sh y puesta a punto en vivo de Homepage Dashboard

## Objetivo
Robustecer el generador determinista `scripts/agent/generate-homepage-config.sh` como fallback transparente para esquemas simplificados de overlays privados (`fleet.yaml`), sanear `templates/homepage/config/services.yaml` eliminando URLs inventadas, regenerar la configuración con el generador y redesplegar en vivo la instancia de Homepage en VPS (<nodo-orquestacion>), verificando tarjeta por tarjeta desde el contenedor y con pase visual final, resolviendo Docker socket proxy y Glances según la realidad viva.

## Contexto técnico
El diagnóstico de campo de la flota (2026-11-03) evidenció que el contenedor Homepage en <nodo-orquestacion> presenta fallos de resolución DNS (`ENOTFOUND`) y de proxy (`ECONNREFUSED` hacia `localhost:8000`), debido a una configuración desfasada en volumen Docker.
Asimismo, `generate-homepage-config.sh --check` falla al ejecutarse contra overlays privados donde los servicios están definidos con puertos enteros numéricos o donde los nodos usan el campo `ip` en lugar de `host`.
Por mandato vinculante del Relé, esta tarea no solo corrige el generador y las plantillas, sino que exige la **remediación en vivo obligatoria** mediante redespliegue generado (nunca editando a mano el volumen), con dependencia estricta de T-166 para la tarjeta de Nango.
Esta tarea se ejecuta bajo el régimen estándar de **Opción D**.

## Diseño macro aprobado en planning
> Registro vinculante del diseño acordado entre el humano y el agente durante el sprint planning.
> El Revisor Ejecutor audita el plan técnico contra esta sección: cualquier desviación gatilla ESCALADO_A_HUMANO.

- **Sprint / Fecha**: Sprint 30 / 2026-11-03
- **Diseño y arquitectura aprobados por**: Relé (Veredicto APROBADO CON CAMBIOS con enmienda vinculante en Sprint Planning Sprint 30)
- **Decisiones e interfaces selladas**:
  - **Dependencia estricta de T-166**: la tarjeta de Nango en Homepage adopta el puerto y esquema verificados en T-166, sin asumir valores rígidos.
  - En `scripts/agent/generate-homepage-config.sh`:
    - Normalizar el acceso a servicios: si el valor de un servicio en `fleet.yaml` es un entero o string (puerto directo, ej. `freellmapi: 3001`), tratarlo como activo y construir el diccionario estándar con puerto por defecto, evitando llamadas directas `.get()` sobre tipos no-dict. Esto actúa como fallback transparente con defaults; el esquema estándar (diccionarios con `endpoint` y `description`) sigue siendo el preferido y documentado.
    - Soportar el campo `ip` como fallback transparente cuando `host` no esté definido en el nodo.
    - Integrar tarjeta de Nango en el grupo de PaaS / Control Plane.
  - En `templates/homepage/config/services.yaml`:
    - Cero URLs inventadas: los placeholders deben seguir siendo reconocibles por el filtro del generador (`is_placeholder_url`) para que se omitan en despliegues reales si no están activos.
    - Orca Desktop Engine queda configurable u omitida (nunca `localhost:8000` rígido ni URL ficticia).
    - La tarjeta de Ollama refleja la realidad viva verificada (puerto nativo o proxy directo en lugar de apuntar erróneamente al agregador).
  - **Remediación en vivo obligatoria**:
    - Regenerar los archivos de configuración con el generador ya tolerante y redesplegar en la instancia viva de Coolify en <nodo-orquestacion>. Queda terminantemente prohibido editar a mano el volumen Docker persistente.
    - Verificar tarjeta por tarjeta desde dentro del contenedor (resolución y conectividad) y certificar pase visual final.
    - Docker socket proxy y Glances se resuelven según la realidad viva (Glances solo se reactiva en `widgets.yaml` si el servicio responde; si no, queda documentado su estado).
  - En `docs/runbooks/coolify-homepage-deployment.md`:
    - Actualizar instrucciones de despliegue, socket proxy de Docker y variables de widgets (`HOMEPAGE_VAR_*`).
  - En `tests/validate-control-plane.sh`:
    - Actualizar Check 11 con subchecks que verifiquen fixtures de esquema estándar, abreviado y mixto, manteniendo el denominador rígidamente inmutable en **38/38** (0 errores).
  - Régimen Opción D: avance desatendido en camino limpio ante veredicto `CONSENSO`.
- **Veredicto de diseño macro**: `[APROBADO_EN_PLANNING]`

## Skills relevantes
- `coolify-admin`: Diagnóstico, configuración y redespliegue del stack Homepage en Coolify.
- `remote-admin`: Verificación y diagnóstico de contenedores remotos.
- `agent-os-scripts`: Herramientas deterministas del core y generadores.

## Caja de archivos
- `scripts/agent/generate-homepage-config.sh`
- `templates/homepage/config/services.yaml`
- `docs/runbooks/coolify-homepage-deployment.md`
- `tests/validate-control-plane.sh`
- `.agents/tasks/task-167.md`

## Criterios de done
- [ ] `generate-homepage-config.sh` procesa overlays con servicios definidos como enteros numéricos y nodos con campo `ip` como fallback transparente con defaults.
- [ ] Check 11 de `tests/validate-control-plane.sh` verifica fixtures de esquema estándar, abreviado y mixto manteniendo el denominador inmutable en 38/38 (0 errores).
- [ ] `templates/homepage/config/services.yaml` saneado sin URLs inventadas, con placeholders reconocibles para omisión, tarjeta de Orca configurable/omitida y Ollama reflejando la realidad viva verificada.
- [ ] Tarjeta de Nango incorporada reflejando el puerto y esquema verificados en T-166.
- [ ] Configuración regenerada deterministamente con el generador y redesplegada en la instancia viva en VPS (sin editar a mano volúmenes).
- [ ] Verificación en vivo tarjeta por tarjeta desde el contenedor y pase visual final certificado.
- [ ] Docker socket proxy y Glances resueltos según realidad viva y documentados en `docs/runbooks/coolify-homepage-deployment.md`.
- [ ] Cero literales privados o rutas absolutas en los cambios.
- [ ] Ejecutada y registrada bajo las reglas de Opción D.
