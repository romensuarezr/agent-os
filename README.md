# Agent OS

> Repositorio central de configuración para agentes de IA en el ecosistema de romensuarezr.

## Propósito
Este repositorio contiene las reglas, skills y workflows universales que comparten todos mis proyectos. El objetivo es mantener una experiencia de desarrollo consistente, segura y eficiente, permitiendo que cada proyecto individual solo gestione su contexto específico.

## Estructura
- `.agents/rules/global/`: Reglas de comportamiento y estándares de ingeniería universales.
- `.agents/skills/`: Habilidades transversales (auditoría, planificación, onboarding).
- `.agents/workflows/`: Plantillas para el ciclo de vida de las sesiones y sprints.
- `.agents/profiles/`: Perfiles declarativos de agentes (`.yaml` y `.md`, ver [guía de precedencia](.agents/profiles/README.md)).
- `scripts/agent/`: Scripts del núcleo para instalación, sincronización y auditoría.

## Cómo Usar

### 1. Inicialización en Proyecto Nuevo
Antes de instalar, puedes ejecutar una simulación determinista sin tocar el disco:
```bash
# Simulación dry-run y comprobación de pre-flights (git, gh, infisical) con desglose de skills:
bash scripts/agent/install.sh --check /ruta/al/proyecto

# Instalación adaptativa recomendada (detecta el stack y propone skills idóneas):
bash scripts/agent/install.sh /ruta/al/proyecto

# Instalación mínima (únicamente conjunto base universal de habilidades):
bash scripts/agent/install.sh --minimal /ruta/al/proyecto

# Instalación completa (incluye habilidades de stacks específicos e infraestructura):
bash scripts/agent/install.sh --full /ruta/al/proyecto

# Bootstrapping sobre el propio core de agent-os:
bash scripts/agent/install.sh . --self
```

#### Modos de Instalación y Manifiesto de Skills (`.agents/config/skills-manifest.yaml`):
Agent OS clasifica sus habilidades mediante `.agents/config/skills-manifest.yaml` siguiendo el principio *Global pequeño, local fino*:
- **Universal** (`--minimal` o base): Habilidades agnósticas de stack e infra (auditoría arquitectónica, testing flows, doe-framework, ADRs, etc.).
- **Stack** (Adaptativo): Habilidades activadas según el framework detectado por `detect-stack.sh` (ej. `coolify-nextjs-deploy` para proyectos Next.js).
- **Infra** (`--full`): Módulos específicos de infraestructura (Coolify, Infisical, SSH).

Pre-flights incluidos:
- `git`, `cp`, `mkdir`: dependencias obligatorias (bloqueantes).
- `gh`: verificación de autenticación (`gh auth status`), bloqueante si se usa `--create-repo`.
- `infisical`: diagnóstico de estado de sesión para gestión centralizada de secretos.

### 2. Onboarding en Proyecto Existente (Con Vida Previa)
Si el repositorio ya tiene desarrollo, commits e historial, ejecuta la auditoría inteligente en modo de detección:
```bash
# Fase 1: Detección (Solo lectura, genera docs/agent-os-audit.md)
bash /ruta/a/agent-os/scripts/agent/audit-repo.sh

# Fase 2: Aplicación (Aplica renames, migra trackers y crea sprint-00)
bash /ruta/a/agent-os/scripts/agent/audit-repo.sh --apply
```

### 3. Sincronización de Actualizaciones
Para propagar mejoras del núcleo de `agent-os` a un proyecto ya configurado:
```bash
# Simular cambios y detectar personalizaciones locales sin tocar disco:
bash scripts/agent/sync.sh --dry-run /ruta/al/proyecto

# Sincronización estándar (protege personalizaciones locales y NO reintroduce skills descartadas):
bash scripts/agent/sync.sh /ruta/al/proyecto

# Forzar sobrescritura de personalizaciones locales:
bash scripts/agent/sync.sh --force /ruta/al/proyecto

# Limpieza interactiva de assets deprecados:
bash scripts/agent/sync.sh --cleanup /ruta/al/proyecto
```

---

Para consultar la versión actual, el historial de cambios y las notas de versiones del core, consulta [changelog.md](changelog.md).
