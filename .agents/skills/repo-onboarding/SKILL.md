---
name: repo-onboarding
description: Guía de auditoría y onboarding inteligente para incorporar repositorios preexistentes al ecosistema de Agent OS.
---

# Repo Onboarding (Auditoría y Adaptación)

Esta habilidad instruye al agente sobre cómo usar `audit-repo.sh` para diagnosticar, alinear y estructurar repositorios existentes que ya contienen código, historial de Git o documentación previa, de manera que cumplan con el estándar de Agent OS sin comprometer el trabajo en curso.

---

## 🎯 Matriz de Decisión de Operaciones

Antes de actuar sobre un repositorio, determina cuál de las tres herramientas del núcleo de Agent OS es la indicada:

| Herramienta | Propósito Principal | Cuándo usar | Impacto / Peligros |
| :--- | :--- | :--- | :--- |
| `install.sh` | **Inicialización limpia** | Repositorios nuevos o que no tienen ninguna estructura previa de agentes. | Bajo (Crea carpetas vacías y copia scripts iniciales). |
| `sync.sh` | **Actualización de assets** | Repositorios ya inicializados que necesitan actualizar las versiones globales de reglas y habilidades del núcleo de `agent-os`. | Medio (Sobrescribe archivos globales modificados localmente si no están protegidos). |
| `audit-repo.sh` | **Auditoría e Integración** | Repositorios con vida previa y archivos preexistentes (ej: `ROADMAP.md`, `external-inbox/` en raíz) que requieren alinearse al formato estándar. | Alto (Realiza `git mv` de archivos de control y modifica contenidos de tracker y roadmap). |

---

## 📋 Protocolo de Ejecución en 3 Pasos

> [!IMPORTANT]
> El onboarding inteligente es un proceso en dos fases (Detección → Aprobación → Aplicación). NUNCA ejecutes el modo aplicación (`--apply`) directamente sin una fase previa de detección y aprobación explícita del usuario.

### Paso 1: Detección (Solo Lectura)
Ejecuta la auditoría en modo pasivo desde la raíz del repositorio de destino:
```bash
bash scripts/agent/audit-repo.sh
```

El script buscará y reportará:
1. **Stack Tecnológico** (mediante `detect-stack.sh`): identifica el ecosistema entre los 11 stacks soportados o emite honestamente `unknown` con guía para declarar `.agents/context/stack.env`.
2. **Pipelines de CI/CD e Infraestructura (IaC)**: detecta marcadores de integración continua (`.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`) e infraestructura como código (`terraform/`, `*.tf`, `docker-compose*.yml`), reportando honestamente `ninguno detectado` si están ausentes.
3. Incompatibilidades de casing (`ROADMAP.md` vs `roadmap.md`, `CHANGELOG.md` vs `changelog.md`, etc.).
4. Ubicación no estándar del inbox (`external-inbox` en la raíz en lugar de `docs/external-inbox/`).
5. Estructuras de `MVP-TRACKER.md` sin columna Peso o fila TOTAL.
6. Secciones faltantes en `roadmap.md`.
7. Commits históricos en Git para proponer un Sprint 00.

### Paso 2: Revisión y Presentación
Abre el reporte autogenerado en `docs/agent-os-audit.md` y preséntale un resumen claro al usuario:
- El stack tecnológico detectado (o recomendación de override si resultó `unknown`).
- Los componentes de CI/CD e IaC identificados (o su ausencia honesta).
- Las incompatibilidades estructurales encontradas.
- Lista exactamente qué archivos se renombrarán o moverán.
- Presenta el diff propuesto para `MVP-TRACKER.md` y `roadmap.md`.
- Muestra el esquema propuesto para `docs/sprints/sprint-00-historical.md`.

> [!WARNING]
> No ejecutes la aplicación de cambios si el usuario no ha aprobado explícitamente el informe de auditoría.

### Paso 3: Aplicación (Requiere Aprobación)
Una vez el usuario autoriza la aplicación de cambios:
1. **Verificación de Limpieza**: Asegúrate de que no haya cambios locales sin commitear ejecutando `git status`. El script `audit-repo.sh` abortará de forma segura si el working tree está sucio.
2. Ejecuta:
   ```bash
   bash scripts/agent/audit-repo.sh --apply
   ```
