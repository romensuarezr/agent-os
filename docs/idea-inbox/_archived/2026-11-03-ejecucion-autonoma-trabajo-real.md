# Idea: Validación de Ejecución Autónoma Desatendida sobre Trabajo Real

- **Fecha:** 2026-11-03
- **Estado:** 💡 REGISTRADA, NO APROBADA
- **Tipo:** Operaciones / Validación de Autonomía / Infraestructura

---

## 1. Visión y Propósito

Probar la ejecución de agentes sin intervención del usuario humano, trabajando exclusivamente sobre trabajo real y casos de uso operativos de la flota, antes de promocionar cambios a la rama principal (`main`).

El objetivo es validar empíricamente que la autonomía acotada del sistema (compuertas deterministas, arbitraje y ejecución) resuelve tareas de infraestructura y producto sin asistencia ni escalados espurios.

---

## 2. Tareas a Acometer (Qué, no cómo)

1. **Bane en vivo**:
   - Poner en funcionamiento real el motor Bane para la búsqueda que actualmente se realiza de forma manual con Perplexity.
   - Estado actual: Existe código en el core (plantillas compose, cliente y workflow de deep-research), pero nunca ha sido desplegado en vivo en la flota, ni se ha ejecutado una query real ni una búsqueda autónoma real por esa vía.

2. **Instalación de Nango en VPS**:
   - Desplegar Nango en el servidor de orquestación (<nodo-orquestacion>) como gestor unificado de autenticación OAuth para herramientas y agentes.
   - Estado actual: No se encuentra instalado y su primera integración real está pendiente de definir.

3. **Corrección del Dashboard Homepage en VPS**:
   - Restablecer la operatividad del dashboard Homepage gestionado mediante Coolify en <nodo-orquestacion>, corrigiendo las discrepancias estructurales, de red y de proxy detectadas.
   - Estado actual: El contenedor se encuentra en ejecución, pero su configuración interna está rota e incompleta.

---

## 3. Hechos del Diagnóstico de Campo (2026-11-03)

Para que el proceso de sprint planning cuente con hechos verificables y no requiera asunciones:

- **Discrepancia de esquema en overlay de flota**:
  El overlay privado (`fleet.yaml`) utiliza un esquema abreviado (campo `ip` y puertos de servicios declarados como enteros numéricos), en contraste con el esquema estándar de `fleet.example.yaml` (campo `host` y diccionarios por servicio con `endpoint` y `description`). Esta disparidad provoca que `generate-homepage-config.sh --check` falle con `AttributeError: 'int' object has no attribute 'get'`. Al ejecutarse contra la plantilla estándar, el generador valida limpiamente.

- **Configuración desfasada y manual en volumen Docker**:
  El archivo `services.yaml` montado en el volumen persistente del contenedor no fue regenerado automáticamente, sino editado manualmente con anterioridad:
  - Mantiene dominios ficticios de ejemplo (`example.com`) en múltiples tarjetas (Infisical, ByteBox, Coolify, Traefik), los cuales fallan por resolución DNS (`ENOTFOUND`).
  - La tarjeta de Ollama apunta erróneamente al puerto del agregador de inferencia en lugar de a su puerto nativo o proxy directo.
  - La tarjeta de Orca apunta a `localhost:8000`, lo que causa `ECONNREFUSED` dentro del contenedor Homepage y en el navegador del usuario.

- **Estado de conectividad de pasarelas**:
  - El agregador de inferencia ($0) y GitHub responden con HTTP 200 OK.
  - La pasarela de inferencia multi-proveedor responde con redirección HTTP 307 en su raíz (`/`), mientras que su endpoint `/health` devuelve HTTP 404.

- **Bloqueo en proxy de Docker y autodescubrimiento**:
  El proxy `docker-socket-proxy` tiene configurado `SERVICES: '0'`. Al realizar Homepage peticiones internas a `/services` para descubrir contenedores, el proxy deniega la conexión con HTTP 403 Forbidden, generando excepciones continuas `AggregateError: code: 'ECONNREFUSED'` en los logs del servicio.

- **Variables de entorno para widgets ausentes**:
  No existe ninguna variable de entorno `HOMEPAGE_VAR_*` inyectada en el contenedor. Los widgets que requieren tokens de autenticación no pueden operar, funcionando únicamente enlaces estáticos. Asimismo, el widget de telemetría de hardware (Glances) del nodo de inferencia se encuentra comentado en `widgets.yaml`.

- **Desfase de versión de imagen**:
  La imagen en ejecución reporta internamente la versión `v2.4.0` (`package.json`), a diferencia de la versión asumida (`v2.7.0`).
