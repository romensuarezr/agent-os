# T-230 — Adaptación de `generate-homepage-config.sh` para Stack Completo y Multi-Host
Sprint: Sprint 43 | Estado: ⬜ Pendiente | Tamaño: M | Rama propuesta: feat/T-230-homepage-generator-multihost | Merge destino: multi-agent

## Diseño macro aprobado en planning
- **Sprint / Fecha**: Sprint 43 — 2026-11-18
- **Diseño y arquitectura aprobados por**: Humano (Operador)
- **Decisiones e interfaces selladas**:
  - Modificar `scripts/agent/generate-homepage-config.sh` para:
    1. Parsear todos los servicios del stack declarados en `fleet.yaml` y distribuirlos en los 4 grupos:
       - `AI Gateways & Inferencia ($0)`: FreeLLMAPI, OmniRoute, Open-WebUI, Ollama.
       - `PaaS, Infraestructura & Control Plane`: Coolify (`https://coolify.romensuarez.com`), Nango OAuth, Infisical, Homepage.
       - `Productividad, Automatización & Búsqueda`: SearXNG, n8n, Umami, ByteBox, Ghost, WhatsApp Bridge, Twenty CRM, Calibre Web.
       - `Aplicaciones Satélite & Productos`: Outbid, Kanarii, Finca Adama, HD-API, Polybot & Bot3.
    2. En `widgets.yaml`:
       - Widget local `resources` para Oracle VPS (CPU, memoria, disco).
       - Widget remoto `glances` para DataManager VPS (`http://<TAILSCALE_IP_DATAMANAGER>:61208`, versión 4, expandido, CPU/RAM/Disco).
    3. En `settings.yaml`:
       - Adaptar la matriz de layouts con 4 columnas o filas proporcionadas a los 4 grupos.
    4. En `bookmarks.yaml`:
       - Enlaces rápidos de administración (Coolify Console, GitHub Agent OS, SearXNG, ByteBox).
    5. Filtrado riguroso de pings para no forzar tarjetas en estado DOWN (omitiendo pings rotos o usando rutas accesibles sin auth).
  - Regenerar la suite de plantillas en `templates/homepage/config/` de forma determinista y reproducible.
- **Veredicto de diseño macro**: [APROBADO_EN_PLANNING]

---

## 1. Objetivo
Permitir que el generador determinista compile de forma reproducible toda la configuración de Homepage reflejando el stack completo verificado en Coolify y soportando widgets de telemetría multi-host en la cabecera.

## 2. Contexto técnico
- Script generador: `scripts/agent/generate-homepage-config.sh`.
- Salida generada: `templates/homepage/config/*.yaml` (`services.yaml`, `widgets.yaml`, `settings.yaml`, `bookmarks.yaml`).
- Configuración de entrada: `.agents/config/fleet.yaml`.

## 3. Caja de archivos
- `scripts/agent/generate-homepage-config.sh`
- `templates/homepage/config/services.yaml`
- `templates/homepage/config/widgets.yaml`
- `templates/homepage/config/settings.yaml`
- `templates/homepage/config/bookmarks.yaml`
- `.agents/tasks/task-230.md`
- `docs/sprints/sprint-43.md`

## 4. Plan de implementación
1. Refactorizar la lógica de categorización de grupos en `generate-homepage-config.sh` para procesar los servicios añadidos en T-228.
2. Incorporar la detección dinámica y generación del bloque `glances` en `widgets.yaml` cuando un nodo reporte servicio Glances.
3. Configurar pings correctos (o desactivar ping cuando el endpoint requiera sesión privada para evitar falsos negativos en rojo).
4. Ejecutar `bash scripts/agent/generate-homepage-config.sh` para compilar los nuevos archivos YAML en `templates/homepage/config/`.
5. Validar con `bash scripts/agent/generate-homepage-config.sh --check` y verificar que la suite de tests de control plane (`tests/validate-control-plane.sh`) continúa en verde.

## 5. Criterios de aceptación
- `templates/homepage/config/services.yaml` contiene todos los servicios verificados del stack organizados coherentemente.
- `templates/homepage/config/widgets.yaml` incluye el widget local de Oracle VPS y el widget Glances de DataManager VPS.
- `scripts/agent/generate-homepage-config.sh --check` retorna exit code 0 sin advertencias de parsing.
