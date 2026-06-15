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

El script buscará:
1. Incompatibilidades de casing (`ROADMAP.md` vs `roadmap.md`, etc.).
2. Ubicación no estándar del inbox (`external-inbox` en la raíz en lugar de `docs/external-inbox/`).
3. Estructuras de `MVP-TRACKER.md` sin columna Peso o fila TOTAL.
4. Secciones faltantes en `roadmap.md`.
5. Commits históricos en Git para proponer un Sprint 00.

### Paso 2: Revisión y Presentación
Abre el reporte autogenerado en `docs/agent-os-audit.md` y preséntale un resumen claro al usuario:
- Describe las incompatibilidades estructurales encontradas.
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

## ⚙️ Configuración del Stack Tecnológico (Override)

Los scripts del núcleo de Agent OS (`inventory-check.sh`, `generate-digest.sh`) autodetectan el stack del proyecto (Python, TypeScript, JavaScript) basándose en la presencia de archivos clave como `pyproject.toml`, `requirements.txt`, `tsconfig.json` o `package.json`.

### Cómo forzar un Stack
Si trabajas en un proyecto híbrido o con una estructura no estándar que confunde a la autodetección, puedes forzar el stack del proyecto de forma manual:

1. Crea el archivo de configuración `.agents/context/stack.env` en la raíz del proyecto destino.
2. Define la variable `AGENT_OS_STACK` con uno de los siguientes valores:
   ```env
   # Valores válidos: python | typescript | javascript
   AGENT_OS_STACK="python"
   ```

Esto saltará las heurísticas de detección y aplicará las variables, rutas y extensiones correctas para ese stack en particular de forma inmediata.
