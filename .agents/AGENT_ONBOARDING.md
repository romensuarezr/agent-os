# AGENT_ONBOARDING.md — agent-os Core

> Secuencia canónica de arranque determinista (boot sequence) para agentes de IA que operan sobre el repositorio del núcleo de **agent-os**.

---

## 🎯 Secuencia Canónica de Arranque (Boot Sequence)

Sigue estrictamente estos pasos numerados al iniciar cualquier interacción con este repositorio:

### 1. Lectura de Arquitectura y Contrato Base
Lee [AGENTS.md](AGENTS.md) completo.  
Contiene los principios de diseño (SRP, DRY, modo no destructivo por defecto, coste 0 de tokens en diagnósticos deterministas) y las reglas de contribución al core.

### 2. Detección y Rescate de Sesión Activa
Ejecuta inmediatamente:
```bash
bash scripts/agent/check-session.sh
```
- Si devuelve `NO_ACTIVE_SESSION`: el entorno está limpio; procede al siguiente paso.
- Si devuelve un objeto JSON con metadatos: existe una sesión previa interrumpida. Activa el **Modo Rescate** según [.agents/workflows/session-start.md](.agents/workflows/session-start.md).

### 3. Descubrimiento de Habilidades (Skills)
Consulta el catálogo consolidado en:
[.agents/context/skills-inventory.md](.agents/context/skills-inventory.md)  
Identifica la skill adecuada para la tarea antes de inventar herramientas o duplicar lógica existente.

### 4. Pre-flights de Herramientas y Servicios Locales
Verifica deterministamente el estado operativo del tooling local ejecutando los comandos exactos y aplicando la resolución indicada ante fallos:

| Herramienta | Comando de Verificación | Estado Esperado | Si Falla (Resolución Guiada) |
|---|---|---|---|
| **Git** | `git status --short` | Árbol limpio | Si hay cambios locales no versionados: `git stash` o descartar antes de operar. |
| **GitHub CLI** | `gh auth status` | `Logged in to github.com account ...` | Ejecutar `gh auth login --web` o exportar `GITHUB_TOKEN` válido en el entorno. |
| **Infisical CLI** | `infisical profile list` | Al menos un perfil autenticado activo | Ejecutar `infisical login` o inyectar `INFISICAL_TOKEN` / Universal Auth en `.env.local`. |
| **Tailscale** | `tailscale status` | Malla conectada (nodo local online) | Ejecutar `sudo tailscale up` o iniciar el servicio con `sudo systemctl start tailscaled`. |
| **Docker** | `docker info` | Demonio respondiendo | Iniciar demonio con `sudo systemctl start docker` y verificar pertenencia al grupo `docker`. |

> 💡 **Diagnóstico integral de flota**: Si existe configuración de flota (`.agents/config/fleet.yaml`), ejecuta de forma determinista `bash scripts/agent/fleet-doctor.sh` para evaluar la conectividad viva de la malla Tailscale y pasarelas de inferencia sin consumir tokens.

### 5. Mapa de Navegación del Repositorio ("¿Dónde está cada cosa?")

