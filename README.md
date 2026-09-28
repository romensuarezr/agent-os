# Agent OS

> Repositorio central de configuración para agentes de IA en el ecosistema de romensuarezr.

## Propósito
Este repositorio contiene las reglas, skills y workflows universales que comparten todos mis proyectos. El objetivo es mantener una experiencia de desarrollo consistente, segura y eficiente, permitiendo que cada proyecto individual solo gestione su contexto específico.

## Estructura
- `.agents/rules/global/`: Reglas de comportamiento y estándares de ingeniería universales.
- `.agents/skills/`: Habilidades transversales (auditoría, planificación, onboarding).
- `.agents/workflows/`: Plantillas para el ciclo de vida de las sesiones y sprints.
- `scripts/agent/`: Scripts del núcleo para instalación, sincronización y auditoría.

## Cómo Usar

### 1. Inicialización en Proyecto Nuevo
Antes de instalar, puedes ejecutar una simulación determinista sin tocar el disco:
```bash
# Simulación dry-run y comprobación de pre-flights (git, gh, infisical)
bash scripts/agent/install.sh --check /ruta/al/proyecto

# Instalación real
bash scripts/agent/install.sh /ruta/al/proyecto

# Bootstrapping sobre el propio core de agent-os
bash scripts/agent/install.sh . --self
```

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

# Sincronización estándar (protege personalizaciones locales sin sobrescribir sin aviso):
bash scripts/agent/sync.sh /ruta/al/proyecto

# Forzar sobrescritura de personalizaciones locales:
bash scripts/agent/sync.sh --force /ruta/al/proyecto

# Limpieza interactiva de assets deprecados:
bash scripts/agent/sync.sh --cleanup /ruta/al/proyecto
```

---
*Core version: 1.1*