3. El script aplicará las modificaciones pertinentes y realizará un commit atómico automático:
   `chore(agent-os): apply audit adaptations to existing repo`

### Paso 4: Migración y Saneamiento de Secretos (`.env` → Infisical)
Si el repositorio preexistente contiene archivos `.env`, `.env.local` o variables sensibles en disco:
1. Auditar y verificar vigencia de claves sin alterar el entorno:
   ```bash
   bash scripts/agent/import-secrets.sh . --dry-run
   ```
2. Aplicar la migración jerárquica al gestor de secretos de la flota y proteger los archivos locales:
   ```bash
   bash scripts/agent/import-secrets.sh . --apply --env=dev --clean-env
   ```
   Esto creará la carpeta correspondiente al proyecto en Infisical y renombrará los archivos a `.env.backup`, eliminando el riesgo de filtraciones accidentales en Git.

---

## 🗃️ Manejo del Sprint 00 Histórico

El archivo `sprint-00-historical.md` tiene como objetivo encapsular el trabajo previo al ecosistema Agent OS para que las métricas y la trazabilidad sigan teniendo sentido sin tener que registrar manualmente las tareas del pasado.

### Cuándo es útil
- Cuando el repositorio tiene más de 2 semanas de desarrollo activo previo.
- Cuando hay commits claros en `git log` que demuestran la evolución de la arquitectura y las features.

### Cuándo omitirlo
- Si el repositorio está recién creado (menos de 5 commits significativos).
- Si el usuario te indica que prefiere ignorar el historial previo y empezar directamente desde el Sprint 01.

---

## ⚠️ Advertencia de Rango y Seguridad

*   **Peligro de pérdida de datos**: El script utiliza `git mv` para renombrar archivos. Si hay conflictos con archivos no rastreados con nombres similares, Git podría presentar advertencias. Trabaja siempre sobre una rama limpia y aislada.
*   **Colaboración en Equipo**: Si otros desarrolladores están trabajando en el mismo repositorio, la migración de casing (mayúsculas a minúsculas) puede ocasionar conflictos de Git en sistemas operativos que no distinguen mayúsculas de minúsculas de forma nativa (como macOS o Windows con sistemas de archivos por defecto). Advierte al usuario sobre esto antes de aplicar.

---

## ⚙️ Detección y Configuración del Stack Tecnológico (`detect-stack.sh`)

Los scripts del núcleo de Agent OS (`audit-repo.sh`, `inventory-check.sh`, `generate-digest.sh`) utilizan el motor universal `scripts/agent/lib/detect-stack.sh` (introducido en T-074). Este motor autodetecta el stack del proyecto según la presencia canónica de marcadores de compilación y empaquetado:

| Stack | Marcadores canónicos evaluados |
| :--- | :--- |
| `bun` | `bun.lock`, `bun.lockb` |
| `typescript` | `tsconfig.json` |
| `javascript` | `package.json` |
| `go` | `go.mod`, `go.sum` |
| `rust` | `Cargo.toml`, `Cargo.lock` |
| `java` | `pom.xml`, `build.gradle`, `build.gradle.kts` |
| `php` | `composer.json`, `composer.lock` |
| `ruby` | `Gemfile`, `Gemfile.lock` |
| `dotnet` | `*.csproj`, `*.sln` |
| `python` | `pyproject.toml`, `requirements.txt`, `setup.py`, `Pipfile` |
| `static` | `index.html`, `index.htm` (sin manifiestos backend) |
| `unknown` | Fallback honesto si ningún marcador coincide |

### Cómo forzar o declarar un Stack (Override)
Si el repositorio es híbrido, tiene monorepo o una estructura no estándar que resulta en `unknown`, puedes declarar el stack de forma determinista:

1. Crea o edita el archivo de configuración `.agents/context/stack.env` en la raíz del proyecto destino.
2. Define la variable `AGENT_OS_STACK` con uno de los 11 valores soportados:
   ```env
   # Valores válidos: python | typescript | javascript | go | rust | java | php | ruby | dotnet | bun | static
   AGENT_OS_STACK="python"
   ```

Alternativamente, puedes exportar la variable de entorno temporalmente en tu shell o sesión:
```bash
export AGENT_OS_STACK="go"
```
Esto tiene precedencia sobre las heurísticas automáticas y configura de inmediato las rutas fuente, patrones de tipos y exclusiones correspondientes para ese ecosistema.
