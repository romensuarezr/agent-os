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
Para instalar este sistema en un nuevo repositorio vacío:
```bash
bash scripts/agent/install.sh /ruta/al/proyecto
```

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
bash scripts/agent/sync.sh /ruta/al/proyecto
```

---
*Core version: 1.1*
