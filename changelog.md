# Changelog — Agent OS Core

Historial de cambios y releases del núcleo de Agent OS.

## [1.3.0] — 2026-09-19
### Añadido
- **Skill Universal `remote-admin`**: Promovida al core (`.agents/skills/remote-admin`) para administración segura de servidores remotos vía SSH (`~/.ssh/config`), inspección de Docker y diagnóstico rápido de latencia/conectividad con el script `scripts/list-hosts.sh`.
- **Plantillas de Despliegue de FreeLLMAPI (`templates/freellmapi/`)**: Plantillas reutilizables de `docker-compose.yml`, `.env.example` y `config/freellmapi.config.json` para desplegar la pasarela de inferencia unificada con backend Ollama y proveedores gratuitos.
- **Runbook Operativo de FreeLLMAPI (`docs/runbooks/freellmapi-vps-runbook.md`)**: Guía detallada de arquitectura, binding seguro en Tailscale (`100.77.82.13:3001`), autenticación con Unified Key y ejemplos de consumo E2E (`curl`, OpenAI SDK).

### Infraestructura / Integración
- **Despliegue de FreeLLMAPI en `datamanager`**: Contenedor Docker configurado en `/home/ubuntu/freellmapi/`, conectado a la red compartida `datamanager_default` con acceso directo a los modelos de Ollama (`llama3.1:8b`, `qwen2.5:7b`, `qwen2.5:3b`, `mistral-nemo:12b`) y enrutamiento automático a proveedores cloud gratuitos.

---

## [1.2.0] — 2026-06-15
### Añadido
- **Biblioteca de Detección de Stack (`detect-stack.sh`)**: Creado un componente centralizado para identificar el framework/lenguaje (Python, TypeScript, JavaScript) y exportar rutas, extensiones, patrones de complejidad y excepciones.
- **Configuración de Stack Manual (`stack.env`)**: Opción de override manual a través de `.agents/context/stack.env` para evitar falsos positivos en proyectos híbridos o con tooling mixto.
- **Gestión de `.gitignore` en la Instalación**: Creado el template `templates/.gitignore-agent-os` y modificado `install.sh` para incorporar de manera automatizada las exclusiones de archivos generados, de sincronización y del session lock en el proyecto destino.

### Modificado
- `scripts/agent/install.sh`: Modificado para verificar la existencia del marcador de Agent OS e inyectar el bloque de exclusiones de forma no destructiva si no existe.
- `scripts/agent/inventory-check.sh`: Refactorizado para usar variables y arrays dinámicos de stack, y salida limpia con código `0` en proyectos vacíos.
- `scripts/agent/generate-digest.sh`: Refactorizado para etiquetar código e indexar extensiones de forma dinámica basándose en el stack del proyecto.

---

## [1.1.0] — 2026-06-15
### Añadido
- **Flujo de Onboarding Inteligente (`sprint-inicial.md`)**: Creado como ritual exclusivo de una sola ejecución para auditar y adaptar repositorios preexistentes.
- **Marca de Onboarding (`onboarding-complete.md`)**: Implementada la generación automática de un archivo de marca al aplicar con éxito la auditoría, garantizando la idempotencia del proceso.
- **Sincronización de Workflows**: Modificado `sync.sh` para propagar de manera segura nuevos flujos y rituales globales al proyecto destino.
- **Detección Desacoplada de Actualizaciones**: Añadido aviso de commits remotos en `sync.sh` y registro de fecha de sincronización local en `.agents/context/last-sync.md`.
- **Integración en Sprint Planning**: Añadida una instrucción en `sprint-planning.md` para recomendar la sincronización si la marca local tiene más de 7 días o si no existe.

### Modificado
- `scripts/agent/audit-repo.sh`: Implementada la salvaguarda de working tree limpio, control de ambigüedad en apply, y generación del archivo de marca.
- `scripts/agent/sync.sh`: Modificado para copiar el changelog del core, escribir la fecha del último sync y comprobar silenciosamente actualizaciones en GitHub.

---

## [1.0.0] — 2026-06-12
### Añadido
- **Estructura Base de Agentes**: Directorios `.agents/rules/`, `.agents/workflows/`, `.agents/skills/`.
- **Scripts del Ciclo de Vida**:
  - `check-session.sh` y `check-sprint.sh`.
  - `close-task.sh` y `close-sprint.sh`.
  - `install.sh` y `sync.sh`.
  - `inventory-check.sh` y `update-mvp-tracker.sh`.
- **Workflows Base**: `session-start.md`, `session-close.md`, `sprint-planning.md`, `changelog.md`, `honesto.md`.
