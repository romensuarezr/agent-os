# Changelog — Agent OS Core

Historial de cambios y releases del núcleo de Agent OS.

## [1.5.0] — 2026-09-24
### Añadido
- **Auditoría Integral de Infraestructura en `oracle` (T-035)**:
  - Creado `scripts/agent/audit-host.sh` en `remote-admin` para diagnóstico rápido en 1 sola llamada SSH (0 tokens de inferencia).
  - Elaborado runbook exhaustivo en `docs/runbooks/oracle-disk-and-ports-audit.md` detectando 83 GB en descargas huérfanas de seedbox, 31 GB de imágenes Docker recuperables y ausencia de UFW con bypass de `DOCKER-USER`.
- **Normalización de Autenticación GitHub SSH en Servidores Remotos (T-036)**:
  - Creado `scripts/agent/check-git-remote.sh` en `remote-admin` para auditar `known_hosts` y claves públicas en servidores remotos sin exponer claves privadas.
  - Elaborado runbook en `docs/runbooks/github-ssh-setup-remote.md` con estrategia de Deploy Keys de solo lectura y aprovisionamiento determinista vía `ssh-keyscan`.
- **Prospección Determinista Pre-Código (T-038)**:
  - Creado `scripts/agent/scout.sh` para consultar repositorios en GitHub REST API, paquetes en NPM Registry y debates de arquitectura en Hacker News Algolia con coste 0 tokens de inferencia.
  - Integrado en `.agents/skills/tech-scout/SKILL.md` como paso 0 obligatorio antes de búsquedas web o Perplexity.
  - Formalizada regla pre-código en `.agents/rules/global/tool-decision-flow.md`.
- **Diagnóstico y Decision Gates de Orca (T-037)**:
  - Creado `scripts/agent/audit-orca.sh` para auditar proceso local de Orca, integridad de `orchestration.db` en modo solo lectura, y conectividad de relés remotos en `datamanager` y `oracle`.
  - Actualizado runbook `docs/runbooks/orca-read-only-audit.md` con el protocolo de compuertas de decisión humanas (L3) ante mutaciones.
- **Captura en Idea Inbox**:
  - Ideas registradas en `docs/idea-inbox/` para gestor de secretos autoalojado Infisical con Coolify/Hermes y para inventario activo de herramientas de la flota.

### Corregido
- Soporte para nombres de archivo `changelog.md` en minúsculas en `scripts/agent/update-changelog.sh`.

## [1.4.0] — 2026-09-24
### Añadido
- **Perfiles Declarativos de Agentes (`.agents/profiles/`)**: Registro de perfiles YAML para `coordinator`, `ops-auditor`, `developer`, `reviewer`, `marketing`, `seo` y `researcher` con definición estricta de herramientas, hosts, modelos preferidos y condiciones de escalado.
- **Registro Central (`config/agent-registry.yaml`)**: Catálogo maestro que asocia cada perfil a sus motores de ejecución (`antigravity`, `hermes`, `orca`, `opencode`) y asignación de hosts.
- **Política de Routing de Modelos (`config/routing-policy.yaml`)**: Matriz abstracta de enrutamiento por criticidad y clase de tarea (`critical_tasks`, `code_implementation`, `read_only_operations`, `marketing_and_seo`, `summaries_and_triage`, `private_data_tasks`, `general_fallback`) con fallbacks a FreeLLMAPI y Ollama local.
- **Política Global de Permisos (`.agents/rules/global/agent-permissions.md`)**: Regla de gobernanza que tipifica permisos en niveles L1 (Autonomía), L2 (Plan Aprobado) y L3 (Decision Gate Humano Obligatorio) para prevenir acciones destructivas en producción.
- **ADR 004 y Topología de Red (`docs/adrs/adr-004-agent-control-plane-architecture.md`, `docs/architecture/control-plane-topology.md`)**: Arquitectura de federación (`agent-os` core vs `hermes-vps-config` infra), asignación de roles (Hermes front door, Orca execution plane) y salvaguardas de disco.
- **Runbook de Auditoría de Orca (`docs/runbooks/orca-read-only-audit.md`)**: Procedimiento estándar de inspección no destructiva de Orca Desktop, sockets de relé remoto en VPS y base de datos relacional.
- **Suite de Validación (`tests/validate-control-plane.sh`)**: Validador no destructivo de sintaxis YAML, esquema de perfiles, consistencia de hosts y detección de secretos.
- **Endurecimiento de `.gitignore` raíz**: Bloqueo activo de variables de entorno, claves criptográficas, logs, caches, worktrees y bases de datos runtime.

---

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