| Dominio | Ruta Canónica | Propósito |
|---|---|---|
| **Reglas Globales** | [.agents/rules/global/](.agents/rules/global/) | Reglas agnósticas de comportamiento, calidad y gobernanza para agentes. |
| **Gobernanza Determinista** | [.agents/rules/global/deterministic-execution.md](.agents/rules/global/deterministic-execution.md) | Regla canónica anti-improvisación, pre-flights obligatorios y verificación determinista. |
| **Configuración Runtime** | [.agents/config/](.agents/config/) | Registro de agentes, routing, manifiesto de skills y overlays locales de flota. |
| **Habilidades (Skills)** | [.agents/skills/](.agents/skills/) | Directorios modulares con `SKILL.md` que capacitan al agente en tareas especializadas. |
| **Workflows** | [.agents/workflows/](.agents/workflows/) | Protocolos paso a paso para ceremonias (`session-start`, `session-close`, `sprint-planning`). |
| **Scripts CLI de Agente** | [scripts/agent/](scripts/agent/) | Herramientas deterministas en Bash/Python para auditoría, instalación, sincronización y tests. |
| **Inbox de Requerimientos** | [docs/external-inbox/](docs/external-inbox/) | Requerimientos de producto y manifiestos externos a procesar en sprint planning. |
| **Inbox de Ideas** | [docs/idea-inbox/](docs/idea-inbox/) | Propuestas técnicas e ideas de mejora pendientes de evaluación para el roadmap. |
| **Sprints y Planificación** | [docs/sprints/](docs/sprints/) | Sprints activos y archivo histórico de sprints completados (`_archived/`). |
| **Tareas Activas** | [.agents/tasks/](.agents/tasks/) | Contratos escritos de tareas del sprint activo (`task-XXX.md`). |
| **Plantillas** | [templates/](templates/) | Plantillas de servicios de infraestructura, documentos raíz y metas (`goals`). |

### 6. Mapa de Fases de Auditoría ("¿Qué regla cubre qué fase?")

Para evitar duplicidades o dispersión, las 4 reglas globales de análisis y auditoría cubren fases sucesivas del ciclo de desarrollo:

| Fase del Ciclo | Regla Canónica | Responsabilidad y Pregunta Clave |
|---|---|---|
| **1. Diagnóstico Inicial** | [.agents/rules/global/analysis-principles.md](.agents/rules/global/analysis-principles.md) | **¿Cuál es el problema real?** Análisis riguroso, lectura de logs y evidencia empírica sin asumir causas a ciegas. |
| **2. Selección de Tooling** | [.agents/rules/global/tool-decision-flow.md](.agents/rules/global/tool-decision-flow.md) | **¿Cómo lo resolvemos sin reinventar la rueda?** Árbol de decisión determinista: Flota > OSS > Free > Premium. |
| **3. Prevención de Duplicados** | [.agents/rules/global/dry-architecture.md](.agents/rules/global/dry-architecture.md) | **¿Existe ya esta lógica?** Firewall DRY: reutilizar módulos y helpers existentes antes de crear archivos nuevos. |
| **4. Modificación Segura** | [.agents/rules/global/audit-before-refactor.md](.agents/rules/global/audit-before-refactor.md) | **¿Qué impacto tiene el cambio?** Auditoría de acoplamiento, dependencias y contratos antes de editar código vivo. |

### 7. Gobernanza de Secretos y Fricción Deliberada (.env vs Infisical)

Agent OS impone **fricción explícita e intencional** en la gestión de credenciales y secretos (Decisión 5B):
- **Cero creación mágica de `.env`**: Ningún script ni agente debe generar o autocompletar archivos `.env` sin intervención consciente. El manejo de claves privadas requiere deliberación humana.
- **Fuente Canónica Centralizada**: La flota delega la gestión de secretos en **Infisical**. Para validar o inyectar variables de entorno de forma efímera y segura, utiliza `bash scripts/agent/import-secrets.sh` o el cliente oficial de Infisical.
- **Invariante L3**: Queda estrictamente prohibido versionar o commitear archivos `.env`, tokens o claves privadas (ver [`agent-permissions.md`](.agents/rules/global/agent-permissions.md) nivel L3). Los repositorios deben versionar únicamente plantillas desensibilizadas (`.env.example`).

---

## 🚫 Restricciones Críticas de Gobernanza
- **Ejecución determinista obligatoria**: Regida canónicamente por [.agents/rules/global/deterministic-execution.md](.agents/rules/global/deterministic-execution.md). Prohibido improvisar código o scripts ad-hoc en caliente.
- **Verificación determinista previa**: Nunca asumir que un servicio o endpoint existe sin comprobación previa mediante `bash scripts/agent/fleet-doctor.sh`.
- **Nunca trabajar directamente en la rama principal (`main`)**: utiliza siempre ramas de feature (`feat/T-XXX-...`).

